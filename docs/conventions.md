# 命名規約・コードスタイル

## 1. API
- snake_case（JSONキー）
- エンドポイントは名詞ベース（/bookmarks）

## 2. DB
- テーブル名：複数形（bookmarks）
- カラム名：snake_case
- enumは小文字英語

## 3. コード
- iOS: SwiftLint準拠
- サーバ: ESLint + Prettier
- 関数名は動詞始まり（saveBookmark）

## 4. コミットメッセージ
- `feat: ...`, `fix: ...`, `docs: ...`
