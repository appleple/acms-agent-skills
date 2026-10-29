# コントリビューション

## Issue

不具合・要望・「このスキルを使ったらエージェントが誤ったコードを書いた」という報告を歓迎します。報告には次を書いてください。

- a-blog cms のバージョン
- 使ったエージェント（Claude Code、Copilot など）とスキル
- 依頼した内容と、エージェントの出力のうち誤っていた部分

顧客名・サイトの URL・ログイン情報・`config.server.php` の内容は書かないでください。

## Pull Request

スキルの正確さを保つため、Pull Request は現在 appleple の社内からのみ受け付けています。外部からいただいた Pull Request は、内容を Issue として引き取ったうえでクローズします。

## 社内メンバー向け

スキルの書き方は [docs/authoring-guide.md](docs/authoring-guide.md)、バージョンの扱いは [docs/compatibility.md](docs/compatibility.md) を参照してください。変更したら次を通してから Pull Request を出します。

```bash
node scripts/validate-skills.mjs
```
