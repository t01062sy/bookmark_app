-- Create BM25-style full-text search function
-- Phase 3A: Advanced full-text search with ranking

-- Create the full-text search RPC function
CREATE OR REPLACE FUNCTION fulltext_search_bookmarks(
  search_query TEXT,
  result_limit INTEGER DEFAULT 20,
  min_rank_threshold REAL DEFAULT 0.1,
  filter_category bookmark_category DEFAULT NULL,
  filter_source_type source_type DEFAULT NULL,
  filter_archived BOOLEAN DEFAULT FALSE
)
RETURNS TABLE (
  id UUID,
  url TEXT,
  title_final TEXT,
  summary TEXT,
  category bookmark_category,
  source_type source_type,
  tags JSONB,
  media_meta JSONB,
  created_at TIMESTAMPTZ,
  rank REAL,
  headline TEXT
) 
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    b.id,
    b.url,
    b.title_final,
    b.summary,
    b.category,
    b.source_type,
    b.tags,
    b.media_meta,
    b.created_at,
    -- Use ts_rank_cd for BM25-style ranking with document length normalization
    ts_rank_cd(
      to_tsvector('english', 
        COALESCE(b.title_final, '') || ' ' || 
        COALESCE(b.summary, '') || ' ' || 
        COALESCE(b.content_text, '')
      ), 
      plainto_tsquery('english', search_query),
      1|2|4|8  -- Use all ranking normalization options
    ) AS rank,
    -- Generate highlighted snippets
    ts_headline('english',
      COALESCE(b.title_final, '') || ' ' || COALESCE(b.summary, ''),
      plainto_tsquery('english', search_query),
      'MaxWords=30, MinWords=15, ShortWord=3, HighlightAll=FALSE, MaxFragments=2, FragmentDelimiter=" ... "'
    ) AS headline
  FROM bookmarks b
  WHERE 
    -- Main full-text search condition
    to_tsvector('english', 
      COALESCE(b.title_final, '') || ' ' || 
      COALESCE(b.summary, '') || ' ' || 
      COALESCE(b.content_text, '')
    ) @@ plainto_tsquery('english', search_query)
    -- Apply filters
    AND (filter_category IS NULL OR b.category = filter_category)
    AND (filter_source_type IS NULL OR b.source_type = filter_source_type)
    AND b.archived = filter_archived
    -- Minimum rank threshold
    AND ts_rank_cd(
      to_tsvector('english', 
        COALESCE(b.title_final, '') || ' ' || 
        COALESCE(b.summary, '') || ' ' || 
        COALESCE(b.content_text, '')
      ), 
      plainto_tsquery('english', search_query),
      1|2|4|8
    ) >= min_rank_threshold
  ORDER BY rank DESC, b.created_at DESC
  LIMIT result_limit;
END;
$$;

-- Create a more advanced search function with phrase and boolean support
CREATE OR REPLACE FUNCTION advanced_fulltext_search_bookmarks(
  search_query TEXT,
  search_type TEXT DEFAULT 'websearch', -- 'plain', 'phrase', 'websearch'
  result_limit INTEGER DEFAULT 20,
  min_rank_threshold REAL DEFAULT 0.1,
  filter_category bookmark_category DEFAULT NULL,
  filter_source_type source_type DEFAULT NULL,
  filter_archived BOOLEAN DEFAULT FALSE
)
RETURNS TABLE (
  id UUID,
  url TEXT,
  title_final TEXT,
  summary TEXT,
  category bookmark_category,
  source_type source_type,
  tags JSONB,
  media_meta JSONB,
  created_at TIMESTAMPTZ,
  rank REAL,
  headline TEXT,
  query_info JSONB
) 
LANGUAGE plpgsql
AS $$
DECLARE
  tsquery_func TEXT;
  search_tsquery TSQUERY;
BEGIN
  -- Choose appropriate tsquery function based on search type
  CASE search_type
    WHEN 'phrase' THEN
      tsquery_func := 'phraseto_tsquery';
    WHEN 'websearch' THEN
      tsquery_func := 'websearch_to_tsquery';
    ELSE
      tsquery_func := 'plainto_tsquery';
  END CASE;

  -- Build the tsquery
  EXECUTE format('SELECT %s(''english'', $1)', tsquery_func) 
  INTO search_tsquery 
  USING search_query;

  RETURN QUERY
  SELECT 
    b.id,
    b.url,
    b.title_final,
    b.summary,
    b.category,
    b.source_type,
    b.tags,
    b.media_meta,
    b.created_at,
    -- Enhanced ranking with title boost
    (
      -- Title gets 3x weight, summary gets 2x weight, content gets 1x weight
      ts_rank_cd('{0.1, 0.2, 0.4, 1.0}',
        setweight(to_tsvector('english', COALESCE(b.title_final, '')), 'A') ||
        setweight(to_tsvector('english', COALESCE(b.summary, '')), 'B') ||
        setweight(to_tsvector('english', COALESCE(b.content_text, '')), 'C'),
        search_tsquery,
        1|2|4|8
      )
    ) AS rank,
    -- Generate highlighted snippets
    ts_headline('english',
      COALESCE(b.title_final, '') || ' ' || COALESCE(b.summary, ''),
      search_tsquery,
      'MaxWords=35, MinWords=15, ShortWord=3, HighlightAll=FALSE, MaxFragments=3, FragmentDelimiter=" ... "'
    ) AS headline,
    -- Query information for debugging
    jsonb_build_object(
      'search_type', search_type,
      'tsquery', search_tsquery::TEXT,
      'original_query', search_query
    ) AS query_info
  FROM bookmarks b
  WHERE 
    -- Main full-text search condition with weighted vectors
    (
      setweight(to_tsvector('english', COALESCE(b.title_final, '')), 'A') ||
      setweight(to_tsvector('english', COALESCE(b.summary, '')), 'B') ||
      setweight(to_tsvector('english', COALESCE(b.content_text, '')), 'C')
    ) @@ search_tsquery
    -- Apply filters
    AND (filter_category IS NULL OR b.category = filter_category)
    AND (filter_source_type IS NULL OR b.source_type = filter_source_type)
    AND b.archived = filter_archived
  ORDER BY rank DESC, b.created_at DESC
  LIMIT result_limit;
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION fulltext_search_bookmarks TO anon, authenticated;
GRANT EXECUTE ON FUNCTION advanced_fulltext_search_bookmarks TO anon, authenticated;