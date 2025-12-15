# ManualServe

[![CI - Container Build & Test](https://github.com/<OWNER>/<REPO>/actions/workflows/ci.yml/badge.svg)](https://github.com/<OWNER>/<REPO>/actions/workflows/ci.yml)

Markdown マニュアルを MkDocs Material で静的サイト化し、コンテナ（Podman / Docker）+ Nginx で配信するためのリポジトリ雛形です。

> **Note**: 上記バッジの `<OWNER>/<REPO>` は実際のリポジトリ名に置き換えてください。

## 目的

- 社内マニュアル・技術ドキュメントを一元管理
- オンプレミス環境で完結（外部 SaaS 不要）
- 開発時のリアルタイムプレビュー
- コンテナによる簡単なデプロイ

## 前提条件

| 項目     | 要件                                            |
| -------- | ----------------------------------------------- |
| OS       | Linux（WSL2 / AlmaLinux / Ubuntu 等）           |
| Python   | 3.9 以上                                        |
| pip      | Python パッケージマネージャ                     |
| コンテナ | Podman（RHEL/AlmaLinux）または Docker（Ubuntu） |

## ディレクトリ構成

```
ManualServe/
├── docs/                          # Markdown ドキュメント
│   ├── index.md                   # トップページ
│   ├── guides/                    # ガイド類
│   │   └── getting-started.md
│   ├── api/                       # API ドキュメント
│   │   └── reference.md
│   └── assets/
│       └── stylesheets/
│           └── extra.css          # カスタム CSS
├── site/                          # ビルド成果物（Git 管理外）
├── container/                     # コンテナ / Nginx 関連
│   ├── Containerfile              # Podman 用
│   ├── Dockerfile                 # Docker 用
│   ├── nginx.conf
│   ├── container-run.sh           # Podman/Docker 自動選択
│   └── podman-run.sh              # Podman 専用（互換性維持）
├── scripts/                       # 補助スクリプト
│   ├── dev-serve.sh
│   ├── build.sh
│   └── publish.sh
├── mkdocs.yml                     # MkDocs 設定
├── README.md
└── .gitignore
```

## セットアップ

### 1. リポジトリのクローン

```bash
git clone <repository-url>
cd ManualServe
```

### 2. Python 仮想環境の作成（推奨）

```bash
python3 -m venv .venv
source .venv/bin/activate
```

### 3. 依存パッケージのインストール

```bash
pip install mkdocs-material
```

### 4. スクリプトに実行権限を付与

```bash
chmod +x scripts/*.sh container/*.sh
```

## 開発プレビュー

開発時はローカルサーバーでリアルタイムプレビューができます。

```bash
./scripts/dev-serve.sh
```

ブラウザで http://localhost:8000 にアクセスしてください。  
Markdown ファイルを編集すると自動的にリロードされます。

## 本番ビルド

静的サイトをビルドします。

```bash
./scripts/build.sh
```

成果物は `site/` ディレクトリに出力されます。

## 本番配信（コンテナ）

RHEL/AlmaLinux では Podman、Ubuntu では Docker が自動的に選択されます。

### 一括デプロイ

ビルドからコンテナ起動まで一括で実行できます。

```bash
./scripts/publish.sh
```

### 個別コマンド

```bash
# ビルド
./scripts/build.sh

# コンテナ起動（Podman/Docker 自動選択）
./container/container-run.sh
```

サイトは http://localhost:8080 で公開されます。

### コンテナランタイムの明示的指定

環境変数でランタイムを指定できます。

```bash
# Docker を強制使用
CONTAINER_CMD=docker ./container/container-run.sh

# Podman を強制使用
CONTAINER_CMD=podman ./container/container-run.sh
```

### ポート変更

環境変数でポートを変更できます。

```bash
HOST_PORT=3000 ./container/container-run.sh
```

### ヘルスチェック

```bash
# HTTP ステータス確認
curl -I http://localhost:8080

# コンテンツ取得確認
curl http://localhost:8080

# コンテナ状態確認（Podman の場合）
podman ps
podman logs mkdocs-nginx

# コンテナ状態確認（Docker の場合）
docker ps
docker logs mkdocs-nginx
```

### コンテナ操作

```bash
# Podman の場合
podman stop mkdocs-nginx
podman restart mkdocs-nginx
podman rm -f mkdocs-nginx
podman logs -f mkdocs-nginx

# Docker の場合
docker stop mkdocs-nginx
docker restart mkdocs-nginx
docker rm -f mkdocs-nginx
docker logs -f mkdocs-nginx
```

## サービス化（自動起動）

### Podman + systemd（RHEL/AlmaLinux）

Podman で systemd ユニットを生成し、OS 起動時に自動起動させることができます。

#### 1. ユニットファイル生成

```bash
mkdir -p ~/.config/systemd/user
podman generate systemd --new --name mkdocs-nginx > ~/.config/systemd/user/mkdocs-nginx.service
```

#### 2. サービス有効化

```bash
systemctl --user daemon-reload
systemctl --user enable mkdocs-nginx.service
systemctl --user start mkdocs-nginx.service
```

#### 3. ログアウト後も継続（linger 有効化）

```bash
loginctl enable-linger $USER
```

#### 4. サービス確認

```bash
systemctl --user status mkdocs-nginx.service
```

### Docker + systemd（Ubuntu）

Docker コンテナを systemd で管理することもできます。

#### 1. ユニットファイル作成

```bash
sudo tee /etc/systemd/system/mkdocs-nginx.service << 'EOF'
[Unit]
Description=MkDocs Nginx Container
After=docker.service
Requires=docker.service

[Service]
Type=simple
Restart=always
ExecStartPre=-/usr/bin/docker rm -f mkdocs-nginx
ExecStart=/usr/bin/docker run --rm --name mkdocs-nginx -p 8080:80 -v /path/to/ManualServe/site:/usr/share/nginx/html:ro mkdocs-nginx
ExecStop=/usr/bin/docker stop mkdocs-nginx

[Install]
WantedBy=multi-user.target
EOF
```

※ `/path/to/ManualServe` は実際のパスに置き換えてください。

#### 2. サービス有効化

```bash
sudo systemctl daemon-reload
sudo systemctl enable mkdocs-nginx.service
sudo systemctl start mkdocs-nginx.service
```

#### 3. サービス確認

```bash
sudo systemctl status mkdocs-nginx.service
```

## SELinux 環境での注意（Podman）

SELinux が有効な環境（RHEL/AlmaLinux 等）では、ボリュームマウント時に `:Z` オプションが必要です。
`container-run.sh` では SELinux の有効/無効を自動検出し、適切なオプションを設定します。

```bash
# SELinux 有効時は自動的に :Z オプションが付与される
-v ./site:/usr/share/nginx/html:ro,Z
```

## トラブルシューティング

### Permission denied エラー

rootless Podman でボリュームマウント時に発生する場合：

```bash
# SELinux ラベルを確認
ls -laZ site/

# 手動でラベル付け
chcon -Rt svirt_sandbox_file_t site/
```

### ポートが使用中

```bash
# 使用中のポートを確認
ss -tlnp | grep 8080

# 別ポートで起動
HOST_PORT=9090 ./container/container-run.sh
```

## 改善案（今後の拡張）

- **Basic 認証の追加**
  - nginx.conf に `auth_basic` 設定を追加
  - htpasswd ファイルをコンテナにマウント

- **リバースプロキシ配下でのパス対応**
  - `mkdocs.yml` の `site_url` を適切に設定
  - nginx.conf で `location /docs/` などサブパス対応

- **検索インデックス最適化**
  - `plugins.search.lang` で日本語トークナイザー調整
  - 大規模サイト向けに `search_index_only: true`

- **HTTPS 対応**
  - Let's Encrypt 証明書の自動取得
  - nginx.conf に SSL 設定追加

- **CI/CD 連携** ✅ 実装済み
  - GitHub Actions で AlmaLinux + Podman / Ubuntu + Docker の両環境でテスト
  - `.github/workflows/ci.yml` を参照

- **多言語対応**
  - MkDocs の i18n プラグイン導入
  - 言語切り替え機能

- **アクセス解析**
  - Matomo（オンプレ）連携
  - nginx アクセスログの可視化

## ライセンス

社内利用向けのテンプレートです。
