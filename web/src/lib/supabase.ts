import { createClient } from '@supabase/supabase-js'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL || 'http://127.0.0.1:54321'
const supabaseKey = import.meta.env.VITE_SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0'

export const supabase = createClient(supabaseUrl, supabaseKey)

// Mock mode flag - set to true when Supabase is not available
const MOCK_MODE = import.meta.env.VITE_MOCK_MODE === 'true'

// Mock data for testing
const mockBookmarks: Bookmark[] = [
  {
    id: '1',
    url: 'https://react.dev/learn',
    title_final: 'React Developer Guide',
    summary: 'Comprehensive guide to learning React with hooks, state management, and modern patterns.',
    category: 'tutorial',
    source_type: 'article',
    tags: ['react', 'frontend', 'javascript'],
    pinned: true,
    archived: false,
    read: false,
    llm_status: 'done',
    created_at: '2024-01-15T10:00:00Z',
    updated_at: '2024-01-15T10:00:00Z'
  },
  {
    id: '2', 
    url: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
    title_final: 'Advanced JavaScript Patterns',
    summary: 'Learn advanced patterns in JavaScript including closures, prototypes, and async programming.',
    category: 'tech',
    source_type: 'youtube',
    tags: ['javascript', 'programming', 'tutorial'],
    pinned: false,
    archived: false,
    read: true,
    llm_status: 'done',
    media_meta: {
      title: 'Advanced JS Patterns',
      description: 'Tutorial video',
      image: 'https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg'
    },
    created_at: '2024-01-14T15:30:00Z',
    updated_at: '2024-01-14T15:30:00Z'
  },
  {
    id: '3',
    url: 'https://news.ycombinator.com/item?id=123456',
    title_final: 'New AI Development Tools Released',
    summary: 'Discussion about the latest AI development tools and their impact on software engineering.',
    category: 'news',
    source_type: 'news',
    tags: ['ai', 'development', 'tools'],
    pinned: false,
    archived: false, 
    read: false,
    llm_status: 'processing',
    created_at: '2024-01-13T08:45:00Z',
    updated_at: '2024-01-13T08:45:00Z'
  }
]

// Type definitions
export interface Bookmark {
  id: string
  url: string
  title_final?: string
  summary?: string
  content_text?: string
  category?: 'tech' | 'news' | 'blog' | 'tutorial' | 'reference' | 'tool' | 'other'
  source_type?: 'youtube' | 'x' | 'article' | 'news' | 'other'
  tags?: string[]
  pinned?: boolean
  archived?: boolean
  read?: boolean
  llm_status?: 'queued' | 'processing' | 'done' | 'failed'
  media_meta?: {
    title?: string
    description?: string
    image?: string
    video?: {
      url: string
      width: number
      height: number
    }
  }
  created_at: string
  updated_at: string
}

export interface BookmarkListResponse {
  data: Bookmark[]
  metadata: {
    total: number
    limit: number
    offset: number
    has_more: boolean
  }
}

export interface SemanticSearchResult {
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

export interface SemanticSearchResponse {
  results: SemanticSearchResult[]
  query: string
  total_results: number
  processing_time_ms: number
  embedding_cost_usd: number
  search_info?: {
    bm25_results: number
    semantic_results: number
  }
}

// API helper functions
export const bookmarkApi = {
  // Get bookmarks list
  async getBookmarks(params: {
    q?: string
    category?: string
    source_type?: string
    tags?: string
    limit?: number
    offset?: number
  } = {}): Promise<BookmarkListResponse> {
    if (MOCK_MODE) {
      // Mock implementation for testing
      await new Promise(resolve => setTimeout(resolve, 500)) // Simulate network delay
      
      let filteredBookmarks = [...mockBookmarks]
      
      // Simple filtering for demo
      if (params.q) {
        const query = params.q.toLowerCase()
        filteredBookmarks = filteredBookmarks.filter(bookmark => 
          bookmark.title_final?.toLowerCase().includes(query) ||
          bookmark.summary?.toLowerCase().includes(query)
        )
      }
      
      if (params.category && params.category !== 'all') {
        filteredBookmarks = filteredBookmarks.filter(bookmark => 
          bookmark.category === params.category
        )
      }
      
      return {
        data: filteredBookmarks,
        metadata: {
          total: filteredBookmarks.length,
          limit: params.limit || 50,
          offset: params.offset || 0,
          has_more: false
        }
      }
    }

    const searchParams = new URLSearchParams()
    
    if (params.q) searchParams.set('q', params.q)
    if (params.category) searchParams.set('category', params.category)
    if (params.source_type) searchParams.set('source_type', params.source_type)
    if (params.tags) searchParams.set('tags', params.tags)
    if (params.limit) searchParams.set('limit', params.limit.toString())
    if (params.offset) searchParams.set('offset', params.offset.toString())

    const response = await fetch(
      `${supabaseUrl}/functions/v1/bookmarks-list?${searchParams}`,
      {
        headers: {
          'Authorization': `Bearer ${supabaseKey}`,
          'apikey': supabaseKey
        }
      }
    )

    if (!response.ok) {
      throw new Error(`Failed to fetch bookmarks: ${response.status}`)
    }

    return response.json()
  },

  // Create new bookmark
  async createBookmark(data: {
    url: string
    title?: string
  }): Promise<Bookmark> {
    if (MOCK_MODE) {
      // Mock implementation for testing
      await new Promise(resolve => setTimeout(resolve, 1000)) // Simulate processing time
      
      const newBookmark: Bookmark = {
        id: Date.now().toString(),
        url: data.url,
        title_final: data.title || 'New Bookmark',
        summary: 'Processing... This bookmark is being analyzed by AI.',
        category: 'other',
        source_type: 'other',
        tags: ['new'],
        pinned: false,
        archived: false,
        read: false,
        llm_status: 'queued',
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      }
      
      mockBookmarks.unshift(newBookmark)
      return newBookmark
    }

    const idempotencyKey = `web-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`
    
    const response = await fetch(
      `${supabaseUrl}/functions/v1/bookmarks-create`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${supabaseKey}`,
          'apikey': supabaseKey,
          'idempotency-key': idempotencyKey
        },
        body: JSON.stringify(data)
      }
    )

    if (!response.ok) {
      const error = await response.json()
      throw new Error(error.error || `Failed to create bookmark: ${response.status}`)
    }

    return response.json()
  },

  // Full-text search (BM25)
  async fulltextSearch(params: {
    query: string
    limit?: number
    category?: string
    source_type?: string
  }): Promise<any> {
    if (MOCK_MODE) {
      // Mock implementation for testing
      await new Promise(resolve => setTimeout(resolve, 400))
      
      const results = mockBookmarks.filter(bookmark => 
        bookmark.title_final?.toLowerCase().includes(params.query.toLowerCase()) ||
        bookmark.summary?.toLowerCase().includes(params.query.toLowerCase())
      ).map(bookmark => ({
        id: bookmark.id,
        url: bookmark.url,
        title: bookmark.title_final || bookmark.url,
        summary: bookmark.summary || '',
        category: bookmark.category || 'other',
        source_type: bookmark.source_type || 'other',
        tags: bookmark.tags || [],
        rank: 0.7 - Math.random() * 0.3, // Mock rank
        created_at: bookmark.created_at,
        media_meta: bookmark.media_meta
      }))
      
      return {
        results: results,
        query: params.query,
        total_results: results.length,
        processing_time_ms: 380,
        search_info: {
          method: 'bm25_fulltext',
          query_terms: params.query.split(/\s+/)
        }
      }
    }

    const response = await fetch(
      `${supabaseUrl}/functions/v1/search-fulltext`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${supabaseKey}`,
          'apikey': supabaseKey
        },
        body: JSON.stringify(params)
      }
    )

    if (!response.ok) {
      const error = await response.json()
      throw new Error(error.error || `Full-text search failed: ${response.status}`)
    }

    return response.json()
  },

  // Hybrid search (BM25 + Vector)
  async hybridSearch(params: {
    query: string
    limit?: number
    bm25_weight?: number
    semantic_weight?: number
    category?: string
    source_type?: string
  }): Promise<any> {
    if (MOCK_MODE) {
      // Mock hybrid search implementation
      await new Promise(resolve => setTimeout(resolve, 800))
      
      const results = mockBookmarks.filter(bookmark => 
        bookmark.title_final?.toLowerCase().includes(params.query.toLowerCase()) ||
        bookmark.summary?.toLowerCase().includes(params.query.toLowerCase())
      ).map(bookmark => ({
        id: bookmark.id,
        url: bookmark.url,
        title: bookmark.title_final || bookmark.url,
        summary: bookmark.summary || '',
        category: bookmark.category || 'other',
        source_type: bookmark.source_type || 'other',
        tags: bookmark.tags || [],
        hybrid_score: 0.85 - Math.random() * 0.3,
        bm25_rank: Math.floor(Math.random() * 5) + 1,
        semantic_score: 0.7 - Math.random() * 0.2,
        rrf_score: 0.8 - Math.random() * 0.3,
        created_at: bookmark.created_at,
        media_meta: bookmark.media_meta
      }))
      
      return {
        results: results,
        query: params.query,
        total_results: results.length,
        processing_time_ms: 750,
        search_info: {
          method: 'hybrid_rrf',
          bm25_results: Math.floor(results.length * 0.8),
          semantic_results: Math.floor(results.length * 0.6),
          bm25_weight: params.bm25_weight || 0.6,
          semantic_weight: params.semantic_weight || 0.4,
          rrf_k: 60
        }
      }
    }

    const response = await fetch(
      `${supabaseUrl}/functions/v1/search-hybrid`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${supabaseKey}`,
          'apikey': supabaseKey
        },
        body: JSON.stringify(params)
      }
    )

    if (!response.ok) {
      const error = await response.json()
      throw new Error(error.error || `Hybrid search failed: ${response.status}`)
    }

    return response.json()
  },

  // Semantic search
  async semanticSearch(params: {
    query: string
    limit?: number
    similarity_threshold?: number
    category?: string
    source_type?: string
  }): Promise<SemanticSearchResponse> {
    if (MOCK_MODE) {
      // Mock implementation for testing
      await new Promise(resolve => setTimeout(resolve, 700)) // Simulate processing time
      
      const results = mockBookmarks.filter(bookmark => 
        bookmark.title_final?.toLowerCase().includes(params.query.toLowerCase()) ||
        bookmark.summary?.toLowerCase().includes(params.query.toLowerCase())
      ).map(bookmark => ({
        id: bookmark.id,
        url: bookmark.url,
        title: bookmark.title_final || bookmark.url,
        summary: bookmark.summary || '',
        category: bookmark.category || 'other',
        source_type: bookmark.source_type || 'other',
        tags: bookmark.tags || [],
        similarity_score: 0.85 - Math.random() * 0.3, // Mock similarity
        created_at: bookmark.created_at,
        media_meta: bookmark.media_meta
      }))
      
      return {
        results: results,
        query: params.query,
        total_results: results.length,
        processing_time_ms: 650,
        embedding_cost_usd: 0.00000004
      }
    }

    const response = await fetch(
      `${supabaseUrl}/functions/v1/search-semantic`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${supabaseKey}`,
          'apikey': supabaseKey
        },
        body: JSON.stringify(params)
      }
    )

    if (!response.ok) {
      const error = await response.json()
      throw new Error(error.error || `Semantic search failed: ${response.status}`)
    }

    return response.json()
  }
}