#!/bin/bash
# publish.sh - ビルドからコンテナ起動まで一括実行
#
# 使い方:
#   ./scripts/publish.sh
#
# 処理内容:
#   1. MkDocs サイトをビルド
#   2. Podman コンテナを起動（既存があれば再起動）

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

echo "=========================================="
echo "MkDocs サイト パブリッシュ"
echo "=========================================="
echo ""

# Step 1: ビルド
echo "[1/2] サイトをビルドします..."
"$SCRIPT_DIR/build.sh"

echo ""

# Step 2: コンテナ起動
echo "[2/2] コンテナを起動します..."
"$PROJECT_ROOT/container/podman-run.sh"

echo ""
echo "=========================================="
echo "パブリッシュ完了！"
echo "=========================================="
