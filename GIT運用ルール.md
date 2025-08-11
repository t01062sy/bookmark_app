# マルチデバイス開発のためのGit運用ルール

BookmarkAppプロジェクトの複数端末開発における効率的なGit運用戦略です。

## ブランチ戦略

### ブランチ構成
```
main ← 本番リリース可能な状態（Protected）
 ↑
develop ← 統合開発ブランチ（開発完了後のintegration）
 ↑                 ↑
dev-mac ← 開発Mac用  test-mac ← テスト用Mac用
 ↑                 ↑
feature/xxx        hotfix/xxx
```

### ブランチ詳細

#### `main` ブランチ
- **用途**: 本番リリース用、安定版
- **更新タイミング**: 機能完成・テスト完了後
- **保護設定**: Direct push禁止、PR必須
- **デバイス**: 全デバイスからpull only

#### `develop` ブランチ  
- **用途**: 統合開発、機能統合前テスト
- **更新タイミング**: 開発完了した機能の統合
- **デバイス**: 開発Mac・テスト用Mac両方

#### `dev-mac` ブランチ
- **用途**: 開発Mac専用の開発作業
- **特徴**: iOS Simulator、Web PWA、Backend開発
- **設定**: 開発Mac固有の設定を含む
- **デバイス**: 開発Macのみ

#### `test-mac` ブランチ
- **用途**: テスト用Mac専用、実機テスト
- **特徴**: Personal Team設定、実機向け調整
- **設定**: テスト用Mac固有の設定を含む
- **デバイス**: テスト用Macのみ

## 端末別開発フロー

### 開発Mac（メイン開発）

#### 日常開発フロー
```bash
# 1. 最新状態に同期
git checkout dev-mac
git pull origin develop

# 2. 機能開発
git checkout -b feature/new-search-ui
# 開発作業...
git add .
git commit -m "feat: 新しい検索UI実装"

# 3. 開発完了後
git checkout dev-mac
git merge feature/new-search-ui
git push origin dev-mac

# 4. 統合準備完了時
git checkout develop
git pull origin develop
git merge dev-mac
git push origin develop
```

#### 機能完成時
```bash
# テスト用Macでの確認依頼
git checkout develop
git push origin develop
# → テスト用Macに実機テスト依頼
```

### テスト用Mac（実機テスト）

#### 初期セットアップ
```bash
# 1. プロジェクトクローン  
git clone https://github.com/t01062sy/bookmark_app.git
cd bookmark_app

# 2. テスト用ブランチ作成・設定
git checkout -b test-mac origin/develop
git push -u origin test-mac

# 3. テスト用Mac固有設定
# Bundle Identifierをテスト用に変更
# Personal Team設定
git add .
git commit -m "config: テスト用Mac環境設定"
git push origin test-mac
```

#### テストフロー
```bash
# 1. 最新機能取得
git checkout test-mac
git pull origin develop
git merge develop

# 2. テスト用Mac固有設定の維持
# 設定競合があれば手動解決

# 3. 実機テスト実行
# iPhone実機でのテスト...

# 4. バグ発見時の修正
git checkout -b hotfix/real-device-issue
# バグ修正...
git commit -m "fix: 実機テストで発見されたタッチ応答性問題修正"
git push origin hotfix/real-device-issue

# 5. 修正をdevelopに反映
git checkout develop
git merge hotfix/real-device-issue
git push origin develop
```

## 設定ファイル管理戦略

### 環境固有ファイルの分離

#### 1. Xcodeプロジェクト設定
```bash
# Bundle Identifier管理
# 開発Mac: com.devmac.BookmarkApp
# テスト用Mac: com.testmac.BookmarkApp

# project.pbxproj は各ブランチで独自管理
# git merge時は手動解決
```

#### 2. 設定ファイルテンプレート化
```bash
# config/
├── xcode-config-template.xcconfig
├── bundle-ids.json
└── team-settings.json
```

#### 3. .gitignore 最適化
```bash
# デバイス固有ファイル
*.xcuserstate
*.xcworkspace/xcuserdata/
DerivedData/
.DS_Store

# 環境固有設定（必要に応じて）
ios/BookmarkApp/BookmarkApp.xcodeproj/project.pbxproj.local
```

## コミット・PR戦略

### コミットメッセージ規約
```bash
# プレフィックス使用
feat: 新機能追加
fix: バグ修正  
docs: ドキュメント更新
config: 設定変更
test: テスト追加・修正
refactor: リファクタリング
perf: パフォーマンス改善

# デバイス情報追加
[dev-mac] feat: iOS Simulator用検索機能改善
[test-mac] fix: iPhone実機でのShare Extension修正
[both] docs: API仕様更新
```

### Pull Request運用

#### 開発完了時のPR
```
Title: [dev-mac] 検索UI改善とパフォーマンス最適化
Base: develop ← Compare: dev-mac

Body:
## 実装内容
- 新しい検索UI実装
- BM25検索のパフォーマンス改善 (50ms → 20ms)
- レスポンシブデザイン対応

## テスト完了項目
- [x] iOS Simulator動作確認
- [x] Web PWA動作確認
- [ ] 実機テスト（test-mac待ち）

## 実機テスト依頼
@test-mac-user iPhone実機でのテストをお願いします
特に検索時のタッチ応答性を重点的にテストしてください
```

#### 実機テスト完了時のPR
```
Title: [test-mac] 実機テスト完了・バグ修正
Base: main ← Compare: develop

Body:
## 実機テスト結果
- ✅ 基本機能: 全て正常動作
- ✅ Share Extension: Safari/YouTube/Twitter対応確認
- ⚠️ 修正事項: タッチ応答性改善 (commit: abc123)

## リリース準備完了
全機能の開発・テストが完了しました
```

## 競合解決戦略

### よくある競合と解決法

#### 1. project.pbxproj競合
```bash
# 競合発生時
git status
# both modified: ios/BookmarkApp/BookmarkApp.xcodeproj/project.pbxproj

# 解決手順
git checkout --theirs ios/BookmarkApp/BookmarkApp.xcodeproj/project.pbxproj
# Xcodeで Bundle Identifier を手動設定
git add ios/BookmarkApp/BookmarkApp.xcodeproj/project.pbxproj
git commit -m "resolve: project.pbxproj Bundle ID競合解決"
```

#### 2. 設定ファイル競合
```bash
# 原則: 各ブランチの設定を尊重
# dev-mac → dev-mac固有設定を保持
# test-mac → test-mac固有設定を保持
```

## 自動化とツール

### Git Hooks設定
```bash
# .git/hooks/pre-commit
#!/bin/bash
# Bundle IDチェック
current_branch=$(git branch --show-current)
if [[ $current_branch == "dev-mac" ]]; then
    # 開発Mac用Bundle ID確認
    grep -q "com.devmac.BookmarkApp" ios/BookmarkApp/BookmarkApp.xcodeproj/project.pbxproj || {
        echo "⚠️  Bundle IDが開発Mac用でありません"
        exit 1
    }
elif [[ $current_branch == "test-mac" ]]; then
    # テスト用Mac Bundle ID確認  
    grep -q "com.testmac.BookmarkApp" ios/BookmarkApp/BookmarkApp.xcodeproj/project.pbxproj || {
        echo "⚠️  Bundle IDがテスト用Mac用でありません"
        exit 1
    }
fi
```

### GitHub Actions設定
```yaml
# .github/workflows/multi-device-ci.yml
name: Multi-Device CI
on:
  push:
    branches: [develop]
  pull_request:
    branches: [main]

jobs:
  ios-simulator-test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - name: iOS Simulatorテスト
        run: |
          cd ios/BookmarkApp
          xcodebuild test -scheme BookmarkApp -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
          
  web-pwa-test:
    runs-on: ubuntu-latest  
    steps:
      - uses: actions/checkout@v3
      - name: Web PWAテスト
        run: |
          cd web
          npm install
          npm run build
          npm run test
```

## 推奨運用フロー

### 日々の開発
1. **開発Mac**: 機能開発 → `dev-mac` → `develop`
2. **テスト用Mac**: `develop` → 実機テスト → バグ修正 → `develop`
3. **統合**: `develop` → テスト完了後 → `main`

### リリースフロー
1. 機能開発完了（開発Mac）
2. develop統合
3. 実機テスト（テスト用Mac）  
4. バグ修正・再テスト
5. main へPR・マージ
6. リリースタグ作成

この運用により、複数端末での効率的な開発が可能になります。