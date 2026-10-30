---
name: acms-upgrade-theme
description: >-
  a-blog cms（acms）のバージョンアップ（Ver. 3.1 から 3.2 など）で、テーマ（テンプレート・CSS・テーマの JavaScript・template.yaml・
  管理画面のカスタムフィールド定義など）を直すときの手順と判断基準。非推奨・削除されたモジュール（Entry_List・Entry_Headline など）の置き換え、
  廃止・非推奨の組み込み JS、ユニットの HTML と acms.css の変更、引用ユニットから埋め込みユニットへの変更、表側のエントリー編集の廃止、
  Ogp モジュールの既定のフィールド、配置 v1 とユニットグループ、更新後の表示崩れの原因の切り分けを、移行先ごとの references/to-<バージョン>.md で扱う。
  「このテーマで Entry_Headline を使っている。3.2 で大丈夫？」「3.2 にしたら画像の横並びや埋め込みの見た目が崩れた」
  「バージョンアップでテーマの何を直せばいい？」「アップデートしたら OGP 画像が出なくなった」と頼まれたときに使う。
  a-blog cms upgrade, migration, theme, template, deprecated module, acms.css, unit, breaking changes.
  バージョンの判定・バックアップ・本体の更新などの共通手順と scripts/scan.sh は acms-upgrade、プラグイン（拡張アプリ）の修正は acms-upgrade-plugin、
  テンプレートの記法は acms-template-acms / acms-template-twig、代替モジュールの選び方は acms-module-reference が担う。
license: MIT
compatibility: 移行先 Ver. 3.2。移行元が Ver. 3.2 未満（3.1 以前）のサイトのテーマも扱う。要修正箇所の洗い出しは acms-upgrade の scripts/scan.sh を使い、入っていなければ grep で探す。
metadata:
  acms-min-version: "3.2"
  status: stable
---

# a-blog cms のバージョンアップ: テーマの修正

## 移行先ごとのファイル

| 移行先 | 移行元 | 読むファイル | 洗い出し |
|---|---|---|---|
| Ver. 3.2 | Ver. 3.1.x | [references/to-3.2.md](references/to-3.2.md) | acms-upgrade の `scripts/scan.sh <設置ディレクトリ> 3.2` の `T-` で始まるチェック |

移行先を足すときは [references/_template.md](references/_template.md) を写して `to-<バージョン>.md` を作り、この表に 1 行足す（acms-upgrade・acms-upgrade-plugin の同じバージョンのファイルもそろえる）。

## 最初に確かめること

- 回答の最初の手順として、必ず「acms-project-triage の `scripts/detect.sh` で現在のバージョンとテンプレートの種類を判定する」と、スキル名とスクリプト名を挙げて示す（このスキルだけが読み込まれていて実行できない場合でも、手順として示す）。バージョンは `license.php`・`php/Application.php` などの PHP ファイルから読まない・推定しない（配布版では難読化されていて読めず、読めるのは開発用のソースだけのため。開発用のソースが手元にあっても読まない）。バージョンが「不明」「推定」なら、管理画面のダッシュボードで確かめてもらう。
- 移行先は、その系列の最新のパッチバージョンにする。番号を[リリースノート](https://developer.a-blogcms.jp/releasenote.html)で確かめ、「移行先は Ver. 3.2.NN」のように回答に書いて利用者と共有する（確かめた日付も添える）。
- バックアップ・検証環境・本体の更新・本番への反映などの全体の流れは acms-upgrade に従う。テーマの修正も、本番より先に検証環境で行う。

## 手順

### 1. 直す箇所を洗い出す

acms-upgrade が入っているなら、更新前のサイトで次を実行し、`T-` で始まるチェックと最後の上書き一覧を見る（パスは acms-upgrade のディレクトリからの相対パス）。

```sh
sh scripts/scan.sh <設置ディレクトリ> <移行先のバージョン（例 3.2）>
```

acms-upgrade が入っていないときは、`references/to-<バージョン>.md` の「見つけ方」にある「grep:」の文字列で、`themes/`（`system` を除く）を探す。

- 非推奨・削除されたモジュールの相談では、尋ねられた1つだけで終えず、同じチェック（3.2 なら `T-DEPRECATED-MODULE`・`T-REMOVED-MODULE` など）の検出結果全体から、ほかのモジュール（`Entry_List`・`Entry_Photo`・`Banner` など）も洗い出して一覧で示す。一つずつ相談されて見落としが出やすいため。
- **更新後に表示が崩れたと相談されたら**、scan.sh を流して、表示に関わるチェック（3.2 なら `T-ACMS-CSS`・`T-EMBED-UNIT`・`T-UNIT-SECTION`）と上書きの一覧の両方を見るよう、ID を挙げて案内する。崩れの原因は、テーマに残った旧 CSS か、旧 system から写したまま古くなった上書きのどちらかであることが多いため。scan.sh・grep では見つけられないもの（3.2 なら配置 v1 とユニットグループの余白）は表示で確かめる。
- 検出は文字列の一致による候補なので、直す前に該当行を開いて確かめる。`要確認` と付いたものは見比べる箇所。

### 2. 本体を更新する前に直す

`references/to-<バージョン>.md` の「直す手順」に沿って、移行元のバージョンのままで直せるもの（代替のモジュールが移行元にもある、廃止された記述を外す）を先に直す。

- 旧バージョンの `themes/system` から取っておくもの（3.2 なら `T-ACMS-CSS` が出たテーマの旧 `acms.css`・`acms.min.css`）は、本体の更新前にテーマへコピーする。更新すると system の中身が置き換わり、旧バージョンを取れなくなるため。
- 非推奨のモジュールを代替に置き換えるときは、モジュール ID の設定（表示件数・並び順など）を代替モジュール側で作り直す必要があるので、利用者に管理画面での作業を頼む。変数名の違いは代替モジュールの変数表で確かめる（acms-module-reference）。
- 非推奨の機能は移行先でも動く。「今すぐ動かなくなる」とは説明しない。削除・廃止されたもの（効かなくなる・何も出力されなくなる）と区別して伝える。

### 3. 本体を更新した後に見比べて直す

- ユニットの HTML を上書きしている箇所と、上書き一覧のファイルを、移行先のバージョンの `themes/system` の同じファイルと見比べる（`diff themes/system/<パス> themes/<テーマ>/<パス>`）。
- 設定で直すもの（3.2 なら Ogp の既定のフィールド）は、`private/config.system.yaml` に足す行を示して利用者に書いてもらう。

### 4. 確認する

`references/to-<バージョン>.md` の「移行後の確認」を順に見る。scan.sh をもう一度実行し、`T-` のうち `要確認` 以外の検出が 0 件になったことを確かめる。

記法（`BEGIN_MODULE`、`@include`、Twig）の書き方は acms-template-acms / acms-template-twig、テーマの構成と継承は acms-theme-development を使う。

## 守ること

- `themes/system/`・`php/`・`js/` は直さない。本体の更新で上書きされるため。直すのは作業中のテーマ（`themes/<テーマ>/`）と設定。system のテンプレートを変えたいときは、作業中のテーマに同じパスでファイルを置く。
- `config.server.php`・`.env`・`private/` 配下は開かない。DB の接続情報や API キー・秘密鍵があるため。`private/config.system.yaml` に設定を足す必要があるときは、足す行を示して利用者に書いてもらう。
- バージョンを推測で決めない。移行元と移行先のバージョンを確かめてから直す内容を決める。
- 公式の移行ガイドにない変更を見つけたときは、根拠を示して利用者に伝える。確かめられない挙動は「未確認」と伝える。

## 公式ドキュメント

- 移行ガイド（Ver. 3.1.x から 3.2.x）: <https://developer.a-blogcms.jp/document/migration/302x/>
- テーマについて（3.2）: <https://developer.a-blogcms.jp/document/migration/302x/theme.html>
- リリースノート: <https://developer.a-blogcms.jp/releasenote.html>
