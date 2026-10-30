# プラグイン（拡張アプリ）の構成

公式ドキュメント:
- 開発の基本（ServiceProvider のプロパティとメソッド）: <https://developer.a-blogcms.jp/document/develop_apps/entry-2906.html>
- 名前空間: <https://developer.a-blogcms.jp/document/develop_apps/entry-2907.html>
- テンプレートの挿入（InjectTemplate）: <https://developer.a-blogcms.jp/document/develop_apps/entry-2912.html>
- Twig で管理画面を実装する: <https://developer.a-blogcms.jp/document/develop_apps/twig-admin.html>
- Twig 拡張 API: <https://developer.a-blogcms.jp/document/develop_apps/twig-extension-api.html>
- アセット API（JS / CSS の読み込み）: <https://developer.a-blogcms.jp/document/develop_apps/asset-api.html>
- サービスコンテナ: <https://developer.a-blogcms.jp/document/develop_apps/service-container.html>

## ディレクトリと名前空間

```
extension/plugins/MyPlugin/
├── ServiceProvider.php        … 必須。Acms\Plugins\MyPlugin\ServiceProvider
├── Hook.php                   … 任意。init() で attach する
├── Corrector.php / Validator.php
├── GET/Foo.php                … 標準テンプレート用の GET モジュール（Acms\Plugins\MyPlugin\GET\Foo）
├── POST/Foo.php               … POST モジュール（Acms\Plugins\MyPlugin\POST\Foo）
├── Modules/Get/V2/Foo.php     … Twig 用の V2 GET モジュール（Ver. 3.2.27 以降。references/modules.md）
└── template/                  … 管理画面に差し込むテンプレート
```

- 名前空間は `Acms\Plugins\<ディレクトリ名>`。`Acms\Plugins\` は `extension/plugins/` に PSR-4 で割り当てられているので、`require` は要らない。
- 管理画面のプラグイン（拡張アプリ）一覧は、`extension/plugins/` 直下のディレクトリごとに `Acms\Plugins\<ディレクトリ名>\ServiceProvider` が `ACMS_App` を継承しているかで判定する。ディレクトリ名とクラスの名前空間がずれると一覧に出ない。
- ディレクトリ名に `_` を使わない（推奨）。モジュール名を解決するとき、本体は名前空間の `_` もすべて `\` に置き換えるため、`My_Plugin` の GET / POST モジュールは見つからなくなる。
- `GET` / `POST` のディレクトリ名は大文字。V2 は `Modules/Get/V2`（`Get` は先頭だけ大文字）。

## ServiceProvider

`ACMS_App` を継承する。抽象メソッドは `install`・`uninstall`・`activate`・`deactivate`・`update`・`checkRequirements` の6つで、すべて実装しないとクラスを読み込めない。`init` は任意だが、Hook などの登録はここでしかできない。

| メソッド | 呼ばれるとき | 書くこと |
|---|---|---|
| `checkRequirements()` | インストールの直前 | 動作条件の確認。`false` を返すとインストールしない |
| `install()` | ルートブログの管理画面でインストールしたとき（続けて `activate()` も呼ばれる） | テーブルの作成など、サイト全体で一度だけの準備 |
| `activate()` / `deactivate()` | ブログごとの有効化 / 無効化 | ブログ単位の準備・後始末 |
| `uninstall()` | ルートブログの管理画面でアンインストールしたとき | テーブルの削除など。`deactivate()` は呼ばれず、全ブログの有効化の記録が消える |
| `update()` | `$version` がインストール済みのバージョンと違うときに、管理画面からアップデートを実行したとき | テーブル構造の変更など |
| `init()` | プラグイン（拡張アプリ）を有効にしたブログへのリクエストのたび | Hook・校正オプション・検証オプションの `attach`、テンプレートの差し込み、Twig のテンプレートパスの登録 |

- これらのメソッドで例外を投げると、本体が受け止めて「失敗しました」と表示し、監査ログに記録する。`activate()` などの戻り値は本体では使われていない。
- `init()` は無効にしたブログ・インストールしていないブログでは呼ばれない。そのブログでは Hook も校正オプションも動かない。
- `$menu` に文字列（例: `myplugin_index`）を入れると、管理画面に `app_myplugin_index` のページができる。`$module` は非推奨。

登録の最小形:

```php
public function init()
{
    \Acms\Services\Common\HookFactory::singleton()->attach('MyPluginHook', new Hook());
    \Acms\Services\Common\CorrectorFactory::singleton()->attach('MyPluginCorrector', new Corrector());
    \Acms\Services\Common\ValidatorFactory::singleton()->attach('MyPluginValidator', new Validator());
}
```

`attach` の第1引数は他と重ならない名前にする。同じ名前で登録すると、先に登録したものが置き換わる。

## 管理画面の設定ページ

| 方法 | 使えるバージョン | 書き方 |
|---|---|---|
| Twig で書く | Ver. 3.2.24 以降 | `init()` で `Twig::addTemplatePath(PLUGIN_LIB_DIR . 'MyPlugin/template', 'myplugin')` を呼び、`ADMIN === 'app_' . $this->menu` のときだけ `InjectTemplate::singleton()->add('admin-main', fn() => Twig::renderTemplate('@myplugin/admin/main.twig'))` で差し込む。Twig 側は `acms_config()` でコンフィグを読む |
| 標準テンプレートで書く | Ver. 3.2 以上 | `InjectTemplate::singleton()->add('admin-main', PLUGIN_DIR . 'MyPlugin/template/admin/main.html')` のように、テンプレートのパスを渡す |

- どちらも保存は本体の `ACMS_POST_Config` に任せる（送信ボタンの `name` を `ACMS_POST_Config` にし、保存するキーを `config[]` で宣言する）。自前の POST モジュールで設定を保存しない。
- Twig で描画した HTML も、差し込むときに標準テンプレートエンジンを通る。同梱のサンプルが `main.twig` の中で `@include("/admin/topicpath.html")` を使えているのはこのため。
- `admin-main` は全プラグイン（拡張アプリ）の画面で共有の差し込みポイントなので、自分の画面（`ADMIN === 'app_' . $this->menu`）のときだけ登録する。
- Twig の Filter / Function は `init()` ではなく Hook の `extendsTwig`（Ver. 3.2.24 以降）で登録する。Twig の環境は作り直されることがあり、そのたびに呼ばれるのが `extendsTwig` のため。
- 差し込みポイントの一覧（`admin-module-select`、`admin-entry-field` など）は「テンプレートの挿入」のページを読む。`admin-module-select` に選択肢を足すと、独自の GET モジュールをモジュール ID の作成画面で選べるようになる。

## 管理画面への JavaScript の読み込み

管理画面の JavaScript プラグインの中身（`ACMS.plugins.register`、`ACMS.events`、Slot）は acms-admin-frontend-plugin が担う。ここでは読み込みだけを扱う。

| バージョン | 方法 |
|---|---|
| Ver. 3.2.29 以降 | `Asset::script('myplugin-admin', '/' . DIR_OFFSET . 'extension/plugins/MyPlugin/assets/admin.js', ['attrs' => ['type' => 'module']])` を呼ぶ。どのページでも読むなら `init()`、ページの種類で出し分けるなら Hook の `afterBuild` から呼ぶ。`src` はそのまま出力されるので、サブディレクトリに設置したサイトでも動くよう `DIR_OFFSET` を付ける |
| Ver. 3.2.28 以前 | Asset API が無い。Hook の `afterBuild(&$res)` で `</body>` の前に `<script>` を差し込む |

- 管理画面の JavaScript プラグインの API（`ACMS.plugins` など）自体が Ver. 3.2.29 以降なので、通常は Asset API を使う。
- `init()` で無条件に登録すると公開側のページにも出る。管理画面だけで読むなら `defined('ADMIN') && ADMIN` などで条件を付ける。
- 本体のアセット（`acms-admin` など）を `Asset::dequeue()` で止めない。管理画面が動かなくなる。

## サービスの差し替え

本体のサービス（Markdown 変換など）を差し替える `override()` / `extend()` は Ver. 3.2.30 以降。`init()` で呼ぶ。詳細はサービスコンテナのページを読む。
