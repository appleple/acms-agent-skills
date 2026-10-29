# バージョンの扱い

## 対象とする a-blog cms

- Ver. 3.2 以上を対象にする（Twig テンプレートが使えるようになったバージョン）。
- 各スキルの `compatibility` と `metadata.acms-min-version` に対象を書く。
- 3.2 系の途中で入った機能を案内するときは、本文に「Ver. 3.2.24 以降」のように注記する。バージョン番号はリリースノート（developer.a-blogcms.jp/releasenote.html）で確認してから書く。
- 3.2 より前のサイトでスキルが使われた場合は、`acms-project-triage` がバージョンを判定し、対象外であることを利用者に伝える。

## このリポジトリのバージョン

- a-blog cms 本体とは独立した Semantic Versioning で、`vX.Y.Z` のタグと GitHub Release を作る（`gh skill install --pin` で固定できるようにするため）。
- スキルの削除・改名はメジャー、スキルの追加はマイナー、内容の修正はパッチとする。
- `.claude-plugin/marketplace.json` の各プラグインの `version` もリリースのたびに揃えて上げる（Claude Code は version が変わったときに更新を配る）。

## a-blog cms 本体との連動

本体の公開 API（テンプレート構文、Twig の関数・フィルター、Hook、管理画面の JavaScript の拡張ポイント）が変わったときは、本体のリリース作業の中でこのリポジトリの該当スキルも更新する。
