# ManualServe

Markdown マニュアルを MkDocs Material で静的サイト化し、Podman + Nginx で配信するためのリポジトリ雛形です。

## 目的

- 社内マニュアル・技術ドキュメントを一元管理
- オンプレミス環境で完結（外部 SaaS 不要）
- 開発時のリアルタイムプレビュー
- コンテナによる簡単なデプロイ

## 前提条件

| 項目 | 要件 |
|------|------|
| OS | Linux（WSL2 / AlmaLinux / Ubuntu 等） |
| Python | 3.9 以上 |
| pip | Python パッケージマネージャ |
| Podman | rootless モード推奨 |

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
├── container/                     # Podman / Nginx 関連
│   ├── Containerfile
│   ├── nginx.conf
│   └── podman-run.sh
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

## 本番配信（Podman）

### 一括デプロイ

ビルドからコンテナ起動まで一括で実行できます。

```bash
./scripts/publish.sh
```

### 個別コマンド

```bash
# ビルド
./scripts/build.sh

# コンテナ起動
./container/podman-run.sh
```

サイトは http://localhost:8080 で公開されます。

### ポート変更

環境変数でポートを変更できます。

```bash
HOST_PORT=3000 ./container/podman-run.sh
```

### ヘルスチェック

```bash
# HTTP ステータス確認
curl -I http://localhost:8080

# コンテンツ取得確認
curl http://localhost:8080

# コンテナ状態確認
podman ps
podman logs mkdocs-nginx
```

### コンテナ操作

```bash
# 停止
podman stop mkdocs-nginx

# 再起動
podman restart mkdocs-nginx

# 削除
podman rm -f mkdocs-nginx

# ログ確認
podman logs -f mkdocs-nginx
```

## systemd によるサービス化（自動起動）

Podman で systemd ユニットを生成し、OS 起動時に自動起動させることができます。

### 1. ユニットファイル生成

```bash
mkdir -p ~/.config/systemd/user
podman generate systemd --new --name mkdocs-nginx > ~/.config/systemd/user/mkdocs-nginx.service
```

### 2. サービス有効化

```bash
systemctl --user daemon-reload
systemctl --user enable mkdocs-nginx.service
systemctl --user start mkdocs-nginx.service
```

### 3. ログアウト後も継続（linger 有効化）

```bash
loginctl enable-linger $USER
```

### 4. サービス確認

```bash
systemctl --user status mkdocs-nginx.service
```

## SELinux 環境での注意

SELinux が有効な環境（RHEL/AlmaLinux 等）では、ボリュームマウント時に `:Z` オプションが必要です。
`podman-run.sh` ではすでに設定済みです。

```bash
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
HOST_PORT=9090 ./container/podman-run.sh
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

- **CI/CD 連携**
  - Git push 時に自動ビルド・デプロイ
  - GitHub Actions / GitLab CI テンプレート追加

- **多言語対応**
  - MkDocs の i18n プラグイン導入
  - 言語切り替え機能

- **アクセス解析**
  - Matomo（オンプレ）連携
  - nginx アクセスログの可視化

## ライセンス

社内利用向けのテンプレートです。
