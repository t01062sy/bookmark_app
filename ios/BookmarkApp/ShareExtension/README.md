# iOS Share Extension for BookmarkApp

## 概要

このShare ExtensionはBookmarkAppのiOS Share Extension実装です。Safari、Chrome、その他のアプリからURLを直接ブックマークアプリに保存することができます。

## 主な機能

### ✅ URL処理
- **自動URL検出**: 共有されたコンテンツからURLを自動抽出
- **テキスト内URL認識**: プレーンテキスト内のURLも検出可能
- **複数形式対応**: URL、プレーンテキスト、リッチテキストに対応

### ✅ ソースタイプ自動判定
```swift
// 自動的にソースタイプを判定
- YouTube: youtube.com, youtu.be
- X (Twitter): twitter.com, x.com  
- ブログ: medium.com, substack.com
- テック: github.com
- その他: パス解析による記事/ニュース判定
```

### ✅ Supabase API統合
- **BookmarkAPIClient使用**: 既存のAPI層を共有
- **冪等性キー**: 重複保存を防止
- **非同期処理**: バックグラウンドでの保存処理
- **エラーハンドリング**: ユーザーフレンドリーなエラー表示

### ✅ ユーザーエクスペリエンス
- **シンプルUI**: 保存中はローディング表示
- **自動終了**: 保存成功後1秒で自動クローズ
- **キャンセル対応**: ユーザーによるキャンセル処理
- **状態フィードバック**: リアルタイムの処理状況表示

## ファイル構成

```
ShareExtension/
├── ShareViewController.swift    # メイン処理ロジック
├── MainInterface.storyboard    # UI定義  
├── Info.plist                  # Extension設定
└── README.md                   # このファイル

Shared/
└── BookmarkAPIClient.swift     # API通信クライアント
```

## セットアップ手順

### 1. Xcodeでの設定
```bash
# Xcodeプロジェクトを開く
open BookmarkApp.xcodeproj

# Target追加手順:
# 1. プロジェクト選択 → ターゲット一覧の「+」ボタン
# 2. iOS → Application Extension → Share Extension
# 3. Product Name: ShareExtension
# 4. Bundle Identifier: com.yourcompany.BookmarkApp.ShareExtension
```

### 2. ファイルの置換
生成されたデフォルトファイルを以下で置換:
- `ShareViewController.swift`
- `MainInterface.storyboard` 
- `Info.plist`

### 3. 共有ファイルの設定
`Shared/BookmarkAPIClient.swift`を両ターゲット（BookmarkApp + ShareExtension）に追加

### 4. Bundle Identifier設定
```
Main App: com.yourcompany.BookmarkApp
Extension: com.yourcompany.BookmarkApp.ShareExtension
```

## 技術仕様

### iOS要件
- **最低バージョン**: iOS 17.0以上
- **言語**: Swift 5.0+
- **UI**: UIKit + Storyboard
- **共有**: NSExtensionItem処理

### API通信
```swift
// リクエスト構造
CreateBookmarkRequest(
    url: String,           // 必須: 保存するURL
    title: String?,        // オプション: 共有時のタイトル
    tags: [String]?,       // オプション: タグ（未使用）
    category: String?,     // オプション: カテゴリ（未使用）
    sourceType: String     // 自動判定: youtube, x, blog, tech, article, news, other
)
```

### エラーハンドリング
- **ネットワークエラー**: 接続失敗時の表示
- **URL無効**: 有効なURLが見つからない場合
- **API エラー**: Supabase側のエラー処理
- **ユーザーキャンセル**: 明示的なキャンセル処理

## 使用方法

### エンドユーザー向け
1. **Safari等でWebページを開く**
2. **共有ボタン（□↑）をタップ**
3. **「Add to Bookmarks」を選択**
4. **自動的に保存完了**

### 開発者向けテスト
```bash
# ビルドとテスト実行
./build-and-test.sh

# 手動テスト手順
# 1. メインアプリをビルド・実行
# 2. Safariでテストページ開く
# 3. 共有シート確認
# 4. Extension動作確認
```

## トラブルシューティング

### よくある問題

**1. Share Extensionが表示されない**
- Bundle Identifierの確認
- Info.plistの設定確認  
- ターゲットのビルド設定確認

**2. URL抽出に失敗する**
```swift
// デバッグログで確認
print("Shared URL: \(sharedURL)")
print("Shared Title: \(sharedTitle)")
```

**3. API通信エラー**
- Supabaseの接続状態確認
- APIキーの有効性確認
- ネットワーク接続確認

**4. ビルドエラー**
```bash
# Clean build
xcodebuild clean -project BookmarkApp.xcodeproj -scheme BookmarkApp
```

### ログ出力
Extension実行中のログはXcodeのConsoleまたはDevice Logsで確認:
```
Device → Open Console → デバイス選択 → ShareExtension
```

## 今後の拡張予定

### Phase 2での機能追加
- [ ] **タグ自動生成**: URL内容に基づく自動タグ付け
- [ ] **カテゴリ学習**: ユーザー行動に基づくカテゴリ自動選択
- [ ] **オフライン対応**: ネットワーク切断時の保存キュー
- [ ] **プレビュー表示**: 保存前のコンテンツプレビュー

### UI改善
- [ ] **SwiftUI化**: より現代的なUI実装
- [ ] **Dark Mode対応**: システム設定に連動
- [ ] **アニメーション追加**: よりスムーズな UX
- [ ] **設定画面**: Extension内での設定変更

## 技術的詳細

### NSExtensionItem処理
```swift
// URL取得の優先順位
1. UTType.url -> 直接URL取得
2. UTType.plainText -> テキスト内URL検索  
3. NSDataDetector -> URL パターンマッチング
```

### ソースタイプ判定ロジック
```swift
private func detectSourceType(from urlString: String) -> String {
    // ドメインベース判定 → パスベース判定 → デフォルト
}
```

### 非同期処理パターン
```swift
Task { @MainActor in
    // UI更新は必ずメインスレッドで実行
    do {
        let response = try await apiClient.createBookmark(request)
        showSuccess("Bookmark saved!")
    } catch {
        showError("Failed: \(error.localizedDescription)")
    }
}
```