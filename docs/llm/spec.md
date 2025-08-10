# LLM仕様

## 1. モデル選択
- 基本：gpt-5-mini
- 長文/精度必要時：gpt-5にフォールバック

## 2. 入力
- title_raw
- domain
- content_excerpt（最大4000文字、先頭＋結論重視）

## 3. 出力 JSON Schema
```json
{
  "title_final": "string(<=60j)",
  "summary": "string(120-200j)",
  "category": "enum([...])",
  "tags": ["string", "..."],
  "language": "enum(ja,en,other)"
}

## 4. 制御パラメータ
temperature=0.2
max_output_tokens=300
欠損時は最大2回再試行

## 5. 学習ループ
ユーザーが編集したタグ/カテゴリをfew-shotに反映
サイトごとの固定ルール登録可能

## 6. `/docs/extract_normalize.md` — 抽出/正規化ルール

```markdown
# 抽出/正規化ルール

## 1. URL正規化
- UTM等トラッキング除去
- AMP→本体URL
- リダイレクト解決
- t.co短縮展開

## 2. メタデータ取得
- OGP/oEmbed取得（タイムアウト3s）
- Readabilityで本文抽出（タイムアウト5s）
- YouTube：oEmbed＋字幕
- X：OGPベース、API非必須

## 3. 失敗時挙動
- 抽出失敗→メタデータのみ保存
- LLM処理は本文なしでも実行可

## 4. 禁止事項
- Paywall記事本文保存（タイトル/概要のみ）
- 利用規約に違反するスクレイピング
