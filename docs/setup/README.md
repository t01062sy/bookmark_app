# セットアップガイド一覧

このフォルダには、ブックマークアプリの開発・運用に必要なセットアップ手順書が含まれています。

## 📋 手順書一覧

### Phase 1B: バックエンド基盤構築
- **[supabase-setup-guide.md](./supabase-setup-guide.md)** - Supabase プロジェクト作成・DB構築手順
  - 所要時間: 2-3時間
  - 対象: Phase 1B Week 1
  - 完了目標: API開発準備完了

### 今後追加予定
- **edge-functions-setup.md** - Supabase Edge Functions 開発環境セットアップ（Phase 1B Week 2）
- **ios-api-integration.md** - iOS アプリ API 連携手順（Phase 1B Week 3）
- **openai-setup.md** - OpenAI API 連携・LLM パイプライン構築（Phase 2A）
- **web-app-setup.md** - React PWA 開発環境構築（Phase 3A）
- **production-deployment.md** - 本番環境デプロイ手順（Phase 4B）

## 🎯 開発フェーズと対応手順書

| フェーズ | 手順書 | 内容 | 所要時間 |
|----------|--------|------|----------|
| Phase 1B Week 1 | supabase-setup-guide.md | Supabase プロジェクト・DB構築 | 2-3時間 |
| Phase 1B Week 2 | edge-functions-setup.md | API開発環境・基本エンドポイント | 1-2日 |
| Phase 1B Week 3 | ios-api-integration.md | iOS アプリとAPI連携 | 1-2日 |
| Phase 2A | openai-setup.md | LLM処理パイプライン構築 | 2-3週 |
| Phase 3A | web-app-setup.md | React PWA 開発 | 3-4週 |

## 📝 使用方法

1. **現在のフェーズを確認**
   - `../開発計画書.md` で進捗状況を確認

2. **対応する手順書を実行**  
   - 各手順書は独立して実行可能
   - チェックリスト形式で進捗管理

3. **完了後の次回準備**
   - 各手順書の最後に「次回開発の準備」セクションあり
   - 必要な情報・環境変数を保存

## ⚠️ 注意事項

- 手順書は**順番通り**に実行すること
- API キーなどの**秘密情報は適切に管理**すること  
- 各フェーズ完了後は**動作確認を必須実行**すること
- 問題が発生した場合は**トラブルシューティング**セクションを参照

## 🆘 サポート

手順書でわからない点があれば:
1. 各手順書の「トラブルシューティング」セクションを確認
2. 関連ドキュメント（`../requirements_specification.md`, `../data_model.md` 等）を参照
3. 開発計画書で全体の流れを再確認