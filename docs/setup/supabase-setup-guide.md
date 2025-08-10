# Supabase セットアップ手順書

**目的**: ブックマークアプリのバックエンド基盤（Supabase）を構築する  
**対象**: Phase 1B Week 1 の実装  
**所要時間**: 2-3 時間

---

## 🎯 完了目標

- ✅ Supabase プロジェクト作成・接続確認
- ✅ データベーススキーマ完全構築
- ✅ 認証・セキュリティ設定完了
- ✅ ストレージ設定完了
- ✅ API 開発準備完了

---

## 📋 事前準備

### 必要なもの
- [ ] メールアドレス（Supabase アカウント用）
- [ ] GitHub アカウント（OAuth ログイン推奨）
- [ ] クレジットカード（将来の有料プラン用、今すぐは不要）
- [ ] インターネット接続環境

### 参考資料
- `docs/data_model.md` - データベーススキーマ設計
- `docs/requirements_specification.md` - 要件定義

---

## Step 1: Supabase アカウント作成・プロジェクト作成 (15分)

### 1.1 アカウント作成
1. **Supabase サイトにアクセス**
   ```
   https://supabase.com
   ```

2. **Sign Up をクリック**
   - 推奨: 「Continue with GitHub」でGitHubアカウント連携
   - または「Sign up with email」でメール登録

3. **メール認証**
   - 登録メールに認証リンクが送信される
   - リンクをクリックして認証完了

### 1.2 プロジェクト作成
1. **Dashboard にアクセス**
   ```
   https://app.supabase.com
   ```

2. **"New project" をクリック**

3. **プロジェクト情報入力**
   ```
   Organization: 個人アカウント選択
   Name: bookmark-app
   Database Password: 安全なパスワード生成（必ず保存）
   Region: Japan (ap-northeast-1) 選択
   Pricing Plan: Free プラン選択
   ```

4. **"Create new project" をクリック**
   - プロジェクト作成に 2-3 分かかります
   - 進行状況が表示されるまで待機

### 1.3 プロジェクト情報の確認・保存
1. **Dashboard で以下の情報を確認**
   - Project URL: `https://[プロジェクトID].supabase.co`
   - API URL: `https://[プロジェクトID].supabase.co/rest/v1`
   - anon key: `eyJhbGci...` (公開鍵)
   - service_role key: `eyJhbGci...` (秘密鍵、**要厳重管理**)

2. **情報を安全に保存**
   ```bash
   # ローカル環境変数ファイル作成（後で使用）
   echo "SUPABASE_URL=https://[プロジェクトID].supabase.co" > .env.local
   echo "SUPABASE_ANON_KEY=eyJhbGci..." >> .env.local
   echo "SUPABASE_SERVICE_ROLE_KEY=eyJhbGci..." >> .env.local
   ```

---

## Step 2: データベース接続確認 (10分)

### 2.1 SQL Editor での接続テスト
1. **左サイドメニュー → "SQL Editor" をクリック**

2. **接続テストクエリ実行**
   ```sql
   -- 現在日時とデータベース情報を確認
   SELECT 
     NOW() as current_time,
     version() as postgresql_version,
     current_database() as database_name;
   ```

3. **"RUN" ボタンをクリック**
   - 結果が表示されることを確認
   - エラーが出る場合は接続に問題あり

### 2.2 Database Dashboard 確認
1. **左サイドメニュー → "Database" をクリック**
2. **"Tables" タブを確認**
   - 初期状態では空（テーブルなし）
3. **"Extensions" タブを確認**
   - PostgreSQL 拡張機能の管理画面

---

## Step 3: データベーススキーマ構築 (45分)

### 3.1 必要な拡張機能の有効化
```sql
-- pgvector 拡張（ベクトル検索用）
CREATE EXTENSION IF NOT EXISTS vector;

-- UUID 拡張
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 日本語全文検索用（将来）
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- 確認
SELECT * FROM pg_extension WHERE extname IN ('vector', 'uuid-ossp', 'pg_trgm');
```

### 3.2 Enum 型の定義
```sql
-- ソースタイプ enum
CREATE TYPE bookmark_source_type AS ENUM (
  'youtube',
  'x',
  'article', 
  'news',
  'other'
);

-- カテゴリ enum
CREATE TYPE bookmark_category AS ENUM (
  'tech',
  'news', 
  'blog',
  'video',
  'social',
  'academic',
  'product',
  'entertainment',
  'lifestyle',
  'other'
);

-- LLM ステータス enum
CREATE TYPE llm_status_type AS ENUM (
  'queued',
  'processing',
  'done',
  'failed'
);

-- 確認
\dT bookmark_source_type
\dT bookmark_category  
\dT llm_status_type
```

### 3.3 メインテーブル作成
```sql
-- bookmarks テーブル
CREATE TABLE bookmarks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  url TEXT NOT NULL,
  canonical_url TEXT,
  domain TEXT NOT NULL,
  source_type bookmark_source_type NOT NULL DEFAULT 'other',
  title_raw TEXT,
  title_final TEXT NOT NULL,
  summary TEXT DEFAULT '',
  tags JSONB DEFAULT '[]'::jsonb,
  category bookmark_category DEFAULT 'other',
  content_text TEXT,
  embedding vector(1536), -- OpenAI embedding サイズ
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  read_at TIMESTAMPTZ,
  pinned BOOLEAN DEFAULT FALSE,
  archived BOOLEAN DEFAULT FALSE,
  hash TEXT,
  canonical_hash TEXT,
  llm_status llm_status_type DEFAULT 'queued',
  llm_model TEXT,
  llm_tokens INTEGER,
  media_meta JSONB DEFAULT '{}'::jsonb,
  source_context JSONB DEFAULT '{}'::jsonb,
  published_at TIMESTAMPTZ,
  captured_at TIMESTAMPTZ DEFAULT NOW()
);

-- テーブル作成確認
\d bookmarks
```

### 3.4 冪等性キーテーブル
```sql
-- idempotency_keys テーブル
CREATE TABLE idempotency_keys (
  key UUID PRIMARY KEY,
  bookmark_id UUID REFERENCES bookmarks(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '24 hours')
);

-- テーブル作成確認  
\d idempotency_keys
```

### 3.5 インデックス作成
```sql
-- URL ユニーク制約（大文字小文字区別なし）
CREATE UNIQUE INDEX bookmarks_url_unique ON bookmarks(LOWER(url));

-- 正規化URL ユニーク制約（NULL 許可）
CREATE UNIQUE INDEX bookmarks_canonical_hash_unique ON bookmarks(canonical_hash) WHERE canonical_hash IS NOT NULL;

-- 作成日時降順（メイン画面用）
CREATE INDEX bookmarks_created_at_desc ON bookmarks(created_at DESC);

-- 更新日時降順
CREATE INDEX bookmarks_updated_at_desc ON bookmarks(updated_at DESC);

-- タグ検索用 GIN インデックス
CREATE INDEX bookmarks_tags_gin ON bookmarks USING gin(tags);

-- ベクトル検索用インデックス（HNSW）
CREATE INDEX bookmarks_embedding_idx ON bookmarks USING hnsw (embedding vector_cosine_ops);

-- 複合インデックス（アーカイブ除外 + 作成日時）
CREATE INDEX bookmarks_active_created_at ON bookmarks(created_at DESC) WHERE archived = FALSE;

-- 全文検索用インデックス（title + content）
CREATE INDEX bookmarks_fulltext_idx ON bookmarks USING gin(
  to_tsvector('simple', COALESCE(title_final, '') || ' ' || COALESCE(content_text, ''))
);

-- ドメイン検索用
CREATE INDEX bookmarks_domain_idx ON bookmarks(domain);

-- LLM ステータス検索用
CREATE INDEX bookmarks_llm_status_idx ON bookmarks(llm_status);

-- 冪等性キー期限切れ削除用
CREATE INDEX idempotency_keys_expires_at ON idempotency_keys(expires_at);

-- インデックス確認
\di
```

### 3.6 トリガー関数作成
```sql
-- updated_at 自動更新トリガー関数
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- bookmarks テーブルにトリガー設定
CREATE TRIGGER update_bookmarks_updated_at 
  BEFORE UPDATE ON bookmarks 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 期限切れ冪等性キー削除関数（定期実行用）
CREATE OR REPLACE FUNCTION cleanup_expired_idempotency_keys()
RETURNS INTEGER AS $$
DECLARE
  deleted_count INTEGER;
BEGIN
  DELETE FROM idempotency_keys WHERE expires_at < NOW();
  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  RETURN deleted_count;
END;
$$ language 'plpgsql';
```

### 3.7 テストデータ投入・確認
```sql
-- テストデータ挿入
INSERT INTO bookmarks (
  url, 
  domain, 
  source_type, 
  title_final, 
  summary, 
  tags, 
  category
) VALUES (
  'https://supabase.com/docs',
  'supabase.com',
  'article',
  'Supabase Documentation',
  'Supabase の公式ドキュメント。データベース、認証、リアルタイム機能の使い方を詳しく解説。',
  '["supabase", "documentation", "database"]'::jsonb,
  'tech'
);

-- データ確認
SELECT 
  id,
  url,
  title_final,
  tags,
  category,
  llm_status,
  created_at
FROM bookmarks;

-- 削除（テスト用なので削除）
DELETE FROM bookmarks WHERE domain = 'supabase.com';
```

---

## Step 4: 認証・セキュリティ設定 (20分)

### 4.1 Row Level Security (RLS) 有効化
```sql
-- bookmarks テーブルに RLS 適用
ALTER TABLE bookmarks ENABLE ROW LEVEL SECURITY;
ALTER TABLE idempotency_keys ENABLE ROW LEVEL SECURITY;

-- 確認
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE tablename IN ('bookmarks', 'idempotency_keys');
```

### 4.2 RLS ポリシー作成（単一ユーザー用）
```sql
-- bookmarks テーブル: 全操作許可（単一ユーザーアプリのため）
CREATE POLICY "Allow all operations on bookmarks" ON bookmarks
  FOR ALL USING (true) WITH CHECK (true);

-- idempotency_keys テーブル: 全操作許可
CREATE POLICY "Allow all operations on idempotency_keys" ON idempotency_keys
  FOR ALL USING (true) WITH CHECK (true);

-- ポリシー確認
SELECT schemaname, tablename, policyname, permissive, cmd, qual
FROM pg_policies 
WHERE tablename IN ('bookmarks', 'idempotency_keys');
```

### 4.3 WebAuthn 認証設定準備
1. **Dashboard → Authentication → Providers**
2. **"Enable custom access token (JWT)"** を有効化
3. **JWT Secret** を確認・保存（既に自動生成済み）

**注意**: WebAuthn の詳細設定は Phase 1B Week 2 で実装

---

## Step 5: ストレージ設定 (15分)

### 5.1 ストレージバケット作成
1. **Dashboard → Storage**
2. **"New bucket" をクリック**
3. **バケット設定**
   ```
   Name: thumbnails
   Public bucket: チェック ✅ (サムネイル画像はパブリック)
   File size limit: 5MB
   Allowed MIME types: image/jpeg, image/png, image/webp
   ```

### 5.2 ストレージポリシー設定
```sql
-- thumbnails バケットのポリシー設定
-- 読み取り: 全員許可（パブリック）
INSERT INTO storage.policies (name, bucket_id, definition)
VALUES (
  'Public Access',
  'thumbnails',
  '(bucket_id = ''thumbnails'')'
);

-- 書き込み: 認証済みユーザーのみ（将来拡張用）
INSERT INTO storage.policies (name, bucket_id, definition)  
VALUES (
  'Authenticated Upload',
  'thumbnails', 
  '(bucket_id = ''thumbnails'' AND auth.role() = ''authenticated'')'
);
```

### 5.3 ストレージ接続テスト
1. **Dashboard → Storage → thumbnails**
2. **"Upload file" でテスト画像アップロード**
3. **アップロードした画像の URL 確認**
   ```
   https://[プロジェクトID].supabase.co/storage/v1/object/public/thumbnails/[ファイル名]
   ```

---

## Step 6: 動作確認・最終チェック (15分)

### 6.1 データベース機能確認
```sql
-- 全テーブル確認
\dt

-- 全インデックス確認  
\di

-- 拡張機能確認
SELECT extname, extversion FROM pg_extension 
WHERE extname IN ('vector', 'uuid-ossp', 'pg_trgm');

-- enum 型確認
SELECT typname, typtype FROM pg_type 
WHERE typname LIKE '%bookmark%' OR typname LIKE '%llm%';
```

### 6.2 API エンドポイント確認
1. **Dashboard → API**
2. **API URL を確認**
   ```
   REST URL: https://[プロジェクトID].supabase.co/rest/v1
   GraphQL URL: https://[プロジェクトID].supabase.co/graphql/v1
   ```

3. **API Key 確認**
   - `anon` key: フロントエンド用（公開可能）
   - `service_role` key: サーバーサイド用（秘密情報）

### 6.3 簡単な API テスト
```bash
# curl でテスト（プロジェクトID、APIキーは実際の値に置換）
curl -X GET \
  'https://[プロジェクトID].supabase.co/rest/v1/bookmarks?select=*' \
  -H "apikey: [anon-key]" \
  -H "Authorization: Bearer [anon-key]"

# 空配列 [] が返れば成功
```

---

## 🎯 完了チェックリスト

### ✅ プロジェクト基盤
- [ ] Supabase アカウント作成完了
- [ ] bookmark-app プロジェクト作成完了  
- [ ] データベース接続確認完了
- [ ] API URL・キー取得・保存完了

### ✅ データベーススキーマ
- [ ] 必要な拡張機能有効化完了（vector, uuid-ossp, pg_trgm）
- [ ] Enum 型定義完了（3種類）
- [ ] bookmarks テーブル作成完了（25フィールド）
- [ ] idempotency_keys テーブル作成完了
- [ ] 全インデックス作成完了（9個）
- [ ] トリガー関数作成完了

### ✅ セキュリティ設定
- [ ] RLS 有効化完了
- [ ] 基本ポリシー設定完了
- [ ] 認証設定準備完了

### ✅ ストレージ設定
- [ ] thumbnails バケット作成完了
- [ ] ストレージポリシー設定完了
- [ ] アップロードテスト完了

---

## 📝 次回開発の準備

### 保存すべき情報
```bash
# .env.local ファイル（Phase 1B Week 2 で使用）
SUPABASE_URL=https://[プロジェクトID].supabase.co
SUPABASE_ANON_KEY=[anon-key]
SUPABASE_SERVICE_ROLE_KEY=[service-role-key]
DATABASE_PASSWORD=[データベースパスワード]
```

### 次回タスク（Phase 1B Week 2）
1. **Supabase Edge Functions 作成**
   - `POST /v1/bookmarks` API
   - `GET /v1/bookmarks` API
2. **メタデータ取得機能実装**
3. **エラーハンドリング強化**

---

## ⚠️ トラブルシューティング

### よくある問題と解決方法

#### 1. プロジェクト作成が失敗する
- **原因**: 名前重複、リージョン問題
- **解決**: プロジェクト名を変更、別リージョン選択

#### 2. SQL 実行でエラー
- **原因**: 文法エラー、権限不足  
- **解決**: SQL Editor で1行ずつ実行、エラーメッセージ確認

#### 3. API 接続エラー
- **原因**: API キー間違い、CORS 設定
- **解決**: API キー再確認、ブラウザの開発者ツール確認

#### 4. ストレージアップロード失敗
- **原因**: ファイルサイズ超過、MIME タイプ不一致
- **解決**: ファイルサイズ・形式確認、ポリシー再確認

---

## ✅ Phase 1B Week 1 完了実績

**実施日**: 2025年8月10日  
**所要時間**: 約3時間  
**実施者**: shohei.yoneda

### 完了した作業
- ✅ Supabaseプロジェクト作成 (ieuurvmlrgkxfetfnlnp)
- ✅ データベーススキーマ完全構築
  - bookmarks テーブル (25フィールド)
  - idempotency_keys テーブル (4フィールド)
  - 3つのenum型、11個のインデックス
  - 2つのトリガー関数
- ✅ セキュリティ設定完了
  - Row Level Security 有効化
  - 6つのRLSポリシー設定
  - thumbnails ストレージバケット作成
- ✅ 動作確認完了
  - SQL Editor での完全CRUD確認
  - ブラウザでのAPI動作確認 (GET: [] レスポンス成功)
  - 全テーブル・インデックス・ポリシー確認済み

### 遭遇した課題と解決
- **APIキー認証エラー**: RLSポリシー修正で解決
- **cURL特殊文字問題**: ブラウザテストで基本動作確認済み
- **Docker daemon エラー**: psql代替でSQL Editor使用

### 確認済み動作
- データベース接続: ✅ 正常
- テーブル作成: ✅ 2テーブル + 関連構造
- インデックス: ✅ 11個作成済み
- RLS: ✅ 全ロール対応ポリシー
- CRUD操作: ✅ INSERT/SELECT/UPDATE/DELETE
- API基本動作: ✅ ブラウザで確認済み

**🎉 Supabase 基盤構築 100% 完了！**

次回開発時は **Phase 1B Week 2: Edge Functions 実装**に進んでください。