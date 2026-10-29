---
name: acms-plugin-development
description: >-
  a-blog cms（acms）のプラグイン（拡張アプリ）と、extension/acms 配下のユーザー拡張を PHP で開発するときの手順と判断基準。
  プラグイン（拡張アプリ）のディレクトリ構成と ServiceProvider（install / uninstall / activate / init の役割、名前空間）、
  Hook の選び方と登録（HOOK_ENABLE、例外を外へ投げない理由）、独自の GET / V2 GET / POST モジュール（CSRF の扱い）、
  校正オプション（Corrector）・検証オプション（Validator）・グローバル変数の追加、管理画面の設定ページ（Twig 管理画面は Ver. 3.2.24 以降）、
  管理画面への JavaScript の読み込み、動かないときのデバッグ、配布・本番運用するプラグインの設計（独自テーブルの作成とマイグレーション、設定値と API キーの置き場所、権限の確認、ログ、テスト、composer の依存、配布の zip と対応バージョン）を扱う。
  「エントリー保存時に処理を足したい」「独自モジュールを作りたい」「プラグインを作って」「Hook.php に書いたのに動かない」と頼まれたとき、
  ServiceProvider.php・Hook.php・Corrector.php・Validator.php・extension/plugins/ を触るときに使う。
  a-blog cms plugin, Hook, ServiceProvider, custom module, corrector, validator, DB table, migration, testing, distribution.
  管理画面の JavaScript プラグインの中身（ACMS.plugins、ACMS.events）は acms-admin-frontend-plugin、テンプレートの記法は acms-template-acms / acms-template-twig が担う。
license: MIT
compatibility: a-blog cms Ver. 3.2 以上。Twig の管理画面と Twig の Filter 登録は Ver. 3.2.24 以降、Asset API は Ver. 3.2.29 以降。
metadata:
  acms-min-version: "3.2"
  status: stable
---

# a-blog cms のプラグイン（拡張アプリ）開発

公式ドキュメント:
- プラグイン（拡張アプリ）: <https://developer.a-blogcms.jp/document/develop_apps/>
- フック処理（Hook のリファレンス）: <https://developer.a-blogcms.jp/document/user_hook/user_hook.html>
- GET モジュール / V2 GET モジュール / POST モジュールの開発: <https://developer.a-blogcms.jp/document/develop/get_module.html>、<https://developer.a-blogcms.jp/document/develop/v2_get_module.html>、<https://developer.a-blogcms.jp/document/develop/post_module.html>

本体のソースが手元にあるときは、`extension/plugins/SamplePlugin/`（同梱のサンプル）と `extension/acms/Hook.php`（Hook の一覧とコメント）を先に読む。どちらもそのバージョンで使える API を表している。

## どこに書くか

| したいこと | 置き場所 |
|---|---|
| 複数のサイトで使い回す・配布する・ブログごとに有効 / 無効を切り替える | プラグイン（拡張アプリ）。`extension/plugins/<名前>/ServiceProvider.php` を置き、管理画面でインストール・有効化する |
| そのサイトだけの小さな処理 | `extension/acms/` 配下のユーザー拡張（`Hook.php`、`Corrector.php`、`Validator.php`、`GET/`、`POST/`、`Modules/Get/V2/`） |
| JavaScript で管理画面の UI を足す | 中身は acms-admin-frontend-plugin。読み込みだけをここで扱う（references/plugin-structure.md） |

- 本体のファイル（`php/` 配下、`themes/system/`）は書き換えない。アップデートで上書きされるため。`extension/acms/` と `extension/plugins/` は上書きされない。
- ユーザー拡張は置けば全ブログで動く（Hook はどちらも `HOOK_ENABLE` が `1` のときだけ）。プラグイン（拡張アプリ）は `ServiceProvider::init()` で Hook・校正オプション・検証オプションを `attach` しないと動かない。
- ユーザー拡張の `Hook.php` でしか受け取れない Hook がある（`init`・`beforeAuthenticate`・`afterAuthenticate`・`restrictionAuthority`・`customRuleValue`）。本体がプラグイン（拡張アプリ）を読み込む前に呼ぶため。

## 作業の手順

1. `acms-project-triage` でバージョンを確かめる。Ver. 3.2 の途中で入った API（Twig の管理画面、Asset API など）は、対象のバージョンで使えるかを references で確かめてから使う。
2. 何をしたいかで、Hook・モジュール・校正オプション・検証オプション・グローバル変数のどれを使うか決める。
   - プラグイン（拡張アプリ）の構成・ServiceProvider・管理画面の設定ページ・JavaScript の読み込みは references/plugin-structure.md を読む。
   - Hook を選ぶとき、Hook が動かないときは references/hooks.md を読む。
   - 独自の GET / V2 GET / POST モジュールを作るときは references/modules.md を読む。
   - 校正オプション・検証オプション・グローバル変数を足すときは references/corrector-validator-global-variables.md を読む。
   - 独自テーブル・設定画面・テスト・配布を伴うプラグイン（拡張アプリ）を作るときは references/production-plugin.md を読む（install / update / uninstall の本体の動き、DB_PREFIX とマイグレーション、API キーの置き場所、POST の権限、composer の依存、対応バージョンの宣言）。
3. 書いたら「確認とデバッグ」の順で動作を確かめる。

## 守ること

- Hook の中で例外を外へ投げない。`try` / `catch (\Throwable $e)` で受けて `AcmsLogger::warning()` などで記録し、処理を続ける。本体の Hook の呼び出し（`HookFactory::call()`）も、エントリー保存などの呼び出し側の多くも例外を受け止めないため、保存は済んだのに画面がエラーになる、メディアは登録されたのにアップロード失敗と表示される、といった食い違いが起きる。
- 参照渡しの引数（`&$globalVarNames`、`&$customRuleString` など）は代入で上書きせず、追記する。ユーザー拡張と各プラグイン（拡張アプリ）の Hook が同じ変数を順に受け取るため、上書きすると先に登録された Hook の結果が消える。
- POST モジュールで CSRF の検証を外さない（`$isCSRF = false` にしない）。権限の確認は本体がしないので、`post()` の先頭で自分でする（references/modules.md）。
- モジュール（ユーザー拡張でもプラグイン（拡張アプリ）でも）と、プラグイン（拡張アプリ）の校正オプション・検証オプションの名前を、本体にある名前と同じにしない。本体側が先に見つかり、自分のクラスやメソッドは呼ばれない（ユーザー拡張の `Corrector.php` / `Validator.php` だけは本体より優先される）。
- 外部 API の URL やキーをコードに直書きしない。プラグイン（拡張アプリ）の設定ページ（コンフィグ）から読む。
- `ServiceProvider::init()` はプラグイン（拡張アプリ）を有効にしたブログへのリクエストのたびに呼ばれる。重い処理を書かず、登録だけにする。
- `config.server.php` は読まない・書き換えない。`HOOK_ENABLE` や `DEBUG_MODE` の変更が必要なときは、利用者に変更を依頼する（DB の接続情報を含むため）。

## 確認とデバッグ

動かないときは、上から順に確かめる。

1. Hook がまったく呼ばれない: `config.server.php` の `HOOK_ENABLE` が `1` か（既定は `0`）。プラグイン（拡張アプリ）の Hook もこの値が `0` なら呼ばれない。利用者に確認を依頼する。
2. プラグイン（拡張アプリ）の処理が動かない: 管理画面の「プラグイン（拡張アプリ）」で、作業中のブログで有効になっているか。インストールはルートブログでしかできず、有効化はブログごと。
3. `init()` は動くが Hook が動かない: `HookFactory::singleton()->attach()` で登録しているか。受け取ろうとしている Hook が、プラグイン（拡張アプリ）から受け取れないもの（上の5つ）ではないか。
4. 画面が真っ白になる・500 になる: 捕まえていない例外が出ている。本体は記録してから、デバッグモードでなければ何も表示しない。管理画面の監査ログでエラーの内容を見る。利用者にデバッグモード（ユーザー編集の「モード」、または `config.server.php` の `DEBUG_MODE`）を有効にしてもらうと、画面にスタックトレースが出る。
5. 記録したログが監査ログに出ない: スタンダードエディションでは `info` のログは保存されない。失敗の記録は `notice` 以上にする。
6. 本番だけで起きる: デバッグモードではテンプレートキャッシュが無効になる。インクルードのパスに足したグローバル変数の問題（references/corrector-validator-global-variables.md）は、デバッグモードでは再現しない。ページキャッシュが返るときは `afterBuild` などは呼ばれない（references/hooks.md）。
7. プラグイン（拡張アプリ）の `$version` を上げたのに反映されない: 管理画面でアップデートを実行すると `update()` が呼ばれる。テーブルの変更はここに書く。

テストと静的解析は <https://developer.a-blogcms.jp/document/develop_apps/plugin-testing.html> と references/production-plugin.md の「テスト」を読む。
