// GET /v1/bookmarks - ブックマーク一覧取得・検索API
// Phase 1B Week 2: 基本検索・フィルタ機能実装

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

interface QueryParams {
  q?: string          // 検索クエリ
  category?: string   // カテゴリフィルタ
  source_type?: string // ソースタイプフィルタ  
  tags?: string       // タグフィルタ (comma-separated)
  archived?: string   // アーカイブフィルタ
  pinned?: string     // ピン留めフィルタ
  limit?: string      // 取得件数制限
  offset?: string     // オフセット
  sort?: string       // ソート順: created_at_desc, created_at_asc, updated_at_desc, title_asc
}

serve(async (req) => {
  // CORS headers
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
    'Access-Control-Allow-Methods': 'GET, OPTIONS',
  }

  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  // Only allow GET
  if (req.method !== 'GET') {
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

    // Parse query parameters
    const url = new URL(req.url)
    const params: QueryParams = Object.fromEntries(url.searchParams)

    // Build query
    let query = supabase
      .from('bookmarks')
      .select('*')

    // Apply filters
    if (params.category && params.category !== 'all') {
      query = query.eq('category', params.category)
    }

    if (params.source_type && params.source_type !== 'all') {
      query = query.eq('source_type', params.source_type)
    }

    if (params.archived !== undefined) {
      query = query.eq('archived', params.archived === 'true')
    } else {
      // Default: exclude archived
      query = query.eq('archived', false)
    }

    if (params.pinned !== undefined) {
      query = query.eq('pinned', params.pinned === 'true')
    }

    // Tag filtering
    if (params.tags) {
      const tagList = params.tags.split(',').map(tag => tag.trim())
      for (const tag of tagList) {
        query = query.contains('tags', `"${tag}"`)
      }
    }

    // Text search (simple implementation)
    if (params.q) {
      const searchTerm = params.q.trim()
      if (searchTerm) {
        // Search in title and summary
        query = query.or(`title_final.ilike.%${searchTerm}%,summary.ilike.%${searchTerm}%,content_text.ilike.%${searchTerm}%`)
      }
    }

    // Sorting
    const sortParam = params.sort || 'created_at_desc'
    switch (sortParam) {
      case 'created_at_asc':
        query = query.order('created_at', { ascending: true })
        break
      case 'updated_at_desc':
        query = query.order('updated_at', { ascending: false })
        break
      case 'title_asc':
        query = query.order('title_final', { ascending: true })
        break
      case 'created_at_desc':
      default:
        query = query.order('created_at', { ascending: false })
        break
    }

    // Pagination
    const limit = Math.min(parseInt(params.limit || '50'), 100) // Max 100
    const offset = parseInt(params.offset || '0')
    
    query = query.range(offset, offset + limit - 1)

    // Execute query
    const { data: bookmarks, error } = await query

    if (error) {
      console.error('Database query error:', error)
      return new Response(
        JSON.stringify({ 
          error: 'Failed to fetch bookmarks', 
          code: 'DATABASE_ERROR', 
          details: error 
        }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' }}
      )
    }

    // Transform data for response
    const transformedBookmarks = bookmarks?.map(bookmark => ({
      ...bookmark,
      tags: Array.isArray(bookmark.tags) ? bookmark.tags : JSON.parse(bookmark.tags || '[]')
    })) || []

    // Get total count for pagination metadata
    let totalCount = 0
    try {
      const { count } = await supabase
        .from('bookmarks')
        .select('*', { count: 'exact', head: true })
        .eq('archived', params.archived === 'true')

      totalCount = count || 0
    } catch (countError) {
      console.warn('Failed to get total count:', countError)
    }

    // Response with metadata
    const response = {
      data: transformedBookmarks,
      metadata: {
        total: totalCount,
        limit: limit,
        offset: offset,
        has_more: (offset + limit) < totalCount
      }
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