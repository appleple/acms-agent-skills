---
name: acms-template-twig
description: >-
  a-blog cms（acms）の Twig テンプレートを書く・直す・標準テンプレートから移すときの記法と判断基準（Ver. 3.2 以降）。
  module('V2_...') によるデータ取得、touch() による出し分け、グローバル変数、フィルター（校正オプション、acms_ 接頭辞）、
  自動エスケープと safe_html / raw、include / extends、標準テンプレートとの併用ルールを扱う。
  template.yaml に tpl_twig: enabled があるテーマ、.twig ファイル、{% %} や {{ }} を含むテンプレートを編集するとき、
  「Twig で書いて」「標準テンプレートを Twig に移して」と頼まれたときに使う。
  a-blog cms Twig template. 標準テンプレート（BEGIN_MODULE）は acms-template-acms が担う。
license: MIT
compatibility: a-blog cms Ver. 3.2 以上（Twig テンプレートは Ver. 3.2 で追加）
metadata:
  acms-min-version: "3.2"
  status: draft
---

# a-blog cms の Twig テンプレート

公式ドキュメント: <https://developer.a-blogcms.jp/document/twig/>

## 書く前に

- テーマで Twig が有効か確かめる（`template.yaml` の `tpl_twig: enabled`、または管理画面のテーマ設定）。無効なテーマに `.twig` を置いても Twig として処理されない。
- 何を表示するモジュールを使うか決まっていなければ、acms-module-reference で選ぶ。Twig で使えるのは名前が `V2_` で始まるモジュールだけ。
- ファイルは `.twig` で作る（`index.twig` → `index.html.twig` → `index.html` の順に探される）。

## 記法の要点

```twig
{% extends '/_layouts/base.twig' %}

{% block main %}
  {% set entrySummary = module('V2_Entry_Summary', 'news_list', { bid: BID, cid: CID, page: PAGE }) %}

  {% if touch('Touch_Category') %}
    <h1>{{ CATEGORY_NAME }}</h1>
  {% endif %}

  {% for entry in entrySummary.items %}
    <a href="{{ entry.url }}">{{ entry.title }}</a>
    <time>{{ entry.datetime|acms_date('Y年m月d日') }}</time>
  {% else %}
    <p>記事がありません</p>
  {% endfor %}

  {{ include('/include/parts/card.twig', { title: 'お知らせ' }) }}
{% endblock %}
```

| やりたいこと | 書き方 |
|---|---|
| モジュールのデータを取る | `module('V2_名前', 'モジュールID', { URL コンテキスト })`。第2・第3引数は省略可。戻り値を `set` して使う |
| 表示を出し分ける | `touch('Touch_名前')` は真偽値を返す。`{% if %}` と組み合わせる |
| グローバル変数 | `{{ BLOG_NAME }}`、`{{ CID }}` のように `{{ }}` で参照する |
| 部品を読み込む | `{{ include('/path.twig', { 変数 }) }}`。無いかもしれないファイルは第3引数に `ignore_missing = true` |
| レイアウトを継承する | `{% extends %}` をテンプレートの最初のタグにし、`{% block %}` を上書きする。`parent()` で親の中身を残す |
| 変数名を調べる | 管理者でログインし、デバッグモードで `Ctrl + K`（Mac は `⌘ + K`）→ `#` を入力すると、そのページの V2 モジュールの変数表が出る |

標準テンプレートとの対応表は references/from-standard-template.md を読む。

## エスケープ（必ず守る）

- `{{ }}` の出力は自動でエスケープされる。そのままにする。
- HTML を出したいときは、まず `|safe_html` を使う（HTMLPurifier で危険な要素・属性を取り除く。標準テンプレートの `[raw]` に相当）。
- `|raw` はエスケープを外し、script も含めてそのまま出す（標準テンプレートの `[raw|allow_dangerous_tag]` に相当）。管理者だけが入力する値で、利用者が明示的に求めたときに限る。フォームの入力値には使わない。

## フィルター（校正オプション）

- 標準テンプレートの校正オプションは Twig のフィルターとして使える（`{{ path|resizeImg(800) }}`）。
- Twig 標準のフィルターと名前が重なるもの（`date` `escape` `nl2br` `trim` `number_format` `split` など）は Twig 側が使われる。a-blog cms の校正オプションの動きが欲しいときは `acms_` を付ける（`|acms_date('Y年m月d日')`）。日付の書式が標準テンプレートと違う結果になったら、まずこれを疑う。
- フィルターの引数には変数を使える。

## 標準テンプレートとの併用

- Twig の記述（`include` / `extends`）が先に処理され、その後に標準テンプレートの記法（`@include` など）が処理される。
- そのため、Twig のテンプレートから標準テンプレートの部品を読み込むことはできるが、`@include` / `@extends` で読み込んだ先に書いた Twig は処理されない。
- 移行するときは、ルート（レイアウト）から Twig にし、部品を順に移す。

詳しくは <https://developer.a-blogcms.jp/document/twig/template-compatibility.html>。

## よくある誤り

- 従来のモジュール（`Entry_Summary` など V2 でないもの）を `module()` で呼ぶ。呼べないので、`V2_` のモジュールを探す。
- `|date` で a-blog cms の日付書式を期待する（`|acms_date` を使う）。
- 表示が崩れたからと `|raw` を付ける。まず `|safe_html` を試す。
- `{% extends %}` の前に別のタグや出力を書く。
