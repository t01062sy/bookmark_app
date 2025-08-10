import { useState, useEffect } from 'react'
import { bookmarkApi, type Bookmark, type SemanticSearchResponse } from './lib/supabase'
import { useAuth } from './contexts/AuthContext'
import { AuthScreen } from './components/AuthScreen'
import './App.css'

function App() {
  const { isAuthenticated, user, logout } = useAuth()
  const [bookmarks, setBookmarks] = useState<Bookmark[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [searchQuery, setSearchQuery] = useState('')
  const [searchType, setSearchType] = useState<'keyword' | 'fulltext' | 'semantic' | 'hybrid'>('keyword')
  const [semanticResults, setSemanticResults] = useState<SemanticSearchResponse | null>(null)
  const [newUrl, setNewUrl] = useState('')
  const [creating, setCreating] = useState(false)

  // Load bookmarks
  const loadBookmarks = async (query?: string) => {
    try {
      setLoading(true)
      setError(null)
      
      if (searchType === 'semantic' && query?.trim()) {
        const response = await bookmarkApi.semanticSearch({
          query: query.trim(),
          limit: 20,
          similarity_threshold: 0.3
        })
        setSemanticResults(response)
        setBookmarks(response.results.map(result => ({
          id: result.id,
          url: result.url,
          title_final: result.title,
          summary: result.summary,
          category: result.category as any,
          source_type: result.source_type as any,
          tags: result.tags,
          similarity_score: result.similarity_score,
          created_at: result.created_at,
          updated_at: result.created_at,
          media_meta: result.media_meta
        })))
      } else if (searchType === 'fulltext' && query?.trim()) {
        const response = await bookmarkApi.fulltextSearch({
          query: query.trim(),
          limit: 20
        })
        setSemanticResults(response)
        setBookmarks(response.results.map(result => ({
          id: result.id,
          url: result.url,
          title_final: result.title,
          summary: result.summary,
          category: result.category as any,
          source_type: result.source_type as any,
          tags: result.tags,
          search_rank: result.rank,
          created_at: result.created_at,
          updated_at: result.created_at,
          media_meta: result.media_meta
        })))
      } else if (searchType === 'hybrid' && query?.trim()) {
        const response = await bookmarkApi.hybridSearch({
          query: query.trim(),
          limit: 20,
          bm25_weight: 0.6,
          semantic_weight: 0.4
        })
        setSemanticResults(response)
        setBookmarks(response.results.map(result => ({
          id: result.id,
          url: result.url,
          title_final: result.title,
          summary: result.summary,
          category: result.category as any,
          source_type: result.source_type as any,
          tags: result.tags,
          hybrid_score: result.hybrid_score,
          bm25_rank: result.bm25_rank,
          semantic_score: result.semantic_score,
          rrf_score: result.rrf_score,
          created_at: result.created_at,
          updated_at: result.created_at,
          media_meta: result.media_meta
        })))
      } else {
        const response = await bookmarkApi.getBookmarks({
          q: query,
          limit: 50
        })
        setBookmarks(response.data)
        setSemanticResults(null)
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load bookmarks')
    } finally {
      setLoading(false)
    }
  }

  // Create new bookmark
  const createBookmark = async () => {
    if (!newUrl.trim()) return

    try {
      setCreating(true)
      setError(null)
      
      await bookmarkApi.createBookmark({
        url: newUrl.trim()
      })
      
      setNewUrl('')
      await loadBookmarks()
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to create bookmark')
    } finally {
      setCreating(false)
    }
  }

  // Search handler
  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault()
    loadBookmarks(searchQuery)
  }

  // Initial load
  useEffect(() => {
    loadBookmarks()
  }, [])

  const getSourceIcon = (sourceType?: string) => {
    switch (sourceType) {
      case 'youtube': return '🎥'
      case 'x': return '🐦'
      case 'article': return '📄'
      case 'news': return '📰'
      default: return '🔗'
    }
  }

  const getCategoryColor = (category?: string) => {
    switch (category) {
      case 'tech': return '#2563eb'
      case 'news': return '#dc2626'
      case 'blog': return '#7c3aed'
      case 'tutorial': return '#059669'
      case 'reference': return '#d97706'
      case 'tool': return '#7c2d12'
      default: return '#6b7280'
    }
  }

  // Show auth screen if not authenticated
  if (!isAuthenticated) {
    return <AuthScreen />
  }

  return (
    <div className="app">
      <header className="app-header">
        <div className="header-content">
          <div>
            <h1>📚 Bookmark App</h1>
            <p>AI-powered bookmark management</p>
          </div>
          <div className="header-user">
            <span className="user-name">👤 {user?.name}</span>
            <button className="logout-button" onClick={logout}>
              Sign Out
            </button>
          </div>
        </div>
      </header>

      {/* Add Bookmark Form */}
      <section className="add-bookmark">
        <form onSubmit={(e) => { e.preventDefault(); createBookmark() }}>
          <input
            type="url"
            value={newUrl}
            onChange={(e) => setNewUrl(e.target.value)}
            placeholder="Enter URL to bookmark..."
            disabled={creating}
            required
          />
          <button type="submit" disabled={creating || !newUrl.trim()}>
            {creating ? '⏳ Processing...' : '➕ Add'}
          </button>
        </form>
      </section>

      {/* Search */}
      <section className="search">
        <form onSubmit={handleSearch}>
          <div className="search-controls">
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Search bookmarks..."
            />
            <select 
              value={searchType} 
              onChange={(e) => setSearchType(e.target.value as 'keyword' | 'fulltext' | 'semantic' | 'hybrid')}
            >
              <option value="keyword">Keyword Search</option>
              <option value="fulltext">BM25 Full-Text</option>
              <option value="semantic">Semantic Search</option>
              <option value="hybrid">🚀 Hybrid (BM25 + Vector)</option>
            </select>
            <button type="submit">🔍 Search</button>
          </div>
        </form>
        
        {searchQuery && (
          <button 
            className="clear-search"
            onClick={() => {
              setSearchQuery('')
              setSemanticResults(null)
              loadBookmarks()
            }}
          >
            ✕ Clear Search
          </button>
        )}
      </section>

      {/* Search Results Info */}
      {semanticResults && (
        <div className="search-info">
          <p>
            {searchType === 'semantic' && `🔍 Semantic search for "${semanticResults.query}" - ${semanticResults.total_results} results in ${semanticResults.processing_time_ms}ms${semanticResults.embedding_cost_usd ? ` (Cost: $${semanticResults.embedding_cost_usd.toFixed(8)})` : ''}`}
            {searchType === 'fulltext' && `📝 BM25 full-text search for "${semanticResults.query}" - ${semanticResults.total_results} results in ${semanticResults.processing_time_ms}ms`}
            {searchType === 'hybrid' && `🚀 Hybrid search (BM25 + Vector) for "${semanticResults.query}" - ${semanticResults.total_results} results in ${semanticResults.processing_time_ms}ms`}
            {semanticResults.search_info && searchType === 'hybrid' && semanticResults.search_info.bm25_results && (
              <span> (BM25: {semanticResults.search_info.bm25_results}, Semantic: {semanticResults.search_info.semantic_results})</span>
            )}
          </p>
        </div>
      )}

      {/* Error Display */}
      {error && (
        <div className="error">
          ❌ {error}
        </div>
      )}

      {/* Loading */}
      {loading && (
        <div className="loading">
          ⏳ Loading bookmarks...
        </div>
      )}

      {/* Bookmarks List */}
      <main className="bookmarks">
        {bookmarks.length === 0 && !loading ? (
          <div className="empty">
            <p>No bookmarks found. Add your first bookmark above! 👆</p>
          </div>
        ) : (
          <div className="bookmark-grid">
            {bookmarks.map((bookmark) => (
              <article key={bookmark.id} className="bookmark-card">
                <div className="bookmark-header">
                  <span className="source-icon">
                    {getSourceIcon(bookmark.source_type)}
                  </span>
                  <span 
                    className="category-badge"
                    style={{ backgroundColor: getCategoryColor(bookmark.category) }}
                  >
                    {bookmark.category || 'other'}
                  </span>
                  {'similarity_score' in bookmark && typeof (bookmark as any).similarity_score === 'number' && (
                    <span className="similarity-score">
                      Semantic: {((bookmark as any).similarity_score * 100).toFixed(1)}%
                    </span>
                  )}
                  {'search_rank' in bookmark && typeof (bookmark as any).search_rank === 'number' && (
                    <span className="search-rank">
                      BM25: {((bookmark as any).search_rank * 100).toFixed(1)}%
                    </span>
                  )}
                  {'hybrid_score' in bookmark && typeof (bookmark as any).hybrid_score === 'number' && (
                    <span className="hybrid-score">
                      Hybrid: {((bookmark as any).hybrid_score * 100).toFixed(1)}%
                    </span>
                  )}
                </div>

                <h3 className="bookmark-title">
                  <a href={bookmark.url} target="_blank" rel="noopener noreferrer">
                    {bookmark.title_final || bookmark.url}
                  </a>
                </h3>

                {bookmark.summary && (
                  <p className="bookmark-summary">{bookmark.summary}</p>
                )}

                {bookmark.tags && bookmark.tags.length > 0 && (
                  <div className="bookmark-tags">
                    {bookmark.tags.map(tag => (
                      <span key={tag} className="tag">#{tag}</span>
                    ))}
                  </div>
                )}

                <div className="bookmark-meta">
                  <span className="llm-status" data-status={bookmark.llm_status}>
                    {bookmark.llm_status === 'done' ? '✅' : 
                     bookmark.llm_status === 'processing' ? '⏳' : 
                     bookmark.llm_status === 'failed' ? '❌' : '📝'}
                  </span>
                  <time dateTime={bookmark.created_at}>
                    {new Date(bookmark.created_at).toLocaleDateString()}
                  </time>
                </div>
              </article>
            ))}
          </div>
        )}
      </main>
    </div>
  )
}

export default App
