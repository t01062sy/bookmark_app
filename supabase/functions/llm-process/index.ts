// POST /v1/llm/process - LLM processing API
// Phase 2A Week 1: OpenAI API統合とLLM基本機能実装

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

interface LLMProcessPayload {
  bookmark_id: string
  url: string
  title?: string
  content?: string
}

interface LLMProcessResponse {
  bookmark_id: string
  summary?: string
  category?: string
  tags?: string[]
  status: 'processing' | 'done' | 'failed'
  error_message?: string
  cost?: number
}

interface ErrorResponse {
  error: string
  code: string
  details?: any
}

// OpenAI API call function
async function callOpenAI(content: string, title: string, url: string): Promise<{
  summary: string,
  category: string,
  tags: string[]
}> {
  const openaiApiKey = Deno.env.get('OPENAI_API_KEY')
  if (!openaiApiKey) {
    throw new Error('OpenAI API key not configured')
  }

  const prompt = `
以下のブックマークを分析して、日本語で要約・分類・タグ付けしてください。

URL: ${url}
タイトル: ${title}
内容: ${content}

以下のJSON形式で回答してください：
{
  "summary": "2-3文の簡潔な要約",
  "category": "tech/news/blog/video/other のいずれか",
  "tags": ["関連するタグ", "最大5個まで"]
}
`

  const response = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${openaiApiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: 'gpt-4o-mini',
      messages: [
        {
          role: 'system',
          content: 'あなたはWebページのコンテンツを分析して要約・分類・タグ付けを行うAIアシスタントです。日本語で回答してください。'
        },
        {
          role: 'user',
          content: prompt
        }
      ],
      temperature: 0.3,
      max_tokens: 500
    })
  })

  if (!response.ok) {
    throw new Error(`OpenAI API error: ${response.status} ${response.statusText}`)
  }

  const result = await response.json()
  
  if (!result.choices?.[0]?.message?.content) {
    throw new Error('Invalid OpenAI API response')
  }

  try {
    return JSON.parse(result.choices[0].message.content)
  } catch {
    throw new Error('Failed to parse OpenAI response as JSON')
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
    const payload: LLMProcessPayload = await req.json()

    // Basic validation
    if (!payload.bookmark_id || !payload.url) {
      return new Response(
        JSON.stringify({ error: 'bookmark_id and url are required', code: 'MISSING_REQUIRED_FIELDS' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' }}
      )
    }

    // Update bookmark status to processing
    await supabase
      .from('bookmarks')
      .update({ 
        llm_status: 'processing',
        llm_processed_at: new Date().toISOString()
      })
      .eq('id', payload.bookmark_id)

    let llmResult: {summary: string, category: string, tags: string[]}
    
    try {
      // Call OpenAI API
      llmResult = await callOpenAI(
        payload.content || '',
        payload.title || payload.url,
        payload.url
      )
    } catch (openaiError) {
      console.error('OpenAI API error:', openaiError)
      
      // Update bookmark with failed status
      await supabase
        .from('bookmarks')
        .update({ 
          llm_status: 'failed',
          llm_error: openaiError.message
        })
        .eq('id', payload.bookmark_id)

      return new Response(
        JSON.stringify({ 
          bookmark_id: payload.bookmark_id,
          status: 'failed',
          error_message: openaiError.message
        } as LLMProcessResponse),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' }}
      )
    }

    // Update bookmark with LLM results
    const { error: updateError } = await supabase
      .from('bookmarks')
      .update({
        summary: llmResult.summary,
        category: llmResult.category,
        tags: JSON.stringify(llmResult.tags),
        llm_status: 'done'
      })
      .eq('id', payload.bookmark_id)

    if (updateError) {
      console.error('Database update error:', updateError)
      return new Response(
        JSON.stringify({ 
          error: 'Failed to update bookmark', 
          code: 'DATABASE_ERROR', 
          details: updateError 
        }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' }}
      )
    }

    // Return success response
    const response: LLMProcessResponse = {
      bookmark_id: payload.bookmark_id,
      summary: llmResult.summary,
      category: llmResult.category,
      tags: llmResult.tags,
      status: 'done'
    }

    return new Response(
      JSON.stringify(response),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' }}
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