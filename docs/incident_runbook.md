# インシデント対応ランブック

## 1. 重大インシデント分類

### Severity 1: サービス停止・データ漏えい
- API全面停止、認証システム障害
- APIキー・認証トークン漏えい疑い
- **対応時間**: 15分以内に初動、1時間以内に応急復旧

### Severity 2: 主要機能障害
- LLM処理完全停止、検索機能停止
- 大量データ破損・消失
- **対応時間**: 30分以内に初動、4時間以内に復旧

### Severity 3: 部分機能障害
- LLM処理遅延、一部API応答遅延
- 単発的な処理失敗
- **対応時間**: 24時間以内に対応完了

## 2. APIキー漏えい対応（Severity 1）

### 2.1 検知・判定基準
```yaml
自動検知:
  - OpenAI API 401/403 > 10回/分
  - トークン消費量 > 通常の10倍/時
  - 異常な地理的アクセス（海外IP等）
  
手動判定:
  - GitHub等での秘密情報露出報告
  - セキュリティツールからのアラート
  - ユーザーからの不正利用報告
```

### 2.2 緊急対応手順（15分以内）
1. **即座に停止**
   ```bash
   # 緊急停止スクリプト実行
   ./scripts/emergency-stop.sh
   
   # または手動で
   export LLM_CIRCUIT_BREAKER=true  # 全LLM呼び出し停止
   ```

2. **APIキー無効化**
   ```bash
   # OpenAI管理画面でキー削除
   # または AWS Secrets Manager で無効化
   aws secretsmanager update-secret \
     --secret-id "openai-api-key" \
     --secret-string '{"key": "DISABLED"}'
   ```

3. **影響範囲調査**
   ```bash
   # 異常なAPI利用状況確認
   grep "openai" /var/log/api/*.log | tail -1000
   
   # 課金状況確認
   curl -H "Authorization: Bearer $OPENAI_KEY" \
     "https://api.openai.com/v1/usage?date=$(date +%Y-%m-%d)"
   ```

### 2.3 復旧手順（1時間以内）
1. **新しいAPIキー発行・設定**
   ```bash
   # 新キー生成（OpenAI管理画面）
   NEW_KEY="sk-new-key-here"
   
   # Secrets Manager更新
   aws secretsmanager update-secret \
     --secret-id "openai-api-key" \
     --secret-string "{\"key\": \"$NEW_KEY\"}"
   
   # サービス再起動
   export LLM_CIRCUIT_BREAKER=false
   ```

2. **制限・監視強化**
   ```bash
   # 緊急コストリミット設定
   export DAILY_COST_LIMIT=50  # 通常の1/10
   export HOURLY_COST_LIMIT=5
   
   # 監視強化
   export ALERT_SENSITIVITY=high
   ```

## 3. サービス停止対応（Severity 1）

### 3.1 原因別対応

#### API応答停止
```bash
# ヘルスチェック
curl -f https://api.bookmarks.example.com/health

# Cloudflare Workers ステータス確認
wrangler tail --format pretty

# データベース接続確認  
psql $DATABASE_URL -c "SELECT 1"

# 緊急時ロードバランサー切り替え
# (セカンダリリージョンがある場合)
```

#### データベース障害
```bash
# Supabase ダッシュボード確認
# 自動フェイルオーバー待機

# 読み取り専用モード有効化（書き込み停止）
export READ_ONLY_MODE=true

# 最新バックアップからリストア準備
```

## 4. コスト異常・LLM暴走対応（Severity 2）

### 4.1 検知基準
- 1時間あたりのコスト > 予算の5倍
- 処理キュー滞留 > 1000件
- LLM エラー率 > 50%

### 4.2 対応手順
```bash
# 1. LLM処理一時停止
export LLM_CIRCUIT_BREAKER=true

# 2. キュー確認・クリア
echo "SELECT COUNT(*) FROM processing_queue" | psql $DATABASE_URL
# 必要に応じてキューパージ

# 3. 異常な処理確認
echo "SELECT url, retry_count FROM bookmarks 
      WHERE llm_status = 'processing' 
      ORDER BY updated_at DESC LIMIT 10" | psql $DATABASE_URL

# 4. 段階的再開
export MAX_CONCURRENT_LLM=1  # 通常は10
export LLM_CIRCUIT_BREAKER=false
```

## 5. エスカレーション・連絡体制

### 5.1 Severity 1（即座）
- Slack: #emergency-channel に @here 通知
- Email: 開発者全員に緊急メール
- SMS: 責任者に直接SMS（深夜・休日）

### 5.2 Severity 2（30分以内）
- Slack: #incidents チャンネル通知  
- Email: 関係者に状況報告

### 5.3 通知テンプレート
```
【緊急】ブックマークアプリ障害発生

発生時刻: 2024-01-01 12:00 JST
症状: APIキー漏えい疑い・LLM処理異常
影響: 新規ブックマーク保存停止中
初動: APIキー無効化完了、調査中

担当: @username
次回報告: 30分後予定
```

## 6. 事後対応・ポストモーテム

### 6.1 必須実施項目
- インシデント報告書作成（24時間以内）
- 根本原因分析（5 Whys手法）
- 再発防止策立案・実装
- 監視・アラート改善

### 6.2 インシデント報告テンプレート
```markdown
# インシデント報告書

## 概要
- 発生日時: 
- 影響範囲: 
- 復旧完了時刻:
- 原因: 

## タイムライン
- XX:XX 障害発生
- XX:XX 検知・通知
- XX:XX 初動対応開始
- XX:XX 応急復旧完了

## 根本原因

## 再発防止策
1. 
2. 
3. 

## 学んだこと
```

## 7. 定期訓練・改善

### 7.1 月次訓練
- APIキー漏えい訓練（シミュレーション）
- 障害対応手順の確認・更新
- 新メンバーへの手順説明

### 7.2 四半期レビュー
- インシデント傾向分析
- 対応手順・ツールの改善
- アラート精度向上
