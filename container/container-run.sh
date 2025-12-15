#!/bin/bash
# container-run.sh - MkDocs サイトを Nginx コンテナで配信
#
# Podman（RHEL/AlmaLinux）と Docker（Ubuntu）の両方に対応
#
# 使い方:
#   ./container/container-run.sh
#
# 環境変数:
#   HOST_PORT     - ホスト側ポート（デフォルト: 8080）
#   FORCE_BUILD   - イメージの強制リビルド（true で有効）
#   CONTAINER_CMD - 使用するコンテナランタイム（auto/podman/docker）
#
# 前提:
#   - site/ ディレクトリが存在すること（scripts/build.sh を先に実行）
#   - Podman または Docker がインストールされていること

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CONTAINER_NAME="mkdocs-nginx"
IMAGE_NAME="mkdocs-nginx"
HOST_PORT="${HOST_PORT:-8080}"

cd "$PROJECT_ROOT"

# ==============================================================================
# コンテナランタイムの検出
# ==============================================================================
detect_container_runtime() {
    local cmd="${CONTAINER_CMD:-auto}"
    
    if [ "$cmd" != "auto" ]; then
        # 明示的に指定された場合
        if command -v "$cmd" &>/dev/null; then
            echo "$cmd"
            return 0
        else
            echo "エラー: 指定されたコンテナランタイム '$cmd' が見つかりません。" >&2
            exit 1
        fi
    fi
    
    # 自動検出: Podman を優先（RHEL/AlmaLinux での標準）
    if command -v podman &>/dev/null; then
        echo "podman"
    elif command -v docker &>/dev/null; then
        echo "docker"
    else
        echo "エラー: podman または docker がインストールされていません。" >&2
        exit 1
    fi
}

RUNTIME=$(detect_container_runtime)
echo "コンテナランタイム: $RUNTIME"

# ==============================================================================
# SELinux 対応（Podman + RHEL/AlmaLinux 環境向け）
# ==============================================================================
get_volume_options() {
    local options="ro"
    
    # Podman かつ SELinux が有効な場合は :Z オプションを追加
    if [ "$RUNTIME" = "podman" ]; then
        if command -v getenforce &>/dev/null && [ "$(getenforce 2>/dev/null)" != "Disabled" ]; then
            options="ro,Z"
        fi
    fi
    
    echo "$options"
}

VOLUME_OPTS=$(get_volume_options)

# ==============================================================================
# Dockerfile/Containerfile の選択
# ==============================================================================
get_containerfile() {
    if [ "$RUNTIME" = "docker" ] && [ -f "container/Dockerfile" ]; then
        echo "container/Dockerfile"
    else
        echo "container/Containerfile"
    fi
}

CONTAINERFILE=$(get_containerfile)

# ==============================================================================
# メイン処理
# ==============================================================================

# site/ ディレクトリの存在確認
if [ ! -d "site" ]; then
    echo "エラー: site/ ディレクトリが存在しません。"
    echo "先に ./scripts/build.sh を実行してください。"
    exit 1
fi

# 既存コンテナの停止・削除
if $RUNTIME ps -a --format "{{.Names}}" 2>/dev/null | grep -q "^${CONTAINER_NAME}$"; then
    echo "既存コンテナを停止・削除します..."
    $RUNTIME stop "$CONTAINER_NAME" 2>/dev/null || true
    $RUNTIME rm "$CONTAINER_NAME" 2>/dev/null || true
fi

# イメージ存在確認用の関数
image_exists() {
    if [ "$RUNTIME" = "podman" ]; then
        $RUNTIME images --format "{{.Repository}}" | grep -q "^localhost/${IMAGE_NAME}$"
    else
        $RUNTIME images --format "{{.Repository}}" | grep -q "^${IMAGE_NAME}$"
    fi
}

# イメージのビルド（存在しない場合または強制ビルド）
if [ "${FORCE_BUILD:-false}" = "true" ] || ! image_exists; then
    echo "コンテナイメージをビルドします..."
    $RUNTIME build -t "$IMAGE_NAME" -f "$CONTAINERFILE" .
fi

# コンテナ起動
echo "コンテナを起動します (port: $HOST_PORT)..."
$RUNTIME run -d \
    --name "$CONTAINER_NAME" \
    -p "${HOST_PORT}:80" \
    -v "${PROJECT_ROOT}/site:/usr/share/nginx/html:${VOLUME_OPTS}" \
    --restart=always \
    "$IMAGE_NAME"

echo ""
echo "=========================================="
echo "コンテナ起動完了！"
echo "=========================================="
echo "URL: http://localhost:${HOST_PORT}"
echo "コンテナ名: $CONTAINER_NAME"
echo "ランタイム: $RUNTIME"
echo ""
echo "操作コマンド:"
echo "  停止:   $RUNTIME stop $CONTAINER_NAME"
echo "  再起動: $RUNTIME restart $CONTAINER_NAME"
echo "  削除:   $RUNTIME rm -f $CONTAINER_NAME"
echo "  ログ:   $RUNTIME logs -f $CONTAINER_NAME"
echo "=========================================="
