// POST /v1/bookmarks - ブックマーク保存API
// Phase 1B Week 2: 基本保存機能実装

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

    // Create new bookmark
    const bookmarkData = {
      url: payload.url,
      domain: domain,
      source_type: sourceType,
      title_final: payload.title || parsedUrl.pathname.split('/').pop() || domain,
      tags: JSON.stringify(payload.tags || []),
      category: payload.category || 'other',
      llm_status: 'queued' as const,
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