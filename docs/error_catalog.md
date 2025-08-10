# エラーカタログ・設計

## 1. APIエラー仕様

| コード | HTTP | 原因 | ユーザー表示文言 | 再試行可否 | アクション |
|--------|------|------|-----------------|-----------|-----------|
| ERR_DUPLICATE | 409 | URL重複（正規化後一致） | 既に保存済みです | × | 既存ブック マーク表示 |
| ERR_INVALID_URL | 400 | URLフォーマット不正 | URLが正しくありません | × | 入力形式案内 |
| ERR_UNAUTHORIZED | 401 | 認証失敗 | ログインしてください | ○ | ログイン画面遷移 |
| ERR_FORBIDDEN | 403 | アクセス権なし | アクセス権がありません | × | サポート連絡先表示 |
| ERR_RATE_LIMIT | 429 | レート上限超過 | 後でもう一度お試しください | ○（時間後） | Retry-After ヘッダー表示 |
| ERR_LLM_FAIL | 500 | LLM処理失敗 | 要約に失敗しました | ○ | 再処理ボタン表示 |
| ERR_EXTRACT_FAIL | 500 | 本文抽出失敗 | 要約できませんでした（メタのみ保存） | × | そのまま保存完了扱い |
| ERR_COST_LIMIT | 503 | LLMコスト上限 | 一時的に利用制限中です | ○（翌日） | 制限解除予定時刻表示 |
| ERR_NETWORK | 500 | 外部API接続失敗 | 接続エラーです | ○ | しばらく待って再試行 |
| ERR_TIMEOUT | 504 | 処理タイムアウト | 処理に時間がかかっています | ○ | バックグラウンド処理継続 |
| ERR_INTERNAL | 500 | 不明エラー | 予期せぬエラーが発生しました | ○ | エラー報告リンク |

## 2. JSON Response Format

```json
{
  "error": "ERR_DUPLICATE",
  "message": "既に保存済みです", 
  "code": "DUPLICATE_BOOKMARK",
  "details": {
    "existing_bookmark_id": "uuid",
    "canonical_url": "https://example.com",
    "created_at": "2024-01-01T00:00:00Z"
  },
  "retry_after": null,
  "suggested_action": "view_existing"
}
```

## 3. クライアント側エラーハンドリング

### iOS
- Toast通知でエラー表示
- 再試行可能な場合は「再試行」ボタン
- ネットワークエラー時はローカルキューに保存

### Web
- トースト + モーダルでエラー詳細表示
- プログレッシブエンハンスメント（JS無効時も対応）

## 4. ログ・監視

### エラーログ形式
```json
{
  "timestamp": "2024-01-01T00:00:00Z",
  "level": "ERROR", 
  "error_code": "ERR_LLM_FAIL",
  "request_id": "uuid",
  "user_id": "uuid",
  "url": "https://example.com",
  "stack_trace": "...",
  "context": {
    "llm_model": "gpt-4o-mini",
    "attempt": 2,
    "total_tokens": 150
  }
}
```

### アラート条件
- `ERR_LLM_FAIL` > 5%/hour
- `ERR_UNAUTHORIZED` spike（認証問題）
- `ERR_INTERNAL` > 1%/hour
- `ERR_COST_LIMIT` 発生時即座

## 5. ユーザーサポート

### エラー報告UI
- エラーコード・時刻の自動入力
- 再現手順入力欄
- ブラウザ/OSバージョン自動検出

### FAQ対応
- よくあるエラーの解決方法
- ネットワーク設定確認方法
