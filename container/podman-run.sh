#!/bin/bash
# podman-run.sh - MkDocs サイトを Nginx コンテナで配信
#
# 使い方:
#   ./container/podman-run.sh
#
# 前提:
#   - site/ ディレクトリが存在すること（scripts/build.sh を先に実行）
#   - Podman がインストールされていること（rootless 推奨）

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CONTAINER_NAME="mkdocs-nginx"
IMAGE_NAME="mkdocs-nginx"
HOST_PORT="${HOST_PORT:-8080}"

cd "$PROJECT_ROOT"

# site/ ディレクトリの存在確認
if [ ! -d "site" ]; then
    echo "エラー: site/ ディレクトリが存在しません。"
    echo "先に ./scripts/build.sh を実行してください。"
    exit 1
fi

# 既存コンテナの停止・削除
if podman ps -a --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
    echo "既存コンテナを停止・削除します..."
    podman stop "$CONTAINER_NAME" 2>/dev/null || true
    podman rm "$CONTAINER_NAME" 2>/dev/null || true
fi

# イメージのビルド（存在しない場合または強制ビルド）
if [ "${FORCE_BUILD:-false}" = "true" ] || ! podman images --format "{{.Repository}}" | grep -q "^localhost/${IMAGE_NAME}$"; then
    echo "コンテナイメージをビルドします..."
    podman build -t "$IMAGE_NAME" -f container/Containerfile .
fi

# コンテナ起動
# SELinux 環境では :Z オプションでラベル付けを行う
# rootless Podman で権限問題を避けるため :ro (読み取り専用) を推奨
echo "コンテナを起動します (port: $HOST_PORT)..."
podman run -d \
    --name "$CONTAINER_NAME" \
    -p "${HOST_PORT}:80" \
    -v "${PROJECT_ROOT}/site:/usr/share/nginx/html:ro,Z" \
    --restart=always \
    "$IMAGE_NAME"

echo ""
echo "=========================================="
echo "MkDocs サイトが起動しました！"
echo "URL: http://localhost:${HOST_PORT}"
echo "=========================================="
echo ""
echo "確認コマンド:"
echo "  curl -I http://localhost:${HOST_PORT}"
echo ""
echo "ログ確認:"
echo "  podman logs -f ${CONTAINER_NAME}"
echo ""
echo "停止:"
echo "  podman stop ${CONTAINER_NAME}"
echo ""

# -----------------------------------------------------
# systemd ユニット生成（自動起動したい場合）
# -----------------------------------------------------
# Podman で systemd ユニットファイルを生成し、ユーザーサービスとして登録できます。
#
# 1. ユニットファイル生成:
#    podman generate systemd --new --name mkdocs-nginx > ~/.config/systemd/user/mkdocs-nginx.service
#
# 2. サービス有効化:
#    systemctl --user daemon-reload
#    systemctl --user enable mkdocs-nginx.service
#    systemctl --user start mkdocs-nginx.service
#
# 3. ログイン時に自動起動（linger 有効化）:
#    loginctl enable-linger $USER
#
# 注意: --restart=always オプションは Podman 単体では限定的です。
#       本番運用では上記の systemd 連携を推奨します。
# -----------------------------------------------------
