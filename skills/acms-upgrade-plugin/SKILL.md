---
name: acms-upgrade-plugin
description: >-
  a-blog cms（acms）のバージョンアップ（Ver. 3.1 から 3.2 など）で、プラグイン（拡張アプリ）と extension/acms のユーザー拡張
  （PHP・管理画面の JavaScript）を直すときの手順と判断基準。PHP の要件、配布されているプラグインの対応版の確認、
  SQL ヘルパーの変更（get() の戻り値、setInsert / setReplace の削除）、削除されたグローバル関数とファサードへの置き換え、
  削除されたモジュール・クラス、標準の GET モジュールの継承、非推奨のクラス、Hook の変化を、移行先ごとの references/to-<版>.md で扱う。
  「自作プラグインは 3.2 で動く？」「SQL::newSelect() を使っている箇所は直す必要がある？」「createImages が見つからないエラーが出た」
  「PHP 8.1 に上げたらプラグインが動かない」と頼まれたときに使う。
  a-blog cms upgrade, migration, plugin, extension/acms, PHP 8.1, SQL helper, removed function, facade, Hook, breaking changes.
  版の判定・バックアップ・本体の更新などの共通手順と scripts/scan.sh は acms-upgrade、テーマの修正は acms-upgrade-theme、
  Hook・ServiceProvider・独自モジュールの書き方は acms-plugin-development、管理画面の JavaScript プラグインは acms-admin-frontend-plugin が担う。
license: MIT
compatibility: 移行先 Ver. 3.2。移行元が Ver. 3.2 未満（3.1 以前）のサイトのプラグイン（拡張アプリ）も扱う。要修正箇所の洗い出しは acms-upgrade の scripts/scan.sh を使い、入っていなければ grep で探す。
metadata:
  acms-min-version: "3.2"
  status: stable
---

# a-blog cms のバージョンアップ: プラグイン（拡張アプリ）の修正

## 移行先ごとのファイル

| 移行先 | 移行元 | 読むファイル | 洗い出し |
|---|---|---|---|
| Ver. 3.2 | Ver. 3.1.x | [references/to-3.2.md](references/to-3.2.md) | acms-upgrade の `scripts/scan.sh <設置ディレクトリ> 3.2` の `P-` で始まるチェック |

移行先を足すときは [references/_template.md](references/_template.md) を写して `to-<版>.md` を作り、この表に 1 行足す（acms-upgrade・acms-upgrade-theme の同じ版のファイルもそろえる）。

## 最初に確かめること

- 回答の最初の手順として、必ず「acms-project-triage の `scripts/detect.sh` で現在の版とプラグイン（拡張アプリ）の構成を判定する」と、スキル名とスクリプト名を挙げて示す（このスキルだけが読み込まれていて実行できない場合でも、手順として示す）。版は `license.php`・`php/Application.php` などの PHP ファイルから読まない・推定しない（配布版では難読化されていて読めず、読めるのは開発用のソースだけのため。開発用のソースが手元にあっても読まない）。版が「不明」「推定」なら、管理画面のダッシュボードで確かめてもらう。
- 移行先は、その系列の最新のパッチ版にする。番号を[リリースノート](https://developer.a-blogcms.jp/releasenote.html)で確かめ、「移行先は Ver. 3.2.NN」のように回答に書いて利用者と共有する（確かめた日付も添える）。関数の引数などはパッチ版の間でも変わることがあるので、移行先の版のソースで確かめる。
- 移行先の PHP の要件（3.2 なら PHP 8.1 以上）を `references/to-<版>.md` の「前提」で確かめる。サーバーの PHP を先に上げるなら、今の版の本体とプラグインがその PHP で動くかも確かめる。
- バックアップ・検証環境・本体の更新・本番への反映などの全体の流れは acms-upgrade に従う。プラグインの修正も、本番より先に検証環境で行う。

## 手順

### 1. 配布されているプラグインの対応版を確かめる

配布されているプラグイン（拡張アプリ）は、移行先の版に対応した版があるかを配布元で確かめ、あれば差し替える。対応版がないものは、検証環境で動作を確かめるまで本番で有効にしない。

### 2. 自作のプラグインと extension/acms の直す箇所を洗い出す

acms-upgrade が入っているなら、更新前のサイトで次を実行し、`P-` で始まるチェックを見る（パスは acms-upgrade のディレクトリからの相対パス）。

```sh
sh scripts/scan.sh <設置ディレクトリ> <移行先の版（例 3.2）>
```

acms-upgrade が入っていないときは、`references/to-<版>.md` の「見つけ方」にある「grep:」の文字列で、`extension/` を探す。

- 検出は文字列の一致による候補なので、直す前に該当行を開いて確かめる。`要確認` と付いたもの（3.2 なら `P-EXTENDS-GET`）は、検証環境で動作を見比べる箇所。
- 削除された関数・クラスや非推奨のクラスの相談では、尋ねられた1つだけで終えず、同じチェックの検出結果全体から、ほかの箇所も洗い出して一覧で示す。一つずつ相談されて見落としが出やすいため。
- scan.sh は PHP の版の違い（PHP 8 系で使えなくなった関数・書き方）を調べない。

### 3. 直す

`references/to-<版>.md` の「直す手順」と「下位互換性のない変更」「非推奨になった機能と代替」の表に沿って直す。

- 削除された関数・クラスの代わりは、移行先の版のソース（`php/Services/Facades/` の注釈、`extension/plugins/SamplePlugin/`、`extension/acms/Hook.php`）で確かめてから置き換える。記憶にある API で書かない。
- 非推奨のクラスは移行先でも動く。削除されたもの（呼ぶとエラーになる）と区別して伝える。

### 4. 確認する

検証環境を移行先の版・移行先の PHP にし、デバッグモードでプラグインの機能を使うページと設定ページを開いて、エラー・警告が出ないかを見る。`references/to-<版>.md` の「移行後の確認」を順に見て、scan.sh をもう一度実行し、`P-` のうち `要確認` 以外の検出が 0 件になったことを確かめる。

Hook・ServiceProvider・独自モジュールの書き方は acms-plugin-development、管理画面の JavaScript プラグインの書き方は acms-admin-frontend-plugin を使う。

## 守ること

- 削除された関数やクラスを、本体の `php/` に書き足して復活させない。本体の更新で消えるうえ、本体の他の処理と衝突するため。呼び出し側のプラグイン（拡張アプリ）を、移行先の API（ファサードなど）に書き換える。

- `php/`・`js/`・`themes/system/` は直さない。本体の更新で上書きされるため。直すのは `extension/plugins/`・`extension/acms/` と設定。
- `config.server.php`・`.env`・`private/` 配下は開かない。DB の接続情報や API キー・秘密鍵があるため。設定を足す必要があるときは、足す行を示して利用者に書いてもらう。
- 版を推測で決めない。移行元と移行先の版を確かめてから直す内容を決める。
- 公式の移行ガイドにない変更を見つけたときは、根拠を示して利用者に伝える。確かめられない挙動は「未確認」と伝える。

## 公式ドキュメント

- 移行ガイド（Ver. 3.1.x から 3.2.x）: <https://developer.a-blogcms.jp/document/migration/302x/>
- 動作条件: <https://developer.a-blogcms.jp/document/requirements.html>
- プラグイン（拡張アプリ）: <https://developer.a-blogcms.jp/document/develop_apps/>
- リリースノート: <https://developer.a-blogcms.jp/releasenote.html>
