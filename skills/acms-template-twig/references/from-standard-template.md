# 標準テンプレートから Twig への対応表

標準テンプレートを Twig に移すとき、または標準テンプレートの知識で Twig を書くときに読む。

| 標準テンプレート | Twig |
|---|---|
| `<!-- BEGIN_MODULE Entry_Summary id="x" -->` … `<!-- END_MODULE Entry_Summary -->` | `{% set data = module('V2_Entry_Summary', 'x') %}`（V2 モジュールに置き換える。データを返すだけで HTML は出さない） |
| `ctx="bid/1/cid/2"` | `module('V2_...', 'x', { bid: 1, cid: 2 })` |
| `<!-- BEGIN entry:loop -->` … `<!-- END entry:loop -->` | `{% for entry in data.items %}` … `{% endfor %}` |
| `<!-- BEGIN notFound -->` | `{% for %}` の `{% else %}`、または `{% if data.items is empty %}` |
| `<!-- BEGIN x:veil -->` | `{% if x %}` … `{% endif %}` |
| `<!-- BEGIN x:glue -->,<!-- END x:glue -->` | `{% if not loop.last %},{% endif %}` |
| `<!-- BEGIN_IF [{a}/eq/b] -->` | `{% if a == 'b' %}` |
| `<!-- BEGIN_IF [{a}/nem] -->` | `{% if a is not empty %}` |
| `<!-- BEGIN_MODULE Touch_Login -->` | `{% if touch('Touch_Login') %}` |
| `{var}` | `{{ item.var }}`（V2 モジュールの変数名と構造は従来のモジュールと違う。変数表で確かめる） |
| カスタムフィールドの `{color}` | `{{ fields.color.value }}`（V2 モジュールでは `{ value, array }` の形） |
| `%{BLOG_NAME}` | `{{ BLOG_NAME }}` |
| `{var}[raw]` | `{{ var|safe_html }}` |
| `{var}[raw|allow_dangerous_tag]` | `{{ var|raw }}` |
| `{var}[nl2br]` | `{{ var|nl2br }}`（Twig の `nl2br` は先にエスケープしてから `<br>` を入れる） |
| `{var}[trim(100, '…')]` | `{{ var|acms_trim(100, '…') }}`（表示幅で切る。`|trim` は Twig 標準の別物でエラーになる）。文字数で切るなら `|mb_trim(100, '…')` |
| `{date}[date('Y/m/d')]`、`{date#Y}` | `{{ entry.datetime|date('Y/m/d') }}`。値が空のことがあるなら `|acms_date('Y/m/d')`（Twig の `date` は空のとき現在日時を出す） |
| `{path}[resizeImg(800)]` | `{{ path|resizeImg(800) }}` |
| `@include("/x.html", {"k": "v"})` | `{{ include('/x.twig', { k: 'v' }) }}` |
| `@extends(/layout.html)` / `@section(main)` / `@parent` | `{% extends '/layout.twig' %}` / `{% block main %}` / `{{ parent() }}` |

## 移すときに挙動が変わる点

- 標準テンプレートの `@include` は、ファイルが無くても何も出さずに続く。Twig の `include` は、ファイルが無いとエラーになる。無いかもしれない部品は `ignore_missing = true` を名前付きで渡す。
- 標準テンプレートの `@include` は相対パスを今のファイルから解決するが、Twig の `include` / `extends` のパスは常にテーマのルートから探す。部品の中の画像・CSS の相対パスはルートのテンプレートの場所から解決される（references/rendering.md）。`/` から書く。
- 標準テンプレートでは `BEGIN_IF` の中のモジュールも実行されるが、Twig の `{% if %}` の中の `module()` は条件が偽なら実行されない。
- 標準テンプレートの `{var}` は既定で `escape` が付く。Twig も `{{ }}` で自動エスケープされるので、エスケープ用のフィルターは足さない（`|acms_escape` を足すと二重にエスケープされる）。
- 移す途中は、ルートを Twig にしたまま、まだ移していない部品を `include` で読み込める（標準テンプレートの記法は Twig の後で処理される）。逆に、標準テンプレートの `@include` で読み込む部品の中に Twig を書いても処理されない。

## 確かめること

- 移したら、元のページと表示を比べる。特に日付・画像サイズ・HTML を含む項目（エスケープとフィルターの違いが出やすい）。
- V2 モジュールの戻り値の構造（`items` のほか、`pagination` などページ送りの情報）はモジュールごとに違う。変数表（デバッグモードで `Ctrl + K` → `#`）で確かめる。
- 公式のチュートリアル: <https://developer.a-blogcms.jp/document/tutorial/twig-template/>
