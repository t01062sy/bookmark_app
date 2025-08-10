-- Create enum types (DROP TYPE if exists, then CREATE)
DO $$ 
BEGIN
    DROP TYPE IF EXISTS source_type;
    CREATE TYPE source_type AS ENUM ('youtube', 'x', 'news', 'other');
    
    DROP TYPE IF EXISTS bookmark_category;
    CREATE TYPE bookmark_category AS ENUM ('tech', 'news', 'blog', 'tutorial', 'reference', 'tool', 'other');
    
    DROP TYPE IF EXISTS llm_status;
    CREATE TYPE llm_status AS ENUM ('queued', 'processing', 'done', 'failed');
    
    DROP TYPE IF EXISTS llm_model_type;
    CREATE TYPE llm_model_type AS ENUM ('gpt-4o', 'gpt-4o-mini', 'gpt-4', 'gpt-3.5-turbo', 'text-embedding-3-small', 'text-embedding-3-large');
END $$;

-- Create bookmarks table
CREATE TABLE IF NOT EXISTS bookmarks (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  url TEXT NOT NULL,
  title_original TEXT,
  title_final TEXT,
  summary TEXT,
  content_text TEXT,
  category bookmark_category DEFAULT 'other',
  source_type source_type DEFAULT 'other',
  tags JSONB DEFAULT '[]'::jsonb,
  embedding JSONB,
  pinned BOOLEAN DEFAULT false,
  archived BOOLEAN DEFAULT false,
  read BOOLEAN DEFAULT false,
  media_meta JSONB DEFAULT '{}'::jsonb,
  llm_status llm_status DEFAULT 'queued',
  llm_processed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT url_unique UNIQUE(url)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_bookmarks_created_at ON bookmarks(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_bookmarks_category ON bookmarks(category);
CREATE INDEX IF NOT EXISTS idx_bookmarks_source_type ON bookmarks(source_type);
CREATE INDEX IF NOT EXISTS idx_bookmarks_archived ON bookmarks(archived);
CREATE INDEX IF NOT EXISTS idx_bookmarks_pinned ON bookmarks(pinned);
CREATE INDEX IF NOT EXISTS idx_bookmarks_llm_status ON bookmarks(llm_status);
CREATE INDEX IF NOT EXISTS idx_bookmarks_tags ON bookmarks USING gin(tags);

-- Create full text search index
CREATE INDEX IF NOT EXISTS idx_bookmarks_fts ON bookmarks USING gin(
  to_tsvector('english', 
    COALESCE(title_final, '') || ' ' || 
    COALESCE(summary, '') || ' ' || 
    COALESCE(content_text, '')
  )
);

-- Enable Row Level Security (RLS)
ALTER TABLE bookmarks ENABLE ROW LEVEL SECURITY;

-- Create policy for anonymous access (single user app)
CREATE POLICY "Allow anonymous access" ON bookmarks
  FOR ALL USING (true);

-- Create updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_bookmarks_updated_at BEFORE UPDATE
  ON bookmarks FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();