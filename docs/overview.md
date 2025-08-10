# アーキテクチャ概要

## 1. 全体構成（C4 Model Level 1）
- **クライアント**  
  - iOSアプリ（SwiftUI + Share Extension）
  - Web PWA
  - Webブックマークレット
- **バックエンド**  
  - API（REST, OpenAPI）
  - 抽出パイプライン（メタ取得, Readability）
  - LLM呼び出し（OpenAI GPT）
  - DB（Postgres/pgvector）
  - ストレージ（R2/Supabase Storage）
  - キュー（Cloudflare Queues or Supabase Functions）

## 2. データフロー
1. クライアント→`POST /bookmarks`（Idempotency-Key付き）
2. サーバが即ACK→キューにジョブ投入
3. メタ取得→本文抽出→LLM要約/分類
4. DB更新＋検索インデックス更新
5. クライアントは定期ポーリング or 通知で更新反映

## 3. 信頼境界
- クライアントとAPI間：TLS
- サーバ内：APIキー・秘密情報はKMS管理

## 4. 採用技術（案）
- Cloudflare Workers + D1/Neon + R2 + Queues
- OpenAI GPT-4o-mini
- Readability.js
