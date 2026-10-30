# Ver. 3.2 への移行（移行元: Ver. 3.1.x）: テーマ

公式の移行ガイドは <https://developer.a-blogcms.jp/document/migration/302x/>。このファイルは、そこに書かれた変更のうちテーマ（テンプレート・CSS・テーマの JavaScript・`template.yaml`・管理画面のカスタムフィールド定義など）の修正が要るものを、見つけ方と直し方に整理したもの。各項目の説明はリンク先を読む。

見つけ方の `T-` で始まる ID は、acms-upgrade の `scripts/scan.sh` のチェック（定義は acms-upgrade の `scripts/checks/to-3.2.tsv`）。acms-upgrade が入っていないときは、「grep:」に挙げた文字列で `themes/`（`system` を除く）を探す。`要確認` と付いたチェックは、直す箇所ではなく見比べる箇所を出す。

PHP・MySQL の要件、オンラインアップデート、DB の更新など、テーマに限らない前提は acms-upgrade の `references/to-3.2.md` にある。

## 前提（移行元・PHP などの要件）

| 項目 | 内容 | 根拠 |
|---|---|---|
| 移行元 | Ver. 3.1.x。3.0 以前からは、途中の版の移行ガイドも読む（acms-upgrade の手順 2） | [移行ガイド 3.1.x → 3.2.x](https://developer.a-blogcms.jp/document/migration/302x/) |
| 更新前にしか取れないもの | 本体を更新すると `themes/system` の中身が 3.2 に置き換わり、旧版の `acms.css`・`acms.min.css` やユニットのテンプレートを取れなくなる。`T-ACMS-CSS` が出たテーマは、更新前にテーマの `css/` へコピーしておく | [incompatible.html](https://developer.a-blogcms.jp/document/migration/302x/incompatible.html) |
| 直す場所 | テーマ（`themes/<テーマ>/`）だけを直す。`themes/system/` は本体の更新で上書きされるので直さない | [オンラインアップデート](https://developer.a-blogcms.jp/document/update/online-update.html)の「更新されるファイル」（`themes/system`・`php`・`js` などが置き換わる） |

## 下位互換性のない変更

| 変更 | 見つけ方 | 直し方 | 根拠 |
|---|---|---|---|
| ユニットのレイアウトが float から Flexbox・CSS Grid に変わり、`acms.css` のユニットのスタイルが変わった | `T-ACMS-CSS`（要確認。grep: `css/acms.css`・`css/acms.min.css`）、`T-UNIT-SECTION`（要確認。grep: `-unit)` を含む `@section(`）、上書き一覧（テーマ内で `themes/system` と同じパスに置いたファイル） | 本体を更新する**前に**、更新前の `themes/system/css/acms.css` と `acms.min.css` を利用中のテーマの `css/` にコピーする（テーマ側が優先されるため、旧スタイルが残る）。ユニットの CSS を自前で書いているなら不要。コピーした旧 `acms.css` には 3.2 で増えたクラス（`acms-cssgrid` など）がないので、新しいユニットの見た目は別に確かめる | [incompatible.html](https://developer.a-blogcms.jp/document/migration/302x/incompatible.html)、`v3.1.79` の `themes/system/src` に `acms-cssgrid` がないこと（`git grep -c acms-cssgrid v3.1.79 -- ablogcms/themes/system/src` が 0 件） |
| 配置 v1 とユニットグループを有効のまま使うと、段組みで余白がずれることがある | scan.sh・grep では見つけられない。表示で確かめる | 「移行後の確認」の 2 項目（横並びの上揃え・ユニットグループ内の左右余白）を見る。更新したサイトは互換のため配置 v1・ユニットグループ有効のまま（`unit_align_version: 'v1'`、`unit_group: on` が既定） | [302x-v1-unit-group-coution.html](https://developer.a-blogcms.jp/document/migration/302x/302x-v1-unit-group-coution.html)、`v3.2.38:ablogcms/private/config.system.default.yaml:1536,1553` |
| 引用ユニットが埋め込みユニットになり、HTML が `blockquote` から `a` 要素に変わった | `T-EMBED-UNIT`（grep: `column-quote-`・`quoteTitleLink`・`@section(quote-unit)`） | 旧クラス（`column-quote-*`、`quoteTitleLink`）向けの CSS を、3.2 の `themes/system/_layouts/unit.html` の `unit#quote` の HTML（`column-embed`、`acms-embed-link`）に合わせて書き直す。テーマで `@section(quote-unit)` を上書きしているなら、その HTML も見直す | [incompatible.html](https://developer.a-blogcms.jp/document/migration/302x/incompatible.html)、`v3.2.38:ablogcms/themes/system/_layouts/unit.html:649-677` |
| 組み込み JS の一部を廃止（高さ揃え・prettyPhoto・Highslide・bxSlider・アダプティブイメージ・プレースホルダー・biggerlink など） | `T-REMOVED-BUILTIN-JS`（grep: `js-autoheight`・`js-biggerlink`・`js-adaptive_image`・`js-bxslider`・`js-placeholder`・`prettyPhoto`・`highslide`・`swfobject`） | クラスを付けても何も起きなくなる。テーマの JavaScript・CSS で代わりを用意するか、記述を消す。`js-autoheight` は廃止、`js-autoheight-r` は非推奨（別の行） | [incompatible.html](https://developer.a-blogcms.jp/document/migration/302x/incompatible.html)、`v3.1.79:ablogcms/js/config.js` と `v3.2.0:ablogcms/js/config.js` の比較（`autoHeightMark`・`biggerlinkMark`・`ppMark`・`hsMark` などが 3.2.0 で消えた） |
| 上の一覧に載っていないが、`.js-toggle`（`toggleMark`）・`.js-fader-storage`・`.js-external_submit`（`externalFormButtonMark`）も 3.2.0 で消えた | `T-REMOVED-BUILTIN-JS`（grep: `js-toggle`・`js-fader-storage`・`js-external_submit`） | 同上 | `v3.1.79:ablogcms/js/config.js:850,867,1296` にあり、`v3.2.0:ablogcms/js/config.js` にないこと |
| SSL への書き換え（`js-link_no_rewrite` など）を廃止 | 対象外（クラスが残っていても害はない） | 消さなくてよい | [incompatible.html](https://developer.a-blogcms.jp/document/migration/302x/incompatible.html) |
| シンタックスハイライトが Google Code Prettify から highlight.js に変わった | `T-PRETTIFY`（grep: `prettyprint`） | `prettyprint` クラスでは色が付かない。既定では `pre` 要素が対象（`ACMS.Config.highlightMark`）。テーマや色は `ACMS.Config.highlightConfig` で変える | [changes.html](https://developer.a-blogcms.jp/document/migration/302x/changes.html)、`v3.2.0:ablogcms/js/config.js:34` |
| グローバル変数 `%{META_KEYWORDS}`・`%{META_DESCRIPTION}` を廃止 | `T-META-VARS`（grep: `%{META_KEYWORDS}`・`%{META_DESCRIPTION}`） | 空になる。カスタムフィールドなど別の値から出す | [incompatible.html](https://developer.a-blogcms.jp/document/migration/302x/incompatible.html)、`v3.1.79:ablogcms/php/ACMS/function.php:6585` にあり 3.2 にないこと |
| トラックバック・Facebook ログインを廃止 | `T-REMOVED-MODULE`・`T-REMOVED-POST`（grep: `BEGIN_MODULE Trackback_`・`ACMS_POST_Trackback_`・`Member_Sns_Facebook_`・`Member_Admin_Login_Facebook`・`callback/signin/facebook`） | モジュール・フォーム・ボタンごと外す。Facebook 以外の SNS ログイン（Google・X・LINE）は残っている | [incompatible.html](https://developer.a-blogcms.jp/document/migration/302x/incompatible.html)、`git diff --diff-filter=D v3.1.53 v3.2.0 -- ablogcms/php/ACMS/GET ablogcms/php/ACMS/POST` |
| 未使用のモジュールを削除（`Case_Auth`・`Case_Ua`・`Case_View`・`Column_List`・`Filter_*`・`Touch_EditDirect` など。承認系の Touch モジュールの一部は Ver. 3.2.20 で削除） | `T-REMOVED-MODULE`（grep: `BEGIN_MODULE Case_`・`BEGIN_MODULE Column_List`・`BEGIN_MODULE Filter_`・`BEGIN_MODULE Touch_`） | ブロックごと外すか、別のモジュール・Touch モジュールで書き直す。`Touch_` は削除されたもの（`Touch_EditDirect`・`Touch_NotEditDirect`・`Touch_Role_CategoryCreate`・`Touch_PreApproval`・`Touch_NotPreApproval`・`Touch_ApprovalEntrySave`・`Touch_RevisionAdministrator`・`Touch_NotsessionWithApprovalAdministrator`）だけが対象 | `git diff --diff-filter=D --name-only v3.1.79 v3.2.38 -- ablogcms/php/ACMS/GET ablogcms/php/ACMS/POST` |
| 表側のエントリー編集画面を廃止（管理画面で編集する） | `T-FRONT-EDIT`（grep: `admin/entry/title.html`・`admin/entry/edit-`・`tpl_entry_edit`）、`T-REMOVED-POST`（grep: `ACMS_POST_Entry_Direct`・`ACMS_POST_Entry_Add`・`ACMS_POST_Unit_Sort`・`ACMS_POST_Through`） | `@include("/admin/entry/title.html")`・`@include("/admin/entry/edit-%{IS_ADMIN}.html")` を消す（`themes/system` から削除済み）。`template.yaml` の `tpl_entry_edit` も使われないので消す。`/admin/entry/action.html` と `revision-info.html` は 3.2 の公式テーマでも使っているので残す | [changes.html](https://developer.a-blogcms.jp/document/migration/302x/changes.html)、`v3.2.38:ablogcms/themes/blog/include/entry-body.html:11,86` |
| AMP 用のユニットのテンプレート（`include/unit-amp.html`・`_layouts/unit-amp.html`）と多言語ユニットのサンプル（`unit_language.html`）を `themes/system` から削除 | `T-UNIT-TEMPLATE-REMOVED`（grep: `unit-amp.html`・`unit_language.html`） | `@include` / `@extends` を外す。使い続けるなら、更新前の system からテーマ内にコピーして自分で保守する | `git log --diff-filter=D v3.1.53..v3.2.0 -- ablogcms/themes/system/include/unit-amp.html ablogcms/themes/system/include/unit_language.html` |
| Ver. 2.7 以前のテキストユニットに戻す設定（`ACMS.Config.LiteEditorFeature = false`）を廃止 | `T-LITEEDITOR-FEATURE`（grep: `LiteEditorFeature`） | 記述を消す | [incompatible.html](https://developer.a-blogcms.jp/document/migration/302x/incompatible.html) |
| Ogp モジュールがエントリーから読む画像フィールドの既定が `ogp_image` から `entry_main_image` に変わった | scan.sh・grep では見つけられない（Ogp モジュールの設定を保存したかは DB にある）。テーマのカスタムフィールド定義に `ogp_image` があるかは grep で探せる | エントリーのカスタムフィールド `ogp_image` で OGP 画像を設定していて、Ogp モジュールの設定を一度も保存していないなら、利用者に `private/config.system.yaml` へ `ogp_image_entry_field_name: ogp_image` を足してもらう（エージェントは `private/` を開かない） | [incompatible.html](https://developer.a-blogcms.jp/document/migration/302x/incompatible.html)、`v3.1.79:ablogcms/private/config.system.default.yaml:434`、`v3.2.38:ablogcms/private/config.system.default.yaml:635` |

## 非推奨になった機能と代替

非推奨の機能は 3.2 でも動く。デバッグモードのとき、モジュールは監査ログ（notice）に、組み込み JS はブラウザーのコンソールに警告が出る（`Acms\Services\Logger\Deprecated::once`、`ACMS.Library.deprecated`）。急がないが、移行のついでに直すと次の版で困らない。代替のモジュール（`Entry_Summary` など）は 3.1 にもあるので、本体を更新する前に置き換えてよい。

| 機能 | 代替 | 見つけ方 | 根拠 |
|---|---|---|---|
| `Entry_List`・`Entry_Headline`・`Entry_Photo` | `Entry_Summary` | `T-DEPRECATED-MODULE`（grep: `BEGIN_MODULE Entry_List`・`BEGIN_MODULE Entry_Headline`・`BEGIN_MODULE Entry_Photo`） | [deprecated.html](https://developer.a-blogcms.jp/document/migration/302x/deprecated.html)、`v3.2.38:ablogcms/php/ACMS/GET/Entry/List.php:73`・`Headline.php:85`・`Photo.php:73` |
| `Category_EntryList` | `Category_EntrySummary` | 同上（grep: `BEGIN_MODULE Category_EntryList`） | `v3.2.38:ablogcms/php/ACMS/GET/Category/EntryList.php:43` |
| `Banner` | `Media_Banner` | 同上（grep: `BEGIN_MODULE Banner`） | `v3.2.38:ablogcms/php/ACMS/GET/Banner.php:10` |
| `User_Profile` | `User_Search` | 同上（grep: `BEGIN_MODULE User_Profile`） | [deprecated.html](https://developer.a-blogcms.jp/document/migration/302x/deprecated.html)（本体は警告を出さない） |
| `Plugin_Schedule` | `Schedule` | 同上（grep: `BEGIN_MODULE Plugin_Schedule`） | `v3.2.38:ablogcms/php/ACMS/GET/Plugin/Schedule.php:15` |
| カート機能（`Shop2_*` の GET・POST モジュール） | Shopping Cart プラグイン（拡張アプリ） | `T-DEPRECATED-SHOP2`（grep: `BEGIN_MODULE Shop2_`・`ACMS_POST_Shop2_`） | [deprecated.html](https://developer.a-blogcms.jp/document/migration/302x/deprecated.html)、`v3.2.38:ablogcms/php/ACMS/GET/Shop2/` 配下の `Deprecated::once` |
| ポストインクルード（`js-post_include` など） | htmx（Ver. 3.2.0 で組み込み JS に追加） | `T-POST-INCLUDE`（grep: `js-post_include`） | [deprecated.html](https://developer.a-blogcms.jp/document/migration/302x/deprecated.html)、`v3.2.38:ablogcms/js/dispatch/postinclude/_postinclude.js:4` |
| Ajax（ポストインクルード・htmx）から呼ぶ `ACMS_POST_2GET` | `ACMS_POST_2GET_Ajax`（Ver. 3.2.0 以降。通常のフォーム送信の 2GET は非推奨ではない） | `T-POST-INCLUDE` の箇所を見る | `v3.2.38:ablogcms/php/ACMS/POST/2GET.php:13-17` |
| 組み込み JS: インクリメンタルサーチ・external form button（`js-external-form-btn`）・マウスオーバー・ロールオーバー・スタイルスイッチ・ゼブラ・テキストの自動選択・日付選択カレンダー・高さ揃え（`js-autoheight-r`）・アコーディオン・スライドトグル（`toggle-head`/`toggle-body`）・タブ・フェーダー | テーマの JavaScript・CSS、HTML の標準機能 | `T-DEPRECATED-BUILTIN-JS`（grep: `js-incremental-search`・`js-external-form-btn`・`js-hover`・`js-rollover`・`imgover`・`styleswitch`・`js-zebra`・`js-click-selection`・`js-datepicker`・`js-autoheight-r`・`js-accordion`・`toggle-head`・`js-tabs`・`js-fader`・`fade-head`） | [deprecated.html](https://developer.a-blogcms.jp/document/migration/302x/deprecated.html)、`v3.2.38:ablogcms/js/dispatch.js` と `ablogcms/js/src/built-in/` の `ACMS.Library.deprecated(` |

リッチエディター・配置 v1・ユニットグループなど、管理画面の設定と入力済みのデータで使う機能の非推奨は、acms-upgrade の `references/to-3.2.md` にある（テーマの修正は要らない）。

## 直す手順

1. 更新前のサイト（3.1）で acms-upgrade の `sh scripts/scan.sh <設置ディレクトリ> 3.2` を実行し、結果を保存する（acms-upgrade がなければ、上の表の「grep:」の文字列で `themes/` を探す）。
2. 本体を更新する前にできること（3.1 のままでよいもの）を先に直す。
   - `T-ACMS-CSS` が出たテーマは、更新前の `themes/system/css/acms.css`・`acms.min.css` をテーマの `css/` にコピーする（更新後は system の中身が 3.2 に置き換わり、旧版を取れなくなる）。
   - `T-DEPRECATED-MODULE`: 代替モジュールへ置き換える。モジュール ID の設定（表示件数・並び順など）は代替モジュール側で作り直す必要があるので、利用者に管理画面での作業を頼む。変数名は代替モジュールの変数表で確かめる（acms-module-reference）。
   - `T-REMOVED-MODULE`・`T-REMOVED-POST`・`T-META-VARS`・`T-REMOVED-BUILTIN-JS`・`T-LITEEDITOR-FEATURE`・`T-FRONT-EDIT`・`T-UNIT-TEMPLATE-REMOVED`: 3.1 でも外してよい記述なので、先に外す。
3. 本体を更新した後に、3.2 の HTML と見比べて直すもの。
   - `T-EMBED-UNIT`・`T-UNIT-SECTION`: 3.2 の `themes/system/_layouts/unit.html` と見比べる。
   - 上書き一覧（scan.sh の最後の節）: テーマで system と同じパスに置いたファイルを、3.2 の system の同じファイルと比べる（`diff themes/system/<パス> themes/<テーマ>/<パス>`）。
   - `T-PRETTIFY`・`T-POST-INCLUDE`（htmx は 3.2.0 から）・`T-DEPRECATED-BUILTIN-JS`。
4. 更新後にもう一度 scan.sh を実行し、`T-` のうち `要確認` 以外の検出が 0 件になったことを確かめる。

記法（`BEGIN_MODULE`、`@include`、Twig）の書き方は acms-template-acms / acms-template-twig を使う。

## 移行後の確認

- エントリーの本文: 画像の横並び・段組み・埋め込みユニット・カスタムユニットの表示。配置 v1 とユニットグループを使っているなら、横並びの上揃え（`hr.clearHidden` の余白）と、ユニットグループ内の `acms-col-*` の左右余白を確かめる（[302x-v1-unit-group-coution.html](https://developer.a-blogcms.jp/document/migration/302x/302x-v1-unit-group-coution.html)）。
- OGP 画像（`meta property="og:image"`）がエントリー詳細で出ているか。
- 廃止・非推奨の組み込み JS を置き換えた箇所（スライダー・画像の拡大表示・高さ揃え・シンタックスハイライトなど）が動くか。ブラウザーのコンソールに非推奨の警告が出ていないか。
- デバッグモードで、監査ログに非推奨モジュールの notice が出ていないか。
- scan.sh を再実行して、`T-` のうち `要確認` 以外が 0 件。

## 参考

- 移行ガイド（Ver. 3.1.x から 3.2.x）: <https://developer.a-blogcms.jp/document/migration/302x/>
- 下位互換性のない変更点: <https://developer.a-blogcms.jp/document/migration/302x/incompatible.html>
- Ver. 3.2.x で推奨されなくなる機能: <https://developer.a-blogcms.jp/document/migration/302x/deprecated.html>
- 改善・修正した変更点: <https://developer.a-blogcms.jp/document/migration/302x/changes.html>
- テーマについて: <https://developer.a-blogcms.jp/document/migration/302x/theme.html>
- 配置 v1 + ユニットグループ有効時の確認事項: <https://developer.a-blogcms.jp/document/migration/302x/302x-v1-unit-group-coution.html>
