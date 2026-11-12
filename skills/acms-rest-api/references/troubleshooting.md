# REST API がうまく動かないとき（Ver. 3.3 以降）

上から順に確かめる。

| 症状 | 原因と直し方 |
|---|---|
| 404（通常のページの 404） | REST API が無効（`rest_api_enable` が off）か、URL のブログが違う。子ブログは `/<ブログのコード>/rest-api/acms/v1/` |
| 301 になり、POST の本文が消える | 末尾の `/` が無い。付けて送る |
| 403 `https_required` | HTTP で呼んでいる。HTTPS にする |
| 401 | トークンが無い・失効・期限切れ。`Authorization: Bearer` ヘッダーで送っているか（クエリでは受け付けない）。`GET /me/` で確かめる |
| 403 `api_access_not_allowed` | トークンの持ち主の権限が「API・MCP を使える権限」に含まれていない（既定で読者は含まれない）。エンタープライズでロールを使うなら、ロールの「API・MCP の接続」 |
| 403（スコープ不足） | 応答の `detail` に足りないスコープが出る。トークンを作り直すか、`entries:publish` が要る操作ならリビジョンか下書きで保存する |
| 403（IP） | 管理画面で許可した接続元の IP 帯の外 |
| 412 | `If-Match` の ETag が古い。読み直して変更を当て直す。`include` を付けた GET の ETag は `If-Match` に使えない |
| 422 `unknown_field` / `read_only_field` / `validation_failed` | `errors[].pointer` の項目を openapi.json の書き込み側のスキーマと見比べる |
| 422 `idempotency_key_reused` | 同じ `Idempotency-Key` で違う内容を送った。新しいキーにする |
| 409 | 同じ冪等キーの処理中、または編集ロック・承認フローとの衝突 |
| 429 | レート制限。`RateLimit` ヘッダーを見て待つ。認証の失敗が続くと IP ごとに一時的に止まる |
| ブログ・カテゴリー・エントリーのコード `rest-api`・`mcp`・`oauth` のページが 404 | 予約セグメントと衝突している。コードを変えるか、定数で予約語を変えてもらう |
| OAuth のメタデータが 301・403 | `.htaccess` が古い。同梱の `htaccess.txt` の `/.well-known/` の除外を取り込む |
