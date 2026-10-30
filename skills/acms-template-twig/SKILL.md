---
name: acms-template-twig
description: >-
  a-blog cms（acms）の Twig テンプレートを書く・直す・標準テンプレートから移すときの記法と判断基準（Ver. 3.2 以降）。
  Twig の有効化（template.yaml の tpl_twig）、.twig / .html の探索順、module('V2_...') と touch() の引数と戻り値、URL を組み立てる acms_link / acms_path とコンフィグを読む acms_config、
  グローバル変数、校正オプションのフィルターと acms_ 接頭辞、自動エスケープと safe_html / raw、include / extends、
  標準テンプレートとの併用順序、管理画面テンプレートとの関係、Twig のキャッシュを扱う。
  template.yaml に tpl_twig: enabled があるテーマ、.twig ファイル、{% %} や {{ }} を含むテンプレートを編集するとき、
  「Twig で書いて」「標準テンプレートを Twig に移して」「Twig で値が出ない・エスケープされる」と頼まれたときに使う。
  a-blog cms Twig template, V2 module. 標準テンプレート（BEGIN_MODULE）は acms-template-acms、
  フォームは acms-form、カスタムフィールドの値の構造は acms-custom-field、モジュール選びは acms-module-reference が担う。
license: MIT
compatibility: a-blog cms Ver. 3.2 以上（Twig テンプレートは Ver. 3.2 で追加）
metadata:
  acms-min-version: "3.2"
  status: stable
---

# a-blog cms の Twig テンプレート

公式ドキュメント: <https://developer.a-blogcms.jp/document/twig/>（チュートリアル: <https://developer.a-blogcms.jp/document/tutorial/twig-template/>）

## 書く前に

- テーマで Twig が有効か確かめる。管理画面のテーマ設定の「Twigテンプレート」、またはテーマの `template.yaml` の `tpl_twig: enabled`。`template.yaml` の値が効くのは、テーマ設定の「テンプレート選択ファイル（template.yaml）の値を優先する」にチェックがあるとき（既定はオン）。子テーマ（`blog@site`）では子 → 親の順に `template.yaml` を見る。
- Twig が有効なテーマでは、ルートのテンプレートと Twig の `include` / `extends` で読む先は、拡張子が `.html` でも Twig として処理される。`{{` `{%` `{#` をそのまま出したい箇所（JavaScript のテンプレートなど）は `{% verbatim %}` で囲む。
- 何を表示するか決まっていなければ acms-module-reference でモジュールを選ぶ。`module()` で呼べるのは名前が `V2_` で始まるモジュールだけ。従来のモジュール名を渡された相談では、個別の置き換えだけでなく、この規則そのものを利用者に説明する（ほかのモジュールでも同じ誤りを避けられるため）。
- 変数名は推測しない。管理者でログインし、デバッグモードのページで `Ctrl + K`（Mac は `⌘ + K`）を押し `#` を入力すると、そのページで呼んだ V2 モジュールの実際の値が見える。

## 記法の要点

```twig
{% extends '/_layouts/base.twig' %}

{% block main %}
  {% set news = module('V2_Entry_Summary', 'news_list', { cid: CID }) %}
  {{ include('/admin/module/setting.twig', { moduleInfo: news.moduleInfo }) }}

  {% for entry in news.items %}
    <a href="{{ entry.url }}">{{ entry.title }}</a>
    <time datetime="{{ entry.datetime|date('Y-m-d') }}">{{ entry.datetime|date('Y年m月d日') }}</time>
  {% else %}
    <p>記事がありません</p>
  {% endfor %}

  {% if touch('Touch_Category') %}
    <h1>{{ CATEGORY_NAME }}</h1>
  {% endif %}

  {{ include('/include/parts/' ~ partName ~ '.twig', {}, ignore_missing = true) }}
{% endblock %}
```

| やりたいこと | 書き方 |
|---|---|
| モジュールのデータを取る | `module('V2_名前', 'モジュールID', { bid: …, cid: … })` で配列を受け取り `set` する。HTML は出さない。第2・第3引数は省略できる（ID なしは `null`） |
| 表示を出し分ける | `touch('Touch_名前')` は真偽値を返す。引数はモジュール名だけ |
| グローバル変数 | `{{ BLOG_NAME }}` のように `%{ }` を外した名前で参照する。フィルターも付けられる |
| 部品を読み込む | `{{ include('/path.twig', { 変数 }) }}`。パスは常にテーマのルートから探す（今のファイルからの相対ではない）。パスに変数を使える |
| 無いかもしれない部品 | `include('/path.twig', {}, ignore_missing = true)`。第3引数に `true` を並べるだけでは効かない（第3引数は `with_context`） |
| レイアウトを継承する | `{% extends %}` をテンプレートの最初のタグにし、`{% block %}` を上書きする。親の中身は `{{ parent() }}` |
| リンクの URL を組み立てる | `acms_link({ bid: BID, cid: 3 }, { inherit: false })`（Ver. 3.2.39 以降）。プロトコル・ドメイン込みの URL を返す。既定（`inherit: true`）は今のページの URL を引き継ぐので、固定リンクは `{ inherit: false }` と `bid` を渡す。第2引数に真偽値を渡すとエラー。モジュールの戻り値の `url` で足りるならそちらを使う |
| ドメイン抜きのパスを得る | `acms_path({ bid: BID, eid: eid })`（Ver. 3.2.39 以降）。先頭の `/` もサブディレクトリも付かないので、リンクには `acms_link` を使う |
| コンフィグの値を読む | `{% set config = acms_config() %}` → `config.get('キー')`（Ver. 3.2.24 以降）。別のブログの値を読む `acms_config({ blogId: … })`、型を変換して取り出す `string()` などは **Ver. 3.2.25 以降**。権限を確かめずに返すので、秘密の値（認証キーなど）を出さない |
| 管理者向けの編集ボタン | `{{ include('/admin/module/setting.twig', { moduleInfo: 戻り値.moduleInfo }) }}`（`moduleInfo` は管理者のときだけ入る） |

- `module()` の引数・戻り値・キャッシュの細かい挙動、`acms_link()` / `acms_path()` の引き継ぎとオプション、`acms_config()` の引数とメソッド（オプションやメソッドを示すときは、それぞれの導入バージョンも添える）、`touch()`・`vite()` などの関数、グローバル変数、Twig 一般の誤りは references/functions-and-filters.md を読む。
- 標準テンプレートからの書き換えは references/from-standard-template.md を読む。

## エスケープ（必ず守る）

- `{{ }}` の出力は自動で HTML エスケープされる（グローバル変数も同じ）。そのままにする。
- 編集者が入力した HTML（リッチエディタのフィールド値など）は `|safe_html` で出す。HTMLPurifier で危険な要素・属性を取り除いてから、エスケープせずに出す（標準テンプレートの `[raw]` に近い）。
- `|raw` はエスケープを外し、script も含めてそのまま出す（標準テンプレートの `[raw|allow_dangerous_tag]` 相当）。使うのは、a-blog cms が組み立てた HTML（`V2_Entry_Body` の `entry.body` など。公式のスニペットとチュートリアルも `|raw`）と、管理者だけが入力する値で利用者が明示的に求めたときに限る。フォームの入力値・コメントなど、不特定の人が入力した値には `|raw` も `|safe_html` も使わない（XSS の原因になる）。`|raw` や `|safe_html` を勧めるときは、この禁止も必ず併せて利用者に伝える。
- 校正オプション由来のフィルターは、`safe_html` 以外は出力を「安全」と扱わない。HTML を返すフィルター（`markdown` など）の出力はエスケープされるので、最後に `|safe_html` を付ける。

## フィルター（校正オプション）

- a-blog cms の校正オプション（`extension/acms/Corrector.php` で足した独自のものを含む）は、Twig のフィルターとして同じ名前で使える（`{{ path|resizeImg(800) }}`）。引数には変数を渡せる。
- Twig 標準のフィルターと名前が重なるもの（Ver. 3.2.38 時点で `date` `escape` `nl2br` `number_format` `split` `striptags` `trim`）は Twig 側が使われ、a-blog cms 版は `acms_` を付けた名前（`|acms_trim(100, '…')`）でだけ呼べる。どの校正オプションにも `acms_` 付きの別名がある（`safe_html` を除く）。標準テンプレートから移したときや、`acms_` を付けたコードを示すときは、この規則（名前が重なると Twig 標準が使われるので `acms_` を付ける）を利用者にも説明する。次に別の校正オプションを移すときに同じ誤りを避けられるため。
- 特に `trim`: 標準テンプレートの `[trim(100, '…')]` を `|trim(100, '…')` と移すと Twig の `trim`（前後の文字を削る）になりエラーになる。標準テンプレートと同じ結果（表示幅で切る）なら `|acms_trim(100, '…')`、文字数で切るなら `|mb_trim(100, '…')`。
- `date`: 書式文字は PHP と同じなので `|date('Y年m月d日')` で普通に出る。違うのは値が空のときで、Twig の `date` は現在日時を出し、`acms_date` は空のまま返す。空があり得る値は `|acms_date` を使うか `{% if %}` で囲む。

## 標準テンプレートとの併用

- 処理順は「Twig（`include` / `extends` / `module()` を含む）→ その出力に対して標準テンプレートの記法（`@include`、`<!-- BEGIN_MODULE -->`、`%{VAR}` など）」。
- そのため Twig から標準テンプレートの部品を `include` したり、Twig の出力の中に `BEGIN_MODULE` を書いたりはできる。逆に `@include` / `@extends` で読み込んだ先に書いた Twig は処理されない。
- 標準テンプレートでは `BEGIN_IF` の中のモジュールも実行されてから条件が判定されるが、Twig では `{% if %}` が偽なら中の `module()` は実行されない。表示しないときに無駄な処理をさせないよう、条件の中で呼んでよい。ただし条件の外でも使う値を `{% if %}` の中だけで `set` すると、条件が偽のとき空になる。
- 移行するときは、ルート（レイアウト）から Twig にし、部品を順に移す。
- 詳しくは <https://developer.a-blogcms.jp/document/twig/template-compatibility.html>。探索順・相対パス・キャッシュ・管理画面の扱いは references/rendering.md を読む。

## 管理画面

- 管理画面の各ページ（`/admin/` 配下のテンプレート）は、system テーマのレイアウトから標準テンプレートの `@include` で読み込まれる。Twig が有効なテーマでも、そこに書いた Twig は処理されない。カスタムフィールドの入力欄（`admin/entry/field.html` など）は標準テンプレートの記法で書く。
- プラグイン（拡張アプリ）の設定画面を Twig で作る仕組みは別物で、acms-plugin-development が担う。

## よくある誤り

- 従来のモジュール（`Entry_Summary` など）を `module()` に渡す。動かないので `V2_` のモジュールを使うか、Twig の出力の中に `BEGIN_MODULE` を書く。
- V2 モジュールの名前を打ち間違える。エラーにならず空の配列が返るだけなので、値が出ないときはまず名前を確かめる。
- カスタムフィールドを `{{ fields.foo }}` や `fields.foo == 'x'` で使う。V2 モジュールのフィールドは `{ value, array }` の形なので `fields.foo.value`（複数値は `.array`）。詳しくは acms-custom-field。
- `include('/x.twig', {}, true)` で ignore_missing のつもりになる（上の表）。
- 部品の中の画像・CSS を相対パスで書く（references/rendering.md）。
- `{% extends %}` の前に別のタグや出力を書く。

## 確認

- デバッグモードでは、Twig の `include` の前後に読み込んだファイルのパスが HTML コメントで出る（Ver. 3.2.15 以降）。意図したファイルが使われているか確かめる。
- デバッグモードでないサイトでは、`.twig` を書き換えても Twig のコンパイル済みキャッシュが使われ続ける。管理画面のダッシュボードの「キャッシュクリア」で「テンプレート キャッシュ」をクリアしてから確かめる。
- 日付・画像サイズ・HTML を含む項目は、移行前の表示と見比べる（エスケープとフィルターの違いが出やすい）。
