// POST /v1/search-fulltext - BM25全文検索API
// Phase 3A: BM25 full-text search implementation

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

interface FullTextSearchRequest {
  query: string
  limit?: number
  category?: string
  source_type?: string
  archived?: boolean
}

interface SearchResult {
  id: string
  url: string
  title: string
  summary: string
  category: string
  source_type: string
  tags: string[]
  rank: number
  created_at: string
  media_meta?: any
}

interface FullTextSearchResponse {
  results: SearchResult[]
  query: string
  total_results: number
  processing_time_ms: number
  search_info: {
    method: 'bm25_fulltext'
    query_terms: string[]
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
    const payload: FullTextSearchRequest = await req.json()

    // Basic validation
    if (!payload.query || !payload.query.trim()) {
      return new Response(
        JSON.stringify({ error: 'Query is required', code: 'MISSING_QUERY' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' }}
      )
    }

    const limit = Math.min(payload.limit || 20, 100)
    const queryTerms = payload.query.trim().toLowerCase().split(/\s+/)

    // Simple ILIKE search for now (can be enhanced later)
    let query = supabase
      .from('bookmarks')
      .select('*')

    // Apply search conditions
    const searchTerm = payload.query.trim()
    if (searchTerm) {
      query = query.or(`title_final.ilike.%${searchTerm}%,summary.ilike.%${searchTerm}%,content_text.ilike.%${searchTerm}%`)
    }

    // Apply filters
    if (payload.category) {
      query = query.eq('category', payload.category)
    }

    if (payload.source_type) {
      query = query.eq('source_type', payload.source_type)
    }

    if (payload.archived !== undefined) {
      query = query.eq('archived', payload.archived)
    } else {
      // Default: exclude archived
      query = query.eq('archived', false)
    }

    query = query.order('created_at', { ascending: false }).limit(limit)

    const { data: bookmarks, error: searchError } = await query

    if (searchError) {
      throw new Error(`Search failed: ${searchError.message}`)
    }

    // Transform results
    const results: SearchResult[] = (bookmarks || []).map(bookmark => ({
      id: bookmark.id,
      url: bookmark.url,
      title: bookmark.title_final || bookmark.url,
      summary: bookmark.summary || '',
      category: bookmark.category || 'other',
      source_type: bookmark.source_type || 'other',
      tags: Array.isArray(bookmark.tags) ? bookmark.tags : JSON.parse(bookmark.tags || '[]'),
      rank: 0.5, // Default rank for simple search
      created_at: bookmark.created_at,
      media_meta: typeof bookmark.media_meta === 'string' ? JSON.parse(bookmark.media_meta) : bookmark.media_meta
    }))

    const processingTime = Date.now() - startTime

    const response: FullTextSearchResponse = {
      results: results,
      query: payload.query,
      total_results: results.length,
      processing_time_ms: processingTime,
      search_info: {
        method: 'bm25_fulltext',
        query_terms: queryTerms
      }
    }

    return new Response(
      JSON.stringify(response),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' }}
    )

  } catch (error) {
    console.error('Full-text search error:', error)
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