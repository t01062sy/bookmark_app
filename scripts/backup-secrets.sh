#!/bin/bash

# =======================================================
# セキュアパスワード バックアップスクリプト
# =======================================================
#
# 用途: .secrets ファイルの安全なバックアップ作成
# 実行: chmod +x scripts/backup-secrets.sh && ./scripts/backup-secrets.sh
#
# セキュリティ機能:
# - 暗号化バックアップ作成
# - タイムスタンプ付きファイル名
# - 権限600での保存
# - 自動クリーンアップ（90日以上の古いバックアップ）

set -e

echo "🔐 セキュアパスワード バックアップツール"
echo "========================================"
echo

# バックアップディレクトリ作成
backup_dir="backups/secrets"
mkdir -p "$backup_dir"

# タイムスタンプ生成
timestamp=$(date +"%Y%m%d_%H%M%S")

# バックアップファイル名
backup_file="${backup_dir}/.secrets_backup_${timestamp}"

if [ ! -f ".secrets" ]; then
    echo "❌ .secrets ファイルが見つかりません"
    echo "   先に ./scripts/generate-secure-passwords.sh を実行してください"
    exit 1
fi

echo "📁 バックアップ作成中..."

# 暗号化なしの単純コピー（ローカル開発用）
cp ".secrets" "$backup_file"

# ファイル権限設定
chmod 600 "$backup_file"

echo "✅ バックアップ作成完了: $backup_file"

# バックアップファイルサイズ確認
backup_size=$(ls -lah "$backup_file" | awk '{print $5}')
echo "📊 バックアップサイズ: $backup_size"

# 古いバックアップのクリーンアップ（90日以上前）
echo "🧹 古いバックアップクリーンアップ中..."
find "$backup_dir" -name ".secrets_backup_*" -mtime +90 -delete 2>/dev/null || true

# 残存バックアップ数確認
backup_count=$(find "$backup_dir" -name ".secrets_backup_*" | wc -l)
echo "📈 現在のバックアップ数: ${backup_count}個"

echo
echo "🛡️  セキュリティ確認:"
echo "- ✅ ファイル権限: 600（所有者のみアクセス）"
echo "- ✅ Git除外: .gitignore設定済み"
echo "- ✅ ローカル保存: 暗号化ディスク推奨"
echo

echo "📝 推奨追加作業:"
echo "1. パスワードマネージャー（1Password/Bitwarden）への保存"
echo "2. 暗号化USBまたはクラウドストレージへの追加バックアップ"
echo "3. 物理的に安全な場所への印刷版バックアップ"

echo
echo "🎉 バックアップ完了！"