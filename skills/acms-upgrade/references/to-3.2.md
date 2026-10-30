# Ver. 3.2 への移行（移行元: Ver. 3.1.x）: 共通

公式の移行ガイドは <https://developer.a-blogcms.jp/document/migration/302x/>。このファイルは、そこに書かれた変更のうち、テーマにもプラグイン（拡張アプリ）にも当てはまるもの（要件・DB の更新・両方に関わる変更・本体側の確認）を整理したもの。各項目の説明はリンク先を読む。

テーマだけに関わる変更は acms-upgrade-theme の `references/to-3.2.md`、プラグイン（拡張アプリ）と `extension/acms/` だけに関わる変更は acms-upgrade-plugin の `references/to-3.2.md` にある。チェック ID の定義は `scripts/checks/to-3.2.tsv`（`T-` はテーマ、`P-` はプラグイン）。`要確認` と付いたチェックは、直す箇所ではなく見比べる箇所を出す。

## 前提（移行元・PHP などの要件）

| 項目 | 内容 | 根拠 |
|---|---|---|
| 移行元 | Ver. 3.1.x。3.0 以前からは、途中の版の移行ガイドも読む（SKILL.md の手順 2） | [移行ガイド 3.1.x → 3.2.x](https://developer.a-blogcms.jp/document/migration/302x/) |
| PHP | 3.2 は PHP 8.1 以上。上限はパッチ版で変わるので、動作条件のページで移行先の版の範囲を確かめる | [下位互換性のない変更点](https://developer.a-blogcms.jp/document/migration/302x/incompatible.html)、[動作条件](https://developer.a-blogcms.jp/document/requirements.html) |
| MySQL | MySQL 8.0 以上（MariaDB は動作条件のページの版） | 同上 |
| オンラインアップデートと PHP | 更新の候補は、サーバーの PHP の版に合うパッケージから選ばれる。PHP 8.1 未満のままでは 3.2 が候補に出ないので、先に PHP を上げられるか（3.1 がその PHP で動くか）をサーバーの管理者と決める | `v3.1.79:ablogcms/php/ACMS/POST/Update/Exec.php:64-71`（`checkUseCache(phpversion(), $range)`）、`v3.1.79:ablogcms/php/Services/Update/System/CheckForUpdate.php:431-448` |
| オンラインアップデートの範囲 | 3.1 → 3.2 はマイナーバージョンアップ。管理画面 > コンフィグ > 機能設定の「オンラインアップデート」を「マイナーバージョンも含める」にしないと候補に出ない | `v3.1.79:ablogcms/php/ACMS/POST/Update/Exec.php:64-67`（`system_update_range`）、[オンラインアップデート](https://developer.a-blogcms.jp/document/update/online-update.html) |
| DB の更新とデータの変換 | 3.2.0 より前からの DB 更新で、カスタムユニットのデータの保存先の移動と、非表示にしたユニットの持ち方の変換が行われる。元に戻すには DB のバックアップから戻すしかない | `v3.2.38:ablogcms/php/Services/Update/Database/Rule.php:427-438`（`update320()`） |
| 配布されているプラグイン（拡張アプリ） | 3.2 対応版が出ているかを先に確かめる（3.2.0 の時点では全部は対応していない）。確かめ方は acms-upgrade-plugin | [下位互換性のない変更点](https://developer.a-blogcms.jp/document/migration/302x/incompatible.html) |

## 下位互換性のない変更

テーマとプラグイン（拡張アプリ）の両方に修正が出るもの。直し方の詳細は、テーマ側は acms-upgrade-theme、プラグイン側は acms-upgrade-plugin の `references/to-3.2.md` の同じ見出しにある。

| 変更 | 見つけ方 | 直し方 | 根拠 |
|---|---|---|---|
| トラックバック・Facebook ログインを廃止 | テーマ: `T-REMOVED-MODULE`・`T-REMOVED-POST`。プラグイン: `P-REMOVED-CLASS`・`P-REMOVED-SERVICE` | モジュール・フォーム・ボタン・クラスの利用ごと外す。Facebook 以外の SNS ログイン（Google・X・LINE）は残っている | [incompatible.html](https://developer.a-blogcms.jp/document/migration/302x/incompatible.html)、`git diff --diff-filter=D v3.1.53 v3.2.0 -- ablogcms/php/ACMS/GET ablogcms/php/ACMS/POST` |
| 未使用のモジュールを削除（`Case_Auth`・`Case_Ua`・`Case_View`・`Column_List`・`Filter_*`・`Touch_EditDirect` など。承認系の Touch モジュールの一部は Ver. 3.2.20 で削除） | テーマ: `T-REMOVED-MODULE`。プラグイン: `P-REMOVED-CLASS` | テーマはブロックごと外すか別のモジュール・Touch モジュールで書き直す。プラグインは継承・呼び出しをやめる | `git diff --diff-filter=D --name-only v3.1.79 v3.2.38 -- ablogcms/php/ACMS/GET ablogcms/php/ACMS/POST` |
| Ver. 2.7 以前のテキストユニットに戻す設定（`ACMS.Config.LiteEditorFeature = false`）を廃止 | `T-LITEEDITOR-FEATURE`（テーマと `extension/` の両方を探す） | 記述を消す | [incompatible.html](https://developer.a-blogcms.jp/document/migration/302x/incompatible.html) |

## 非推奨になった機能と代替

非推奨の機能は 3.2 でも動く。デバッグモードのとき、PHP 側は監査ログ（notice）に、組み込み JS はブラウザーのコンソールに警告が出る（`Acms\Services\Logger\Deprecated::once`、`ACMS.Library.deprecated`）。急がないが、移行のついでに直すと次の版で困らない。

| 機能 | 代替 | 見つけ方 | 根拠 |
|---|---|---|---|
| 非推奨のモジュール（`Entry_List`・`Entry_Headline`・`Entry_Photo`・`Category_EntryList`・`Banner`・`User_Profile`・`Plugin_Schedule`）、カート機能（`Shop2_*`） | `Entry_Summary` など（モジュールごとの代替は acms-upgrade-theme の表）。代替は 3.1 にもあるので、本体を更新する前に置き換えてよい | テーマ: `T-DEPRECATED-MODULE`・`T-DEPRECATED-SHOP2`。プラグイン: `P-DEPRECATED-CLASS` | [deprecated.html](https://developer.a-blogcms.jp/document/migration/302x/deprecated.html) |
| リッチエディター、テキストユニットのタグセレクト（pre・none・markdown・wysiwyg）、多言語ユニット、ユニットグループ、配置 v1 | ブロックエディター、各ユニット、グループユニット、配置 v2 | scan.sh では見つけられない（管理画面の設定と入力済みのデータ）。既存のデータはそのまま使えるので、移行の作業には含めない | [deprecated.html](https://developer.a-blogcms.jp/document/migration/302x/deprecated.html) |

## 直す手順

1. 更新前のサイト（3.1）で `sh scripts/scan.sh <設置ディレクトリ> 3.2` を実行し、結果を保存する。
2. 本体を更新する前に、テーマとプラグイン（拡張アプリ）で 3.1 のままでも直せるものを直し、更新前の `themes/system` から取っておくもの（`T-ACMS-CSS` が出たテーマの旧 `acms.css`・`acms.min.css`）を取る。`T-` の項目は acms-upgrade-theme、`P-` の項目は acms-upgrade-plugin の手順で直す。
3. 本体を更新し、DB を更新する（SKILL.md の手順 7）。
4. 更新後に見比べて直すもの（ユニットの HTML・上書きしたテンプレート・組み込み JS）を、acms-upgrade-theme の手順で直す。
5. scan.sh をもう一度実行し、`要確認` 以外の検出が 0 件になったことを確かめる。

## 移行後の確認

本体側の確認。テーマの表示の確認は acms-upgrade-theme、プラグインの動作の確認は acms-upgrade-plugin の「移行後の確認」を続けて見る。

- 管理画面のユーザー設定でデバッグモードにして、主要なページ（トップ・一覧・詳細・フォーム・検索・会員ページ）をログイン時とログアウト時の両方で見る。
- 監査ログに error・warning と非推奨の notice が出ていないか、ブラウザーのコンソールに非推奨の警告が出ていないかを見る。
- 非表示にしていたユニットが非表示のままか（DB 更新で持ち方が変わる）。
- エントリー管理画面: 3.2 で新しくなった。独自に直していて旧画面に戻したいなら、利用者に `private/config.system.yaml` へ `entry_admin_page_version: 1` を足してもらう（[changes.html](https://developer.a-blogcms.jp/document/migration/302x/changes.html)。エージェントは `private/` を開かない）。
- `scripts/scan.sh` を再実行して、`要確認` 以外が 0 件。

## 参考

- 移行ガイド（Ver. 3.1.x から 3.2.x）: <https://developer.a-blogcms.jp/document/migration/302x/>
- 下位互換性のない変更点: <https://developer.a-blogcms.jp/document/migration/302x/incompatible.html>
- Ver. 3.2.x で推奨されなくなる機能: <https://developer.a-blogcms.jp/document/migration/302x/deprecated.html>
- 改善・修正した変更点: <https://developer.a-blogcms.jp/document/migration/302x/changes.html>
- 新機能: <https://developer.a-blogcms.jp/document/migration/302x/new-features.html>
- アップデート方法: <https://developer.a-blogcms.jp/document/update/>
- 動作条件: <https://developer.a-blogcms.jp/document/requirements.html>
