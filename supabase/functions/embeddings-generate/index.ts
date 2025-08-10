// POST /v1/embeddings-generate - ベクトル埋め込み生成API
// Phase 2B Week 1: ベクトル検索機能実装

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

interface EmbeddingRequest {
  bookmark_id?: string
  text: string
  batch?: boolean // バッチ処理モード
}

interface EmbeddingResponse {
  bookmark_id?: string
  embedding: number[]
  tokens: number
  cost_usd: number
  success: boolean
  error_message?: string
}

interface ErrorResponse {
  error: string
  code: string
  details?: any
}

// OpenAI Embeddings API call
async function generateEmbedding(text: string): Promise<{
  embedding: number[],
  tokens: number
}> {
  const openaiApiKey = Deno.env.get('OPENAI_API_KEY')
  if (!openaiApiKey) {
    throw new Error('OpenAI API key not configured')
  }

  // テキストを適切な長さに制限（8192トークン制限）
  const maxLength = 32000 // 約8192トークンに相当
  const processedText = text.length > maxLength ? text.substring(0, maxLength) : text

  const response = await fetch('https://api.openai.com/v1/embeddings', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${openaiApiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: 'text-embedding-3-small',
      input: processedText,
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

// コスト計算（text-embedding-3-small: $0.02 per 1M tokens）
function calculateEmbeddingCost(tokens: number): number {
  return tokens * 0.00000002
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
    const payload: EmbeddingRequest = await req.json()

    // Basic validation
    if (!payload.text) {
      return new Response(
        JSON.stringify({ error: 'Text is required', code: 'MISSING_TEXT' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' }}
      )
    }

    // Check cost limits before processing (unless batch mode)
    if (!payload.batch) {
      const { data: canProcess } = await supabase
        .rpc('check_daily_cost_limit')
      
      if (!canProcess) {
        return new Response(
          JSON.stringify({ 
            error: 'Daily cost limit reached',
            code: 'COST_LIMIT_REACHED'
          }),
          { status: 429, headers: { ...corsHeaders, 'Content-Type': 'application/json' }}
        )
      }
    }

    let result: EmbeddingResponse
    
    try {
      // Generate embedding
      const { embedding, tokens } = await generateEmbedding(payload.text)
      const cost = calculateEmbeddingCost(tokens)

      // Update bookmark with embedding if bookmark_id provided
      if (payload.bookmark_id) {
        const { error: updateError } = await supabase
          .from('bookmarks')
          .update({ 
            embedding: `[${embedding.join(',')}]`,
            updated_at: new Date().toISOString()
          })
          .eq('id', payload.bookmark_id)

        if (updateError) {
          console.error('Failed to update bookmark embedding:', updateError)
        }
      }

      // Record cost
      await supabase
        .from('llm_costs')
        .insert({
          bookmark_id: payload.bookmark_id || null,
          model: 'text-embedding-3-small',
          prompt_tokens: tokens,
          completion_tokens: 0,
          total_tokens: tokens,
          cost_usd: cost,
          request_type: 'embedding',
          success: true
        })

      result = {
        bookmark_id: payload.bookmark_id,
        embedding: embedding,
        tokens: tokens,
        cost_usd: cost,
        success: true
      }

    } catch (embeddingError) {
      console.error('Embedding generation error:', embeddingError)
      
      // Record failed attempt
      await supabase
        .from('llm_costs')
        .insert({
          bookmark_id: payload.bookmark_id || null,
          model: 'text-embedding-3-small',
          prompt_tokens: 0,
          completion_tokens: 0,
          total_tokens: 0,
          cost_usd: 0,
          request_type: 'embedding',
          success: false,
          error_message: embeddingError.message
        })

      result = {
        bookmark_id: payload.bookmark_id,
        embedding: [],
        tokens: 0,
        cost_usd: 0,
        success: false,
        error_message: embeddingError.message
      }
    }

    return new Response(
      JSON.stringify(result),
      { status: result.success ? 200 : 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' }}
    )

  } catch (error) {
    console.error('Function error:', error)
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