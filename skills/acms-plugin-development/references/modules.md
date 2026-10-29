# 独自の GET / V2 GET / POST モジュール

公式ドキュメント:
- GET モジュールの開発: <https://developer.a-blogcms.jp/document/develop/get_module.html>
- V2 GET モジュールの開発: <https://developer.a-blogcms.jp/document/develop/v2_get_module.html>
- POST モジュールの開発: <https://developer.a-blogcms.jp/document/develop/post_module.html>
- GET モジュールの ID 化: <https://developer.a-blogcms.jp/document/develop/entry-2571.html>
- プラグイン（拡張アプリ）でのモジュール: <https://developer.a-blogcms.jp/document/develop_apps/entry-2908.html>

## どれを作るか

| テンプレート | 作るもの | 置き場所（ユーザー拡張 / プラグイン（拡張アプリ）） | テンプレートでの呼び方 |
|---|---|---|---|
| 標準テンプレート | GET モジュール（`ACMS_GET` を継承し、`get()` で HTML 文字列を返す） | `extension/acms/GET/Foo.php` / `extension/plugins/MyPlugin/GET/Foo.php` | `<!-- BEGIN_MODULE Foo --> ... <!-- END_MODULE Foo -->` |
| Twig テンプレート | V2 GET モジュール（`Acms\Modules\Get\V2\Base` を継承し、`get(): array` で配列を返す） | `extension/acms/Modules/Get/V2/Foo.php` / `extension/plugins/MyPlugin/Modules/Get/V2/Foo.php`（Ver. 3.2.27 以降） | `{% set data = module('V2_Foo') %}` |
| フォームの送信を受ける | POST モジュール（`ACMS_POST` を継承し、`post()` で `$this->Post` を返す） | `extension/acms/POST/Foo.php` / `extension/plugins/MyPlugin/POST/Foo.php` | 送信ボタンの `name="ACMS_POST_Foo"` |

- Twig の `module()` が呼べるのは V2 GET モジュールだけ。Twig のテーマ向けに作るなら、最初から V2 で作る。標準テンプレートと Twig の両方で使うなら、データを作る処理をクラスに分け、GET と V2 の両方から呼ぶ。
- プラグイン（拡張アプリ）の V2 モジュールを `Modules/Get/V2/` に置いて解決できるのは Ver. 3.2.27 以降。それより前は本体がプラグイン（拡張アプリ）の `Modules` 名前空間を探さない。ユーザー拡張の `Modules/Get/V2/` は Ver. 3.2 から使える。
- モジュール ID で使えるようにするには、管理画面のモジュール選択肢に足す（プラグイン（拡張アプリ）では `InjectTemplate` の `admin-module-select`。references/plugin-structure.md）。

## 名前の解決

- モジュール名の `_` は名前空間の `\` に対応する。`Own_Foo` は `GET/Own/Foo.php`、`V2_Own_Foo` は `Modules/Get/V2/Own/Foo.php`。
- 本体は次の順に名前空間を探し、最初に見つかったクラスを使う（`php/ACMS/Namespace.php`）。
  1. 本体のモジュール（`ACMS_GET_*`、`Acms\Modules\Get\V2\*`）
  2. ユーザー拡張（`Acms\Custom\*`、`Acms\Custom\Modules\*`）
  3. プラグイン（拡張アプリ）（有効なものを順に）
- そのため、本体と同じ名前のモジュールを作っても本体のものが使われる（上書きはできない）。ユーザー拡張とプラグイン（拡張アプリ）で名前が重なると、ユーザー拡張が使われる。名前は本体と重ならないものにする。

## GET モジュール

- 標準テンプレートの GET モジュールは、`new Template($this->tpl, new ACMS_Corrector())` で受け取ったテンプレートを描画して返す。変数は既定でエスケープされる（校正オプション `[raw]` を付けた変数を除く）。HTML を組み立てて文字列で返さず、テンプレートの変数に値を渡す。
- V2 モジュールは配列を返す。出力のエスケープは Twig の自動エスケープに任せる。HTML を返したいときも、テンプレート側で `|raw` を付ける判断は利用者に残す。
- `$this->keyword`・`$this->tag` などの URL コンテキストや、`$this->Get`（クエリ）、`module()` の第3引数（V2）で受け取る値は、利用者が URL で変えられる。SQL に入れるときは本体の `SQL` クラスで組み立て、文字列連結しない。

## POST モジュール

### CSRF

本体の `ACMS_POST::fire()`（`php/ACMS/POST.php`）が、`post()` を呼ぶ前に次を確かめる。どれかに失敗すると `post()` は呼ばれず、`beforePostFire` / `afterPostFire` も呼ばれない。

1. POST に `formToken` があるか
2. セッションに CSRF トークンがあるか
3. `$checkDoubleSubmit = true` のクラスでは、二重送信でないか
4. POST の `formToken` がセッションのトークンと一致するか
5. リファラーが自サイトか

- `formToken` は、本体が出力の直前に、HTML の各 `</form>` の前へ `<input type="hidden" name="formToken">` として自動で入れる（`php/Services/Security/CsrfTokenManager.php`）。テンプレートに `formToken` を書かない。`</head>` の前には `<meta name="csrf-token">` も入るので、JavaScript から送るときはこの値を `formToken` として送る。
- `protected $isCSRF = false;` にして検証を外さない。
- ログインしていない利用者のページでは、本体はセッションを始めず、その場限りのトークンを入れる（CDN などでキャッシュできるようにするため）。テンプレートに本体のフォームのモジュール名（`ACMS_POST_Form_` など）か `check-csrf-token` という文字列があるときだけ、セッションに保存したトークンを使う。独自の POST モジュールを公開側のフォームから呼ぶときは、フォームの `class` などに `check-csrf-token` を入れる。入れないと、送信のたびにトークン切れ（`CsrfTokenExpired`）になる。

### 権限とその他

- 本体は POST モジュールの権限を確かめない。管理者だけが使う処理なら、`post()` の先頭で `sessionWithAdministration()`（管理者）や `sessionWithContribution()`（投稿者以上）を確かめ、満たさなければ何もせずに `$this->Post` を返す。
- `post()` の中で `echo` などで出力しない。結果は `$this->Post` に入れて返し、表示は GET モジュール（テンプレート）で行う。別のページへ移すなら `$this->redirect()` を使う。
- 送信ボタンの `name` は `ACMS_POST_` + モジュール名。`ACMS_POST_Own_Foo` は `POST/Own/Foo.php`。
