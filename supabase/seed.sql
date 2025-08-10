-- Seed data for testing
-- Insert sample bookmarks for development and testing

INSERT INTO bookmarks (
  url, 
  title_original, 
  title_final, 
  summary, 
  content_text, 
  category, 
  source_type, 
  tags, 
  llm_status,
  pinned,
  archived,
  read,
  media_meta
) VALUES 
(
  'https://react.dev/learn',
  'Learn React',
  'React: 最新の学習ガイド - 2024年版',
  'React公式サイトの最新学習ガイド。Hooksやコンポーネント設計パターン、状態管理について詳細に解説している。',
  'React is a JavaScript library for building user interfaces. Learn React with hands-on tutorials and examples...',
  'tutorial',
  'other',
  '["react", "javascript", "frontend", "tutorial"]'::jsonb,
  'done',
  true,
  false,
  false,
  '{"title": "Learn React", "description": "The official React tutorial", "image": "https://react.dev/images/og-learn.png"}'::jsonb
),
(
  'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
  'Advanced JavaScript Patterns',
  'JavaScript高級パターン完全ガイド',
  'プロトタイプチェーン、クロージャ、非同期プログラミングなどのJavaScript高級パターンを学習できる動画コンテンツ。',
  'This comprehensive video covers advanced JavaScript concepts including closures, prototypes, and async programming patterns...',
  'tech',
  'youtube',
  '["javascript", "programming", "advanced", "patterns"]'::jsonb,
  'done',
  false,
  false,
  true,
  '{"title": "Advanced JavaScript Patterns", "description": "Learn advanced JS patterns", "video": {"url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ", "width": 1280, "height": 720}}'::jsonb
),
(
  'https://news.ycombinator.com/item?id=123456',
  'New AI Development Tools Released',
  'AI開発ツールの最新リリース情報',
  'OpenAIとAnthropicから新しいAI開発ツールがリリースされ、ソフトウェアエンジニアリングの効率化が期待される。',
  'Discussion about the latest AI development tools and their impact on software engineering productivity...',
  'news',
  'news',
  '["ai", "development", "tools", "news"]'::jsonb,
  'processing',
  false,
  false,
  false,
  '{"title": "AI Development Tools", "description": "Latest AI tools for developers"}'::jsonb
),
(
  'https://vercel.com/blog/nextjs-15',
  'Next.js 15 Release',
  'Next.js 15の新機能とアップデート内容',
  'Next.js 15がリリースされ、App Router、Server Components、新しいキャッシング戦略などの改善が含まれている。',
  'Next.js 15 introduces significant improvements to the App Router, enhanced Server Components, and new caching strategies for better performance...',
  'tech',
  'other',
  '["nextjs", "react", "web", "framework"]'::jsonb,
  'done',
  false,
  false,
  false,
  '{"title": "Next.js 15 Release", "description": "Latest features and improvements"}'::jsonb
),
(
  'https://supabase.com/docs/guides/edge-functions',
  'Supabase Edge Functions Guide',
  'Supabase Edge Functions開発ガイド',
  'Supabase Edge Functionsの基本概念から高度な使用方法まで、サーバーレス関数開発の完全ガイド。',
  'Complete guide to developing serverless functions with Supabase Edge Functions, including deployment strategies and best practices...',
  'reference',
  'other',
  '["supabase", "serverless", "deno", "backend"]'::jsonb,
  'done',
  false,
  false,
  false,
  '{"title": "Edge Functions Guide", "description": "Serverless functions with Supabase"}'::jsonb
);

-- LLM costs will be populated by actual API usage