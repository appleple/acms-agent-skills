# バージョンの扱い

## 対象とする a-blog cms

- Ver. 3.2 以上を対象にする（Twig テンプレートが使えるようになったバージョン）。
- 各スキルの `compatibility` と `metadata.acms-min-version` に対象を書く。
- 3.2 系の途中で入った機能を案内するときは、本文に「Ver. 3.2.24 以降」のように注記する。バージョン番号はリリースノート（developer.a-blogcms.jp/releasenote.html）で確認してから書く。
- 3.2 より前のサイトでスキルが使われた場合は、`acms-project-triage` がバージョンを判定し、対象外であることを利用者に伝える。バージョンを上げる作業だけは `acms-upgrade` が扱う（移行元が 3.2 より前でもよい）。

## このリポジトリのバージョン

- a-blog cms 本体とは独立した Semantic Versioning で、`vX.Y.Z` のタグと GitHub Release を作る（`gh skill install --pin` で固定できるようにするため）。
- スキルの削除・改名はメジャー、スキルの追加はマイナー、内容の修正はパッチとする。
- `.claude-plugin/marketplace.json` の各プラグインの `version` もリリースのたびに揃えて上げる（Claude Code は version が変わったときに更新を配る）。

### リリースの手順

1. `CHANGELOG.md` の `## [Unreleased]` を `## [X.Y.Z] - YYYY-MM-DD` に改め、新しい `## [Unreleased]` を上に足す。
2. `.claude-plugin/marketplace.json` の `metadata.version` と各プラグインの `version` を `X.Y.Z` に揃える。
3. main にコミットして push し、`git tag vX.Y.Z && git push origin vX.Y.Z` でタグを push する。
4. `.github/workflows/release.yml` が、検証・タグと marketplace.json の版の一致・CHANGELOG の節の有無を確かめてから、CHANGELOG の節をリリースノートにした GitHub Release を作る。どれかが合わなければ Release は作られないので、直してタグを打ち直す（`git tag -d vX.Y.Z && git push origin :refs/tags/vX.Y.Z`）。

## a-blog cms 本体との連動

本体の公開 API（テンプレート構文、Twig の関数・フィルター、Hook、管理画面の JavaScript の拡張ポイント）が変わったときは、本体のリリース作業の中でこのリポジトリの該当スキルも更新する。

## 新しいバージョンへの移行を足すとき

本体の新しいマイナーバージョン（3.3、3.4 など）が出たら、`acms-upgrade` に次を足す。既存のファイルは書き換えない（古い版からの移行に今も使われるため）。

1. `skills/acms-upgrade/references/_template.md` を複製して `references/to-<版>.md` を作り、固定の見出しに沿って書く。根拠は developer サイトの移行ガイド（`/document/migration/` 配下）と、前の版の最終タグとの本体ソースの差分。
2. `skills/acms-upgrade/scripts/checks/to-<版>.tsv` に、テーマ・プラグイン（拡張アプリ）の文字列から検出できる変更を1行1チェックで足す。公式テーマの旧版で検出でき、新版で誤検出しないことを `scripts/scan.sh` で確かめる。
3. `SKILL.md` の「移行先ごとのファイル」の表に1行足す。
4. `evals/scenarios.json` にその版への移行のシナリオを足す。
