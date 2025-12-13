# API リファレンス

本セクションでは、各種 API のリファレンスを提供します。

## エンドポイント一覧

| メソッド | パス | 説明 |
|---------|------|------|
| GET | `/api/v1/health` | ヘルスチェック |
| GET | `/api/v1/users` | ユーザー一覧取得 |
| POST | `/api/v1/users` | ユーザー作成 |
| GET | `/api/v1/users/{id}` | ユーザー詳細取得 |

## サンプルリクエスト

### ヘルスチェック

```bash
curl -X GET http://localhost:8080/api/v1/health
```

**レスポンス例:**

```json
{
  "status": "ok",
  "timestamp": "2025-01-01T00:00:00Z"
}
```

### ユーザー一覧取得

```bash
curl -X GET http://localhost:8080/api/v1/users \
  -H "Authorization: Bearer <token>"
```

**レスポンス例:**

```json
{
  "users": [
    {
      "id": 1,
      "name": "田中太郎",
      "email": "tanaka@example.com"
    }
  ],
  "total": 1
}
```

## エラーレスポンス

!!! warning "エラーハンドリング"
    すべてのエラーは以下の形式で返されます。

```json
{
  "error": {
    "code": "NOT_FOUND",
    "message": "リソースが見つかりません"
  }
}
```

### ステータスコード

| コード | 説明 |
|--------|------|
| 200 | 成功 |
| 400 | リクエスト不正 |
| 401 | 認証エラー |
| 403 | 権限エラー |
| 404 | リソース未発見 |
| 500 | サーバーエラー |

## 認証

API へのアクセスには Bearer トークンが必要です。

```bash
curl -X GET http://localhost:8080/api/v1/users \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```
