#!/bin/bash
# dev-serve.sh - 開発用ローカルプレビューサーバー
#
# 使い方:
#   ./scripts/dev-serve.sh
#
# ファイル変更時に自動リロードされます。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

# 仮想環境のアクティベート確認
if [ -z "${VIRTUAL_ENV:-}" ]; then
    if [ -d ".venv" ]; then
        echo "仮想環境をアクティベートします..."
        source .venv/bin/activate
    else
        echo "警告: 仮想環境が見つかりません。グローバルの mkdocs を使用します。"
    fi
fi

# mkdocs の存在確認
if ! command -v mkdocs &> /dev/null; then
    echo "エラー: mkdocs がインストールされていません。"
    echo "pip install mkdocs-material を実行してください。"
    exit 1
fi

echo "開発サーバーを起動します..."
echo "URL: http://localhost:8000"
echo "終了するには Ctrl+C を押してください。"
echo ""

# 0.0.0.0 でバインドして外部からもアクセス可能に
mkdocs serve -a 0.0.0.0:8000
