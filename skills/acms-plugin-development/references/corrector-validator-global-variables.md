# 校正オプション・検証オプション・グローバル変数の追加

公式ドキュメント:
- 校正オプションの拡張: <https://developer.a-blogcms.jp/document/user_corrector/user_corrector.html>（プラグイン（拡張アプリ）では <https://developer.a-blogcms.jp/document/develop_apps/entry-2909.html>）
- Validator の拡張: <https://developer.a-blogcms.jp/document/user_validator/entry-2393.html>（プラグイン（拡張アプリ）では <https://developer.a-blogcms.jp/document/develop_apps/entry-2911.html>）
- グローバル変数の一覧: <https://developer.a-blogcms.jp/document/reference/global_variable.html>

## 校正オプション（Corrector）

- ユーザー拡張は `extension/acms/Corrector.php`（`Acms\Custom\Corrector`）に public メソッドを足す。プラグイン（拡張アプリ）は自前のクラスを `CorrectorFactory::singleton()->attach()` する。
- メソッドは `($txt, $args = [])` を受け取り、文字列を返す。`$args` はテンプレートで書いた引数の配列。
- テンプレートからの呼び方:

| テンプレート | 書き方 | 注意 |
|---|---|---|
| 標準テンプレート | `{var}[myFormat('a', 'b')]` | 既定ではエスケープが先に掛かるので、メソッドはエスケープ済みの文字列を受け取り、戻り値はそのまま出力される |
| Twig | `{{ var\|myFormat('a', 'b') }}` | Twig の自動エスケープが戻り値に掛かる。Twig 標準と同じ名前のメソッドは `acms_` 付き（`acms_nl2br` など）でしか呼べない。`acms_` 付きの名前はどのメソッドにも用意される |

- 同じ名前のメソッドが複数あるとき、標準テンプレートではユーザー拡張 → 本体 → プラグイン（拡張アプリ）の順で最初に見つかったものが使われる。プラグイン（拡張アプリ）の校正オプションは、本体の校正オプションと同じ名前にすると呼ばれない。Twig では逆に後から登録されたものが使われるため、同じ名前にすると標準テンプレートと Twig で結果が変わる。
- 標準テンプレートでは、メソッドが受け取った文字列を戻すときにエスケープを外す処理（`html_entity_decode` など）をしない。戻り値はそのまま出力されるため、入力に含まれた HTML が有効になる。
- Twig の Filter として Twig 専用の機能を足すなら、校正オプションではなく `extendsTwig` Hook で `registerFilter()` する（Ver. 3.2.24 以降）。標準テンプレートでも使うものだけを校正オプションにする。

## 検証オプション（Validator）

- ユーザー拡張は `extension/acms/Validator.php`（`Acms\Custom\Validator`）に public メソッドを足す。プラグイン（拡張アプリ）は `ValidatorFactory::singleton()->attach()` する。
- メソッドは `($val, $arg)` を受け取り、正しければ `true` を返す。`$arg` はテンプレートの `name="field:v#method"` の `value`。名前が `all_` で始まるメソッドは、値を1件ずつではなく配列でまとめて受け取る。
- テンプレートでの呼び方は本体の検証オプションと同じ（`<input type="hidden" name="var:v#myCheck" value="引数">`、エラー表示は `<!-- BEGIN var:validator#myCheck -->`）。記法は acms-template-acms を読む。
- 管理画面のフォーム編集の「入力チェック」に出すには、メソッドに `#[AsValidationOption(label: '...', group: '...')]` を付ける（Ver. 3.2.24 以降）。付けなくても、テンプレートに書けば検証には使われる。
- 同じ名前のメソッドは、ユーザー拡張 → 本体 → プラグイン（拡張アプリ）の順で最初に見つかったものが使われる。プラグイン（拡張アプリ）の検証オプションを本体と同じ名前（`required` など）にすると呼ばれない。
- 見つからない名前を指定したとき、またはメソッドの中で例外が出たとき、本体は例外を出さず、`value`（引数）が空でなければ「正しい」と扱う（`php/ACMS/Validator.php`）。プラグイン（拡張アプリ）を無効にしたブログや名前の打ち間違いでは、検証が黙って素通りする。検証が効いているかは、わざと誤った値を送って確かめる。

## グローバル変数

| したいこと | Hook | 注意 |
|---|---|---|
| テンプレートで `%{MY_VAR}`（Twig では `{{ MY_VAR }}`）を使えるようにする | `extendsGlobalVars(&$globalVars)` で `$globalVars->set('MY_VAR', $value)` | 本体のグローバル変数や、同じ名前のクエリパラメーターがあるとそちらが優先され、設定した値は使われない。本体と重ならない名前にする |
| インクルードのパス（`@include("/include/%{MY_VAR}.html")`）で使えるようにする | `addGlobalVarsInIncludePath(&$globalVarNames)` で `$globalVarNames[] = 'MY_VAR'` | 下の「テンプレートキャッシュ」を読む |

- 値は出力時に本体がエスケープする。エスケープ済みの値を渡さない（二重にエスケープされる）。
- `extendsGlobalVars` は、テンプレートを使うほぼすべてのリクエストで呼ばれる（結果はリクエストの中で使い回される）。ここで外部への通信や重い DB の問い合わせをしない。ページによって要らない値なら、GET モジュールで出す。

### テンプレートキャッシュ

テンプレートキャッシュ（コンフィグ `template_cache`）が有効なとき、本体はインクルードのパスに使えるグローバル変数を `BCD`・`CCD`・`ECD`・`MODULE_ID` などの決まった一覧に限る（`php/ACMS/function.php` の `setGlobalVarsForInclude()`）。一覧にない変数をパスに書くと、キャッシュ有効時だけ解決されない。

`addGlobalVarsInIncludePath` で一覧に足すと、その変数の値がテンプレートキャッシュのキーに入る（`getTemplateCacheKey()`）。値の種類の数だけ別のキャッシュができるので、次を守る。

- 値の種類が少ない変数（デバイスの種別、ログイン状態の区分など）だけを足す。エントリー ID・日時・検索語のように、ページごとに値が変わる変数を足さない。キャッシュがほぼ効かなくなり、キャッシュの量も増え続ける。
- 足す前に、テンプレートの側で分岐できないか（`BEGIN_IF` や Twig の `if`）を考える。
- デバッグモードではテンプレートキャッシュが無効になるので、デバッグモードで正しく表示されても、キャッシュ有効時の動作は別に確かめる。
