// POST /v1/bookmarks - ブックマーク保存API
// Phase 1B Week 2: 基本保存機能実装
// Phase 2A Week 2: URLメタデータ取得・LLM処理自動統合

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

interface BookmarkPayload {
  url: string
  title?: string
  tags?: string[]
  category?: string
  source_type?: 'youtube' | 'x' | 'article' | 'news' | 'other'
}

interface ErrorResponse {
  error: string
  code: string
  details?: any
}

// URLメタデータを取得
async function fetchUrlMetadata(url: string): Promise<any> {
  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseKey = Deno.env.get('SUPABASE_ANON_KEY')!
    
    const response = await fetch(`${supabaseUrl}/functions/v1/url-metadata`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${supabaseKey}`,
      },
      body: JSON.stringify({ url })
    })
    
    if (response.ok) {
      return await response.json()
    } else {
      console.warn('URL metadata fetch failed:', response.status, response.statusText)
      return null
    }
  } catch (error) {
    console.warn('URL metadata fetch error:', error)
    return null
  }
}

// LLM処理を開始（バックグラウンド）
async function startLLMProcessing(bookmarkId: string, url: string, title?: string, content?: string): Promise<void> {
  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseKey = Deno.env.get('SUPABASE_ANON_KEY')!
    
    // バックグラウンドでLLM処理を開始（結果は待たない）
    fetch(`${supabaseUrl}/functions/v1/llm-process`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${supabaseKey}`,
      },
      body: JSON.stringify({
        bookmark_id: bookmarkId,
        url: url,
        title: title,
        content: content
      })
    }).catch(error => {
      console.error('Background LLM processing failed:', error)
    })
  } catch (error) {
    console.error('Failed to start LLM processing:', error)
  }
}

serve(async (req) => {
  // CORS headers
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, idempotency-key',
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
    const payload: BookmarkPayload = await req.json()

    // Basic validation
    if (!payload.url) {
      return new Response(
        JSON.stringify({ error: 'URL is required', code: 'MISSING_URL' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' }}
      )
    }

    // URL validation
    let parsedUrl: URL
    try {
      parsedUrl = new URL(payload.url)
    } catch {
      return new Response(
        JSON.stringify({ error: 'Invalid URL format', code: 'INVALID_URL' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' }}
      )
    }

    // Extract domain from URL
    const domain = parsedUrl.hostname.replace('www.', '')

    // Determine source type if not provided
    let sourceType = payload.source_type || 'other'
    if (!payload.source_type) {
      if (domain.includes('youtube.com') || domain.includes('youtu.be')) {
        sourceType = 'youtube'
      } else if (domain.includes('twitter.com') || domain.includes('x.com')) {
        sourceType = 'x'
      } else if (domain.includes('news') || domain.includes('nikkei') || domain.includes('asahi')) {
        sourceType = 'news'
      } else {
        sourceType = 'article'
      }
    }

    // Handle idempotency
    const idempotencyKey = req.headers.get('idempotency-key')
    if (idempotencyKey) {
      const { data: existingKey } = await supabase
        .from('idempotency_keys')
        .select('bookmark_id')
        .eq('key', idempotencyKey)
        .single()

      if (existingKey) {
        // Return existing bookmark
        const { data: bookmark } = await supabase
          .from('bookmarks')
          .select('*')
          .eq('id', existingKey.bookmark_id)
          .single()

        return new Response(
          JSON.stringify(bookmark),
          { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' }}
        )
      }
    }

    // Check if URL already exists
    const { data: existingBookmark } = await supabase
      .from('bookmarks')
      .select('*')
      .eq('url', payload.url.toLowerCase())
      .single()

    if (existingBookmark) {
      return new Response(
        JSON.stringify(existingBookmark),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' }}
      )
    }

    // Fetch URL metadata for enhanced information
    let metadata = null
    try {
      metadata = await fetchUrlMetadata(payload.url)
    } catch (error) {
      console.warn('Metadata fetch failed, continuing without metadata:', error)
    }

    // Create new bookmark with metadata
    const bookmarkData = {
      url: payload.url,
      canonical_url: metadata?.canonical_url || payload.url,
      domain: domain,
      source_type: sourceType,
      title_raw: metadata?.title || null,
      title_final: payload.title || metadata?.title || parsedUrl.pathname.split('/').pop() || domain,
      summary: metadata?.description || '',
      tags: JSON.stringify(payload.tags || []),
      category: payload.category || 'other',
      content_text: metadata?.content_text || null,
      llm_status: 'queued' as const,
      media_meta: JSON.stringify({
        image: metadata?.image,
        video: metadata?.video,
        favicon: metadata?.favicon,
        site_name: metadata?.site_name,
        type: metadata?.type,
        author: metadata?.author,
        published_time: metadata?.published_time
      }),
      captured_at: new Date().toISOString()
    }

    const { data: newBookmark, error: insertError } = await supabase
      .from('bookmarks')
      .insert(bookmarkData)
      .select()
      .single()

    if (insertError) {
      console.error('Database insert error:', insertError)
      return new Response(
        JSON.stringify({ error: 'Failed to save bookmark', code: 'DATABASE_ERROR', details: insertError }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' }}
      )
    }

    // Store idempotency key if provided
    if (idempotencyKey && newBookmark) {
      await supabase
        .from('idempotency_keys')
        .insert({
          key: idempotencyKey,
          bookmark_id: newBookmark.id
        })
    }

    // Start background LLM processing
    if (newBookmark?.id) {
      try {
        await startLLMProcessing(
          newBookmark.id,
          payload.url,
          bookmarkData.title_final,
          bookmarkData.content_text
        )
        console.log('Background LLM processing started for bookmark:', newBookmark.id)
      } catch (error) {
        console.warn('Failed to start LLM processing:', error)
      }
    }

    return new Response(
      JSON.stringify(newBookmark),
      { status: 201, headers: { ...corsHeaders, 'Content-Type': 'application/json' }}
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