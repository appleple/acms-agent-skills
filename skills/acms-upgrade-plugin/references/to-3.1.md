# Ver. 3.1 への移行（移行元: Ver. 3.0.x）: プラグイン（拡張アプリ）

公式の移行ガイドは <https://developer.a-blogcms.jp/document/migration/301x/>。ガイドには PHP の API の変更が書かれていないので、このファイルは本体ソースの差分（v3.0.68 と v3.1.80。3.1.x の途中で入ったものは「Ver. 3.1.NN 以降」）から、プラグイン（拡張アプリ）と `extension/acms/` のユーザー拡張（Hook・独自モジュール・校正オプション・検証オプション・ServiceProvider）の修正が要るものを洗い出して整理した。3.1.x の途中で消えた・変わったものが多いので、移行先のパッチバージョンのソースで最後に確かめる。

見つけ方の `P-` で始まる ID は、acms-upgrade の `scripts/scan.sh` のチェック（定義は acms-upgrade の `scripts/checks/to-3.1.tsv`）。acms-upgrade が入っていないときは、「grep:」に挙げた正規表現で `extension/` を `grep -rnE --include='*.php'` する。`要確認` と付いたチェックは、直す箇所ではなく見比べる箇所を出す。

要件・更新の方法・ライセンス・設定値・DB は acms-upgrade の `references/to-3.1.md`、テンプレートは acms-upgrade-theme の `references/to-3.1.md` にある。

## 前提（移行元・PHP などの要件）

| 項目 | 内容 | 根拠 |
|---|---|---|
| 移行元 | Ver. 3.0.x | [移行ガイド 3.0.x → 3.1.x](https://developer.a-blogcms.jp/document/migration/301x/) |
| PHP | 3.1.80 は 7.3.0 以上 8.4.0 未満（最低 7.3 は Ver. 3.1.7 以降、8.2・8.3 は Ver. 3.1.14 以降）。プラグインが PHP 7.4 以降の書き方（型付きプロパティ・アロー関数）を使っていると PHP 7.3 では動かない。PHP 8.2 に上げるなら、宣言していないプロパティへの代入（動的プロパティ）が非推奨の警告になる（`ACMS_GET`・`ACMS_POST` に `#[AllowDynamicProperties]` はない）。scan.sh は PHP のバージョンの違いを調べないので、検証環境で E_ALL の警告を見る | `v3.1.80:ablogcms/php/Application.php:99-100`、`v3.1.80:ablogcms/php/Field.php:8` |
| 配布されているプラグイン（拡張アプリ） | 3.1 対応バージョンが出ているかを配布元で先に確かめる | — |
| 直す場所 | `extension/plugins/` と `extension/acms/` だけを直す。本体の `php/` は直さない | [オンラインアップデート](https://developer.a-blogcms.jp/document/update/online-update.html)の「更新されるファイル」 |
| プラグインの読み込み | ServiceProvider の読み込み方（`init()`）、`Acms\Plugins\`・`Acms\Custom\` の名前空間、Hook の呼び出し方（`method_exists` で呼ぶ）は 3.0 と同じ | `v3.0.68:ablogcms/php/main.php:1263-1282`、`v3.1.80:ablogcms/php/main.php:1493-1512` |

## 下位互換性のない変更

変わったものを、クラス・継承・メソッドの引数・グローバル関数・定数・ライブラリの 6 つに分ける。どれも `extension/` の文字列から探せる。

### 1. 削除されたクラス

継承・`new` していると Class not found（Fatal）になる。

| 削除されたもの | 代わり | 見つけ方 | 根拠 |
|---|---|---|---|
| ログイン: `ACMS_GET_Login`、`ACMS_POST_Login`（と同じファイルの `ACMS_Validator_Login`）、`ACMS_POST_Login_Auth`・`_Remind`・`_ResetPassword`・`_Subscribe`・`_Tfa_*`、`ACMS_GET_Admin_User_Sns`・`ACMS_GET_Admin_User_Tfa` | `ACMS_GET_Member_*`・`ACMS_POST_Member_*`（基底は `ACMS_GET_Member`・`ACMS_POST_Member`。対応は acms-upgrade-theme の `to-3.1.md` の 2 章の表）、検証は `Acms\Services\Validator\Signin`。`ACMS_POST_Login_TerminalRestriction` は残る | `P-REMOVED-AUTH-CLASS`（grep: `ACMS_GET_Login([^A-Za-z0-9_]\|$)\|ACMS_POST_Login(_(Auth\|Subscribe\|Remind\|ResetPassword\|Tfa_[A-Za-z]+))?([^A-Za-z0-9_]\|$)\|ACMS_Validator_Login\|ACMS_GET_Admin_User_(Sns\|Tfa)`） | `git diff --diff-filter=D --name-only v3.0.28 v3.1.0 -- ablogcms/php/ACMS` |
| 外部サービス連携: `ACMS_GET_Api` と配下すべて、`ACMS_POST_Api` と配下すべて、`ACMS_Services_Twitter`・`ACMS_Services_Amazon`、`php/OAuth.php`（`OAuth_Client` など）、`Acms\Services\SocialLogin\Base`・`SocialLogin\Exceptions\*`。`ACMS_Services`（基底）は Ver. 3.1.3 で削除 | `ACMS_POST_Api::addUserFromOauth()` は `Login::addUserFromOauth($data)`、`userIconFromUri()` は `Login::userIconFromUri($uri)`。SNS のコールバックは `ACMS_GET_Member_Sns_Callback_*`。API の応答のキャッシュは Cache ファサードで自作する | `P-REMOVED-AUTH-CLASS`（grep: `ACMS_(GET\|POST)_Api([^A-Za-z0-9]\|$)\|SocialLogin\\(Base\|Exceptions)\|OAuth_(Client\|RequestToken\|AccessToken)`）、`P-REMOVED-CLASS`（grep: `ACMS_Services([^A-Za-z0-9]\|$)`） | `v3.0.68:ablogcms/php/ACMS/POST/Api.php`、`v3.1.0:ablogcms/php/Services/Login/Helper.php` |
| `Acms\Services\Login\Engine`（`Acms\Services\Login\Tfa` に改名。サービス名 `login.tfa` と Tfa ファサードは同じ） | `Acms\Services\Login\Tfa` | `P-REMOVED-AUTH-CLASS`（grep: `Services\\Login\\Engine`） | `v3.1.80:ablogcms/php/Services/Login/LoginServiceProvider.php` |
| 3.1.x の途中で削除: 旧ショップ `ACMS_GET_Shop*`・`ACMS_POST_Shop*`・`ACMS_GET_Admin_Shop_*`、`ACMS_GET_Google_Translate`（Ver. 3.1.12）。`ACMS_GET_Ios_*`・`ACMS_POST_Ios_*`、`ACMS_GET_Analytics_Mobile`・`BackLink`・`Touch_Crm*`・`Utility_ArchiveZipList`・`Utility_Message`、`ACMS_POST_Blog_Index_Config`・`Cache_Save`・`Entry_Apply`・`Entry_Confirm`、`Acms\Services\React\*`（Ver. 3.1.14）。`ACMS_GET_Admin_Unit`（Ver. 3.1.23）。`ACMS_GET_Touch_Role_ModuleEdit`・`NotModuleEdit`、`Acms\Services\Facades\React`（Ver. 3.1.37。React のサービスの登録は 3.1.14 で外れた） | 代わりなし。`Shop2_*` は残る | `P-REMOVED-CLASS` | `git diff --diff-filter=D --name-only v3.0.68 v3.1.80 -- ablogcms/php` と各タグの比較 |
| 3.1.0 で削除: `ACMS_POST_Shortcut`（ショートカットのサービス `shortcut.helper` へ）、`ACMS_POST_Form_Mail`、`ACMS_GET_Admin_Config_Menu`、`ACMS_GET_Admin_Dashboard_LogAccess`・`Log_Access` | — | `P-REMOVED-CLASS` | 同上 |
| `ACMS_POST_Member_Tfa_UnRegister`（3.1.0〜3.1.53）は Ver. 3.1.54 で `Unregister` に改名 | `ACMS_POST_Member_Tfa_Unregister` | `T-TFA-UNREGISTER`（`extension/` も探す） | `git diff --name-status v3.1.53 v3.1.54 -- ablogcms/php/ACMS/POST/Member/Tfa` |

### 2. 本体の基底クラスを継承したクラス

| 変更 | 影響 | 見つけ方 | 直し方 | 根拠 |
|---|---|---|---|---|
| `ACMS_POST::extract()` に戻り値の型 `: Field_Validation` が付いた（3.1.0） | 型なしでオーバーライドしていると宣言の互換性エラー（Fatal） | `P-EXTRACT-SIGNATURE`（要確認。grep: `function[[:space:]]+extract[[:space:]]*\([^)]*\)[[:space:]]*(\{\|$)`） | `: Field_Validation` を付ける。第 4 引数 `$moveArchive` は 3.1 でなくなったので、使っていたなら外す | `v3.0.68:ablogcms/php/ACMS/POST.php:343`、`v3.1.80:ablogcms/php/ACMS/POST.php:394` |
| `ACMS_GET` に `public $page`・`$order`・`$identifier`・`$showField` を宣言（Ver. 3.1.14）。`ACMS_App` に `public $module`・`$menu` を追加。`ACMS_GET` の `$step` を削除（Ver. 3.1.14） | 子クラスで同じ名前を protected・private で宣言すると Fatal。`$this->step` は PHP 8.2 以上で動的プロパティの警告 | `P-PROPERTY-VISIBILITY`（要確認。grep: `(protected\|private)[[:space:]]+\$(page\|order\|identifier\|showField\|module\|menu)([^A-Za-z0-9_]\|$)\|\$this->step([^A-Za-z0-9_]\|$)`） | public にする。`$step` を使うなら自分で宣言する | `v3.1.80:ablogcms/php/ACMS/GET.php`、`v3.1.80:ablogcms/php/ACMS/App.php:32-43` |
| 削除されたメソッド: `ACMS_GET`・`ACMS_POST` の `checkShortcut()`（3.1.0）、`ACMS_POST` の `moduleCacheSensitivity()`・`checkConfigSetBlogChild()`（Ver. 3.1.14）、`loadPluginFulltext()`・`savePluginFulltext()`（Ver. 3.1.36）、`ACMS_GET` の `buildInputTextValue()`・`buildInputCheckboxChecked()`・`buildSelectSelected()`（Ver. 3.1.37）、`ACMS_GET_Entry::buildColumn()`・`ACMS_GET_Unit::buildUnit()`・`ACMS_POST_Entry::saveColumn()`・`extractColumn()`・`saveUnitRevision()`（Ver. 3.1.23）、`ACMS_Filter::formbuild*`・`crmMailField`（Ver. 3.1.16）、`ACMS_GET_Admin::createUrl()`・`extractQuery()`（3.1.0） | 呼ぶと Fatal | `P-REMOVED-METHOD`（grep: `(load\|save)PluginFulltext\|moduleCacheSensitivity\|checkConfigSetBlogChild\|(save\|extract\|getSaved)Column[[:space:]]*\(\|saveUnitRevision\|build(InputTextValue\|InputCheckboxChecked\|SelectSelected)\|formbuild\|crmMailField\|(->\|::)(buildColumn\|buildUnit)[[:space:]]*\(`）。`createUrl`・`extractQuery` は名前がよくあるので、`ACMS_GET_Admin` を継承したクラスの中で探す | 全文検索に値を足す処理は Hook の `filterEntryFulltext`・`filterUserFulltext`・`filterCategoryFulltext`・`filterBlogFulltext`（Ver. 3.1.36 以降）、ユニットの保存・読み込みは `App::make('unit-repository')`（Ver. 3.1.23 以降） | 各タグでのメソッドの有無の比較、`v3.1.80:ablogcms/php/Services/Unit/Repository.php` |
| コアの `ACMS_POST_Entry_*`・Import 系を継承したクラス | protected のメソッドが多く消えた（Import/Model/Entry は 20 件以上） | `grep -rnE 'extends[[:space:]]+\\?ACMS_POST_(Entry\|Import)' extension/` | 継承をやめ、ファサード・サービスを呼ぶ形に書き直す | `git diff v3.0.68 v3.1.80 -- ablogcms/php/ACMS/POST/Entry ablogcms/php/ACMS/POST/Import` |

### 3. 引数が変わったメソッド・関数

引数の位置がずれても、エラーにならずに誤動作するものがある。

| 変更 | 見つけ方 | 直し方 | 根拠 |
|---|---|---|---|
| `Auth::checkShortcut($action, $admin, $idKey, $id)` → `Auth::checkShortcut(array $ids): bool`（3.1.0。`$ids` は bid・cid・rid・mid・scid・setid） | `P-SIGNATURE`（要確認） | 配列で渡す | `v3.1.80:ablogcms/php/Services/Auth/General.php:197` |
| `Common::saveField($type,$id,$Field,$deleteField,$rvid,$moveFieldArchive,$targetBid)` → 第 6 引数 `$moveFieldArchive` を削除（3.1.0）。7 引数で呼ぶと `$moveFieldArchive` が `$targetBid` に入る。`Common::extract()` の第 4 引数、`Entry::saveFieldRevision()` の第 4 引数も削除 | `P-SIGNATURE` | 引数を減らす | `v3.1.80:ablogcms/php/Services/Common/Helper.php` |
| `Entry::saveEntryRevision($eid,$entryAry,$type,$memo)` → `($eid,$rvid,$entryAry,$type,$memo)`（3.1.0） | `P-SIGNATURE` | 第 2 引数に `$rvid` を入れる | `v3.1.80:ablogcms/php/Services/Entry/Helper.php` |
| `sessionWithSubscription`・`sessionWithContribution`・`sessionWithCompilation`・`sessionWithAdministration`・`sessionWithFormAdministration` が `($bid, $options = [])` に（Ver. 3.1.23）。旧引数（`$revision`・`$superUser`・`$nocache`）は無視される。`isSession{Subscriber,Contributor,Editor,Administrator}()` と `enableRevision()` は引数なしに。Ver. 3.1.78 で `sessionWithContribution`・`sessionWithCompilation` に第 3 引数 `?int $userId = SUID` | `P-SIGNATURE`（grep: `sessionWith(...)[[:space:]]*\([^)]*,` など） | 旧引数で挙動を変えていたなら、`$options`（`cache`・`considerTimemachineMode`）で書き直す | `v3.1.80:ablogcms/php/ACMS/function.php:1232,1300,1346,1439` |
| `Media::getBaseInfo($fileObj,$tags,$name)` の第 3 引数を削除（Ver. 3.1.64）。`Field_Search::setSeparator($separator)` → `setSeparator($fd, $separator)`（Ver. 3.1.14） | `P-SIGNATURE` | 呼び方を直す | 各タグの比較 |
| `Login::accessRestricted(bool)`（3.1.0〜3.1.64）は Ver. 3.1.65 で `Login::canAccessAdminLoginFromCurrentIp()`・`canAccessSigninFromCurrentIp()` に置き換わった | `P-REMOVED-FUNCTION`（`accessRestricted`） | 置き換える | `v3.1.80:ablogcms/php/Services/Facades/Login.php` |
| `Config::get()`・`config()` のキーが必須に（Ver. 3.1.14）。型の付いた関数（`env()`・`redirect()`・`acmsUnserialize()`・`isValidCode()`・`deleteFile()` など）と Cache の `get`・`put` などに null を渡すと TypeError | grep: `config\(\)` と、null を渡している箇所 | 値を渡す | `v3.1.80:ablogcms/php/ACMS/function.php:618,633` |
| `Login::addExtraLoggedInCookie(int $uid)` に型が付いた | grep: `addExtraLoggedInCookie` | int を渡す | `v3.1.80:ablogcms/php/Services/Login/Helper.php` |

### 4. 削除されたグローバル関数

| 削除された関数 | 代わり | 見つけ方 | 根拠 |
|---|---|---|---|
| `checkShortcut()`（3.1.0） | `Auth::checkShortcut(array $ids)` | `P-REMOVED-FUNCTION`（grep: `(^\|[^A-Za-z0-9_>:$])(checkShortcut\|accessRestricted\|getUser\|loginAuthentication\|isBench\|isFacebookLoginAvailable\|createOtherSizeImages\|editImages\|getUserGroup\|alignColumn)[[:space:]]*\(`） | 両タグの `^function` の一覧の比較 |
| `accessRestricted()`（3.1.0） | 3.1.65 以降は `Login::canAccessAdminLoginFromCurrentIp()`・`canAccessSigninFromCurrentIp()` | 同上 | 同上 |
| `getUser()`・`loginAuthentication()`（3.1.0） | 直接の代わりはない。`Login::findUser($email, $bid)` など | 同上 | 同上 |
| `isBench()`（3.1.0） | `isBenchMarkMode()` | 同上 | 同上 |
| `isFacebookLoginAvailable()`（3.1.0） | なし | 同上 | 同上 |
| `createOtherSizeImages()`・`editImages()`（Ver. 3.1.14） | `Image::createImages()`・`Image::copyImage()`（引数は移行先のソースで確かめる） | 同上 | 同上 |
| `getUserGroup()`（Ver. 3.1.14） | `getUserGroupIds()` | 同上 | 同上 |
| `alignColumn()`（Ver. 3.1.23） | ユニットのサービス | 同上 | 同上 |
| `Common::generateFileSecret()`・`verifyFileSecret()`（3.0 の終盤だけにある） | 3.1.80 ではグローバル関数 `acmsFileSecret()`・`verifyAcmsFileSecret()`（3.1.79 以前の 3.1 にはどちらもない） | grep: `(generate\|verify)FileSecret` | `v3.1.80:ablogcms/php/ACMS/function.php` |

`loadUser($uid, $noCache)` の第 2 引数は Ver. 3.1.7 から無視される（エラーにはならない）。

### 5. 定数・Hook

| 変更 | 見つけ方 | 直し方 | 根拠 |
|---|---|---|---|
| `RVID` が整数になった（3.0 は文字列） | `P-RVID-STRICT`（grep: `RVID[[:space:]]*(===\|!==)[[:space:]]*['"]`） | 整数で比べる | `v3.0.68:ablogcms/php/main.php:676`、`v3.1.80:ablogcms/php/main.php:816` |
| 3.0 の Hook は名前・引数ともすべて残っている。ログイン・会員登録の専用の Hook はない（3.0 も 3.1 も）。追加された Hook: `addGlobalVarsInIncludePath`（3.1.0）、`saveMedia`（Ver. 3.1.17）、`filterEntryFulltext` など 4 つ（Ver. 3.1.36）、`unserializeAllowedClasses`（Ver. 3.1.43） | Hook のクラスに同じ名前のメソッドがあると、本体から呼ばれるようになる。grep: `function (addGlobalVarsInIncludePath\|saveMedia\|filter(Entry\|User\|Category\|Blog)Fulltext\|unserializeAllowedClasses)\b` | 名前がぶつかるなら変える。会員登録などの前後に処理を挟むなら `beforePostFire`・`afterPostFire` でモジュールのクラスを見て分ける（動作は未確認） | `git diff v3.0.68 v3.1.80 -- ablogcms/extension/acms/Hook.php` |

### 6. 本体の vendor のライブラリ

| 変更 | 見つけ方 | 直し方 | 根拠 |
|---|---|---|---|
| `google/apiclient` が v1 から v2 に（3.1.0）。apiclient-services は Ver. 3.1.14 から Translate だけ。`react/react` が 0.4 から 1.x に（Ver. 3.1.14）。`monolog/monolog` 2・`league/oauth1-client` を追加（3.1.0）。guzzlehttp/psr7 は 2.x に | `P-VENDOR-LIBRARY`（要確認。grep: `Google_(Client\|Service_)\|Google\\(Client\|Service)\\\|React\\(EventLoop\|Http\|Promise)\|Monolog\\`）と、`extension/plugins/*/composer.json`・`vendor/` の有無 | 本体の vendor に頼っているなら、移行先のバージョンで動くかを確かめる。自前の vendor で同じライブラリの別バージョンを持っていると、クラスがぶつかることがある | `ablogcms/composer.json`・`composer.lock` の v3.0.68 と v3.1.80 の比較 |

## 非推奨になった機能と代替

3.1 で非推奨の警告を出すようになったクラス・関数はない。`DEBUG_MODE` を直接見る代わりに `isDebugMode()`（ユーザーごとのデバッグモードも見る）を使うのが 3.1 の書き方だが、直接見てもエラーにはならない。

## 直す手順

1. 配布されているプラグインは、3.1 対応バージョンを配布元で確かめ、あれば移行先のバージョンに合わせて入れ替える（管理画面 > 拡張アプリで更新する）。
2. 更新前のサイト（3.0）で acms-upgrade の `sh scripts/scan.sh <設置ディレクトリ> 3.1` を実行し、`P-` のチェックを見る（acms-upgrade がなければ、上の表の「grep:」で `extension/` を探す）。
3. 3.0 のままでも直せるもの（削除されたクラス・関数の利用をやめる、`RVID` の比較、プロパティの可視性）を先に直す。
4. 本体を更新した後に、3.1 の API に合わせるもの（`Member_*` への継承の付け替え、`Login::addUserFromOauth`、`Auth::checkShortcut`、`unit-repository`、Hook の `filter*Fulltext`、`extract()` の戻り値の型）を直す。3.1.x の途中で変わったもの（3 章・4 章）は、移行先のパッチバージョンのソースで引数を確かめる。
5. 検証環境で PHP の E_ALL の警告をログに出し、独自モジュールのある画面と POST を実際に動かす。静的解析を使うなら、PHPStan で本体を読み込ませて `extension/` を解析すると、削除されたクラス・関数・引数の数の不一致をまとめて見つけられる。
6. scan.sh をもう一度実行し、`P-` のうち `要確認` 以外の検出が 0 件になったことを確かめる。

Hook・ServiceProvider・独自モジュールの書き方は acms-plugin-development を使う（3.2 向けの書き方なので、3.1 で止めるなら移行先のソースで確かめる）。

## 移行後の確認

- 管理画面 > 拡張アプリで、プラグインが有効のままか、エラーが出ていないか。
- 独自の GET モジュールの表示と、独自の POST モジュールの送信が通るか。
- Hook で足した処理（エントリーの保存・ログイン・メールの送信など）が動くか。
- 監査ログとサーバーの PHP のエラーログに Fatal・Deprecated が出ていないか。
- scan.sh を再実行して、`P-` のうち `要確認` 以外が 0 件。

## 参考

- 移行ガイド（Ver. 3.0.x から 3.1.x）: <https://developer.a-blogcms.jp/document/migration/301x/>
- 下位互換性のない変更点: <https://developer.a-blogcms.jp/document/migration/301x/incompatible.html>
- 動作条件: <https://developer.a-blogcms.jp/document/requirements.html>
