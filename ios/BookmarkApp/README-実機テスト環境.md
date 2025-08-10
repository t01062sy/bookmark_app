# 実機テスト用Mac環境構築ガイド

このガイドは、開発用Macとは別のMacでiPhone実機テストを行うための手順書です。

## 前提条件

### テスト用Mac要件
- **macOS**: Big Sur 11.0以降
- **Xcode**: 15.0以降
- **iPhone**: iOS 17.0以降
- **Apple ID**: Personal Team使用可能
- **Git**: インストール済み

## セットアップ手順

### ステップ1: プロジェクトClone

```bash
# 1. プロジェクトをクローン
git clone https://github.com/[your-username]/bookmark_app.git
cd bookmark_app/ios/BookmarkApp

# 2. 最新の変更を取得
git pull origin main
```

### ステップ2: Xcode設定

#### 2-1. プロジェクトを開く
```bash
open BookmarkApp.xcodeproj
```

#### 2-2. Signing & Capabilities設定
1. **プロジェクト選択**: 左側NavigatorでBookmarkAppプロジェクト名をクリック
2. **ターゲット選択**: TARGETSでBookmarkAppを選択  
3. **Signing & Capabilities**タブをクリック
4. **Team設定**:
   - Team: [Add Account...]をクリック
   - あなたのApple IDでサインイン
   - Team: [あなたの名前] (Personal Team)を選択

#### 2-3. Bundle Identifier変更
```
Bundle Identifier: com.example.BookmarkApp
↓ 以下に変更（あなたの一意な名前）
Bundle Identifier: com.[yourname].BookmarkApp
```

**例**: `com.tanaka.BookmarkApp`, `com.testuser.BookmarkApp`

### ステップ3: iPhone実機接続

#### 3-1. 物理接続
1. Lightning/USB-CケーブルでiPhoneをMacに接続
2. iPhone側で「このコンピュータを信頼しますか？」→ **信頼**
3. パスコード入力（必要に応じて）

#### 3-2. デバイス選択
1. Xcode上部の実行対象選択（BookmarkApp > iPhone Simulator部分）をクリック
2. **My Devices**セクションであなたのiPhoneを選択

### ステップ4: Developer Mode有効化

#### 4-1. 初回ビルド
1. **Command + R**でビルド実行
2. 初回は「Could not launch」エラーが表示される（正常）

#### 4-2. iPhone設定
```
iPhone設定 → プライバシーとセキュリティ → デベロッパモード
→ デベロッパモードをオン
→ 再起動実行
→ 再起動後、パスコード入力してDeveloper Mode有効化
```

#### 4-3. 開発者信頼設定
```
iPhone設定 → 一般 → VPNとデバイス管理  
→ デベロッパApp → [あなたのApple ID]
→ "[あなたのApple ID]"を信頼 → 信頼
```

### ステップ5: アプリ実行

1. 再度**Command + R**でビルド・実行
2. iPhoneにBookmarkAppがインストール・起動される
3. サンプルデータでブックマーク一覧が表示されることを確認

## テスト項目

### 基本機能テスト
- [ ] **アプリ起動**: ホーム画面からアプリ起動
- [ ] **ブックマーク一覧**: 13個のサンプルデータ表示
- [ ] **検索機能**: タイトル・要約・タグでの検索
- [ ] **フィルタ機能**: カテゴリ・ソースタイプ別表示
- [ ] **詳細表示**: ブックマーク詳細画面表示
- [ ] **編集機能**: ブックマーク情報編集
- [ ] **新規追加**: 手動URL入力での新規作成

### 実機特有テスト
- [ ] **タッチ操作**: スワイプ・タップの応答性
- [ ] **画面回転**: Portrait/Landscape対応
- [ ] **バックグラウンド**: アプリ切り替え時の状態保持
- [ ] **通知**: システム通知との競合確認

## Share Extension実機テスト

### 事前準備（重要）
Share Extensionを実機でテストするには、Xcodeで追加ターゲット設定が必要です：

#### ShareExtension ターゲット追加
1. **Xcodeプロジェクト**で左側のプロジェクト名をクリック
2. **ターゲット一覧**の下部「+」ボタンをクリック
3. **iOS** > **Application Extension** > **Share Extension**
4. 設定:
   ```
   Product Name: ShareExtension
   Bundle Identifier: com.[yourname].BookmarkApp.ShareExtension  
   Language: Swift
   Use Storyboard: Yes
   ```

#### ファイル置換
生成されたデフォルトファイルを以下で置換：
```
ShareViewController.swift → /ShareExtension/ShareViewController.swift
MainInterface.storyboard → /ShareExtension/MainInterface.storyboard
Info.plist → /ShareExtension/Info.plist
```

#### 共有ファイル設定
1. `Shared/BookmarkAPIClient.swift`を選択
2. File Inspectorで**両ターゲット**（BookmarkApp + ShareExtension）にチェック

### Share Extension実機テスト手順

#### テスト1: Safari共有
1. **Safari**でWebサイトを開く（例: https://github.com/microsoft/vscode）
2. **共有ボタン**（□↑）をタップ
3. **「Add to Bookmarks」**が表示されることを確認
4. タップして保存処理をテスト
5. 「Bookmark saved successfully!」メッセージ確認
6. BookmarkAppでデータ反映確認

#### テスト2: その他アプリ共有
1. **Twitter/X アプリ**でツイートの共有ボタン
2. **YouTube アプリ**で動画の共有ボタン
3. **Notes アプリ**でURLを含むメモの共有
4. 各アプリでShare Extensionが表示されることを確認

#### テスト3: エラーハンドリング
1. **機内モード**でShare Extension実行 → ネットワークエラー表示確認
2. **無効URL**で共有実行 → 「No valid URL found」表示確認
3. **キャンセル操作** → 正常終了確認

## トラブルシューティング

### よくある問題

#### 1. iPhone認識されない
```bash
# システムレベルでの認識確認
system_profiler SPUSBDataType | grep -i phone
```
- USBケーブル再接続
- iPhone再起動
- Xcode再起動

#### 2. ビルドエラー
- Bundle Identifierの一意性確認
- Development Team設定確認
- プロビジョニングプロファイル再生成

#### 3. Share Extensionが表示されない
- Bundle Identifier階層確認:
  - Main: com.[name].BookmarkApp
  - Extension: com.[name].BookmarkApp.ShareExtension
- Info.plist設定確認
- 両ターゲット同時ビルド確認

#### 4. Certificate エラー
Personal Team使用時の制限:
- **署名期限**: 7日間（期限後再ビルド必要）
- **デバイス制限**: 自分のiPhoneのみ
- **配布不可**: 他人への配布不可

## 重要な注意点

### 開発・テスト環境の使い分け
- **開発Mac**: コード編集、Simulator動作確認
- **テスト用Mac**: 実機での最終動作確認
- **同期**: Git経由で変更内容を同期

### セキュリティ考慮
- Personal Team使用のため機能制限あり
- 実機テスト時も個人使用の範囲内
- 配布・公開は Apple Developer Program加入後

### データ同期注意
- 実機テスト時はSupabase本番環境使用
- 開発時のローカルデータとは分離
- テスト用データの混入に注意

## 完了チェックリスト

### 環境構築完了確認
- [ ] Git clone成功
- [ ] Xcode プロジェクト正常オープン
- [ ] Bundle Identifier変更完了
- [ ] Personal Team設定完了
- [ ] iPhone認識・信頼設定完了
- [ ] Developer Mode有効化完了

### アプリテスト完了確認
- [ ] メインアプリ正常動作確認
- [ ] 基本機能（一覧・検索・編集）動作確認
- [ ] Share Extension ターゲット追加完了
- [ ] Safari Share Extension動作確認
- [ ] エラーハンドリング動作確認

これで実機テスト環境が完全に整います。