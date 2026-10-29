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
| `{var}` | `{{ item.var }}`（V2 モジュールの変数名は従来のモジュールと違うことがある。変数表で確かめる） |
| `%{BLOG_NAME}` | `{{ BLOG_NAME }}` |
| `{var}[raw]` | `{{ var|safe_html }}` |
| `{var}[raw|allow_dangerous_tag]` | `{{ var|raw }}` |
| `{date}[date('Y/m/d')]`、`{date#Y}` | `{{ entry.datetime|acms_date('Y/m/d') }}` |
| `{path}[resizeImg(800)]` | `{{ path|resizeImg(800) }}` |
| `@include("/x.html", {"k": "v"})` | `{{ include('/x.twig', { k: 'v' }) }}` |
| `@extends(/layout.html)` / `@section(main)` / `@parent` | `{% extends '/layout.twig' %}` / `{% block main %}` / `{{ parent() }}` |

## 注意

- 移したら、元のページと表示を比べて確かめる。特に日付・画像サイズ・HTML を含む項目（エスケープの違いが出やすい）。
- V2 モジュールの戻り値の構造（`items` のほか、ページ送りの情報など）はモジュールごとに違う。変数表（デバッグモードで `Ctrl + K` → `#`）で確かめる。
- 公式のチュートリアル: <https://developer.a-blogcms.jp/document/twig-template/>
