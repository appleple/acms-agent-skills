# バージョンの扱い

## 対象とする a-blog cms

- Ver. 3.2 以上を対象にする（Twig テンプレートが使えるようになったバージョン）。
- 各スキルの `compatibility` と `metadata.acms-min-version` に対象を書く。
- 3.2 系の途中で入った機能を案内するときは、本文に「Ver. 3.2.24 以降」のように注記する。バージョン番号はリリースノート（developer.a-blogcms.jp/releasenote.html）で確認してから書く。
- 3.2 より前のサイトでスキルが使われた場合は、`acms-project-triage` がバージョンを判定し、対象外であることを利用者に伝える。バージョンを上げる作業だけは `acms-upgrade`・`acms-upgrade-theme`・`acms-upgrade-plugin` が扱う（移行元が 3.2 より前でもよい）。

## このリポジトリのバージョン

- a-blog cms 本体とは独立した Semantic Versioning で、`vX.Y.Z` のタグと GitHub Release を作る（`gh skill install --pin` で固定できるようにするため）。
- スキルの削除・改名はメジャー、スキルの追加はマイナー、内容の修正はパッチとする。
- `.claude-plugin/marketplace.json` の各プラグインの `version` もリリースのたびに揃えて上げる（Claude Code は version が変わったときに更新を配る）。

### リリースの手順

1. `CHANGELOG.md` の `## [Unreleased]` を `## [X.Y.Z] - YYYY-MM-DD` に改め、新しい `## [Unreleased]` を上に足す。
2. `.claude-plugin/marketplace.json` の `metadata.version` と各プラグインの `version` を `X.Y.Z` に揃える。
3. main にコミットして push し、`git tag vX.Y.Z && git push origin vX.Y.Z` でタグを push する。
4. `.github/workflows/release.yml` が、検証・タグと marketplace.json のバージョンの一致・CHANGELOG の節の有無を確かめてから、CHANGELOG の節をリリースノートにした GitHub Release を作る。どれかが合わなければ Release は作られないので、直してタグを打ち直す（`git tag -d vX.Y.Z && git push origin :refs/tags/vX.Y.Z`）。

## a-blog cms 本体との連動

本体の公開 API（テンプレート構文、Twig の関数・フィルター、Hook、管理画面の JavaScript の拡張ポイント）が変わったときは、本体のリリース作業の中でこのリポジトリの該当スキルも更新する。

## 新しいバージョンへの移行を足すとき

バージョンアップは 3 つのスキルで分担する。`acms-upgrade` はバージョンに依存しない共通の手順・移行先ごとの共通の要件・洗い出しのスクリプト（`scripts/scan.sh` とチェック定義）、`acms-upgrade-theme` はテーマの修正、`acms-upgrade-plugin` はプラグイン（拡張アプリ）と `extension/acms/` の修正を持つ。3 スキルの `references/to-<バージョン>.md` は同じ見出し（前提・下位互換性のない変更・非推奨になった機能と代替・直す手順・移行後の確認・参考）でそろえる。

本体の新しいマイナーバージョン（3.3、3.4 など）が出たら、次を足す。既存のファイルは書き換えない（古いバージョンからの移行に今も使われるため）。

1. 3 スキルそれぞれの `references/_template.md` を複製して `references/to-<バージョン>.md` を作り、固定の見出しに沿って書く。テーマにもプラグインにも当てはまるもの（要件・DB の更新・両方に出る変更）は `acms-upgrade`、テーマだけのものは `acms-upgrade-theme`、プラグインだけのものは `acms-upgrade-plugin` に書く。根拠は developer サイトの移行ガイド（`/document/migration/` 配下）と、前のバージョンの最終タグとの本体ソースの差分。
2. `skills/acms-upgrade/scripts/checks/to-<バージョン>.tsv` に、テーマ・プラグイン（拡張アプリ）の文字列から検出できる変更を1行1チェックで足す。ID はテーマを `T-`、プラグインを `P-` で始め、section 列には直し方を書いた場所を `acms-upgrade-theme: to-<バージョン>.md#<見出し>` の形で書く。公式テーマの旧バージョンで検出でき、新バージョンで誤検出しないことを `scripts/scan.sh` で確かめる。`acms-upgrade-theme`・`acms-upgrade-plugin` の「見つけ方」には、チェック ID と、`acms-upgrade` がない環境のための grep の文字列の両方を書く。
3. 3 スキルの `SKILL.md` の「移行先ごとのファイル」の表に1行ずつ足す。
4. 3 スキルそれぞれの `evals/scenarios.json` に、そのバージョンへの移行のシナリオを足す。
