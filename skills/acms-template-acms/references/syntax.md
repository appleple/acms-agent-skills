# 標準テンプレートの記法の詳細

迷ったら公式ドキュメントの該当ページを読む。ここには判断に必要な要点と、ドキュメントからは読み取りにくい挙動だけを置く。

## ページ一覧

| 内容 | ページ |
|---|---|
| 標準テンプレートの目次 | <https://developer.a-blogcms.jp/document/template/> |
| テンプレートの基本 | <https://developer.a-blogcms.jp/document/template/basic.html> |
| 実行順序 | <https://developer.a-blogcms.jp/document/template/execution-order.html> |
| モジュールに外部コンテキスト（ctx）を挿入する | <https://developer.a-blogcms.jp/document/template/entry-2851.html> |
| veil ブロック | <https://developer.a-blogcms.jp/document/template/veil.html> |
| touch ブロック | <https://developer.a-blogcms.jp/document/template/entry-2275.html> |
| IF ブロック | <https://developer.a-blogcms.jp/document/template/if.html> |
| エスケープ（処理を遅らせる） | <https://developer.a-blogcms.jp/document/template/entry-2274.html> |
| 波括弧を展開しない（@verbatim） | <https://developer.a-blogcms.jp/document/template/verbatim.html> |
| インクルード | <https://developer.a-blogcms.jp/document/template/include.html> |
| テンプレートの継承 | <https://developer.a-blogcms.jp/document/template/entry-2850.html> |
| テンプレートの変数化（SetTemplate / SetRendered） | <https://developer.a-blogcms.jp/document/template/entry-2276.html> |
| パスの書き換え | <https://developer.a-blogcms.jp/document/template/entry-1443.html> |
| テンプレート変数表 | <https://developer.a-blogcms.jp/document/template/varstable.html> |
| グローバル変数（テンプレートキャッシュで使える印つき） | <https://developer.a-blogcms.jp/document/reference/global_variable.html> |
| 校正オプション | <https://developer.a-blogcms.jp/document/reference/proofreading.html> |
| タッチモジュール | <https://developer.a-blogcms.jp/document/reference/touch.html> |
| テンプレートキャッシュ | <https://developer.a-blogcms.jp/document/cache/template-cache.html> |

## 実行順序

1つのページは次の順に組み立てられる。

1. テンプレートファイルを読むたびに、インクルードの引数 `{{key}}` を埋め、グローバル変数 `%{VAR}` を置き換え、パスを書き換えてから、その中の `@include` を読みにいく。`@extends` / `@section` もこの段階で解決する。
2. `SetTemplate` を集め、`GET_Template` に差し込む。
3. タッチモジュール（`Touch_` で始まるモジュール）を判定し、当てはまらないものは中身ごと取り除く（システム設定 `preprocess_touch` が既定の on のとき）。
4. モジュールを、入れ子の内側から（同じ階層では下から）実行する。
5. `BEGIN_MODULE\` でエスケープしたモジュールを実行する。
6. IF ブロックを評価する。
7. `SetRendered` を集め、`GET_Rendered` に差し込む。

ここから次のことが決まる。

| やりたいこと | 書き方 | 理由 |
|---|---|---|
| 条件によって重いモジュールを動かさない | グローバル変数でインクルードのパスを分ける。タッチモジュールで表せる条件ならタッチモジュールで囲む | IF ブロックはモジュールの後に評価されるので、囲んでもモジュールは実行される |
| モジュールの変数で表示を切り替える | IF ブロックをモジュールの中に書く | IF はモジュールの後なので変数が入っている |
| モジュールの変数でインクルードするファイルを変える | できない。グローバル変数で分けるか、IF ブロックで出し分ける | インクルードはモジュールより前 |
| 外側のモジュールの値を内側のモジュールの ctx に使う | 内側を `BEGIN_MODULE\` でエスケープする | 通常は内側が先に実行される |
| モジュールの外（サイドバーなど）にページャーを出す | `SetRendered` で囲み、`GET_Rendered` で呼ぶ | `SetRendered` は解決後の HTML を部品にする |

## モジュール

- `id="..."` のモジュール ID が効くのは、管理画面でそのモジュール名・ID で作られ、ステータスが有効で、表示中のブログで作られたもの、または親ブログで「グローバル」に設定されたものだけ。条件に合わない ID はモジュール ID なしと同じ動きになる。
- モジュール ID にキャッシュ時間を設定すると、キャッシュはモジュール名と ID だけで区別される（ログインしていない閲覧者が対象）。同じ ID を別のテンプレートや別の `ctx` で使うと、先に作られた HTML が出る。置く場所ごとに ID を分ける。
- `ctx="bid/1/cid/2"` で URL コンテキストを指定できる（使えるキーは公式ドキュメントのページを見る）。モジュール ID 側で値を固定した項目は `ctx` より優先される。
- `ctx` にはグローバル変数（`ctx="cid/%{CID}"`）を使える。モジュールの変数を使うときは、そのモジュールを外側のモジュールの中に置き、`BEGIN_MODULE\` でエスケープする。
- `<!-- BEGIN_MODULE ... -->` と `<!-- END_MODULE ... -->` のモジュール名が一致しないと、そのモジュールは実行されない。

## ブロック

ブロックは、モジュールが表示を指示したとき、または中の変数のどれかにモジュールが値を渡したときだけ出力される。どちらもなければ消える。

| ブロック | 使いどころ | 注意 |
|---|---|---|
| `x:loop` | 一覧の繰り返し | ブロック名は変数表で確かめる（`entry:loop` など） |
| `x:glue` | 繰り返しの間に出す区切り | `:loop` の中に置く。モジュールが用意している名前だけ動く |
| `x:veil` | 値が無いときに見出しごと消す | 特別な機能ではなく上の規則による。モジュールが空文字を渡すと消えないことがある。確実に消したいなら `BEGIN_IF [{var}/nem]` を使う |
| `x:touch#値` | 変数がその値のときだけ出す | 中に変数を書くと、その変数は空になる |
| `notFound` など | モジュールが用意した特別なブロック | モジュールの変数表で確かめる |

- 同じ名前のブロックを入れ子にしない。内側の `BEGIN` が無視され、内側の `END` で外側のブロックが閉じる。
- `BEGIN` と `END` の名前が食い違うと、ブロックとして扱われない。

## 変数と校正オプション

- `{var}[a|b(引数)]` の校正オプションは左から順に適用される。`raw`・`escape`・`resizeImg` のどれも含まなければ先頭に `escape` が付くので、`{body}[nl2br]` は「エスケープしてから改行を `<br>` に」の順になる。
- `raw` を含むとき、システム設定 `strip_dangerous_tag` が on なら危険なタグを取り除く処理が先頭に付く。`allow_dangerous_tag` を付けるとこの処理が外れる。
- 変数名が `selected` `checked` `disabled` `class` `attr`、または `:selected` / `:checked` を含むときは、オプションが空なら `raw`、`raw` も `escape` も無ければ `raw|` が先頭に付く（`<option{selected}>` のように属性ごと出すため）。
- グローバル変数は、モジュールより前に HTML エスケープした文字列として置き換わる。校正オプションは付けられない。
- JavaScript に値を埋め込むときは、校正オプションの一覧で用途に合うもの（`jsonEscape` など）を選ぶ。

## エスケープ（処理を遅らせる）

a-blog cms の「エスケープ」は、変数やブロックを1段階後のモジュールまで解決させないこと。

- 変数は `\{var\}`、ブロックは `<!-- BEGIN\ x -->` 〜 `<!-- END\ x -->`、モジュールは `<!-- BEGIN_MODULE\ 名前 -->` 〜 `<!-- END_MODULE\ 名前 -->`。
- 変数とブロックのバックスラッシュは、モジュールを1つ通るたびに1つ外れる。モジュールのエスケープは1段階だけ。
- JavaScript のテンプレートなど、波括弧をそのまま出したい広い範囲は `@verbatim` 〜 `@endverbatim` で囲む（中のグローバル変数 `%{VAR}` は置き換わる）。

## IF ブロック

- 書式は `[基準値/演算子/比較値]`。基準を左、比較する値を右に書く（`[{title}/lk/お知らせ]` は「title にお知らせが含まれる」）。
- `eq` / `neq` は文字列として完全一致を比べる。`gt` などは両辺が数値なら数値として比べる。`re` / `nre` の比較値は正規表現（区切り文字なしで書く）。
- `em` / `nem` は `"0"` を空とみなす。`"0"` を値ありとして扱いたいときは `isset` / `nisset`。
- 複数の条件は1つのブラケットの中で `_and_` / `_or_` でつなぐ。ブラケットを並べると、全体が1つの式として扱われ、2つ目以降の条件が比較値の一部になる。
- `_and_` は `_or_` より先に結び付き、括弧は使えない。複雑な条件は IF ブロックを入れ子にする（入れ子は使える）。
- 値に改行が入ると条件が評価できない。`{var}[delnl]` を付ける。値の中に `_and_` / `_or_` や `/and/` / `/or/` という並びがあると、条件の区切りと誤解される。
- `<!-- ELSE_IF [...] -->` と `<!-- ELSE -->` が使える。

## インクルード

```html
@include("/include/parts/heading.html", {"title": "お知らせ", "level": "2"})
```

- 先頭が `/` のパスは、テーマのディレクトリを基準に、テーマの継承に沿って探される。
- 第2引数は JSON（キーと値をダブルクォートで囲む）。JSON として読めないと引数は無視される。値に `)` を含められない。
- インクルード先では `{{title}}` で参照し、`{{title | default("見出し")}}` で既定値、`{{a | b}}` で左から空でない方を使う。引数の値はエスケープされずにそのまま入る。
- インクルード先のファイルが無いときは何も出力されない（エラーにならない）。グローバル変数でパスを分けるとき、該当しない値のファイルを置かなければ何も出ない。
- 旧記法の `<!--#include file="..."-->` も動くが、新しく書くときは `@include` を使う。

### テンプレートキャッシュとの関係

- テンプレートキャッシュが有効（システム設定 `template_cache` が on、かつデバッグモードでない）だと、インクルードのパスの中で置き換わるグローバル変数が、キャッシュのキーに使う一部（`%{BCD}`・`%{CCD}`・`%{ECD}`・`%{ALIAS_CODE}` など）に限られる。一覧はグローバル変数のページの印か、テンプレートキャッシュのページで確かめる。
- それ以外の変数（`%{CID}`、`%{EID}` など）をパスに使うと、パスに `%{...}` が残ったままファイルを探すので、何も読み込まれない。デバッグモードでは動くので気付きにくい。ID ではなくコード（`%{CCD}` など）を使う。
- 使えるグローバル変数は、プラグイン（拡張アプリ）や `extension/acms/Hook.php` の `addGlobalVarsInIncludePath` で足せる。ページごとに値が変わる変数を足すとキャッシュの効果がなくなる。
- テンプレートを編集したら、管理画面からテンプレートキャッシュを消す（消すまで反映されない）。

## テンプレートの継承

- 子テンプレートに `@extends("/layout/base.html")` を書き、差し替える範囲を `@section(名前)` 〜 `@endsection` で囲む。
- 親の同じ名前のセクションの中身を残すときは、子のセクションに `@parent` を書く。さらに上の親は `@@parent`。
- 継承は何段でもできる。

## SetTemplate / SetRendered

| | SetTemplate / GET_Template | SetRendered / GET_Rendered |
|---|---|---|
| 部品にする時点 | モジュール実行前のテンプレート | モジュール・IF ブロックの解決後の HTML |
| 囲んだ部分 | 表示されず、`GET_Template` で呼ぶまで実行されない | 囲んだ位置で実行され、表示はされない |
| 向いている用途 | 同じ形の部品を何度も呼ぶ（呼ぶたびにモジュールが動く） | モジュールの中で作った HTML を、モジュールの外で表示する |

- `<!-- GET_Template id="card" title="お知らせ" -->` のように属性で値を渡すと、部品の中の `{{title}}` に入る。値は HTML エスケープされる。`<!-- BEGIN_SetTemplate id="card" title="既定" -->` の属性は既定値になる。
- `trim="1"` を付けると、呼び出した部品の改行を取り除く。
- 同じ `id` を複数定義すると、後に書いた方が使われる。
- インクルードは SetTemplate より前に解決されるため、`{{title}}` をインクルードのパスに使っても効かない。
- ポストインクルードで読み込むテンプレートからは、元のページの SetTemplate / SetRendered は見えない。読み込まれる側で定義し直す。

## 直接表示させないテンプレート

- システム設定 `forbid_direct_access_tpl` に正規表現（配布時の設定は `/^_/`）が入っていると、パスをディレクトリ・ファイル名に分けたどれかが一致するテンプレートは、URL から直接表示されない。
- インクルード専用の部品や、エントリー詳細（既定の `_entry.html`）・トップページ（既定の `_top.html`）のようにシステムが選んで表示するテンプレートは、`_` で始まる名前にする。
- 設定が off のサイトでは効かない。
