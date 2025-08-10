// POST /v1/search-semantic - ベクトル意味検索API
// Phase 2B Week 1: 意味検索機能実装

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

interface SemanticSearchRequest {
  query: string
  limit?: number
  similarity_threshold?: number
  category?: string
  source_type?: string
  tags?: string[]
}

interface SearchResult {
  id: string
  url: string
  title: string
  summary: string
  category: string
  source_type: string
  tags: string[]
  similarity_score: number
  created_at: string
  media_meta?: any
}

interface SemanticSearchResponse {
  results: SearchResult[]
  query: string
  total_results: number
  processing_time_ms: number
  embedding_cost_usd: number
}

// OpenAI Embeddings API call for query
async function generateQueryEmbedding(query: string): Promise<{
  embedding: number[],
  tokens: number
}> {
  const openaiApiKey = Deno.env.get('OPENAI_API_KEY')
  if (!openaiApiKey) {
    throw new Error('OpenAI API key not configured')
  }

  const response = await fetch('https://api.openai.com/v1/embeddings', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${openaiApiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: 'text-embedding-3-small',
      input: query,
      encoding_format: 'float'
    })
  })

  if (!response.ok) {
    const errorText = await response.text()
    throw new Error(`OpenAI Embeddings API error: ${response.status} ${errorText}`)
  }

  const result = await response.json()
  
  if (!result.data?.[0]?.embedding) {
    throw new Error('Invalid OpenAI Embeddings API response')
  }

  return {
    embedding: result.data[0].embedding,
    tokens: result.usage?.total_tokens || 0
  }
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
    const payload: SemanticSearchRequest = await req.json()

    // Basic validation
    if (!payload.query) {
      return new Response(
        JSON.stringify({ error: 'Query is required', code: 'MISSING_QUERY' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' }}
      )
    }

    const limit = Math.min(payload.limit || 20, 100)
    const similarityThreshold = payload.similarity_threshold || 0.7

    // Generate embedding for query
    const { embedding: queryEmbedding, tokens } = await generateQueryEmbedding(payload.query)
    const embeddingCost = tokens * 0.00000002

    // Record embedding cost
    await supabase
      .from('llm_costs')
      .insert({
        bookmark_id: null,
        model: 'text-embedding-3-small',
        prompt_tokens: tokens,
        completion_tokens: 0,
        total_tokens: tokens,
        cost_usd: embeddingCost,
        request_type: 'search_embedding',
        success: true
      })

    // Get all bookmarks with embeddings for now (simple implementation)
    let query = supabase
      .from('bookmarks')
      .select('*')
      .not('embedding', 'is', null)

    // Apply filters
    if (payload.category) {
      query = query.eq('category', payload.category)
    }

    if (payload.source_type) {
      query = query.eq('source_type', payload.source_type)
    }

    const { data: allBookmarks, error: searchError } = await query

    if (searchError) {
      throw new Error(`Search failed: ${searchError.message}`)
    }

    // Calculate similarity scores manually (temporary solution)
    const searchResults = (allBookmarks || [])
      .map(bookmark => {
        if (!bookmark.embedding) return null
        
        try {
          const bookmarkEmbedding = JSON.parse(bookmark.embedding)
          
          // Calculate cosine similarity
          let dotProduct = 0
          let normA = 0
          let normB = 0
          
          for (let i = 0; i < Math.min(queryEmbedding.length, bookmarkEmbedding.length); i++) {
            dotProduct += queryEmbedding[i] * bookmarkEmbedding[i]
            normA += queryEmbedding[i] * queryEmbedding[i]
            normB += bookmarkEmbedding[i] * bookmarkEmbedding[i]
          }
          
          const similarity = dotProduct / (Math.sqrt(normA) * Math.sqrt(normB))
          
          return {
            ...bookmark,
            similarity_score: similarity
          }
        } catch (e) {
          return null
        }
      })
      .filter(item => item && item.similarity_score > similarityThreshold)
      .sort((a, b) => b.similarity_score - a.similarity_score)
      .slice(0, limit)

    if (searchError) {
      throw new Error(`Search failed: ${searchError.message}`)
    }

    // Format results
    const results: SearchResult[] = (searchResults || []).map(item => ({
      id: item.id,
      url: item.url,
      title: item.title_final || item.url,
      summary: item.summary || '',
      category: item.category,
      source_type: item.source_type,
      tags: typeof item.tags === 'string' ? JSON.parse(item.tags) : (item.tags || []),
      similarity_score: item.similarity_score,
      created_at: item.created_at,
      media_meta: typeof item.media_meta === 'string' ? JSON.parse(item.media_meta) : item.media_meta
    }))

    const processingTime = Date.now() - startTime

    const response: SemanticSearchResponse = {
      results: results,
      query: payload.query,
      total_results: results.length,
      processing_time_ms: processingTime,
      embedding_cost_usd: embeddingCost
    }

    return new Response(
      JSON.stringify(response),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' }}
    )

  } catch (error) {
    console.error('Semantic search error:', error)
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