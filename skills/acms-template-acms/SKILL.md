---
name: acms-template-acms
description: >-
  a-blog cms（acms）の標準テンプレート（従来の独自記法）を書く・直す・読むときの記法と判断基準。
  <!-- BEGIN_MODULE --> によるモジュール配置とモジュール ID（id）・URL コンテキストの指定（ctx）、ブロック（:loop / :glue / :veil / :touch）、
  変数 {var} とグローバル変数 %{VAR}、校正オプション [option] と既定のエスケープ・raw の扱い、BEGIN_IF の演算子と _and_ / _or_、
  @include / @extends / @section、SetTemplate / SetRendered、実行順序とテンプレートキャッシュ、直接表示させないテンプレート（先頭の _）を扱う。
  Twig が有効でないテーマの .html テンプレートを編集するとき、BEGIN_MODULE・BEGIN_IF・{var}[option]・@include を含むファイルを触るとき、
  「条件でモジュールを出し分けたい」「表示が重い」「インクルードが効かない」と頼まれたときに使う。
  a-blog cms standard template syntax, module, include, escape.
  Twig テンプレート（.twig、module('V2_...')）は acms-template-twig、フォームの記法は acms-form、
  カスタムフィールド・カスタムユニットは acms-custom-field、テーマの構成は acms-theme-development が担う。
license: MIT
compatibility: a-blog cms Ver. 3.2 以上
metadata:
  acms-min-version: "3.2"
  status: stable
---

# a-blog cms の標準テンプレート

公式ドキュメント: <https://developer.a-blogcms.jp/document/template/>

## 書く前に

- テーマが Twig（`template.yaml` の `tpl_twig: enabled`）でないことを確かめる。Twig のテーマなら acms-template-twig を使う。
- 何を表示するモジュールを使うか決まっていなければ、acms-module-reference で選ぶ。
- 変数名・ブロック名は推測しない。モジュールの変数表（acms-module-reference から辿る）か、同じテーマの既存テンプレートで確かめる。
- フォーム（`{field:v}`、`:validator`、確認画面）の書き方は acms-form、カスタムフィールド・カスタムユニットの入力欄と出力は acms-custom-field を使う。

## 記法の要点

```html
<!-- BEGIN_MODULE Entry_Summary id="news_list" ctx="bid/1/cid/2" -->
<!-- BEGIN entry:loop -->
<a href="{url}">{title}</a><!-- BEGIN entry:glue -->, <!-- END entry:glue -->
<!-- END entry:loop -->
<!-- BEGIN notFound -->記事がありません<!-- END notFound -->
<!-- END_MODULE Entry_Summary -->

<!-- BEGIN_IF [%{PAGE}/gte/2/_and_/%{KEYWORD}/nem] -->2ページ目以降の検索結果<!-- END_IF -->
@include("/include/parts/card.html", {"title": "見出し"})
```

| 記法 | 意味 |
|---|---|
| `<!-- BEGIN_MODULE 名前 id="..." ctx="..." -->` | モジュールの配置。`id` はモジュール ID、`ctx` は URL コンテキストの指定 |
| `<!-- BEGIN x -->` 〜 `<!-- END x -->` | ブロック。モジュールが表示を指示したとき、または中の変数のどれかに値が渡されたときだけ出る |
| `x:loop` / `x:glue` | 繰り返し / 繰り返しの間の区切り（モジュールが用意している名前だけ使える） |
| `x:veil` | 中の変数に1つも値が渡されなければ消える（上のブロックの規則を使った命名） |
| `x:touch#値` | 変数がその値のときだけ出る。中に変数を書かない |
| `{var}` / `%{VAR}` | モジュールの変数（そのモジュールの中だけ）/ グローバル変数（どこでも） |
| `{var}[option]` | 校正オプション。複数のときはパイプ記号で区切る |
| `<!-- BEGIN_IF [値/演算子/値] -->` | 条件分岐。`ELSE_IF` / `ELSE` / `END_IF` |
| `@include` / `@extends` / `@section` / `@parent` | インクルードとテンプレートの継承 |
| `<!-- BEGIN_SetTemplate id="..." -->` / `<!-- GET_Template id="..." -->` | 解決前のテンプレートを部品にして呼び出す（Rendered は解決後） |

各記法の細部（モジュール ID の効く範囲、ブロックの規則、エスケープ `\{var\}`・`BEGIN_MODULE\`、`@verbatim`、インクルードの引数、SetTemplate の変数）は references/syntax.md を読む。

## 実行順序から決まること（必ず守る）

処理はおおまかに「グローバル変数 → インクルード・継承 → SetTemplate → タッチモジュール → モジュール（内側から）→ IF ブロック → SetRendered」の順に進む。詳しい順序は references/syntax.md の「実行順序」を読む。

- **IF ブロックで囲んでも、中のモジュールとインクルードは実行される。** IF はモジュールより後に評価され、出力を捨てるだけになる。表示しない分岐の重いモジュールを止めたいときは、次のどちらかにする。
  - グローバル変数でインクルードのパスを分ける: `@include("/include/top/%{BCD}.html")`。インクルード先が無ければ何も出ない（エラーにならない）ので、出したいときだけファイルを置く。
  - 条件がタッチモジュール（`Touch_Entry`、`Touch_Login` など）で表せるなら、タッチモジュールで囲む。タッチモジュールは他のモジュールより先に判定され、当てはまらなければ中身ごと取り除かれる（システム設定 `preprocess_touch` が既定の on のとき）。
- IF ブロックは最後に評価されるので、条件にモジュールの変数を使える（モジュールの中・ループの中に書く）。
- インクルードのパスにはモジュールの変数 `{var}` を使えない（インクルードのときにはまだ値がない）。使えるのはグローバル変数だけ。
- **テンプレートキャッシュが有効なとき（配布時の設定は on。デバッグモードでは無効）、インクルードのパスで使えるグローバル変数は限られる**（`%{BCD}`・`%{CCD}`・`%{ECD}` など）。それ以外（`%{CID}` など）をパスに使うと、デバッグモードでは動くのに本番で読み込まれない。使える変数はグローバル変数の一覧の印で確かめる: <https://developer.a-blogcms.jp/document/reference/global_variable.html>
- 入れ子のモジュールは内側から実行される。外側のモジュールの値を内側のモジュールの `ctx` などに使うときは、内側を `<!-- BEGIN_MODULE\ 名前 -->` でエスケープして後に回す。

## 校正オプションとエスケープ（必ず守る）

- `{var}` は既定で `escape` される。`[nl2br]` や `[trim(20)]` のように他の校正オプションを付けても、`raw`・`escape`・`resizeImg` のどれも含まなければ `escape` が自動で先頭に付く。改行を `<br>` にしたいだけなら `{var}[nl2br]` と書き、`raw` を足さない。
- `[raw]` はエスケープを外すだけで、HTML の無害化ではない。システム設定 `strip_dangerous_tag` が on なら `raw` の値から危険なタグが取り除かれるが、off のサイトもある。
- `[raw|allow_dangerous_tag]` は script や iframe もそのまま出す。管理者だけが入力する値で、利用者が明示的に求めたときに限る。
- フォームの入力値など、不特定の人が入力した値には `raw` を付けない。
- 変数名が `selected` `checked` `disabled` `class` `attr`、または `:selected` / `:checked` を含む変数には `raw` が自動で付く。ここにユーザーの入力値を入れない。
- グローバル変数 `%{VAR}` は HTML エスケープした文字列として先に置き換わる。校正オプションは付けられない。
- 値の `javascript:` などの危険なスキームは、システム設定 `sanitize_scheme` が既定の on なら `#` に置き換わる。

校正オプションの一覧: <https://developer.a-blogcms.jp/document/reference/proofreading.html>

## IF ブロックの条件（よく間違える）

- 書式は `[基準値/演算子/比較値]`。演算子は `eq` `neq` `gt` `gte` `lt` `lte` `lk` `nlk` `re` `nre` `em` `nem` `isset` `nisset`。`em` は `"0"` も空とみなし、`isset` は `"0"` を値ありとみなす。
- 複数の条件は **1つのブラケットの中で** `_and_` / `_or_` でつなぐ: `[{a}/nem/_and_/{b}/nem]`。`[{a}/nem][{b}/nem]` とブラケットを並べても AND にならない（ブラケットは取り除かれ、全体が1つの式として評価されて結果が狂う）。
- `_and_` は `_or_` より先に結び付く（`A _or_ B _and_ C` は `A または (B かつ C)`）。括弧は使えない。
- 改行が入りうる変数は `{var}[delnl]` にしてから比べる。

## 直接表示させないテンプレート

- インクルード専用の部品など、URL で直接開かれたくないテンプレートは、ファイル名かディレクトリ名の先頭を `_` にする。システム設定 `forbid_direct_access_tpl` が `/^_/`（配布時の設定）のとき、パスのどこかが `_` で始まるテンプレートは URL から直接表示されない。
- この設定が off のサイトでは効かない。直接表示されて困るなら、サイトの設定を利用者に確かめてもらう。

## よくある誤り

- モジュールの外で `{var}` を使う（値が入らない）。
- `BEGIN` と `END` のブロック名・モジュール名が一致していない。同じ名前のブロックを入れ子にする（内側の BEGIN が無視され、内側の END で外側が閉じてしまう）。
- 同じモジュールを複数置いたのにモジュール ID を分けない。設定が混ざり、モジュール ID にキャッシュ時間を設定するとキャッシュも共有される。
- `:touch#値` のブロックの中に変数を書く（変数は空になる）。
- IF ブロックで重いモジュールを囲んで負荷を減らしたつもりになる。
- Twig のテーマに BEGIN_MODULE を書く（Twig テーマでは V2 モジュールを `module()` で呼ぶ）。

## 確認

- デバッグモードでは、インクルードしたテンプレートのパスが HTML コメント（`<!-- Start of include : source=... -->`）に出る。意図したファイルが使われているか確かめる。
- 本番（デバッグモード off）とデバッグモードで表示が違うときは、テンプレートキャッシュ（インクルードのパスのグローバル変数、テンプレート編集後のキャッシュクリア）を疑う: <https://developer.a-blogcms.jp/document/cache/template-cache.html>
- 変数が空になるときは、変数表で名前と、どのブロックの中で使えるかを確かめる。
