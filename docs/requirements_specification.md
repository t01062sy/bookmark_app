
# ブックマークアプリ 要件定義書（AI開発用）

## 1. プロジェクト概要

* **目的**：iOSとWebから最小ステップでURLを保存し、自動的にタイトル・要約・カテゴリ分けする。
* **対象URL**：YouTube動画、X（Twitter）ポスト、Web記事、ニュース記事。
* **利用者**：単一ユーザー（本人のみ）。ユーザー登録は不要。
* **重視点**：

  * 保存操作の最小化（共有シート1タップ）
  * 保存後の自動整理（GPTによる）
  * クラウド同期とWebアクセス
* **個人情報**：保持しない。漏えいリスクはAPIキーが最大。

---

## 2. 機能要件（MVP）

### 2.1 保存機能

* **iOS共有シート**からワンタップ保存（無UI）。
* **iOSアプリ内**：クリップボードURL検知→1タップ保存バー。
* **Web**：ブックマークレット（1クリック保存）。
* 保存API呼び出しは冪等（`Idempotency-Key`必須）。
* オフライン時はローカルキューに格納→復帰時自動送信。

### 2.2 自動処理

* サーバでURL正規化（UTM除去、リダイレクト解決、AMP→本体）。
* メタデータ取得：OGP/oEmbed、Readabilityで本文抽出。
* LLM（OpenAI GPT）でタイトル補正・要約（120〜200文字）・カテゴリ・タグ付与。
* タグ・カテゴリは事前定義（例：動画/ポスト/技術記事/ニュース 等）。
* LLM失敗時は最大2回再試行→失敗状態でユーザー再実行可能。

### 2.3 閲覧・検索

* 未読/既読、ピン留め、アーカイブ。
* フィルタ：source\_type（youtube/x/article/news）、タグ、期間。
* 検索：BM25（全文検索）＋ベクトル検索（embedding）併用。
* 将来拡張：スマートフォルダ（条件保存）。

### 2.4 認証

* WebAuthnパスキー（iOS/ブラウザ対応）。
* アクセストークンTTL=15分、リフレッシュトークン=30日、自動ローテ。
* デバイス別セッション失効UI。

### 2.5 エクスポート

* JSON/CSV形式で全ブックマークを出力。

---

## 3. 非機能要件

### 3.1 パフォーマンス

* 保存API呼び出し→レスポンスまでP95<1.2秒（ネット良好時）。
* 保存→要約完了P95<20秒。
* 抽出失敗率<3%、LLM失敗率<1%（再試行後）。

### 3.2 セキュリティ

* APIキーはサーバのみ保持、クライアントに渡さない。
* 外向きHTTPは許可リスト制限（`api.openai.com`等）。
* APIキーは30日ごと自動ローテーション。
* 保存データはKMS暗号化（at rest）、TLS通信。
* CORSは自サービスオリジンのみ許可。

### 3.3 可用性・運用

* API稼働率99.9%/月。
* 再試行キューとDLQ（UIから再処理可能）。
* メトリクス収集：保存件数、処理成功率、LLMコスト、滞留ジョブ。

---

## 4. データモデル（主要項目）

**Bookmark**

```
id: UUID
url: string
canonical_url: string
domain: string
source_type: enum(youtube, x, article, news, other)
title_raw: string
title_final: string
summary: string
tags: array[string]
category: enum(...)
content_text: string
embedding: vector(1536)
created_at: datetime
updated_at: datetime
read_at: datetime?
pinned: bool
archived: bool
hash: string
llm_status: enum(queued, processing, done, failed)
```

---

## 5. API仕様（MVP）

### POST /v1/bookmarks

* **入力**：

```json
{
  "url": "https://example.com",
  "source_hint": "article",
  "created_from": "ios"
}
```

* **ヘッダ**：`Idempotency-Key: <uuid>`
* **出力**：

```json
{
  "id": "uuid",
  "llm_status": "queued"
}
```

### GET /v1/bookmarks

* クエリ：`q`, `tag`, `source_type`, `after`, `before`, `limit`

### POST /v1/bookmarks/{id}/reprocess

* LLM再実行。

### 認証

* `POST /v1/auth/webauthn/registration`
* `POST /v1/auth/webauthn/assertion`

---

## 6. LLM要件

### モデル選択

* 既定：`gpt-4o-mini`
* 長文/高精度必要時：`gpt-4o`にフォールバック。

### プロンプト仕様（出力JSON Schema）

```json
{
  "title_final": "string(<=60j)",
  "summary": "string(120-200j)",
  "category": "enum([...])",
  "tags": ["string", "..."],
  "language": "enum(ja,en,other)"
}
```

* 厳格パース＋欠損時再試行。
* ユーザー編集結果をfew-shot学習に反映可能。

---

## 7. インフラ構成（候補）

* バックエンド：Cloudflare Workers + D1/Neon + R2 + Queues
  または Supabase（Postgres + Edge Functions）
* ストレージ：サムネイル・静的ファイルはR2/Supabase Storage。
* LLM呼び出し：サーバサイドのみ。

---

## 8. 運用・監視

* ダッシュボード：日別トークン消費、処理成功率、DLQ件数。
* アラート：トークン急増、課金閾値超過、LLM 401/429、キュー滞留。
* インシデント手順：

  1. LLM呼び出し停止（ブレーカー）
  2. APIキー無効化
  3. 利用状況調査
  4. 閾値見直し

---

## 9. ロードマップ（MVP）

1. 認証（パスキー）、保存API、共有シート最短動線
2. 抽出パイプライン（OGP/Readability）、LLM処理
3. 検索（BM25）、タグ/フィルタ
4. Webブックマークレット
5. 観測・コストガード

---

## 10. 成功指標（KPI）

* 保存平均タップ数 ≤ 1.2
* 保存→要約完了P95 < 20秒
* 検索1回で目的ヒット率 ≥ 80%
* 月次LLMコストが予算内（上限ガード作動0回）

---