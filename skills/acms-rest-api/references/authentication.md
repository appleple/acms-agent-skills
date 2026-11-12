# REST API の認証とスコープ（Ver. 3.3 以降）

Ver. 3.3.0-alpha.1 のソースで確かめた内容。

## API トークン（アプリパスワード）

- 発行: ユーザー編集画面の「API トークン」。管理者は「API トークン管理」で全ユーザーのトークンを一覧・失効できる。
- 値は `acms_` で始まる。平文は発行時に 1 回だけ表示され、DB にはハッシュだけが残る。なくしたら再発行する。
- 有効期限の既定は 90 日、上限は 365 日、1 ユーザーあたり 20 本まで（システム設定 `rest_api_token_default_expire_days`・`rest_api_token_max_expire_days`・`rest_api_token_max_per_user`）。
- 発行と OAuth の接続のたびに、本人へ通知メールが送られる。差出人の既定が `info@example.com` なので、メール設定で差出人を設定してもらう。
- トークンが持てる権限は、発行したユーザーの権限を超えない。実際に許されるかは「スコープ」と「管理画面と同じ権限」の両方を満たすかで決まる。連携用には、必要な権限だけを持つ専用のユーザーを作ってトークンを発行するのがよい。
- ログインできる端末の制限は、発行済みのトークンには効かない。
- バックアップを復元すると、トークンと OAuth の接続はすべて失効する。

## スコープ

| スコープ | 意味 |
|---|---|
| `read` / `write` | 汎用。`write` は `read` を含む。専用スコープのリソースには効かない |
| `<リソース>:read` / `<リソース>:write` | entries・media・categories・blogs・modules・tags・rules・config-sets・cache・fulltext など。汎用の `read`・`write` でも満たされる |
| 専用（読み書きとも）| users・aliases・forms・usergroups・roles・webhooks・redirects。個人情報や影響の大きいリソースで、汎用の `read`・`write` では満たされない |
| 専用（書き込みだけ） | configs・field-definitions の `:write`、approvals・backups・imports・exports・static-exports・plugins の `:write` |
| `audit-logs:read` | 監査ログの読み取り（専用） |
| `entries:publish` | 公開・非公開、公開中のエントリーの更新・削除、最終承認（専用） |

- 実際の一覧は openapi.json の securitySchemes と、発行画面で確かめる（プラグインのスコープが足されることがある）。
- 決め方: 連携が何をするかを先に列挙し、リソースごとのスコープだけを付ける。`entries:publish` は、公開まで自動で行うと利用者が決めたときだけ付ける。

## OAuth 2.1

- 管理画面の「REST API 設定」の OAuth の欄で有効にする（`oauth_enable`、既定は off）。
- 認可コード + PKCE（S256 が必須）とリフレッシュトークンだけ。クライアントは管理画面「OAuth クライアント」で事前に登録するか、動的クライアント登録（DCR）か Client ID Metadata Document（CIMD）で自動登録される（既定で受け入れる。許可するホストを絞れる）。
- 同意画面は毎回出る。専用スコープは既定では付与されない。
- アクセストークンは 1 時間、リフレッシュトークンは 30 日。リフレッシュトークンは使うたびに替わり、古いものを再利用すると接続ごと失効する（盗まれた兆候として扱われる）。
- アクセストークンは宛先（REST か MCP か）に結び付く。MCP 用に発行したトークンは REST に使えない。
- 接続を切る: 本人はユーザー編集の「接続済みアプリ」、管理者は「OAuth の接続」。
- 認可サーバーのメタデータは `/.well-known/oauth-authorization-server`。既存サイトの `.htaccess` が `/.well-known/` を隠していると 301 や 403 になる（同梱の `htaccess.txt` との差を取り込む）。

## 管理画面の JavaScript から呼ぶ

ログイン中の管理画面からは、セッション（Cookie と `X-Csrf-Token`、同じサイトからの送信）で呼ぶ。ベース URL は `ACMS.Config.restApiBaseUrl`。`rest_api_enable` が off でも通る。外部からの連携には使わない。
