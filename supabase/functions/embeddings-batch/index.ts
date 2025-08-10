// POST /v1/embeddings-batch - 既存ブックマーク埋め込み生成バッチAPI
// Phase 2B Week 1: 既存データのベクトル化

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

interface BatchRequest {
  limit?: number // 処理する件数（デフォルト10件）
  offset?: number // スキップする件数
}

interface BatchResponse {
  processed: number
  successful: number
  failed: number
  total_cost_usd: number
  remaining_count: number
  errors: string[]
}

// OpenAI Embeddings API call（バッチ用）
async function generateEmbeddingBatch(texts: string[]): Promise<{
  embeddings: number[][],
  tokens: number
}> {
  const openaiApiKey = Deno.env.get('OPENAI_API_KEY')
  if (!openaiApiKey) {
    throw new Error('OpenAI API key not configured')
  }

  // テキストを適切な長さに制限
  const maxLength = 32000
  const processedTexts = texts.map(text => 
    text.length > maxLength ? text.substring(0, maxLength) : text
  )

  const response = await fetch('https://api.openai.com/v1/embeddings', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${openaiApiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: 'text-embedding-3-small',
      input: processedTexts,
      encoding_format: 'float'
    })
  })

  if (!response.ok) {
    const errorText = await response.text()
    throw new Error(`OpenAI Embeddings API error: ${response.status} ${errorText}`)
  }

  const result = await response.json()
  
  if (!result.data || result.data.length !== texts.length) {
    throw new Error('Invalid OpenAI Embeddings API response')
  }

  return {
    embeddings: result.data.map((item: any) => item.embedding),
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

  try {
    // Initialize Supabase client
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseKey)

    // Parse request body
    const payload: BatchRequest = await req.json() || {}
    const limit = Math.min(payload.limit || 10, 50) // 最大50件まで
    const offset = payload.offset || 0

    // Get bookmarks without embeddings
    const { data: bookmarks, error: fetchError } = await supabase
      .from('bookmarks')
      .select('id, title_final, summary, content_text')
      .is('embedding', null)
      .range(offset, offset + limit - 1)

    if (fetchError) {
      throw new Error(`Failed to fetch bookmarks: ${fetchError.message}`)
    }

    if (!bookmarks || bookmarks.length === 0) {
      return new Response(
        JSON.stringify({
          processed: 0,
          successful: 0,
          failed: 0,
          total_cost_usd: 0,
          remaining_count: 0,
          errors: []
        } as BatchResponse),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' }}
      )
    }

    // Get total remaining count
    const { count: totalRemaining } = await supabase
      .from('bookmarks')
      .select('*', { count: 'exact', head: true })
      .is('embedding', null)

    // Prepare texts for embedding
    const texts = bookmarks.map(bookmark => {
      const parts = [
        bookmark.title_final,
        bookmark.summary,
        bookmark.content_text?.substring(0, 1000) // 最初の1000文字のみ
      ].filter(Boolean)
      
      return parts.join(' | ')
    })

    let successful = 0
    let failed = 0
    let totalCost = 0
    const errors: string[] = []

    try {
      // Generate embeddings in batch
      const { embeddings, tokens } = await generateEmbeddingBatch(texts)
      const cost = tokens * 0.00000002 // text-embedding-3-small cost

      // Update bookmarks with embeddings
      for (let i = 0; i < bookmarks.length; i++) {
        try {
          const { error: updateError } = await supabase
            .from('bookmarks')
            .update({ 
              embedding: `[${embeddings[i].join(',')}]`,
              updated_at: new Date().toISOString()
            })
            .eq('id', bookmarks[i].id)

          if (updateError) {
            throw new Error(`Update failed: ${updateError.message}`)
          }

          successful++
        } catch (updateError) {
          failed++
          errors.push(`Bookmark ${bookmarks[i].id}: ${updateError.message}`)
        }
      }

      totalCost = cost

      // Record batch cost
      await supabase
        .from('llm_costs')
        .insert({
          bookmark_id: null,
          model: 'text-embedding-3-small',
          prompt_tokens: tokens,
          completion_tokens: 0,
          total_tokens: tokens,
          cost_usd: cost,
          request_type: 'embedding_batch',
          success: true
        })

    } catch (batchError) {
      failed = bookmarks.length
      errors.push(`Batch processing failed: ${batchError.message}`)

      // Record failed batch
      await supabase
        .from('llm_costs')
        .insert({
          bookmark_id: null,
          model: 'text-embedding-3-small',
          prompt_tokens: 0,
          completion_tokens: 0,
          total_tokens: 0,
          cost_usd: 0,
          request_type: 'embedding_batch',
          success: false,
          error_message: batchError.message
        })
    }

    const response: BatchResponse = {
      processed: bookmarks.length,
      successful: successful,
      failed: failed,
      total_cost_usd: totalCost,
      remaining_count: (totalRemaining || 0) - successful,
      errors: errors
    }

    return new Response(
      JSON.stringify(response),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' }}
    )

  } catch (error) {
    console.error('Batch function error:', error)
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