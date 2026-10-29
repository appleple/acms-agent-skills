# acms-agent-skills メンテナンス用メモ

このリポジトリで作業するエージェント・メンテナー向けの決まりごと。スキルの利用者向けの説明は README.md にある。

## 構成

- `skills/<name>/SKILL.md` がスキル本体。`references/`（詳細）、`scripts/`（決まった処理）、`evals/scenarios.json`（評価シナリオ）を必要に応じて置く。
- `.claude-plugin/marketplace.json` は Claude Code 用。スキル本体は `skills/` に置いたまま、各プラグインの `skills` 配列で参照する（`npx skills` / `gh skill` が `skills/*/SKILL.md` を探すため、ディレクトリを動かさない）。
- MCP サーバーを足すときは、該当プラグインのエントリに `mcpServers` を書く（`plugin.json` を置かない限りエントリがマニフェストになる）。

## 守ること

- frontmatter は Agent Skills 仕様の6項目（`name` / `description` / `license` / `compatibility` / `metadata` / `allowed-tools`）だけを使う。Claude Code 固有の `argument-hint` などは書かない（他のエージェントの検証で弾かれるため）。
- 正は developer.a-blogcms.jp。変数表・スニペット・ドキュメントの文章を写さず、リンクと「どれを選ぶか」の判断表に留める。
- 社内情報（社内のリポジトリ・チケット番号・社内 Wiki・ローカル環境のパスや URL・顧客名）を書かない。`scripts/validate-skills.mjs` が代表的なパターンを検出する。
- 名前は略さない（`dev`・`js` ではなく `development`・`javascript`）。
- 対象は a-blog cms Ver. 3.2 以上。それより新しいバージョンで入った機能には本文で「Ver. 3.2.24 以降」のように注記する（docs/compatibility.md）。
- 新しいスキルには評価シナリオを最低1件置く。

詳しくは docs/authoring-guide.md。
