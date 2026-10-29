# Ver. 3.2 への移行（移行元: Ver. 3.1.x）

公式の移行ガイドは <https://developer.a-blogcms.jp/document/migration/302x/>。このファイルは、そこに書かれた変更のうちテーマ・プラグイン（拡張アプリ）の修正が要るものを、見つけ方（`scripts/scan.sh` のチェック ID）と直し方に整理したもの。各項目の説明はリンク先を読む。

チェック ID の定義は `scripts/checks/to-3.2.tsv`。`要確認` と付いたチェックは、直す箇所ではなく見比べる箇所を出す。

## 前提（移行元・PHP などの要件）

| 項目 | 内容 | 根拠 |
|---|---|---|
| 移行元 | Ver. 3.1.x。3.0 以前からは、途中の版の移行ガイドも読む（SKILL.md の手順 2） | [移行ガイド 3.1.x → 3.2.x](https://developer.a-blogcms.jp/document/migration/302x/) |
| PHP | 3.2 は PHP 8.1 以上。上限はパッチ版で変わるので、動作条件のページで移行先の版の範囲を確かめる | [下位互換性のない変更点](https://developer.a-blogcms.jp/document/migration/302x/incompatible.html)、[動作条件](https://developer.a-blogcms.jp/document/requirements.html) |
| MySQL | MySQL 8.0 以上（MariaDB は動作条件のページの版） | 同上 |
| オンラインアップデートと PHP | 更新の候補は、サーバーの PHP の版に合うパッケージから選ばれる。PHP 8.1 未満のままでは 3.2 が候補に出ないので、先に PHP を上げられるか（3.1 がその PHP で動くか）をサーバーの管理者と決める | `v3.1.79:ablogcms/php/ACMS/POST/Update/Exec.php:64-71`（`checkUseCache(phpversion(), $range)`）、`v3.1.79:ablogcms/php/Services/Update/System/CheckForUpdate.php:431-448` |
| オンラインアップデートの範囲 | 3.1 → 3.2 はマイナーバージョンアップ。管理画面 > コンフィグ > 機能設定の「オンラインアップデート」を「マイナーバージョンも含める」にしないと候補に出ない | `v3.1.79:ablogcms/php/ACMS/POST/Update/Exec.php:64-67`（`system_update_range`）、[オンラインアップデート](https://developer.a-blogcms.jp/document/update/online-update.html) |
| DB の変換 | 3.2.0 より前からの DB 更新で、カスタムユニットのデータの保存先の移動と、非表示にしたユニットの持ち方の変換が行われる。元に戻すには DB のバックアップから戻すしかない | `v3.2.38:ablogcms/php/Services/Update/Database/Rule.php:427-438`（`update320()`） |
| プラグイン（拡張アプリ） | 配布されているプラグインは 3.2 対応版が出ているかを先に確かめる（3.2.0 の時点では全部は対応していない） | [下位互換性のない変更点](https://developer.a-blogcms.jp/document/migration/302x/incompatible.html) |

## 下位互換性のない変更

| 変更 | 見つけ方 | 直し方 | 根拠 |
|---|---|---|---|
| ユニットのレイアウトが float から Flexbox・CSS Grid に変わり、`acms.css` のユニットのスタイルが変わった | `T-ACMS-CSS`（要確認）、`T-UNIT-SECTION`（要確認）、上書き一覧 | 本体を更新する**前に**、更新前の `themes/system/css/acms.css` と `acms.min.css` を利用中のテーマの `css/` にコピーする（テーマ側が優先されるため、旧スタイルが残る）。ユニットの CSS を自前で書いているなら不要。コピーした旧 `acms.css` には 3.2 で増えたクラス（`acms-cssgrid` など）がないので、新しいユニットの見た目は別に確かめる | [incompatible.html](https://developer.a-blogcms.jp/document/migration/302x/incompatible.html)、`v3.1.79` の `themes/system/src` に `acms-cssgrid` がないこと（`git grep -c acms-cssgrid v3.1.79 -- ablogcms/themes/system/src` が 0 件） |
| 配置 v1 とユニットグループを有効のまま使うと、段組みで余白がずれることがある | scan.sh では見つけられない。表示で確かめる | 「移行後の確認」の 2 項目（横並びの上揃え・ユニットグループ内の左右余白）を見る。更新したサイトは互換のため配置 v1・ユニットグループ有効のまま（`unit_align_version: 'v1'`、`unit_group: on` が既定） | [302x-v1-unit-group-coution.html](https://developer.a-blogcms.jp/document/migration/302x/302x-v1-unit-group-coution.html)、`v3.2.38:ablogcms/private/config.system.default.yaml:1536,1553` |
| 引用ユニットが埋め込みユニットになり、HTML が `blockquote` から `a` 要素に変わった | `T-EMBED-UNIT` | 旧クラス（`column-quote-*`、`quoteTitleLink`）向けの CSS を、3.2 の `themes/system/_layouts/unit.html` の `unit#quote` の HTML（`column-embed`、`acms-embed-link`）に合わせて書き直す。テーマで `@section(quote-unit)` を上書きしているなら、その HTML も見直す。プラグインの Hook `extendsQuoteUnit` は Ver. 3.2.29 以降も呼ばれる（同じ版で `extendsEmbedUnit` が増えた） | [incompatible.html](https://developer.a-blogcms.jp/document/migration/302x/incompatible.html)、`v3.2.38:ablogcms/themes/system/_layouts/unit.html:649-677`、`v3.2.38:ablogcms/php/Services/Unit/Models/Embed.php:160-162` |
| 組み込み JS の一部を廃止（高さ揃え・prettyPhoto・Highslide・bxSlider・アダプティブイメージ・プレースホルダー・biggerlink など） | `T-REMOVED-BUILTIN-JS` | クラスを付けても何も起きなくなる。テーマの JavaScript・CSS で代わりを用意するか、記述を消す。`js-autoheight` は廃止、`js-autoheight-r` は非推奨（別の行） | [incompatible.html](https://developer.a-blogcms.jp/document/migration/302x/incompatible.html)、`v3.1.79:ablogcms/js/config.js` と `v3.2.0:ablogcms/js/config.js` の比較（`autoHeightMark`・`biggerlinkMark`・`ppMark`・`hsMark` などが 3.2.0 で消えた） |
| 上の一覧に載っていないが、`.js-toggle`（`toggleMark`）・`.js-fader-storage`・`.js-external_submit`（`externalFormButtonMark`）も 3.2.0 で消えた | `T-REMOVED-BUILTIN-JS` | 同上 | `v3.1.79:ablogcms/js/config.js:850,867,1296` にあり、`v3.2.0:ablogcms/js/config.js` にないこと |
| SSL への書き換え（`js-link_no_rewrite` など）を廃止 | 対象外（クラスが残っていても害はない） | 消さなくてよい | [incompatible.html](https://developer.a-blogcms.jp/document/migration/302x/incompatible.html) |
| シンタックスハイライトが Google Code Prettify から highlight.js に変わった | `T-PRETTIFY` | `prettyprint` クラスでは色が付かない。既定では `pre` 要素が対象（`ACMS.Config.highlightMark`）。テーマや色は `ACMS.Config.highlightConfig` で変える | [changes.html](https://developer.a-blogcms.jp/document/migration/302x/changes.html)、`v3.2.0:ablogcms/js/config.js:34` |
| グローバル変数 `%{META_KEYWORDS}`・`%{META_DESCRIPTION}` を廃止 | `T-META-VARS` | 空になる。カスタムフィールドなど別の値から出す | [incompatible.html](https://developer.a-blogcms.jp/document/migration/302x/incompatible.html)、`v3.1.79:ablogcms/php/ACMS/function.php:6585` にあり 3.2 にないこと |
| トラックバック・Facebook ログインを廃止 | `T-REMOVED-MODULE`、`T-REMOVED-POST`、`P-REMOVED-CLASS`、`P-REMOVED-SERVICE` | モジュール・フォーム・ボタンごと外す。Facebook 以外の SNS ログイン（Google・X・LINE）は残っている | [incompatible.html](https://developer.a-blogcms.jp/document/migration/302x/incompatible.html)、`git diff --diff-filter=D v3.1.53 v3.2.0 -- ablogcms/php/ACMS/GET ablogcms/php/ACMS/POST` |
| 表側のエントリー編集画面を廃止（管理画面で編集する） | `T-FRONT-EDIT` | `@include("/admin/entry/title.html")`・`@include("/admin/entry/edit-%{IS_ADMIN}.html")` を消す（`themes/system` から削除済み）。`template.yaml` の `tpl_entry_edit` も使われないので消す。`/admin/entry/action.html` と `revision-info.html` は 3.2 の公式テーマでも使っているので残す | [changes.html](https://developer.a-blogcms.jp/document/migration/302x/changes.html)、`v3.2.38:ablogcms/themes/blog/include/entry-body.html:11,86` |
| 未使用のモジュールを削除（`Case_Auth`・`Case_Ua`・`Case_View`・`Column_List`・`Filter_*`・`Touch_EditDirect` など。承認系の Touch モジュールの一部は Ver. 3.2.20 で削除） | `T-REMOVED-MODULE`、`P-REMOVED-CLASS` | ブロックごと外すか、別のモジュール・Touch モジュールで書き直す | `git diff --diff-filter=D --name-only v3.1.79 v3.2.38 -- ablogcms/php/ACMS/GET ablogcms/php/ACMS/POST` |
| AMP 用のユニットのテンプレート（`include/unit-amp.html`・`_layouts/unit-amp.html`）と多言語ユニットのサンプル（`unit_language.html`）を `themes/system` から削除 | `T-UNIT-TEMPLATE-REMOVED` | `@include` / `@extends` を外す。使い続けるなら、更新前の system からテーマ内にコピーして自分で保守する | `git log --diff-filter=D v3.1.53..v3.2.0 -- ablogcms/themes/system/include/unit-amp.html ablogcms/themes/system/include/unit_language.html` |
| Ver. 2.7 以前のテキストユニットに戻す設定（`ACMS.Config.LiteEditorFeature = false`）を廃止 | `T-LITEEDITOR-FEATURE` | 記述を消す | [incompatible.html](https://developer.a-blogcms.jp/document/migration/302x/incompatible.html) |
| Ogp モジュールがエントリーから読む画像フィールドの既定が `ogp_image` から `entry_main_image` に変わった | scan.sh では見つけられない（Ogp モジュールの設定を保存したかは DB にある） | エントリーのカスタムフィールド `ogp_image` で OGP 画像を設定していて、Ogp モジュールの設定を一度も保存していないなら、利用者に `private/config.system.yaml` へ `ogp_image_entry_field_name: ogp_image` を足してもらう（エージェントは `private/` を開かない） | [incompatible.html](https://developer.a-blogcms.jp/document/migration/302x/incompatible.html)、`v3.1.79:ablogcms/private/config.system.default.yaml:434`、`v3.2.38:ablogcms/private/config.system.default.yaml:635` |
| 標準の GET モジュールの内部を整理 | `P-EXTENDS-GET`（要確認） | 標準の GET モジュールを継承した独自モジュールは、オーバーライドしたメソッドが今も呼ばれるかを検証環境で確かめる。V2 モジュールや独自の実装へ移すことも検討する | [incompatible.html](https://developer.a-blogcms.jp/document/migration/302x/incompatible.html) |
| SQL ヘルパーの `get()` が SQL 文字列ではなく `['sql' => ..., 'params' => ...]` を返すようになった。`setInsert()`・`setReplace()` を削除 | `P-SQL-GET-STRING`、`P-SQL-SET` | `get()` の結果を文字列として連結しない。SQL ヘルパーで条件まで組み立て、`get(dsn())` の結果をそのまま `DB::query()` に渡す（`array` も受け付ける）。SQL 文だけが要るなら `getSQL()`、値は `getParams()`。`setInsert` は `addInsert`、`setReplace` は `addReplace` | [incompatible.html](https://developer.a-blogcms.jp/document/migration/302x/incompatible.html)、`v3.2.0:ablogcms/php/SQL.php`（`get()` の戻り値と `getSQL()`）、`v3.2.38:ablogcms/php/Services/Database/Engine/Base.php:112`、`v3.1.53:ablogcms/php/SQL.php:1536,1648` |
| グローバル関数の削除（`loadFulltext`・`createImages`・`uniqueFilePath`・`buildUnitData`・`spreadTemplate` など） | `P-REMOVED-FUNCTION` | ファサードのメソッドに置き換える。例: `createImages` → `Image::createImages`、`uniqueFilePath` → `Storage::uniqueFilePath`、`loadFulltext` → `Common::loadEntryFulltext`（Ver. 3.2.29 以降は `Fulltext::loadEntryFulltext` を使う）。引数はパッチ版の間でも変わることがあるので、移行先の版の `php/Services/Facades/` の注釈で確かめる | `v3.1.53` と `v3.2.0` の `ablogcms/php` の `^function` の比較、`v3.2.38:ablogcms/php/Services/Facades/Image.php:19`、`v3.2.38:ablogcms/php/Services/Facades/Storage.php` |
| 削除されたクラス（`Acms\Services\Facades\Api`・`Acms\Services\SocialLogin\Facebook`・`MysqliEngine`） | `P-REMOVED-SERVICE` | 使っている箇所を外す。DB は PDO のエンジンだけになった | `git diff --diff-filter=D --name-only v3.1.53 v3.2.0 -- ablogcms/php/Services` |

## 非推奨になった機能と代替

非推奨の機能は 3.2 でも動く。デバッグモードのとき、PHP 側は監査ログ（notice）に、組み込み JS はブラウザーのコンソールに警告が出る（`Acms\Services\Logger\Deprecated::once`、`ACMS.Library.deprecated`）。急がないが、移行のついでに直すと次の版で困らない。代替のモジュール（`Entry_Summary` など）は 3.1 にもあるので、本体を更新する前に置き換えてよい。

| 機能 | 代替 | 見つけ方 | 根拠 |
|---|---|---|---|
| `Entry_List`・`Entry_Headline`・`Entry_Photo` | `Entry_Summary` | `T-DEPRECATED-MODULE`、`P-DEPRECATED-CLASS` | [deprecated.html](https://developer.a-blogcms.jp/document/migration/302x/deprecated.html)、`v3.2.38:ablogcms/php/ACMS/GET/Entry/List.php:73`・`Headline.php:85`・`Photo.php:73` |
| `Category_EntryList` | `Category_EntrySummary` | 同上 | `v3.2.38:ablogcms/php/ACMS/GET/Category/EntryList.php:43` |
| `Banner` | `Media_Banner` | 同上 | `v3.2.38:ablogcms/php/ACMS/GET/Banner.php:10` |
| `User_Profile` | `User_Search` | 同上 | [deprecated.html](https://developer.a-blogcms.jp/document/migration/302x/deprecated.html)（本体は警告を出さない） |
| `Plugin_Schedule` | `Schedule` | 同上 | `v3.2.38:ablogcms/php/ACMS/GET/Plugin/Schedule.php:15` |
| カート機能（`Shop2_*` の GET・POST モジュール） | Shopping Cart プラグイン（拡張アプリ） | `T-DEPRECATED-SHOP2`、`P-DEPRECATED-CLASS` | [deprecated.html](https://developer.a-blogcms.jp/document/migration/302x/deprecated.html)、`v3.2.38:ablogcms/php/ACMS/GET/Shop2/` 配下の `Deprecated::once` |
| ポストインクルード（`js-post_include` など） | htmx（Ver. 3.2.0 で組み込み JS に追加） | `T-POST-INCLUDE` | [deprecated.html](https://developer.a-blogcms.jp/document/migration/302x/deprecated.html)、`v3.2.38:ablogcms/js/dispatch/postinclude/_postinclude.js:4` |
| Ajax（ポストインクルード・htmx）から呼ぶ `ACMS_POST_2GET` | `ACMS_POST_2GET_Ajax`（Ver. 3.2.0 以降。通常のフォーム送信の 2GET は非推奨ではない） | `T-POST-INCLUDE` の箇所を見る | `v3.2.38:ablogcms/php/ACMS/POST/2GET.php:13-17` |
| ping 送信（`ACMS_POST_PingWeblogUpdate`） | なし | `P-DEPRECATED-CLASS` | `v3.2.38:ablogcms/php/ACMS/POST/PingWeblogUpdate.php:19` |
| 組み込み JS: インクリメンタルサーチ・external form button（`js-external-form-btn`）・マウスオーバー・ロールオーバー・スタイルスイッチ・ゼブラ・テキストの自動選択・日付選択カレンダー・高さ揃え（`js-autoheight-r`）・アコーディオン・スライドトグル（`toggle-head`/`toggle-body`）・タブ・フェーダー | テーマの JavaScript・CSS、HTML の標準機能 | `T-DEPRECATED-BUILTIN-JS` | [deprecated.html](https://developer.a-blogcms.jp/document/migration/302x/deprecated.html)、`v3.2.38:ablogcms/js/dispatch.js` と `ablogcms/js/src/built-in/` の `ACMS.Library.deprecated(` |
| リッチエディター、テキストユニットのタグセレクト（pre・none・markdown・wysiwyg）、多言語ユニット、ユニットグループ、配置 v1 | ブロックエディター、各ユニット、グループユニット、配置 v2 | scan.sh では見つけられない（管理画面の設定と入力済みのデータ）。既存のデータはそのまま使えるので、移行の作業には含めない | [deprecated.html](https://developer.a-blogcms.jp/document/migration/302x/deprecated.html) |

## テーマで直すこと

1. 更新前のサイト（3.1）で `sh scripts/scan.sh <設置ディレクトリ> 3.2` を実行し、結果を保存する。
2. 本体を更新する前にできること（3.1 のままでよいもの）を先に直す。
   - `T-ACMS-CSS` が出たテーマは、更新前の `themes/system/css/acms.css`・`acms.min.css` をテーマの `css/` にコピーする（更新後は system の中身が 3.2 に置き換わり、旧版を取れなくなる）。
   - `T-DEPRECATED-MODULE`: 代替モジュールへ置き換える。モジュール ID の設定（表示件数・並び順など）は代替モジュール側で作り直す必要があるので、利用者に管理画面での作業を頼む。変数名は代替モジュールの変数表で確かめる（acms-module-reference）。
   - `T-REMOVED-MODULE`・`T-REMOVED-POST`・`T-META-VARS`・`T-REMOVED-BUILTIN-JS`・`T-LITEEDITOR-FEATURE`・`T-FRONT-EDIT`・`T-UNIT-TEMPLATE-REMOVED`: 3.1 でも外してよい記述なので、先に外す。
3. 本体を更新した後に、3.2 の HTML と見比べて直すもの。
   - `T-EMBED-UNIT`・`T-UNIT-SECTION`: 3.2 の `themes/system/_layouts/unit.html` と見比べる。
   - 上書き一覧（scan.sh の最後の節）: テーマで system と同じパスに置いたファイルを、3.2 の system の同じファイルと比べる（`diff themes/system/<パス> themes/<テーマ>/<パス>`）。
   - `T-PRETTIFY`・`T-POST-INCLUDE`（htmx は 3.2.0 から）・`T-DEPRECATED-BUILTIN-JS`。
4. 更新後にもう一度 scan.sh を実行し、`要確認` 以外の検出が 0 件になったことを確かめる。

記法（`BEGIN_MODULE`、`@include`、Twig）の書き方は acms-template-acms / acms-template-twig を使う。

## プラグイン（拡張アプリ）で直すこと

1. 配布されているプラグインは、3.2 対応版があるかを配布元で確かめ、あれば差し替える。対応版がないものは検証環境で動作を確かめるまで本番で有効にしない。
2. 自作のプラグインと `extension/acms/` の独自モジュール・Hook は、scan.sh の `P-*` を直す。
   - `P-SQL-GET-STRING`・`P-SQL-SET`: SQL ヘルパーの使い方を直す（上の表）。
   - `P-REMOVED-FUNCTION`・`P-REMOVED-CLASS`・`P-REMOVED-SERVICE`: 移行先の版のソースで代わりを探して置き換える。
   - `P-EXTENDS-GET`（要確認）・`P-DEPRECATED-CLASS`: 継承元の変更の影響を検証環境で確かめる。
3. PHP 8.1 以上で動くかを確かめる（PHP 8 系で使えなくなった関数・書き方）。scan.sh は PHP の版の違いを調べない。検証環境でデバッグモードにして、エラーと警告が出ないかを見る。

Hook・ServiceProvider・独自モジュールの書き方は acms-plugin-development を使う。

## 移行後の確認

- 管理画面のユーザー設定でデバッグモードにして、主要なページ（トップ・一覧・詳細・フォーム・検索・会員ページ）をログイン時とログアウト時の両方で見る。
- 監査ログに error・warning と非推奨の notice が出ていないか、ブラウザーのコンソールに非推奨の警告が出ていないかを見る。
- エントリーの本文: 画像の横並び・段組み・埋め込みユニット・カスタムユニットの表示。配置 v1 とユニットグループを使っているなら、横並びの上揃え（`hr.clearHidden` の余白）と、ユニットグループ内の `acms-col-*` の左右余白を確かめる（[302x-v1-unit-group-coution.html](https://developer.a-blogcms.jp/document/migration/302x/302x-v1-unit-group-coution.html)）。
- 非表示にしていたユニットが非表示のままか（DB 更新で持ち方が変わる）。
- OGP 画像（`meta property="og:image"`）がエントリー詳細で出ているか。
- エントリー管理画面: 3.2 で新しくなった。独自に直していて旧画面に戻したいなら、利用者に `private/config.system.yaml` へ `entry_admin_page_version: 1` を足してもらう（[changes.html](https://developer.a-blogcms.jp/document/migration/302x/changes.html)）。
- `scripts/scan.sh` を再実行して、`要確認` 以外が 0 件。

## 参考

- 移行ガイド（Ver. 3.1.x から 3.2.x）: <https://developer.a-blogcms.jp/document/migration/302x/>
- 下位互換性のない変更点: <https://developer.a-blogcms.jp/document/migration/302x/incompatible.html>
- Ver. 3.2.x で推奨されなくなる機能: <https://developer.a-blogcms.jp/document/migration/302x/deprecated.html>
- 改善・修正した変更点: <https://developer.a-blogcms.jp/document/migration/302x/changes.html>
- 新機能: <https://developer.a-blogcms.jp/document/migration/302x/new-features.html>
- テーマについて: <https://developer.a-blogcms.jp/document/migration/302x/theme.html>
- 配置 v1 + ユニットグループ有効時の確認事項: <https://developer.a-blogcms.jp/document/migration/302x/302x-v1-unit-group-coution.html>
- 動作条件: <https://developer.a-blogcms.jp/document/requirements.html>
