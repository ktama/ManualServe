# はじめに

このガイドでは、プロジェクトのセットアップから基本的な操作までを説明します。

## 前提条件

- Python 3.9 以上
- pip（Python パッケージマネージャ）
- Podman（コンテナランタイム）

## インストール

### 1. リポジトリのクローン

```bash
git clone <repository-url>
cd ManualServe
```

### 2. Python 仮想環境の作成

```bash
python3 -m venv .venv
source .venv/bin/activate
```

### 3. 依存パッケージのインストール

```bash
pip install mkdocs-material
```

## 基本操作

### ローカルプレビュー

開発中にリアルタイムでプレビューを確認できます。

```bash
./scripts/dev-serve.sh
# または
mkdocs serve -a 0.0.0.0:8000
```

ブラウザで `http://localhost:8000` にアクセスしてください。

### ビルド

静的サイトをビルドします。

```bash
./scripts/build.sh
# または
mkdocs build --clean
```

成果物は `site/` ディレクトリに出力されます。

## 次のステップ

- [API リファレンス](../api/reference.md) を参照する
- 新しいドキュメントを追加する

!!! tip "ヒント"
    Markdown ファイルを編集すると、`mkdocs serve` が自動的に変更を検知してリロードします。
