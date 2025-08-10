// POST /v1/search-hybrid - ハイブリッド検索API (BM25 + ベクトル)
// Phase 3A: RRF (Reciprocal Rank Fusion) による統合検索

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

interface HybridSearchRequest {
  query: string
  limit?: number
  bm25_weight?: number      // BM25結果の重み (0-1, デフォルト: 0.6)
  semantic_weight?: number  // セマンティック結果の重み (0-1, デフォルト: 0.4)
  similarity_threshold?: number
  category?: string
  source_type?: string
  rrf_k?: number           // RRF定数 (デフォルト: 60)
}

interface HybridSearchResult {
  id: string
  url: string
  title: string
  summary: string
  category: string
  source_type: string
  tags: string[]
  hybrid_score: number
  bm25_rank?: number
  semantic_score?: number
  rrf_score: number
  created_at: string
  media_meta?: any
}

interface HybridSearchResponse {
  results: HybridSearchResult[]
  query: string
  total_results: number
  processing_time_ms: number
  search_info: {
    method: 'hybrid_rrf'
    bm25_results: number
    semantic_results: number
    bm25_weight: number
    semantic_weight: number
    rrf_k: number
  }
}

// RRF (Reciprocal Rank Fusion) スコア計算
function calculateRRF(rank: number, k: number = 60): number {
  return 1 / (k + rank)
}

// 2つの検索結果をRRFでマージ
function mergeResultsWithRRF(
  bm25Results: any[], 
  semanticResults: any[], 
  bm25Weight: number = 0.6,
  semanticWeight: number = 0.4,
  rrfK: number = 60
): HybridSearchResult[] {
  const mergedMap = new Map<string, any>()

  // BM25結果を処理
  bm25Results.forEach((result, index) => {
    const rrfScore = calculateRRF(index + 1, rrfK)
    mergedMap.set(result.id, {
      ...result,
      bm25_rank: index + 1,
      bm25_rrf: rrfScore,
      semantic_score: 0,
      semantic_rrf: 0
    })
  })

  // セマンティック検索結果を統合
  semanticResults.forEach((result, index) => {
    const rrfScore = calculateRRF(index + 1, rrfK)
    
    if (mergedMap.has(result.id)) {
      // 既存の結果に追加
      const existing = mergedMap.get(result.id)
      existing.semantic_score = result.similarity_score
      existing.semantic_rrf = rrfScore
    } else {
      // 新しい結果を追加
      mergedMap.set(result.id, {
        id: result.id,
        url: result.url,
        title: result.title,
        summary: result.summary,
        category: result.category,
        source_type: result.source_type,
        tags: result.tags,
        created_at: result.created_at,
        media_meta: result.media_meta,
        bm25_rank: null,
        bm25_rrf: 0,
        semantic_score: result.similarity_score,
        semantic_rrf: rrfScore
      })
    }
  })

  // 最終スコアを計算してソート
  const results = Array.from(mergedMap.values()).map(result => ({
    ...result,
    rrf_score: (result.bm25_rrf || 0) + (result.semantic_rrf || 0),
    hybrid_score: (result.bm25_rrf * bm25Weight) + (result.semantic_rrf * semanticWeight)
  }))

  return results.sort((a, b) => b.hybrid_score - a.hybrid_score)
}

serve(async (req) => {
  // CORS headers
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
  }

  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  // Only allow POST
  if (req.method !== 'POST') {
    return new Response(
      JSON.stringify({ error: 'Method not allowed', code: 'METHOD_NOT_ALLOWED' }), 
      { 
        status: 405, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  }

  const startTime = Date.now()

  try {
    // Initialize Supabase client
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseKey)

    // Parse request body
    const payload: HybridSearchRequest = await req.json()

    // Basic validation
    if (!payload.query || !payload.query.trim()) {
      return new Response(
        JSON.stringify({ error: 'Query is required', code: 'MISSING_QUERY' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' }}
      )
    }

    const limit = Math.min(payload.limit || 20, 100)
    const bm25Weight = payload.bm25_weight ?? 0.6
    const semanticWeight = payload.semantic_weight ?? 0.4
    const rrfK = payload.rrf_k ?? 60

    // 並列でBM25検索とセマンティック検索を実行
    const [bm25Response, semanticResponse] = await Promise.allSettled([
      // BM25全文検索
      fetch(`${supabaseUrl}/functions/v1/search-fulltext`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${supabaseKey}`,
          'apikey': supabaseKey
        },
        body: JSON.stringify({
          query: payload.query,
          limit: limit * 2, // より多くの候補を取得
          category: payload.category,
          source_type: payload.source_type
        })
      }),
      // セマンティック検索
      fetch(`${supabaseUrl}/functions/v1/search-semantic`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${supabaseKey}`,
          'apikey': supabaseKey
        },
        body: JSON.stringify({
          query: payload.query,
          limit: limit * 2, // より多くの候補を取得
          similarity_threshold: payload.similarity_threshold || 0.3,
          category: payload.category,
          source_type: payload.source_type
        })
      })
    ])

    // BM25検索結果を処理
    let bm25Results: any[] = []
    if (bm25Response.status === 'fulfilled' && bm25Response.value.ok) {
      const bm25Data = await bm25Response.value.json()
      bm25Results = bm25Data.results || []
    } else {
      console.warn('BM25 search failed:', bm25Response)
    }

    // セマンティック検索結果を処理
    let semanticResults: any[] = []
    if (semanticResponse.status === 'fulfilled' && semanticResponse.value.ok) {
      const semanticData = await semanticResponse.value.json()
      semanticResults = semanticData.results || []
    } else {
      console.warn('Semantic search failed:', semanticResponse)
    }

    // RRFでマージ
    const hybridResults = mergeResultsWithRRF(
      bm25Results,
      semanticResults,
      bm25Weight,
      semanticWeight,
      rrfK
    ).slice(0, limit) // 最終的なリミットを適用

    const processingTime = Date.now() - startTime

    const response: HybridSearchResponse = {
      results: hybridResults,
      query: payload.query,
      total_results: hybridResults.length,
      processing_time_ms: processingTime,
      search_info: {
        method: 'hybrid_rrf',
        bm25_results: bm25Results.length,
        semantic_results: semanticResults.length,
        bm25_weight: bm25Weight,
        semantic_weight: semanticWeight,
        rrf_k: rrfK
      }
    }

    return new Response(
      JSON.stringify(response),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' }}
    )

  } catch (error) {
    console.error('Hybrid search error:', error)
    return new Response(
      JSON.stringify({ 
        error: 'Internal server error', 
        code: 'INTERNAL_ERROR',
        details: error.message 
      }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' }}
    )
  }
})