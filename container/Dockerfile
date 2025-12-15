# Dockerfile for Nginx + MkDocs site (Docker用)
# Containerfile と同一内容（Docker 互換）
#
# 使い方:
#   docker build -t mkdocs-nginx -f container/Dockerfile .
#   docker run -d -p 8080:80 -v ./site:/usr/share/nginx/html:ro mkdocs-nginx

FROM docker.io/library/nginx:alpine

# カスタム nginx.conf をコピー
COPY container/nginx.conf /etc/nginx/nginx.conf

# ヘルスチェック用
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost/ || exit 1

# ポート公開（ドキュメント用）
EXPOSE 80

# デフォルトの entrypoint/cmd は nginx イメージのものを使用
