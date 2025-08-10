# レポジトリ構成 & CI/CD設計

## 1. ディレクトリ構成
```
bookmark_app/
├── api/                    # バックエンドAPI
│   ├── src/
│   │   ├── handlers/       # Cloudflare Workers handlers
│   │   ├── services/       # ビジネスロジック
│   │   ├── db/            # データベース関連
│   │   └── utils/         # ユーティリティ
│   ├── migrations/        # DBマイグレーション
│   ├── tests/            # テストファイル
│   └── wrangler.toml     # Cloudflare設定
├── ios/                   # iOSアプリ
│   ├── BookmarkApp/      # メインアプリ
│   ├── ShareExtension/   # 共有エクステンション
│   └── Tests/           # テストファイル
├── web/                  # Web PWA
│   ├── src/
│   │   ├── components/   # Reactコンポーネント
│   │   ├── hooks/       # カスタムフック
│   │   └── services/    # API呼び出し
│   └── tests/          # テストファイル
├── docs/                # ドキュメント
├── scripts/             # 開発・運用ツール
└── shared/              # 共通型定義・定数
```

## 2. GitHub Actions CI/CD Pipeline

### PR時（.github/workflows/pr-check.yml）
```yaml
name: PR Check
on: [pull_request]

jobs:
  changes:
    # paths-filter で変更検出
    
  api-test:
    if: needs.changes.outputs.api == 'true'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/setup-node@v4
      - run: npm ci && npm run lint && npm run test
        working-directory: ./api
        
  ios-test:
    if: needs.changes.outputs.ios == 'true'
    runs-on: macos-latest
    steps:
      - uses: maxim-lobanov/setup-xcode@v1
      - run: xcodebuild test -scheme BookmarkApp
        working-directory: ./ios
        
  web-test:
    if: needs.changes.outputs.web == 'true'
    runs-on: ubuntu-latest
    steps:
      - run: npm ci && npm run test && npm run build
        working-directory: ./web
```

### メインブランチ（.github/workflows/deploy-staging.yml）
```yaml
name: Deploy Staging
on:
  push:
    branches: [main]

jobs:
  deploy-api:
    runs-on: ubuntu-latest
    steps:
      - uses: cloudflare/wrangler-action@v3
        with:
          command: deploy --env staging
          workingDirectory: ./api
          
  deploy-web:
    runs-on: ubuntu-latest
    steps:
      - run: npm run build
        env:
          REACT_APP_API_URL: ${{ secrets.STAGING_API_URL }}
      - uses: amondnet/vercel-action@v25
```

### 本番デプロイ（.github/workflows/deploy-prod.yml）
```yaml
name: Deploy Production
on:
  workflow_dispatch:  # 手動実行のみ
    inputs:
      version:
        description: 'Release version'
        required: true

jobs:
  deploy:
    environment: production  # 承認ゲート
    runs-on: ubuntu-latest
    steps:
      - name: Run DB Migration
        run: npm run migrate:prod
      - name: Deploy API
        uses: cloudflare/wrangler-action@v3
```

## 3. ブランチ戦略・フロー

### Git Flow
- `main`: 本番リリース可能状態
- `develop`: 開発統合ブランチ
- `feature/*`: 機能開発
- `hotfix/*`: 緊急修正

### リリースフロー
1. `feature/xxx` → `develop` PR
2. `develop` で統合テスト
3. `develop` → `main` PR（ステージング自動デプロイ）
4. ステージング確認後、手動で本番デプロイ

## 4. 品質ゲート

### マージ要件
- [ ] 全テスト通過
- [ ] Lint/Format通過
- [ ] コードレビュー承認
- [ ] Lighthouse Performance > 90

### デプロイ要件（本番）
- [ ] ステージング動作確認
- [ ] E2Eテスト通過
- [ ] DBマイグレーション検証
- [ ] ロールバック手順確認

## 5. 環境管理

### 設定
- **開発**: localhost + local DB
- **ステージング**: Cloudflare Workers + Supabase staging
- **本番**: Cloudflare Workers + Supabase production

### シークレット管理
```yaml
# GitHub Secrets
CLOUDFLARE_API_TOKEN
SUPABASE_STAGING_URL / SUPABASE_STAGING_KEY
SUPABASE_PROD_URL / SUPABASE_PROD_KEY
OPENAI_API_KEY_STAGING / OPENAI_API_KEY_PROD
APPLE_SIGNING_CERTIFICATE
```

## 6. 監視・アラート

### ヘルスチェック
```yaml
# .github/workflows/health-check.yml
name: Health Check
on:
  schedule:
    - cron: '*/5 * * * *'  # 5分毎
    
jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - run: curl -f https://api.bookmarks.example.com/health
      - name: Notify on failure
        if: failure()
        run: slack-notify "API health check failed"
```

### デプロイ後チェック
- API応答確認
- 主要機能のスモークテスト
- エラー率監視
- 失敗時自動ロールバック

## 7. 開発ツール

### ローカル開発
```bash
# 全サービス起動
npm run dev:all

# 個別起動
npm run dev:api     # Cloudflare Workers local
npm run dev:web     # React dev server
npm run dev:ios     # Xcode simulator
```

### データベース
```bash
# マイグレーション
npm run db:migrate

# シード投入
npm run db:seed

# リセット
npm run db:reset
```

### テスト
```bash
# 全テスト
npm run test:all

# 単体テスト
npm run test:unit

# E2Eテスト
npm run test:e2e -- --headed
```
