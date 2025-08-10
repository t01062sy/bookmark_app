# データモデル & マイグレーションガイド

## 1. 現行スキーマ概要
**主要テーブル**：`bookmarks`, `audit_logs`, `idempotency_keys`

### bookmarks
- id (uuid, pk)
- url (text, not null)
- canonical_url (text)
- domain (text, not null)
- source_type (enum: youtube/x/article/news/other)
- title_raw (text)
- title_final (text)
- summary (text)
- tags (jsonb)
- category (enum)
- content_text (text)
- embedding (vector[1536], optional)
- created_at / updated_at / read_at
- pinned / archived (bool)
- hash / canonical_hash (text)
- llm_status (enum: queued/processing/done/failed)
- llm_model (text)
- llm_tokens (int)
- media_meta (jsonb)
- source_context (jsonb)
- published_at / captured_at

## 2. インデックス方針
- URL unique (lowercase)
- canonical_hash unique (nullable)
- created_at desc
- tags GIN
- full-text (title_final + content_text, Japanese dictionary)
- embedding vector index（pgvector）

## 3. マイグレーション方針
- `ALTER TABLE`で追加/変更
- 破壊的変更は段階的に（新カラム追加→データ移行→旧カラム削除）
- 常にバックアップを取得後に実施
