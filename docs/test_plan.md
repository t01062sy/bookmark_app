# テスト計画

## 1. 単体テスト
- URL正規化
- Idempotency-Key生成/再利用
- 抽出（OGP/Readability）
- LLM出力スキーマ検証

## 2. 結合テスト
- iOS共有シート→API→キュー→LLM→一覧表示
- Webブックマークレット保存

## 3. E2Eテスト
- 保存→要約表示までのシナリオ
- 検索ヒット確認（BM25 + ベクトル）

## 4. 負荷テスト
- 保存100件同時POST（成功率/遅延測定）
- LLM呼び出し並列負荷（コスト監視）

## 5. 回帰テスト
- 対象サイト：youtube.com, x.com, note.com, medium.com, nytimes.com
- 定期実行：週1

## 6. 合否基準
- 成功率 ≥ 99%
- P95遅延基準を満たす
