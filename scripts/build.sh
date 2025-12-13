#!/bin/bash
# build.sh - MkDocs サイトビルド
#
# 使い方:
#   ./scripts/build.sh
#
# site/ ディレクトリに静的サイトが生成されます。

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

echo "MkDocs サイトをビルドします..."
mkdocs build --clean

echo ""
echo "ビルド完了！"
echo "成果物: ${PROJECT_ROOT}/site/"
echo ""
echo "ローカルで確認する場合:"
echo "  python -m http.server 8000 --directory site/"
