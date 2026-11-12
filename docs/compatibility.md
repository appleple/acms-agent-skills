# バージョンの扱い

## 対象とする a-blog cms

- Ver. 3.2 以上を対象にする（Twig テンプレートが使えるようになったバージョン）。
- 各スキルの `compatibility` と `metadata.acms-min-version` に対象を書く。
- 3.2 系の途中で入った機能を案内するときは、本文に「Ver. 3.2.24 以降」のように注記する。バージョン番号はリリースノート（developer.a-blogcms.jp/releasenote.html）で確認してから書く。
- 3.2 より前のサイトでスキルが使われた場合は、`acms-project-triage` がバージョンを判定し、対象外であることを利用者に伝える。バージョンを上げる作業だけは `acms-upgrade`・`acms-upgrade-theme`・`acms-upgrade-plugin` が扱う（移行元が 3.2 より前でもよい）。
- 3.3 など新しいマイナーバージョンの機能は、次の節の置き方に従う。

## 新しいマイナーバージョンの機能を足すとき

3.3 以降の機能は、3.2 のサイトの制作でエージェントが誤って使わないように、置き場所を分ける。Agent Skills の仕様には製品のバージョンで読み込みを切り替える仕組みがなく（`compatibility` と `metadata` は説明のための自由記述）、切り替えられるのは「スキルを読み込むか」（description で決まる）と「references を開くか」（SKILL.md の案内で決まる）の 2 つだけのため。以下は 3.3 を例に書く。

| 足す内容 | 置き場所 |
|---|---|
| そのバージョンにしかない新しい領域（3.3 の REST API・MCP・OAuth など） | 新しいスキル |
| 既存のスキルの領域の追加・変更（カスタムフィールド定義の GUI、エントリーコードの付け方、プラグインの Hook の追加など） | 既存のスキルの `references/ver-3.3.md` |
| 前のバージョンからの移行（下位互換性のない変更・非推奨） | `acms-upgrade` などの `references/to-3.3.md`（下の「新しいバージョンへの移行を足すとき」） |

### 新しいスキルにするとき

- frontmatter は `compatibility: a-blog cms Ver. 3.3 以上`、`metadata.acms-min-version: "3.3"` にする。
- description の先頭に「a-blog cms Ver. 3.3 以降の」、最後に「Ver. 3.2 のサイトでは使わない」と書く。description はスキルを読み込むかどうかを決める唯一の材料で、3.2 のサイトの依頼で読み込まれないようにするため。
- 本文の最初の手順を「`acms-project-triage` でバージョンを確かめ、3.3 未満なら作業せず、バージョンアップが要ることを伝える」にする。
- `acms-router` の振り分けの表に行を足し、3.3 未満なら案内しないことを書く。

### 既存のスキルに足すとき

- 3.3 の内容は `references/ver-3.3.md` にまとめ、SKILL.md には「a-blog cms が Ver. 3.3 以上なら references/ver-3.3.md も読む」という案内を 1 行だけ足す。3.2 のサイトではこのファイルが開かれないため、3.2 の制作に影響しない。
- SKILL.md と既存の references の本文は 3.2 の内容のまま変えない。3.3 で挙動が変わったものは、`ver-3.3.md` に「3.3 では〜に変わった」と書く。
- 3.2.x の途中で入った機能のように本文へ「Ver. 3.3 以降」の注記を散らさない。新しいマイナーバージョンでは変更の量が多く、本文が新しいバージョン寄りになって 3.2 の制作で誤って使われやすくなるため。
- 既存のスキルの `compatibility` と `acms-min-version` は変えない（3.2 のサイトでも使うため）。`compatibility` の末尾に「Ver. 3.3 の内容は references/ver-3.3.md」と足してよい。
- 新しいバージョンの中の途中で入った機能（3.3.x の途中で入ったもの）は、`ver-3.3.md` の中で「Ver. 3.3.5 以降」のように注記する。

### プレリリース（アルファ・ベータ）の間

- main には入れず、`acms-3.3` のようなブランチで作る。プレリリースの間は仕様が変わり得て、正とする developer.a-blogcms.jp のドキュメントもまだ無いため。
- 根拠は本体のプレリリース版のソースになる。どのバージョン（`3.3.0-alpha.1` など）で確かめたかを `ver-3.3.md` や新しいスキルの references の冒頭に書く。変数表やスニペットを写さない決まりはプレリリースの間も同じ。
- 新しいスキルの `metadata.status` は `draft` にする。
- 正式版が出たら、正式版との差を確かめて直し、developer サイトのページへのリンクを足してから main にマージし、マイナーリリースにする（スキルの追加があるため）。

## このリポジトリのバージョン

- a-blog cms 本体とは独立した Semantic Versioning で、`vX.Y.Z` のタグと GitHub Release を作る（`gh skill install --pin` で固定できるようにするため）。
- スキルの削除・改名はメジャー、スキルの追加はマイナー、内容の修正はパッチとする。
- `.claude-plugin/marketplace.json` の各プラグインの `version` もリリースのたびに揃えて上げる（Claude Code は version が変わったときに更新を配る）。

### リリースの手順

1. `CHANGELOG.md` の `## [Unreleased]` を `## [X.Y.Z] - YYYY-MM-DD` に改め、新しい `## [Unreleased]` を上に足す。
2. `.claude-plugin/marketplace.json` の `metadata.version` と各プラグインの `version` を `X.Y.Z` に揃える。
3. 前回のリリースから内容を変えたスキルについて、[docs/authoring-guide.md](authoring-guide.md) の「検証」の 2（受け入れ）と 3（振る舞い）を済ませる。
4. main にコミットして push し、CI（validate）が通ったら、`git tag vX.Y.Z && git push origin vX.Y.Z` でタグを push する。
5. `.github/workflows/release.yml` が、検証・タグと marketplace.json のバージョンの一致・CHANGELOG の節の有無を確かめてから、CHANGELOG の節をリリースノートにした GitHub Release を作り、`scripts/build-zips.sh` で作ったスキルごとの zip を添付する。どれかが合わなければ Release は作られないので、直してタグを打ち直す（`git tag -d vX.Y.Z && git push origin :refs/tags/vX.Y.Z`）。

## a-blog cms 本体との連動

本体の公開 API（テンプレート構文、Twig の関数・フィルター、Hook、管理画面の JavaScript の拡張ポイント）が変わったときは、本体のリリース作業の中でこのリポジトリの該当スキルも更新する。

## 新しいバージョンへの移行を足すとき

バージョンアップは 3 つのスキルで分担する。`acms-upgrade` はバージョンに依存しない共通の手順・移行先ごとの共通の要件・洗い出しのスクリプト（`scripts/scan.sh` とチェック定義）、`acms-upgrade-theme` はテーマの修正、`acms-upgrade-plugin` はプラグイン（拡張アプリ）と `extension/acms/` の修正を持つ。3 スキルの `references/to-<バージョン>.md` は同じ見出し（前提・下位互換性のない変更・非推奨になった機能と代替・直す手順・移行後の確認・参考）でそろえる。

本体の新しいマイナーバージョン（3.3、3.4 など）が出たら、次を足す。既存のファイルは書き換えない（古いバージョンからの移行に今も使われるため）。

1. 3 スキルそれぞれの `references/_template.md` を複製して `references/to-<バージョン>.md` を作り、固定の見出しに沿って書く。テーマにもプラグインにも当てはまるもの（要件・DB の更新・両方に出る変更）は `acms-upgrade`、テーマだけのものは `acms-upgrade-theme`、プラグインだけのものは `acms-upgrade-plugin` に書く。根拠は developer サイトの移行ガイド（`/document/migration/` 配下）と、前のバージョンの最終タグとの本体ソースの差分。
2. `skills/acms-upgrade/scripts/checks/to-<バージョン>.tsv` に、テーマ・プラグイン（拡張アプリ）の文字列から検出できる変更を1行1チェックで足す。ID はテーマを `T-`、プラグインを `P-` で始め、section 列には直し方を書いた場所を `acms-upgrade-theme: to-<バージョン>.md#<見出し>` の形で書く。公式テーマの旧バージョンで検出でき、新バージョンで誤検出しないことを `scripts/scan.sh` で確かめる。`acms-upgrade-theme`・`acms-upgrade-plugin` の「見つけ方」には、チェック ID と、`acms-upgrade` がない環境のための grep の文字列の両方を書く。
3. 3 スキルの `SKILL.md` の「移行先ごとのファイル」の表に1行ずつ足す。
4. 3 スキルそれぞれの `evals/scenarios.json` に、そのバージョンへの移行のシナリオを足す。
