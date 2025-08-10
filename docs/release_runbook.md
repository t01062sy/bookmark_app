# リリース & ロールバック ランブック

## 1. リリース分類・戦略

### パッチリリース（緊急修正）
- **頻度**: 必要時即座
- **対象**: バグ修正・セキュリティ更新
- **戦略**: 即座に本番適用、最小限の検証

### マイナーリリース（機能追加）
- **頻度**: 週1回（金曜夜）
- **対象**: 新機能・改善
- **戦略**: Feature Flag使用、段階的ロールアウト

### メジャーリリース（大規模変更）
- **頻度**: 月1回（計画的）
- **対象**: API変更・DB変更・アーキテクチャ変更
- **戦略**: Blue-Green deployment、長期検証期間

## 2. リリース前チェックリスト

### 2.1 コード・品質確認
```bash
# 必須チェック項目
- [ ] GitHub Actions 全テスト通過
- [ ] Security scan クリア
- [ ] Performance test 通過（Lighthouse > 90）
- [ ] E2E test scenario 全通過

# 手動確認項目  
- [ ] ステージング環境で主要フロー動作確認
- [ ] 異常系・エラーハンドリング確認
- [ ] モバイル・デスクトップ両方での動作確認
```

### 2.2 インフラ・運用確認
```bash
# データベース
- [ ] マイグレーション dry-run 成功
- [ ] インデックス作成の性能影響評価
- [ ] バックアップ取得完了

# 監視・アラート
- [ ] 新メトリクス定義・ダッシュボード追加
- [ ] アラート閾値設定・テスト
- [ ] ログフォーマット変更時の解析ツール対応

# 外部依存
- [ ] OpenAI API レート制限・コスト確認
- [ ] Cloudflare Workers 設定確認
- [ ] 新しいサードパーティサービス認証確認
```

## 3. 本番リリース手順

### 3.1 段階的デプロイメント戦略

#### Phase 1: カナリアデプロイ（5%ユーザー）
```bash
# 1. Feature Flag でトラフィック制御
export FEATURE_NEW_UI_ENABLED=true
export FEATURE_NEW_UI_ROLLOUT_PERCENTAGE=5

# 2. デプロイ実行
wrangler deploy --env production

# 3. 30分間監視
# - エラー率 < 0.1%
# - P95レスポンスタイム変化 < 20%
# - LLMコスト変化 < 50%

# 問題なければ次段階へ
```

#### Phase 2: 段階的拡大（25% → 50% → 100%）
```bash
# 25%に拡大
export FEATURE_NEW_UI_ROLLOUT_PERCENTAGE=25
# 1時間監視

# 50%に拡大  
export FEATURE_NEW_UI_ROLLOUT_PERCENTAGE=50
# 2時間監視

# 100%（全ユーザー）
export FEATURE_NEW_UI_ROLLOUT_PERCENTAGE=100
```

### 3.2 データベースマイグレーション

#### 非破壊的マイグレーション（通常）
```bash
# 1. ステージングで事前実行
npm run db:migrate --env staging

# 2. 本番で実行（ゼロダウンタイム）
npm run db:migrate --env production

# 3. 新スキーマ利用開始
# アプリケーションデプロイで自動的に新カラム利用開始
```

#### 破壊的マイグレーション（慎重に）
```bash
# 1. メンテナンス通知（24時間前）

# 2. 読み取り専用モード有効化
export READ_ONLY_MODE=true

# 3. 最新バックアップ取得
pg_dump $DATABASE_URL > backup_$(date +%Y%m%d_%H%M%S).sql

# 4. マイグレーション実行
npm run db:migrate --env production --force

# 5. アプリケーションデプロイ

# 6. 読み取り専用モード解除
export READ_ONLY_MODE=false
```

## 4. 監視・検証フェーズ

### 4.1 リリース直後監視（30分間）
```yaml
Critical Metrics:
  - HTTP 5xx error rate < 0.1%
  - API response time P95 < 1.2s
  - Database connection pool utilization < 80%
  - LLM success rate > 99%

Business Metrics:
  - Bookmark save success rate > 99.5%
  - Search query success rate > 99%
  - User session error rate < 0.5%
```

### 4.2 スモークテスト自動実行
```bash
#!/bin/bash
# scripts/post-deploy-smoke-test.sh

# 基本API動作確認
curl -f https://api.bookmarks.example.com/health

# 認証フロー確認
npm run test:e2e:auth-flow

# ブックマーク保存・検索確認  
npm run test:e2e:bookmark-flow

# LLM処理確認（サンプルURL）
npm run test:integration:llm-processing
```

## 5. ロールバック手順

### 5.1 判断基準
```yaml
自動ロールバック:
  - HTTP 5xx rate > 1% for 5 minutes
  - P95 response time > 2x baseline for 10 minutes
  - Database connection errors > 10/minute

手動ロールバック判断:
  - 主要機能（保存・検索）の完全停止
  - データ破損・消失の検知
  - セキュリティインシデントの疑い
```

### 5.2 アプリケーション・ロールバック
```bash
# 1. 前バージョンに即座に戻す
wrangler rollback --env production

# 2. Feature Flag で新機能無効化
export FEATURE_NEW_UI_ENABLED=false

# 3. データベース接続先変更（必要時）
export DATABASE_URL=$BACKUP_DATABASE_URL

# 4. 確認・監視
curl -f https://api.bookmarks.example.com/health
```

### 5.3 データベース・ロールバック（重大時のみ）
```bash
# 注意: データ損失の可能性あり。慎重に実施

# 1. サービス停止
export MAINTENANCE_MODE=true

# 2. 最新バックアップから復旧
psql $DATABASE_URL < backup_latest.sql

# 3. データ整合性チェック
npm run db:integrity-check

# 4. サービス再開
export MAINTENANCE_MODE=false
```

## 6. ポストリリース・運用

### 6.1 24時間監視項目
- ユーザー行動パターン変化
- コスト変化（特にLLM利用量）
- 新機能利用率・エラー率
- パフォーマンス劣化の兆候

### 6.2 1週間後レビュー
```markdown
# リリースレビューテンプレート

## リリース概要
- バージョン: v1.2.0
- リリース日時: 2024-01-01 20:00 JST
- 影響範囲: Web UI新デザイン

## メトリクス比較
| 項目 | リリース前 | リリース後 | 変化率 |
|------|------------|------------|--------|
| 保存成功率 | 99.8% | 99.9% | +0.1% |
| 検索レスポンス時間 | 234ms | 198ms | -15.4% |
| LLMコスト/日 | $12.50 | $11.80 | -5.6% |

## 問題・改善点
1. 初日にiOS Safariで軽微なCSS問題発生（即座に修正）
2. Feature Flag切り替え時の一時的な混乱（手順改善要）

## 学んだこと
- カナリアデプロイ期間をもう少し長く取る
- モバイルブラウザテストの強化が必要
```

## 7. 緊急時・例外フロー

### 7.1 金曜夜リリース禁止の例外
- セキュリティパッチ（CVE対応）
- サービス停止につながるクリティカルバグ
- 外部サービス変更への緊急対応

### 7.2 承認フロー
```yaml
通常リリース: 開発者 → Tech Lead 確認
重要リリース: 開発者 → Tech Lead → Product Owner 承認  
緊急リリース: On-call engineer 判断で即座実行
```
