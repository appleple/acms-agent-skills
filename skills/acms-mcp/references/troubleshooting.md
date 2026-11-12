# MCP でつながらないとき（Ver. 3.3 以降）

上から順に確かめる。REST API と共通の原因（HTTPS、権限、IP、`.htaccess`）は acms-rest-api の references/troubleshooting.md も読む。

| 症状 | 原因と直し方 |
|---|---|
| 404 | MCP が無効（`mcp_enable` が off）、URL が `/rest-api/mcp/` になっている、子ブログのコードが違う |
| 301 | 末尾の `/` が無い |
| 405 | GET・DELETE で呼んでいる。MCP は POST だけ |
| 401 | トークンの失効・期限切れ。OAuth なら接続をやり直す（リフレッシュトークンを再利用すると接続ごと失効する） |
| 403 `api_access_not_allowed` | ユーザーの権限が「API・MCP を使える権限」に入っていない |
| 403（ツールを名前で呼んだ） | `mcp_access_level` の上限を超えている。`acms_site_overview` の `mcp` で上限を確かめ、利用者に設定の変更を頼む |
| 書き込みのツールが一覧に無い | `mcp_access_level` が `read`、またはトークンに書き込みのスコープが無い |
| OAuth の画面に進まない | OAuth が無効、`.htaccess` が `/.well-known/` を隠している、サイトがパスのある場所にある（API トークンを使う） |
| claude.ai から登録できない | OAuth の DCR・CIMD の受け入れが無効か、許可するホストに入っていない |
| 自己署名の証明書の検証環境でつながらない | Node.js 製のクライアントなら `NODE_EXTRA_CA_CERTS` に CA 証明書を渡す |
| 一覧の取得が遅い・大きい | `mcp_tool_mode` が `full`。`compact` に戻す |
