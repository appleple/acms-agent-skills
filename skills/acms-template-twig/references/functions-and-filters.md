# Twig で使える a-blog cms の関数・フィルター・変数

`module()` の引数や戻り値で迷うとき、a-blog cms 独自の関数やフィルターを使うとき、値が空になる・エラーになる原因を探すときに読む。

## module()

```twig
{% set data = module('V2_Entry_Summary', 'news_list', { cid: 3, limit: 5 }) %}
```

| 引数 | 内容 |
|---|---|
| 第1引数 | V2 モジュール名（`V2_` で始まる）。必須 |
| 第2引数 | モジュール ID の識別子。省略するか `null` |
| 第3引数 | URL コンテキストのハッシュ。キーは `bid` `cid` `eid` `uid`（数値か数値の配列）、`page` `limit`、`keyword` `tag` `field` `order` `start` `end` |

- 戻り値は配列。HTML は返さない。中身（`items`、`pagination` など）はモジュールごとに違うので、デバッグモードの変数表（`Ctrl + K` → `#`）か、配布物の `themes/system/acms-code/snippets/v2_*.html` で確かめる。
- モジュール ID は、現在のブログのもの、または親ブログでグローバルに設定された公開中のものから探す。見つからなくてもエラーにはならず、モジュールの既定の設定で動く。設定が効かないときは、識別子・公開状態・ブログを確かめる。
- モジュール ID の設定画面で引数（ブログ・カテゴリーなど）を指定していると、第3引数より優先される。テンプレートで渡した値が効かないときは、モジュール ID の設定を確かめる。
- モジュール ID が指すエントリー・ブログを閲覧できない状態のときは、空の配列が返る。
- 存在しないモジュール名（打ち間違い）を渡すと、エラーにならず空の配列が返る。従来のモジュール名（`Entry_Summary` など）は呼べない。
- 戻り値の `moduleInfo` は管理者としてログインしているときだけ入る。`/admin/module/setting.twig` に渡して編集ボタンを出すのに使う。
- 同じ管理画面の設定を複数の場所で使い分けたいとき、キャッシュを効かせたいとき、編集ボタンからその場所の設定を開きたいときは、モジュール ID を作って第2引数に渡す（ID が無いと設定を場所ごとに持てない）。

公式: <https://developer.a-blogcms.jp/document/twig/module.html>、モジュール ID: <https://developer.a-blogcms.jp/document/moduleid/>

### カスタムフィールドの値

V2 モジュールが返すフィールドは、1 項目ごとに `{ value: 最初の値, array: すべての値 }` の形になる。

- 出力・比較には `.value` を付ける（`fields.color.value == 'red'`）。`fields.color == 'red'` は常に偽になる。
- チェックボックスなど複数の値は `.array` をループする。
- メディアやグループなどの形は acms-custom-field を読む。

## touch()

- `touch('Touch_Login')` のようにモジュール名だけを渡し、真偽値を受け取る。モジュール ID や引数は渡せない。
- 標準テンプレートのタッチモジュールはすべて呼べる。Twig の条件式なので `and` / `or` / `not` やグローバル変数と組み合わせられる。
- タッチモジュールの一覧: <https://developer.a-blogcms.jp/document/reference/touch.html>

## そのほかの関数・タグ

| 名前 | 内容 |
|---|---|
| `include(パス, 変数, with_context, ignore_missing)` | Twig 標準の `include` を a-blog cms が置き換えたもの。引数は同じ。デバッグモードでは前後にパスの HTML コメントを出す（Ver. 3.2.15 以降）。ignore_missing は名前付きで渡す（`ignore_missing = true`）か、タグで `{% include '/x.twig' ignore missing %}` と書く |
| `vite(エントリー, オプション)` / `viteReactRefresh()` | Vite でビルドしたアセットの読み込みタグを出す。標準テンプレートの `@vite()` にあたる。<https://developer.a-blogcms.jp/document/vite.html> |
| `acms_config(スコープ)` | コンフィグの値を読むオブジェクトを返す（Ver. 3.2.24 以降）。<https://developer.a-blogcms.jp/document/twig/acms-config.html> |
| `{% markdown %}…{% endmarkdown %}` | 囲んだ Markdown を HTML にして出す |
| `dump()` | 変数の中身を出す。デバッグモードのときだけ出力される |

## フィルター（校正オプション）

- 校正オプションは、システムのもの・`extension/acms/Corrector.php` で足したもののどちらも、同じ名前のフィルターとして使える。校正オプションの引数はフィルターの引数として並べる（`|resizeImg(640)`、`|mb_trim(20, '…')`）。
- Twig 標準のフィルターと名前が重なるもの（Ver. 3.2.38 時点で `date` `escape` `nl2br` `number_format` `split` `striptags` `trim`）は Twig 側になる。a-blog cms 版は `acms_` を付けて呼ぶ。`acms_` 付きの名前は、重ならない校正オプションにも用意されている（`safe_html` を除く）。
- 校正オプション由来のフィルターの出力は、`safe_html` を除いて自動エスケープの対象になる。HTML を返すものの後ろには `|safe_html` を付ける。
- 校正オプションの一覧: <https://developer.a-blogcms.jp/document/reference/proofreading.html>、独自の校正オプション: <https://developer.a-blogcms.jp/document/user_corrector/>、Twig での使い方: <https://developer.a-blogcms.jp/document/twig/filter.html>

## グローバル変数

- 標準テンプレートの `%{BLOG_NAME}` は、Twig では `{{ BLOG_NAME }}`（`%{` `}` を外した名前）。条件式やフィルターにもそのまま使える。
- 値は文字列のものが多い（`IS_ADMIN` は `'1'` / `'0'`）。`{% if IS_ADMIN %}` は `'0'` を偽として扱うのでそのまま使える。
- 一覧: <https://developer.a-blogcms.jp/document/reference/global_variable.html>

## Twig の設定と、起きやすい誤り

a-blog cms の Twig は、自動エスケープが HTML、`strict_variables` が無効（既定のまま）、デバッグはデバッグモードに連動する。

- `strict_variables` が無効なので、存在しない変数や `a.b.c` の途中が無いものはエラーにならず空になる。変数名の打ち間違いに気付きにくいので、値が出ないときは変数表で名前を確かめる。前段の存在チェック（`{% if a and a.b %}`）は要らない。
- 否定は `!` ではなく `not`、論理演算は `&&` `||` ではなく `and` `or`、文字列の連結は `+` ではなく `~`。
- `|default('x')` が効くのは、未定義・`null`・空文字・`false`・空配列のとき。`0` には効かない。
- `{% for %}` の中で初めて `set` した変数は、ループの外では空になる。ループの後で使う値は、ループの前で `set` しておく（中で書き換えた値は外に残る）。
- ブロック名に使えるのは英数字とアンダースコアだけ（`head-js` は不可）。
