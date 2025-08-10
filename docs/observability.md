# 観測設計

## 1. ログ
- 必須フィールド：`timestamp`, `request_id`, `user_id`, `endpoint`, `status_code`, `latency_ms`
- マスク対象：`Authorization`, `api_key`, `cookies`
- 相関ID：`trace_id`をキュー/LLM処理まで伝搬

## 2. メトリクス
- 保存応答P95
- 保存→要約完了P95
- 抽出成功率、LLM成功率
- LLM日次トークン消費
- キュー滞留時間（ms）

## 3. アラート閾値
- `llm_401_rate > 1% / 5m`
- `tokens_day > budget`
- `queue_lag_ms > 300000`（5分）
- `error_rate > 5%`

## 4. トレーシング
- 分散トレーシング（OpenTelemetry）
- 各ジョブ開始/終了をイベント化
