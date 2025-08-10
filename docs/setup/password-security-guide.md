# パスワード・セキュリティ管理ガイド

**目的**: Supabase・OpenAI等のAPIキー・パスワードを安全に管理する  
**対象**: 開発・本番環境での機密情報管理  
**所要時間**: 15分

---

## 🎯 セキュリティ目標

- ✅ 強力で予測不可能なパスワード生成
- ✅ ローカル環境での安全な機密情報管理
- ✅ GitHubへの機密情報流出防止
- ✅ 適切なファイル権限設定
- ✅ 定期的なパスワードローテーション準備

---

## 🔐 パスワード生成・管理方法

### Step 1: 自動パスワード生成スクリプト実行

```bash
# スクリプト実行権限確認
ls -la scripts/generate-secure-passwords.sh

# パスワード生成実行
./scripts/generate-secure-passwords.sh
```

**生成される内容:**
- Supabase データベースパスワード（24文字、英数字混合）
- その他セキュリティキー（32-64文字、Base64エンコード）
- セキュリティ強度自動チェック
- `.env.local` ファイル自動作成

### Step 2: 手動でのパスワード生成（スクリプト未使用時）

```bash
# OpenSSL による強力なパスワード生成
openssl rand -base64 32 | head -c 24

# より複雑なパスワード（記号含む）
openssl rand -base64 32 | tr -d "=+/" | head -c 20

# 数字付きパスワード
echo "$(openssl rand -base64 20 | head -c 16)$(date +%s | tail -c 4)"
```

### Step 3: 環境変数ファイル設定

```bash
# テンプレートから .env.local を作成
cp .env.local.template .env.local

# 生成されたパスワードを設定
echo "SUPABASE_DATABASE_PASSWORD=your_generated_password" >> .env.local

# ファイル権限を所有者のみに制限
chmod 600 .env.local

# 設定確認（パスワードは表示されない）
ls -la .env.local
```

---

## 📁 ファイル構成・役割

### 🔧 作成されるファイル
- **`.env.local.template`** - 環境変数テンプレート（Git管理対象）
- **`.env.local`** - 実際の機密情報（Git管理対象外、.gitignore設定済み）
- **`scripts/generate-secure-passwords.sh`** - パスワード生成スクリプト

### 🛡️ セキュリティ設定
- **ファイル権限**: `.env.local` は `600`（所有者のみ読み書き）
- **Git除外**: `.gitignore` で `.env.local` は除外済み
- **バックアップ**: 既存ファイル上書き時に自動バックアップ作成

---

## 🔑 管理すべき機密情報一覧

### Supabase 関連
```env
SUPABASE_URL=https://[プロジェクトID].supabase.co
SUPABASE_ANON_KEY=eyJhbGci...（公開可能）
SUPABASE_SERVICE_ROLE_KEY=eyJhbGci...（⚠️極秘）
SUPABASE_DATABASE_PASSWORD=生成された強力パスワード（⚠️極秘）
```

### OpenAI 関連（Phase 2A で追加）
```env
OPENAI_API_KEY=sk-...（⚠️極秘）
OPENAI_ORGANIZATION_ID=org-...（必要に応じて）
```

### セキュリティ・制限設定
```env
DAILY_COST_LIMIT=1.00
MONTHLY_COST_LIMIT=30.00
API_RATE_LIMIT=100
```

---

## 🚨 セキュリティベストプラクティス

### ✅ やるべきこと
1. **強力なパスワード使用**
   - 24文字以上、英数字混合
   - 予測不可能なランダム生成
   - 辞書攻撃耐性のある文字列

2. **適切なファイル管理**
   - `.env.local` は絶対にGitHubにコミットしない
   - ファイル権限 `600` で他者からの読み取り防止
   - 定期的なバックアップ作成

3. **複数箇所での保存**
   - パスワードマネージャーでの管理
   - 安全な場所への物理的バックアップ
   - チーム開発時は暗号化された共有方法

### ❌ やってはいけないこと
1. **機密情報の平文保存**
   - コードに直接埋め込み
   - GitHubリポジトリへのコミット
   - 安全でない場所（デスクトップ等）への保存

2. **弱いパスワード使用**
   - 短すぎるパスワード（12文字未満）
   - 辞書にある単語
   - 個人情報由来のパスワード

3. **不適切な共有**
   - メール・チャットでの平文送信
   - 暗号化されていないクラウドストレージ
   - スクリーンショットでの共有

---

## 🔄 定期メンテナンス

### パスワードローテーション（推奨: 3ヶ月毎）

```bash
# 1. 新しいパスワード生成
./scripts/generate-secure-passwords.sh

# 2. Supabase Dashboard でパスワード変更
# Settings → Database → Reset database password

# 3. .env.local ファイル更新
# SUPABASE_DATABASE_PASSWORD を新しい値に変更

# 4. 接続テスト
# docs/setup/supabase-setup-guide.md の Step 2 を実行
```

### APIキーローテーション（推奨: 1ヶ月毎）

```bash
# 1. Supabase Dashboard → Settings → API
# 2. "Reset API keys" → 新しいキー生成
# 3. .env.local ファイルの SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY を更新
# 4. iOS/Web アプリでの接続テスト
```

---

## ⚠️ インシデント対応

### APIキー漏えい時の対応

1. **即座にキー無効化**
   ```bash
   # Supabase Dashboard → Settings → API → Reset API keys
   # OpenAI Dashboard → API Keys → Revoke leaked key
   ```

2. **新しいキー生成・設定**
   ```bash
   ./scripts/generate-secure-passwords.sh
   # 新しいキーを .env.local に設定
   ```

3. **影響範囲調査**
   - Git履歴での漏えい確認
   - 不正使用状況の確認
   - アクセスログの精査

4. **再発防止策**
   - `.gitignore` 設定再確認
   - commit hook 設定検討
   - チーム内セキュリティ教育

---

## 🔍 トラブルシューティング

### よくある問題と解決方法

#### 1. パスワード生成スクリプトが実行できない
```bash
# 実行権限確認
ls -la scripts/generate-secure-passwords.sh

# 権限付与
chmod +x scripts/generate-secure-passwords.sh

# OpenSSL がない場合（macOS Homebrew）
brew install openssl
```

#### 2. .env.local が Git に含まれそうになる
```bash
# .gitignore 確認
cat .gitignore | grep env

# 強制的に Git 追跡から除外
git rm --cached .env.local
git commit -m "Remove .env.local from Git tracking"
```

#### 3. Supabase 接続エラー
```bash
# パスワード再確認
echo $SUPABASE_DATABASE_PASSWORD

# 接続テスト
curl -X GET \
  "$SUPABASE_URL/rest/v1/bookmarks" \
  -H "apikey: $SUPABASE_ANON_KEY"
```

---

## 📝 チェックリスト

### 初回セットアップ
- [ ] パスワード生成スクリプト実行
- [ ] 強力なSupabaseパスワード生成確認
- [ ] `.env.local` ファイル作成・権限設定
- [ ] `.gitignore` でのファイル除外確認
- [ ] パスワードマネージャーでのバックアップ

### 定期メンテナンス
- [ ] 3ヶ月毎: データベースパスワードローテーション
- [ ] 1ヶ月毎: APIキーローテーション  
- [ ] 週1回: 不正アクセス状況確認
- [ ] 月1回: セキュリティ設定見直し

---

**🛡️ セキュリティは継続的な取り組みです**

機密情報の適切な管理により、安全な開発・運用環境を維持しましょう。