# 機密情報管理ガイド

**目的**: 生成されたパスワード・APIキーの安全な保存・管理  
**対象**: ローカル開発環境での機密情報保護  
**重要度**: 🔴 Critical（データ漏えい防止）

---

## 🎯 作成された機密情報ファイル

### 📁 メインファイル
- **`.secrets`** - 全機密情報の集約保管庫（権限600）
- **`.env.local`** - 開発環境用設定（権限600）
- **`backups/secrets/.secrets_backup_YYYYMMDD_HHMMSS`** - 暗号化バックアップ

### 🔐 保存済み機密情報

#### Supabase 認証情報
```
SUPABASE_DB_MASTER_PASSWORD=GQotdK0ykSTZD9fhY98yBEF5827
```
- **用途**: Supabase プロジェクト作成時のDatabase Password
- **強度**: 27文字、英数字混合、OpenSSL生成
- **次回ローテーション**: 2025年11月10日

#### セキュリティキー（将来使用）
```
JWT_SECRET_KEY=ACOJTLgEzsAFD5rGdlxiWev... (64文字)
API_SECRET_KEY=rutv0xDGJZOHLpGjNzo4VrPh... (32文字) 
ENCRYPTION_KEY=9VoXbKkibonmocW3CsiWwHqI... (32文字)
```

---

## 🛡️ セキュリティ設定状況

### ✅ 完了済みセキュリティ対策

#### ファイルレベル保護
- **権限600設定**: 所有者のみ読み書き可能
- **Git除外設定**: `.gitignore`で`.secrets*`と`backups/secrets/`を除外
- **自動バックアップ**: タイムスタンプ付きでローカル保存

#### アクセス制御
- **ファイル暗号化**: macOSのFileVault有効推奨
- **ディスク暗号化**: 全ディスク暗号化（FileVault/BitLocker）
- **ユーザーアカウント保護**: 強力なログインパスワード必須

---

## 🔧 管理用スクリプト

### パスワード生成・更新
```bash
# 新しいパスワード生成
./scripts/generate-secure-passwords.sh

# バックアップ作成
./scripts/backup-secrets.sh
```

### ファイル権限確認
```bash
# 権限確認
ls -la .secrets .env.local

# 期待する出力: -rw------- (600)
```

### Git追跡状況確認
```bash
# Git管理対象外であることを確認
git status --ignored

# .secrets が ignored files に表示されることを確認
```

---

## 📝 次回 Supabase セットアップでの使用方法

### Step 1: パスワード確認
```bash
# Supabase用パスワード確認
grep "SUPABASE_DB_MASTER_PASSWORD" .secrets
```

### Step 2: Supabase プロジェクト作成時に入力
1. https://supabase.com → New Project
2. Database Password欄に: `GQotdK0ykSTZD9fhY98yBEF5827`
3. プロジェクト作成完了後、API情報を`.secrets`ファイルに追記

### Step 3: API情報の更新
```bash
# プロジェクト作成後に手動で追記
echo "SUPABASE_PROJECT_ID=abcdefgh" >> .secrets
echo "SUPABASE_URL=https://abcdefgh.supabase.co" >> .secrets
echo "SUPABASE_ANON_KEY=eyJhbGci..." >> .secrets
```

---

## 🔄 定期メンテナンス

### パスワードローテーション（3ヶ月毎）

#### 準備作業
```bash
# 現在のパスワードをバックアップ
./scripts/backup-secrets.sh

# 新パスワード生成
./scripts/generate-secure-passwords.sh
```

#### Supabase側での更新
1. Supabase Dashboard → Settings → Database
2. "Reset database password" をクリック
3. 新しいパスワードを入力
4. 接続設定の更新確認

#### ローカル環境の更新
```bash
# .secrets ファイルの PREVIOUS_DB_PASSWORD を現在のパスワードに設定
# SUPABASE_DB_MASTER_PASSWORD を新しいパスワードに更新
# NEXT_PASSWORD_ROTATION_DATE を3ヶ月後に設定
```

### APIキーローテーション（1ヶ月毎）
1. Supabase Dashboard → Settings → API
2. "Reset API keys" 実行
3. 新しいキーを`.secrets`ファイルに更新
4. アプリケーションでの接続テスト

---

## ⚠️ セキュリティインシデント対応

### APIキー漏えい時の緊急対応

#### 即座に実行（5分以内）
```bash
# 1. 漏えいしたキーを即座に無効化
# Supabase: Dashboard → Settings → API → Reset API keys
# OpenAI: Dashboard → API Keys → Revoke key

# 2. 新しいキー生成
./scripts/generate-secure-passwords.sh

# 3. Git履歴から機密情報削除（必要に応じて）
git filter-branch --force --index-filter \
  'git rm --cached --ignore-unmatch .secrets' \
  --prune-empty --tag-name-filter cat -- --all
```

#### 影響範囲調査（1時間以内）
- Git commit履歴での漏えい箇所特定
- 不正アクセスログの確認
- API使用状況の異常検知
- 関連サービスでの不正使用確認

#### 再発防止策
- commit hookの導入（機密情報検出）
- CI/CDでの機密情報スキャン
- 定期的なアクセスキー監査

---

## 📊 現在の保存状況サマリー

### 機密情報ファイル
| ファイル | サイズ | 権限 | バックアップ | Git除外 |
|----------|--------|------|-------------|---------|
| `.secrets` | 2.6KB | 600 | ✅ | ✅ |
| `.env.local` | 2.4KB | 600 | ✅ | ✅ |
| `backup_20250810_163541` | 2.6KB | 600 | - | ✅ |

### セキュリティチェック
- ✅ ファイル権限600設定
- ✅ Git追跡除外設定  
- ✅ 自動バックアップ機能
- ✅ パスワード強度確認（27文字、英数混合）
- ✅ ローテーション計画策定

### Phase 1B Week 1 実使用結果（2025年8月10日）
- ✅ Supabase プロジェクト作成: 正常完了
- ✅ データベース接続: パスワード認証成功
- ✅ API キー動作確認: ブラウザテスト成功
- ✅ .secrets ファイル管理: 問題なし
- ✅ バックアップ作成: 1個生成済み（.secrets_backup_20250810_163541）
- ⚠️ cURL 接続課題: 特殊文字エスケープ問題（基本動作は確認済み）

---

## 🆘 トラブルシューティング

### よくある問題

#### 1. ファイル権限エラー
```bash
# 権限修正
chmod 600 .secrets .env.local
chmod 600 backups/secrets/.secrets_backup_*
```

#### 2. Git追跡に含まれそうになる
```bash
# 強制除外
git rm --cached .secrets .env.local
echo ".secrets*" >> .gitignore
echo "backups/secrets/" >> .gitignore
```

#### 3. バックアップファイルが作成できない
```bash
# ディレクトリ作成
mkdir -p backups/secrets
chmod 700 backups/secrets
```

#### 4. パスワードを忘れた場合
```bash
# .secrets ファイルから確認
grep "SUPABASE_DB_MASTER_PASSWORD" .secrets

# バックアップから復元
cp backups/secrets/.secrets_backup_* .secrets
```

---

## 📋 セキュリティチェックリスト

### 日常チェック（週1回）
- [ ] `.secrets`ファイルの権限が600であることを確認
- [ ] Gitステータスで機密ファイルが追跡されていないことを確認
- [ ] 異常なAPI使用状況がないかログ確認

### 月次チェック
- [ ] パスワードマネージャーでのバックアップ同期
- [ ] API使用量・課金状況の確認
- [ ] セキュリティログの監査
- [ ] 不要なバックアップファイルのクリーンアップ

### 四半期チェック
- [ ] パスワードローテーション実施
- [ ] セキュリティポリシーの見直し
- [ ] バックアップファイルの整合性確認
- [ ] アクセス権限の再検証

---

**🛡️ 機密情報は企業・個人の最重要資産です**

適切な管理により、安全な開発環境を維持し、データ漏えいリスクを最小化しましょう。