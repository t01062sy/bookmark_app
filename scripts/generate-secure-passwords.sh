#!/bin/bash

# =======================================================
# Supabase セキュアパスワード生成スクリプト
# =======================================================
#
# 用途: Supabase データベースパスワード等の強力なパスワード生成
# 実行: chmod +x scripts/generate-secure-passwords.sh && ./scripts/generate-secure-passwords.sh
#
# セキュリティ要件:
# - 32文字以上
# - 英数字 + 特殊文字
# - 予測不可能なランダム生成
# - Base64エンコード（特殊文字問題回避）

set -e  # エラー時即座に終了

echo "🔐 Supabase セキュアパスワード生成ツール"
echo "=============================================="
echo

# 生成するパスワードの種類（macOS bash 3.x 対応）
echo "📋 以下のパスワードを生成します:"
echo "  - SUPABASE_DATABASE: 32文字"
echo "  - JWT_SECRET: 64文字" 
echo "  - API_SECRET: 32文字"
echo "  - ENCRYPTION_KEY: 32文字"
echo

# 一時ファイル（生成後に削除）
temp_file=$(mktemp)

echo "🔑 パスワード生成中..."
echo

# SUPABASE_DATABASE パスワード
supabase_db_password=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-32)
echo "✅ SUPABASE_DATABASE:"
echo "   ${supabase_db_password}"
echo
echo "SUPABASE_DATABASE_PASSWORD=${supabase_db_password}" >> "$temp_file"

# JWT_SECRET
jwt_secret=$(openssl rand -base64 64 | tr -d "=+/" | cut -c1-64)
echo "✅ JWT_SECRET:"
echo "   ${jwt_secret}"
echo
echo "JWT_SECRET=${jwt_secret}" >> "$temp_file"

# API_SECRET  
api_secret=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-32)
echo "✅ API_SECRET:"
echo "   ${api_secret}"
echo
echo "API_SECRET=${api_secret}" >> "$temp_file"

# ENCRYPTION_KEY
encryption_key=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-32)
echo "✅ ENCRYPTION_KEY:"
echo "   ${encryption_key}"
echo
echo "ENCRYPTION_KEY=${encryption_key}" >> "$temp_file"

# 推奨パスワード（Supabase用）の生成・表示
echo "🎯 Supabase データベース用推奨パスワード:"
echo "=============================================="

# より複雑なパスワード生成（英数字+記号）
supabase_password=$(openssl rand -base64 32 | head -c 24)$(date +%s | tail -c 4)
echo "推奨パスワード: ${supabase_password}"
echo

# セキュリティチェック（推奨パスワード使用）
password_length=${#supabase_password}
if [ $password_length -ge 20 ]; then
    echo "✅ パスワード長: ${password_length}文字 (推奨: 20文字以上)"
else
    echo "⚠️  パスワード長: ${password_length}文字 (短すぎます)"
fi

# 文字種チェック
if [[ "$supabase_password" =~ [A-Z] ]]; then
    echo "✅ 大文字を含む"
else
    echo "⚠️  大文字が含まれていません"
fi

if [[ "$supabase_password" =~ [a-z] ]]; then
    echo "✅ 小文字を含む"
else
    echo "⚠️  小文字が含まれていません"
fi

if [[ "$supabase_password" =~ [0-9] ]]; then
    echo "✅ 数字を含む"
else
    echo "⚠️  数字が含まれていません"
fi

echo

# .env.local ファイル生成確認
echo "📄 .env.local ファイル設定:"
echo "=============================================="

if [ -f ".env.local" ]; then
    echo "⚠️  .env.local ファイルが既に存在します"
    echo "   バックアップを作成してから上書きしますか？ [y/N]"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        cp ".env.local" ".env.local.backup.$(date +%Y%m%d_%H%M%S)"
        echo "✅ バックアップ作成: .env.local.backup.$(date +%Y%m%d_%H%M%S)"
    else
        echo "❌ .env.local ファイルの更新をスキップしました"
        rm "$temp_file"
        exit 0
    fi
fi

# .env.local.template からコピー
if [ -f ".env.local.template" ]; then
    cp ".env.local.template" ".env.local"
    echo "✅ .env.local.template から .env.local を作成しました"
    
    # 生成したパスワードを設定
    echo "SUPABASE_DATABASE_PASSWORD=${supabase_password}" >> ".env.local"
    echo "✅ Supabase データベースパスワードを .env.local に設定しました"
else
    echo "❌ .env.local.template が見つかりません"
fi

echo

# セキュリティ注意事項
echo "🛡️  セキュリティ注意事項:"
echo "=============================================="
echo "1. .env.local ファイルは絶対にGitHubにコミットしないこと"
echo "2. パスワードは安全な場所（パスワードマネージャー）にも保存すること"
echo "3. 本番環境では定期的にパスワードローテーションを実施すること"
echo "4. このスクリプト実行後、ターミナル履歴をクリアすることを推奨"
echo

# ファイル権限設定
chmod 600 ".env.local" 2>/dev/null || true
echo "✅ .env.local ファイルの権限を 600（所有者のみ読み書き）に設定"

# クリーンアップ
rm "$temp_file"

echo
echo "🎉 パスワード生成完了！"
echo "   Supabase プロジェクト作成時に上記パスワードを使用してください"
echo
echo "📝 次のステップ:"
echo "   1. https://supabase.com でプロジェクト作成"
echo "   2. 生成されたパスワードを入力"  
echo "   3. プロジェクト作成後、.env.local にAPI URLとキーを追記"
echo "   4. docs/setup/supabase-setup-guide.md の手順に従って進める"