# Ver. 3.2 への移行（移行元: Ver. 3.1.x）: プラグイン（拡張アプリ）

公式の移行ガイドは <https://developer.a-blogcms.jp/document/migration/302x/>。このファイルは、そこに書かれた変更（と移行ガイドにない本体ソースの変更）のうち、プラグイン（拡張アプリ）と `extension/acms/` のユーザー拡張（PHP・管理画面の JavaScript）の修正が要るものを、見つけ方と直し方に整理したもの。各項目の説明はリンク先を読む。

見つけ方の `P-` で始まる ID は、acms-upgrade の `scripts/scan.sh` のチェック（定義は acms-upgrade の `scripts/checks/to-3.2.tsv`）。acms-upgrade が入っていないときは、「grep:」に挙げた文字列で `extension/` を探す。`要確認` と付いたチェックは、直す箇所ではなく見比べる箇所を出す。

MySQL の要件、オンラインアップデート、DB の更新など、プラグインに限らない前提は acms-upgrade の `references/to-3.2.md` にある。

## 前提（移行元・PHP などの要件）

| 項目 | 内容 | 根拠 |
|---|---|---|
| 移行元 | Ver. 3.1.x。3.0 以前からは、途中の版の移行ガイドも読む（acms-upgrade の手順 2） | [移行ガイド 3.1.x → 3.2.x](https://developer.a-blogcms.jp/document/migration/302x/) |
| PHP | 3.2 は PHP 8.1 以上。上限はパッチ版で変わるので、動作条件のページで移行先の版の範囲を確かめる。プラグインのコードが PHP 8.1 以上で動くか（PHP 8 系で使えなくなった関数・書き方）を確かめる。scan.sh は PHP の版の違いを調べない | [下位互換性のない変更点](https://developer.a-blogcms.jp/document/migration/302x/incompatible.html)、[動作条件](https://developer.a-blogcms.jp/document/requirements.html) |
| オンラインアップデートと PHP | PHP 8.1 未満のサーバーでは、オンラインアップデートの候補に 3.2 が出ない。PHP を先に上げるときは、3.1 と今のプラグインがその PHP で動くかも確かめる | `v3.1.79:ablogcms/php/ACMS/POST/Update/Exec.php:64-71`（`checkUseCache(phpversion(), $range)`） |
| 配布されているプラグイン（拡張アプリ） | 3.2 対応版が出ているかを配布元で先に確かめる（3.2.0 の時点では全部は対応していない） | [下位互換性のない変更点](https://developer.a-blogcms.jp/document/migration/302x/incompatible.html) |
| 直す場所 | `extension/plugins/` と `extension/acms/` だけを直す。本体の `php/`・`js/` は本体の更新で上書きされるので直さない | [オンラインアップデート](https://developer.a-blogcms.jp/document/update/online-update.html)の「更新されるファイル」（`php`・`js`・`themes/system` などが置き換わる） |

## 下位互換性のない変更

| 変更 | 見つけ方 | 直し方 | 根拠 |
|---|---|---|---|
| SQL ヘルパーの `get()` が SQL 文字列ではなく `['sql' => ..., 'params' => ...]` を返すようになった | `P-SQL-GET-STRING`（grep: `->get(dsn())` の前後で `.` による連結や `"{$sql->get(dsn())}"` のような埋め込みをしている箇所） | `get()` の結果を文字列として連結しない。SQL ヘルパーで条件まで組み立て、`get(dsn())` の結果をそのまま `DB::query()` に渡す（`array` も受け付ける）。SQL 文だけが要るなら `getSQL()`、値は `getParams()` | [incompatible.html](https://developer.a-blogcms.jp/document/migration/302x/incompatible.html)、`v3.2.0:ablogcms/php/SQL.php`（`get()` の戻り値と `getSQL()`）、`v3.2.38:ablogcms/php/Services/Database/Engine/Base.php:112` |
| SQL ヘルパーの `setInsert()`・`setReplace()` を削除 | `P-SQL-SET`（grep: `->setInsert(`・`->setReplace(`） | `setInsert` は `addInsert`、`setReplace` は `addReplace` | `v3.1.53:ablogcms/php/SQL.php:1536,1648` |
| グローバル関数の削除（`loadFulltext`・`createImages`・`uniqueFilePath`・`buildUnitData`・`spreadTemplate` など） | `P-REMOVED-FUNCTION`（grep: `buildUnitData(`・`createImages(`・`explodeUnitData(`・`implodeUnitData(`・`loadFulltext(`・`uniqueFilePath(`・`spreadTemplate(`・`setTemplateComment(`・`includeCommentBegin(`・`includeCommentEnd(`・`extendTemplate(`・`resolveSection(`・`resolvePath(`・`rewritePath(`・`get403HtmlString(`。`Image::createImages(` のようなメソッド呼び出しは対象外） | ファサードのメソッドに置き換える。例: `createImages` → `Image::createImages`、`uniqueFilePath` → `Storage::uniqueFilePath`、`loadFulltext` → `Common::loadEntryFulltext`（Ver. 3.2.29 以降は `Fulltext::loadEntryFulltext` を使う）。引数はパッチ版の間でも変わることがあるので、移行先の版の `php/Services/Facades/` の注釈で確かめる | `v3.1.53` と `v3.2.0` の `ablogcms/php` の `^function` の比較、`v3.2.38:ablogcms/php/Services/Facades/Image.php:19`、`v3.2.38:ablogcms/php/Services/Facades/Storage.php` |
| 削除されたクラス（`Acms\Services\Facades\Api`・`Acms\Services\SocialLogin\Facebook`・`MysqliEngine`） | `P-REMOVED-SERVICE`（grep: `Facades\Api`・`SocialLogin\Facebook`・`MysqliEngine`） | 使っている箇所を外す。DB は PDO のエンジンだけになった | `git diff --diff-filter=D --name-only v3.1.53 v3.2.0 -- ablogcms/php/Services` |
| 削除された GET・POST モジュールのクラス（トラックバック・Facebook ログイン・`Case_*`・`Column_List`・`Filter_*`・承認系などの `Touch_*`・表側のダイレクト編集・`Ajax_Unit`・`Update_ExecDB` など。承認系の Touch モジュールの一部は Ver. 3.2.20 で削除） | `P-REMOVED-CLASS`（grep: `ACMS_GET_Trackback_`・`ACMS_POST_Trackback_`・`Member_Sns_Facebook_`・`Member_Admin_Login_Facebook`・`ACMS_GET_Case_`・`ACMS_GET_Column_List`・`ACMS_GET_Filter`・`ACMS_GET_Touch_`・`ACMS_POST_Entry_Direct`・`ACMS_POST_Entry_Add`・`ACMS_POST_Unit_Sort`・`ACMS_POST_Through`・`ACMS_GET_Ajax_Unit`・`ACMS_POST_Update_ExecDB`） | 継承・呼び出しをやめ、移行先の版のソースで代わりを探す。Facebook 以外の SNS ログイン（Google・X・LINE）は残っている | [incompatible.html](https://developer.a-blogcms.jp/document/migration/302x/incompatible.html)、`git diff --diff-filter=D --name-only v3.1.79 v3.2.38 -- ablogcms/php/ACMS/GET ablogcms/php/ACMS/POST` |
| 標準の GET モジュールの内部を整理 | `P-EXTENDS-GET`（要確認。grep: `extends ACMS_GET_`） | 標準の GET モジュールを継承した独自モジュールは、オーバーライドしたメソッドが今も呼ばれるかを検証環境で確かめる。V2 モジュールや独自の実装へ移すことも検討する | [incompatible.html](https://developer.a-blogcms.jp/document/migration/302x/incompatible.html) |
| 引用ユニットが埋め込みユニットになった（Hook の名前） | grep: `extendsQuoteUnit` | Hook `extendsQuoteUnit` は Ver. 3.2.29 以降も呼ばれる（同じ版で `extendsEmbedUnit` が増え、後に呼ばれる）。新しく書くなら移行先の版の `extension/acms/Hook.php` で使える Hook を確かめる | [incompatible.html](https://developer.a-blogcms.jp/document/migration/302x/incompatible.html)、`v3.2.38:ablogcms/php/Services/Unit/Models/Embed.php:160-162` |
| Ver. 2.7 以前のテキストユニットに戻す設定（`ACMS.Config.LiteEditorFeature = false`）を廃止 | `T-LITEEDITOR-FEATURE`（`extension/` も探す。grep: `LiteEditorFeature`） | 記述を消す | [incompatible.html](https://developer.a-blogcms.jp/document/migration/302x/incompatible.html) |

## 非推奨になった機能と代替

非推奨の機能は 3.2 でも動く。デバッグモードのとき、PHP 側は監査ログ（notice）に警告が出る（`Acms\Services\Logger\Deprecated::once`）。急がないが、移行のついでに直すと次の版で困らない。代替のモジュール（`Entry_Summary` など）は 3.1 にもあるので、本体を更新する前に移してよい。

| 機能 | 代替 | 見つけ方 | 根拠 |
|---|---|---|---|
| `ACMS_GET_Entry_List`・`ACMS_GET_Entry_Headline`・`ACMS_GET_Entry_Photo` の継承・利用 | `Entry_Summary` | `P-DEPRECATED-CLASS`（grep: `ACMS_GET_Entry_List`・`ACMS_GET_Entry_Headline`・`ACMS_GET_Entry_Photo`） | [deprecated.html](https://developer.a-blogcms.jp/document/migration/302x/deprecated.html)、`v3.2.38:ablogcms/php/ACMS/GET/Entry/List.php:73`・`Headline.php:85`・`Photo.php:73` |
| `ACMS_GET_Category_EntryList`・`ACMS_GET_Banner`・`ACMS_GET_User_Profile`・`ACMS_GET_Plugin_Schedule` | `Category_EntrySummary`・`Media_Banner`・`User_Search`・`Schedule` | 同上（grep: クラス名） | [deprecated.html](https://developer.a-blogcms.jp/document/migration/302x/deprecated.html)、`v3.2.38:ablogcms/php/ACMS/GET/Category/EntryList.php:43`・`Banner.php:10`・`Plugin/Schedule.php:15` |
| カート機能（`ACMS_GET_Shop2_*`・`ACMS_POST_Shop2_*`） | Shopping Cart プラグイン（拡張アプリ） | 同上（grep: `_Shop2_`） | [deprecated.html](https://developer.a-blogcms.jp/document/migration/302x/deprecated.html)、`v3.2.38:ablogcms/php/ACMS/GET/Shop2/` 配下の `Deprecated::once` |
| ping 送信（`ACMS_POST_PingWeblogUpdate`） | なし | 同上（grep: `PingWeblogUpdate`） | `v3.2.38:ablogcms/php/ACMS/POST/PingWeblogUpdate.php:19` |

## 直す手順

1. 配布されているプラグインは、3.2 対応版があるかを配布元で確かめ、あれば差し替える。対応版がないものは検証環境で動作を確かめるまで本番で有効にしない。
2. 自作のプラグインと `extension/acms/` の独自モジュール・Hook は、更新前のサイト（3.1）で acms-upgrade の `sh scripts/scan.sh <設置ディレクトリ> 3.2` を実行し、`P-*` を直す（acms-upgrade がなければ、上の表の「grep:」の文字列で `extension/` を探す）。
   - `P-SQL-GET-STRING`・`P-SQL-SET`: SQL ヘルパーの使い方を直す（上の表）。
   - `P-REMOVED-FUNCTION`・`P-REMOVED-CLASS`・`P-REMOVED-SERVICE`: 移行先の版のソースで代わりを探して置き換える。
   - `P-EXTENDS-GET`（要確認）・`P-DEPRECATED-CLASS`: 継承元の変更の影響を検証環境で確かめる。
3. PHP 8.1 以上で動くかを確かめる（PHP 8 系で使えなくなった関数・書き方）。scan.sh は PHP の版の違いを調べない。検証環境でデバッグモードにして、エラーと警告が出ないかを見る。
4. 更新後にもう一度 scan.sh を実行し、`P-` のうち `要確認` 以外の検出が 0 件になったことを確かめる。

Hook・ServiceProvider・独自モジュールの書き方は acms-plugin-development、管理画面の JavaScript プラグインの書き方は acms-admin-frontend-plugin を使う。

## 移行後の確認

- 検証環境でデバッグモードにして、プラグインの機能を使うページと管理画面の設定ページを開き、エラー・警告が出ないかを見る。
- 監査ログに error・warning と非推奨の notice が出ていないか。
- scan.sh を再実行して、`P-` のうち `要確認` 以外が 0 件。

## 参考

- 移行ガイド（Ver. 3.1.x から 3.2.x）: <https://developer.a-blogcms.jp/document/migration/302x/>
- 下位互換性のない変更点: <https://developer.a-blogcms.jp/document/migration/302x/incompatible.html>
- Ver. 3.2.x で推奨されなくなる機能: <https://developer.a-blogcms.jp/document/migration/302x/deprecated.html>
- 動作条件: <https://developer.a-blogcms.jp/document/requirements.html>
- プラグイン（拡張アプリ）: <https://developer.a-blogcms.jp/document/develop_apps/>
