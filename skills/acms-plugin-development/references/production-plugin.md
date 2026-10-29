# 配布・本番運用するプラグイン（拡張アプリ）の設計

独自テーブル・設定画面・テスト・配布を伴うプラグイン（拡張アプリ）を作るときの判断基準。ServiceProvider の各メソッドの役割は references/plugin-structure.md、POST モジュールの CSRF は references/modules.md を先に読む。

公式ドキュメント:
- 開発の基本: <https://developer.a-blogcms.jp/document/develop_apps/entry-2906.html>
- DB クラス / SQL クラス: <https://developer.a-blogcms.jp/document/develop/db1-db-query.html>、<https://developer.a-blogcms.jp/document/develop/db2-sql-select.html>
- サービスコンテナ: <https://developer.a-blogcms.jp/document/develop_apps/service-container.html>
- テスト: <https://developer.a-blogcms.jp/document/develop_apps/plugin-testing.html>（書き方 <https://developer.a-blogcms.jp/document/develop_apps/plugin-testing-writing.html>、静的解析 <https://developer.a-blogcms.jp/document/develop_apps/plugin-testing-phpstan.html>、CI <https://developer.a-blogcms.jp/document/develop_apps/plugin-testing-ci.html>）

## ディレクトリ構成

本体に同梱の `extension/plugins/SamplePlugin/` と、developer サイトが案内するひな型 `ablogcms/plugin-skeleton`（テスト・PHPStan・CI が設定済み）を手本にする。リポジトリでは本体に置く部分（`src/`）とテストを分ける。

```
my-plugin/                     … リポジトリ（開発用）
├── composer.json              … require-dev（testing-framework など）と autoload
├── phpunit.xml.dist / phpstan.neon
├── src/                       … これが extension/plugins/MyPlugin/ になる
│   ├── ServiceProvider.php    … 登録と、install / update / uninstall の入口だけ
│   ├── Hook.php               … 受け取って Services へ渡すだけ
│   ├── GET/ POST/ Modules/Get/V2/
│   ├── Services/              … 処理の本体（テストの対象）
│   ├── template/ assets/
│   └── vendor/                … 実行時に要る依存を同梱するときだけ（後述）
└── tests/Unit/ tests/Integration/
```

- `src/` の中身を `extension/plugins/<名前>/` に置く。`<名前>` は名前空間 `Acms\Plugins\<名前>` と同じにする。ハイフンや `_` を含めない（ハイフンは名前空間に使えず、`_` はモジュール名の解決で `\` に置き換えられる）。
- ServiceProvider・Hook・GET / POST のクラスは薄くし、処理は `Services/` のクラスに書く。本体の GET / POST のクラスは CSRF・セッション・定数に依存して直接テストしにくいため（テストのドキュメントも同じ方針）。
- Hook クラスは `init()` でリクエストのたびに作られる。コンストラクタで DB や外部に触れない。
- 共有したいサービスは `init()` で `App::singleton()` / `App::bind()` に登録する。プラグイン（拡張アプリ）の ServiceProvider では `register()` は呼ばれない。本体のサービスの差し替え（`override()` / `extend()`）は Ver. 3.2.30 以降。

## ライフサイクルの本体の動き（設計の前提）

`php/ACMS/POST/App/*.php` と `php/main.php` の動き。

| 場面 | 本体の動き | 設計で気をつけること |
|---|---|---|
| インストール | ルートブログだけ。`checkRequirements()` が `false` なら「要件を満たしていません」とだけ出す。続けて `install()` → `activate()`、成功したら `app` テーブルに登録 | 満たしていない理由は `AcmsLogger::notice()` などで記録する。`install()` は2回流しても壊れないようにする（`activate()` の失敗でも未インストールに戻り、やり直されるため） |
| 例外 | 各メソッドの例外は `catch (Exception)` で受けて「失敗しました」と表示する。`Error`（`TypeError` など）は受け止められず、画面がエラーになる | `install()` / `update()` / `uninstall()` の中は `catch (\Throwable)` で受けて `\RuntimeException` に包み直して投げる |
| ファイルを差し替えた直後 | `$version` が `app` テーブルの版と違うと一覧が「要アップデート」になるが、有効なブログでは `init()` も Hook もそのまま動く | 新しいコードが古いテーブルで動く時間がある。`update()` を実行するまで、足した列やテーブルが無くても落ちないように書く |
| アップデート | `update()` には前の版が渡されない。`update()` が成功したあとに `app` テーブルの版が書き換わる。`checkRequirements()` は呼ばれない | 前の版は `update()` の中で `app` テーブルから読む（下の例）。新しい版で本体の要件を上げたなら、`update()` でも確かめて足りなければ例外を投げる（版は書き換わらず「要アップデート」のまま残る） |
| アンインストール | ルートブログだけ。`deactivate()` は呼ばれない。全ブログの有効化の記録が消える。確認ダイアログは「データも削除されます」と表示する | 表示どおり、独自テーブルと自分のコンフィグを `uninstall()` で消す。残す設計にするなら、利用者向けの説明に必ず書く |
| ブログの削除 | 呼ばれる Hook は無い | 消えたブログの行が独自テーブルに残る前提で、読み出し側で `blog_id` を絞る |

## 独自テーブル

### 名前と作り方

- テーブル名は `DB_PREFIX` から始める。`SQL::newSelect('myplugin_item')` などの SQL クラスは接頭辞を自動で付けるので、論理名（接頭辞なし）を渡す。`CREATE TABLE` などを文字列で書くときだけ `DB_PREFIX . 'myplugin_item'` と自分で付ける。
  - 理由: 同じ DB に接頭辞違いで複数のサイトを置けるようにするため。また、管理画面の DB バックアップは `DB_PREFIX` で始まるテーブルだけを書き出す（`php/ACMS/POST/Backup/Export.php`）。接頭辞の無いテーブルはバックアップにも復元にも含まれない。
- テーブル名に `cache_data`・`cache_tag`・`user_session`・`session_php`・`lock`・`lock_source`・`audit_log` を含めない。バックアップはこれらを名前の部分一致で除外するため、`myplugin_block` のような名前でもデータが書き出されない。
- 自分のテーブル名には、本体と重ならない接頭辞（`myplugin_` など）を付ける。
- 値は SQL クラスで組み立てる（プレースホルダーになる）。文字列連結で SQL を作らない。
- `CREATE TABLE IF NOT EXISTS ... ENGINE=InnoDB` にする（本体のテーブルも InnoDB）。

### 失敗を検知する

`DB::query()` は SQL の失敗で例外を投げない。デバッグモードでなければ、失敗はデバッグレベルの監査ログに残るだけで、`false`（`'all'` では空配列）を返す（`php/Services/Database/Engine/PdoEngine.php` の `query()`）。`install()` / `update()` では戻り値が `false` なら自分で例外を投げる。投げないと、テーブルが作れていないのに「インストールに成功しました」と表示される。

### マイグレーションの最小形

```php
public function install()
{
    $this->migrate('0');
}

public function update()
{
    $this->migrate($this->installedVersion());
}

private function installedVersion(): string
{
    // update() の実行中は、app テーブルにまだ前の版が入っている
    $sql = \SQL::newSelect('app');
    $sql->addSelect('app_version');
    $sql->addWhereOpr('app_name', static::class);
    $sql->setLimit(1);
    return (string) \DB::query($sql->get(dsn()), 'one');
}

private function migrate(string $from): void
{
    if (version_compare($from, '1.0.0', '<')) {
        $this->exec('CREATE TABLE IF NOT EXISTS `' . DB_PREFIX . 'myplugin_item` ('
            . ' item_id INT UNSIGNED NOT NULL AUTO_INCREMENT,'
            . ' item_blog_id INT NOT NULL,'
            . ' item_name VARCHAR(255) NOT NULL,'
            . ' PRIMARY KEY (item_id), KEY item_blog_id (item_blog_id)'
            . ') ENGINE=InnoDB');
    }
    // 1.1.0 で列を足したら、ここに version_compare($from, '1.1.0', '<') の段を足す
}

private function exec(string $query): void
{
    if (\DB::query($query, 'exec') === false) {
        throw new \RuntimeException('MyPlugin: テーブルの作成・変更に失敗しました');
    }
}
```

- `$version` は `version_compare()` で比べられる形（`1.2.0` など）にする。本体も一覧の「要アップデート」の判定に `version_compare()` を使う。
- 名前空間の中では `\DB`・`\SQL` のように先頭に `\` を付ける（`DB` は本体が実行時に作る別名で、名前空間の中から自動では見つからない）。
- 追加した行の ID は `\DB::query($insert->get(dsn()), 'seq')` で受け取れる。
- 本体の `Acms\Services\Update\Database\Schema` と `SchemaDefinitions::fromYaml()`（Ver. 3.2.27 以降）は YAML の定義からテーブルを作る本体内部のクラスで、developer サイトに記載がない。配布するプラグインでは使わない。

### マルチブログ

- 行ごとに `*_blog_id` を持ち、読み書きのたびに `BID`（今のリクエストのブログ）で絞る。POST で受け取った ID の行も、`BID` のブログのものかを確かめてから更新・削除する。あるブログの管理者が、別のブログの ID を送って書き換えられないようにするため。
- 有効化はブログごと、インストールはサイト全体で一度。テーブルは `install()` で作り、`activate()` ではブログごとの初期値だけを入れる。
- ブログ単位のエクスポート（`php/Services/Blog/Export.php`）は本体の決まったテーブルだけを書き出す。独自テーブルの行は含まれないので、ブログを移すときの扱いを利用者向けに書く。

## 設定値と秘密情報

### 置き場所

| 値 | 置き場所 | 読み方 |
|---|---|---|
| ブログごとの設定（ON / OFF、件数、API の URL など） | プラグイン（拡張アプリ）の設定ページから `ACMS_POST_Config` で保存（references/plugin-structure.md）。コンフィグはブログ単位で `config` テーブルに入る | `$config = \Config::loadDefaultField(); $config->overload(\Config::loadBlogConfig(BID));` |
| 件数が多い・構造がある・ブログをまたぐデータ | 独自テーブル | SQL クラス |
| サイト全体で一つの秘密（サーバー単位の API キーなど） | サイトの `.env`（本体が起動時に読み込む）やサーバーの環境変数 | `env('MYPLUGIN_API_KEY')` |

- プラグイン（拡張アプリ）の設定ページで保存した値は、`config('key')` では読めないことがある。ブログにコンフィグセットが割り当てられている（親ブログからの継承を含む）と、`config()` はコンフィグセットの値を返し、ブログ自体のコンフィグを見ない（`php/main.php` の `Config::loadBlogConfigSet()`）。設定ページの値は上の表の `loadBlogConfig(BID)` で読む。本体の静的書き出しなどの機能も同じ読み方をしている。
- コンフィグのキーは自分のプラグイン（拡張アプリ）の接頭辞を付ける（`myplugin_`）。`uninstall()` で `config` テーブルから `config_key` が接頭辞で始まる行を消せるようにするため。

### 秘密情報（API キー・トークン）

- 秘密を扱う処理（外部 API の呼び出し）は PHP の側で行い、ブラウザに値を渡さない。管理画面の JavaScript に `ctx.config` で値を渡すと acms.js の URL のクエリとして見える（acms-admin-frontend-plugin の担当。そちらを読む）。
- テンプレートに秘密の値を出さない。ブログのコンフィグは、テーマのテンプレートから `BlogConfig` モジュールや Twig の `acms_config()` で読める。
- 秘密のキー名には `api_key`・`secret`・`token`・`pass` のどれかを含める（`myplugin_api_key` など）。監査ログは、キー名にこれらを含む POST の値（Ver. 3.2.2 以降。`notice` 以上のログに付く）とログのコンテキスト（Ver. 3.2.29 以降）を伏せ字にする（`php/Services/Logger/LoggerServiceProvider.php`、`php/Services/Logger/Filter.php`）。`ACMS_POST_Config` は保存したコンフィグの値をコンテキストに入れて記録するので、Ver. 3.2.28 以前ではキー名にかかわらず監査ログに平文で残る（スタンダードエディションでは info のログ自体が保存されない）。古い版も対象にするなら、利用者にそのことを伝え、`.env` に置く方法を案内する。
- ブログのエクスポートと DB バックアップには `config` テーブルが含まれる。設定ページに保存した秘密もファイルに入る。
- 設定ページを差し込む `init()` では、`ADMIN === 'app_' . $this->menu` に加えて `sessionWithAdministration()` も条件にする。差し込まれたテンプレートを描く本体の `ACMS_GET_Admin_InjectTemplate` は権限を確かめないため。保存は `ACMS_POST_Config` がコンフィグの編集権限（管理者、ロールでは `config_edit`、またはその画面へのショートカットの権限）を確かめる。

## POST モジュールの権限・入力の検証

- 本体は独自の POST モジュールの権限を確かめない。`post()` の先頭で確かめる。

| 対象 | 関数 |
|---|---|
| 管理者 | `sessionWithAdministration()` |
| 編集者以上 | `sessionWithCompilation()` |
| 投稿者以上 | `sessionWithContribution()` |
| 読者以上 | `sessionWithSubscription()` |
| ロール（エンタープライズ）を使っているサイト | `roleAvailableUser()` が真なら `roleAuthorization('<操作>', BID)` で確かめる（本体の POST も同じ分岐をしている） |

- どれも既定では `BID`（URL のブログ）について判定する。別のブログの行を扱うなら、そのブログ ID を渡して確かめる。
- 入力は `$this->Post->setMethod('キー', '検証の名前', 条件)` で検証を宣言し、`$this->Post->validate(new \ACMS_Validator())` のあと `$this->Post->isValidAll()` が偽なら処理せずに `$this->Post` を返す。本体の POST モジュール（`php/ACMS/POST/Tag/Update.php` など）と同じ形にすると、テンプレートの `validator#...` のブロックでエラーを出せる。権限も `operable` のような検証として宣言できる。
- CSRF は本体が `post()` の前に確かめる。外さない（references/modules.md）。
- POST モジュールが終わると、本体は設定（「POST 時にキャッシュをクリア」）に従ってページキャッシュを消す（`$isCacheDelete`、既定 `true`）。Hook・cron・外部からの通知など、POST モジュールの外でデータを変えたときは `\ACMS_POST_Cache::clearPageCache(BID)` を呼ぶ。
- プラグイン（拡張アプリ）の PHP ファイルを直接 URL で呼ぶ作りにしない。本体同梱の `.htaccess` は `index.php` 以外の `.php` へのアクセスを拒否する。外部からの通知（Webhook）も POST モジュールで受ける。

## ログと例外

`AcmsLogger` のレベルの使い分け（`php/Services/Logger/Level.php` のコメントに沿う）:

| レベル | 使う場面 |
|---|---|
| `debug` | 原因調査のために一時的に足すもの。残さない |
| `info` | 正常な操作の記録（設定を変えた、同期した）。スタンダードエディションでは保存されない |
| `notice` | 不正な操作・アクセスの記録、要件を満たさないなどの想定内の失敗 |
| `warning` | 処理は続けられるが問題がある（外部 API が失敗した、Hook の中の例外） |
| `error` / `critical` | 処理を続けられない、機能が使えない |

- `warning` 以上は、既定で管理者へメールで通知される（`.env` の `ALERT_REPORTING_LEVEL`、既定 `WARNING`）。リクエストのたびに起きうる想定内の失敗（相手のサーバーが落ちている間の失敗など）を `warning` で毎回記録すると、通知が続く。一度記録したら一定時間は記録しないなどの工夫をする。
- 例外は `\AcmsLogger::warning('MyPlugin: ...', \Common::exceptionArray($e, ['eid' => $eid]))` の形で記録する。メッセージの先頭にプラグイン（拡張アプリ）の名前を入れると、監査ログで絞り込める。
- ログのコンテキストに秘密の値・個人情報をそのまま入れない。
- Hook の中の例外は外へ投げない（SKILL.md の「守ること」）。POST モジュールでも、利用者に見せる失敗は例外にせず、検証のエラーとして `$this->Post` に入れて返す。

## 依存ライブラリ（composer）

- 本体は `php/vendor/` に composer の依存を持ち（Guzzle、Symfony のコンポーネント、Monolog、Twig、league/* など）、プラグイン（拡張アプリ）の `Acms\Plugins\` も本体のオートローダーで読み込まれる。実行時の依存を足さずに済むなら足さない。
- 足すときは `src/vendor/` に同梱し、プラグイン（拡張アプリ）の中で `require_once __DIR__ . '/vendor/autoload.php'` する。本体はプラグイン（拡張アプリ）の `vendor/` を読み込まない。
  - `install()` / `update()` / `uninstall()` は、そのブログでプラグイン（拡張アプリ）がまだ有効でない（`init()` が呼ばれていない）リクエストで呼ばれる。これらの中で依存を使うなら、`init()` とは別にそこでも読み込む。
- 本体の `php/vendor/` にあるライブラリを別の版で同梱しない。composer のオートローダーは後から読み込んだものが先に探される（`prepend`）ため、まだ読み込まれていないクラスはプラグイン（拡張アプリ）側の版になり、読み込み済みのクラスは本体の版のまま残る。版の混ざったクラスで本体まで壊れる。どうしても要るなら、名前空間を書き換えるツール（PHP-Scoper など）で別の名前空間にしてから同梱する。
- テストの側で同梱の依存を読み込む方法（`tests/bootstrap.php`、PHPStan の `excludePaths.analyse`）は、テスト基盤 `ablogcms/testing-framework` の README にある。

## テスト

developer サイトの「プラグイン（拡張アプリ）のテスト」の手順に従う。何が用意されているかだけをまとめる。

| 提供物 | 役割 |
|---|---|
| `ablogcms/testing-framework`（`require-dev`） | 単体テストの基底 `TestCase`、DB を使う統合テストの基底 `DatabaseTestCase`（テストごとにロールバック）、Seeder（ブログ・カテゴリー・ユーザー・エントリーなど）、`PluginActivator`（有効化の状態を作る）、テスト用 DB にテーブルを作る `vendor/bin/acms-create-database`、PHPStan の設定 |
| 開発用 Docker イメージ `appleple/acms:<マイナー>-php<PHP>` | 本体を含む実行環境。開発・CI 用で、本番には使わない |
| `ablogcms/plugin-skeleton` | テスト・PHPStan・CI が設定済みのひな型 |

- `ablogcms/testing-framework` は本体のマイナーに合わせて `3.2.*` と書く。`^3.2` は 3.3 系まで拾う。
- `acms-create-database` が作るのは本体の定義にあるテーブルだけ（プラグイン（拡張アプリ）の `install()` は呼ばない）。独自テーブルを使う統合テストでは、`setUp` で自分の `migrate()` を呼んでテーブルを作る（上のマイグレーションを ServiceProvider の外のクラスに置くと、テストから呼びやすい）。
- 単体テストを先に考え、DB が要るときだけ統合テストにする。GET / POST のクラスは直接テストせず、`Services/` をテストする。
- イメージのタグはマイナー単位（`3.2`）なので、テストは 3.2 系の新しい本体で動く。対応範囲に入れた古いパッチ版（下の「対応バージョン」）での動作は、別に確かめる。

## 対応バージョンと配布

- 使う Hook・API ごとに導入バージョンを確かめ（SKILL.md・各 references の「Ver. 3.2.NN 以降」の注記）、いちばん新しいものを最小の対応バージョンにする。例: Twig の設定ページ（3.2.24）、プラグイン（拡張アプリ）の V2 モジュール（3.2.27）、Asset API（3.2.29）、`override()` / `extend()`（3.2.30）。
- 最小の対応バージョンを3か所で守る。
  - `checkRequirements()`: `version_compare(VERSION, '3.2.29', '>=')` などで確かめ、足りなければ理由を記録して `false` を返す。
  - `update()`: `checkRequirements()` は呼ばれないので、ここでも確かめて足りなければ例外を投げる。
  - `init()`: 本体を古い版に戻したサイトでも落ちないよう、足りなければ登録をせずに戻る。
- 配布物は、展開すると `<名前>/ServiceProvider.php` になる zip にする（利用者は `<名前>/` を `extension/plugins/` に置く）。ディレクトリ名が名前空間とずれると管理画面の一覧に出ない。Git のホスティングが自動で作るアーカイブは展開先が `<リポジトリ名>-<タグ>` になるので、そのまま配布物にしない。
- 配布物に `tests/`、`composer.json` / `composer.lock`（同梱する `vendor/` の読み込みには要らない）、開発用の設定、`.env` の写しを入れない。`extension/plugins/` は Web から見える場所にあり、本体同梱の `.htaccess` が拒否するのは `.php`・ドットファイル・一部の設定ファイル（`composer.json` など）だけで、Apache 以外のサーバーではそれも効かない。
- 利用者向けの説明（README）に、対応する a-blog cms のバージョン、`HOOK_ENABLE` が要るか、アンインストールで消えるデータを書く。

## 多言語化

- 本体は gettext を一つのドメイン（本体の `lang/` の `messages`）だけで使う。テンプレートの `<!--T-->...<!--/T-->` はこのカタログを引く（`php/ACMS/function.php` の `i18n()`）。プラグイン（拡張アプリ）専用の翻訳カタログを読み込む仕組みは本体に無い。
- 本体の管理画面と同じ文言は `<!--T-->` で囲めば本体の翻訳が使われる。プラグイン（拡張アプリ）独自の文言は翻訳されず、書いたとおりに出る。多言語で配布するなら、文言を言語ごとに持つ仕組みを自前で用意する必要がある（本体の機能ではない）。
