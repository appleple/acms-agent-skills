# カスタムフィールドの出力

## ページ一覧

| 内容 | ページ |
|---|---|
| フィールドモジュール（標準テンプレートの Blog_Field / Category_Field / Entry_Field / User_Field / Module_Field。V2 バージョンの変数は Twig の変数表で確かめる） | <https://developer.a-blogcms.jp/document/reference/field.html> |
| 校正オプション（resizeImg・getHeightFromRatio・imageRatioSizeH など） | <https://developer.a-blogcms.jp/document/reference/proofreading.html> |
| メディアのフィールド | <https://developer.a-blogcms.jp/document/customfield/media-field.html> |
| 画像のフィールド | <https://developer.a-blogcms.jp/document/customfield/img-upload.html> |
| ファイルのフィールド | <https://developer.a-blogcms.jp/document/customfield/file-upload.html> |

## どのモジュールで出すか

| 値の持ち主 | 標準テンプレート | Twig |
|---|---|---|
| エントリー | `Entry_Field`、または一覧系モジュールの `entry:loop` の中（モジュール ID でエントリーフィールドの出力を有効にする） | `module('V2_Entry_Field', null, { eid: EID }).fields`。一覧系の V2 モジュールも、モジュール ID の設定で有効にすると各エントリーの `fields` に入る |
| ブログ | `Blog_Field`、または一覧系モジュールの `blogField` ブロック | `module('V2_Blog_Field').fields` |
| カテゴリー | `Category_Field` | `module('V2_Category_Field').fields` |
| ユーザー | `User_Field` | `module('V2_User_Field').fields` |
| モジュール | そのモジュールの中の `<!-- BEGIN moduleField -->` 〜 `<!-- END moduleField -->` | V2 モジュールの戻り値の `moduleFields`（`V2_Module_Field` なら `fields`） |

モジュールのカスタムフィールドは、モジュール ID の「カスタムフィールド」が有効なときだけ出る（新規作成時は有効）。どの一覧系モジュールでどの設定を有効にするかは acms-module-reference から変数表を辿って確かめる。

## 標準テンプレート

```html
<!-- BEGIN_MODULE Entry_Field -->
<p>{entry_subtitle}</p>

<!-- BEGIN_IF [{entry_image@path}/nem] -->
<img src="%{MEDIA_ARCHIVES_DIR}{entry_image@path}[resizeImg(800)]"
     width="800" height="{entry_image@ratio}[getHeightFromRatio(800)]" alt="{entry_image@alt}">
<!-- END_IF -->

<!-- BEGIN group_spec:loop -->
<dl><dt>{spec_label}</dt><dd>{spec_value}</dd></dl>
<!-- END group_spec:loop -->
<!-- END_MODULE Entry_Field -->
```

| フィールド | パスの前に付けるもの | 主な接尾辞 |
|---|---|---|
| メディア（画像） | `%{MEDIA_ARCHIVES_DIR}` | `@path`・`@alt`・`@caption`・`@link`・`@text`・`@ratio`・`@width`・`@height`・`@focalX`・`@focalY`・`@thumbnail`・`@type`（`image` / `svg` / `file`） |
| メディア（ファイル） | 付けない（`@path` がダウンロード用のリンクになっている） | `@path`・`@name`・`@extension`・`@fileSize`・`@thumbnail` |
| 画像（archives） | `%{ARCHIVES_DIR}` | `@path`・`@x`・`@y`・`@alt`、サイズ違いは `@largePath`・`@tinyPath`・`@squarePath` |
| ファイル（archives） | `%{ARCHIVES_DIR}` | `@path` ほか（メーカーの「出力用コード」で確かめる） |

- 複数の値（チェックボックスなど）は `<!-- BEGIN name:loop -->{name}<!-- END name:loop -->` で回す。
- グループは `<!-- BEGIN グループ名:loop -->` で回す。入力チェックの無いグループでは、すべての項目が空の行は出力されない。
- 値の有無で囲むときは `<!-- BEGIN name:veil -->` か `<!-- BEGIN_IF [{name}/nem] -->`。画像・メディアは `@path` で判定する（下記）。

## Twig（V2 モジュール）

```twig
{% set entryField = module('V2_Entry_Field', null, { eid: EID }) %}
{% set fields = entryField.fields %}

<p>{{ fields.entry_subtitle.value }}</p>

{% if fields.entry_image.value.path %}
  {% set image = fields.entry_image.value %}
  <img src="{{ image.path|resizeImg(800) }}" width="800"
       height="{{ image.ratio|getHeightFromRatio(800) }}" alt="{{ image.alt }}">
{% endif %}

{% for row in fields.group_spec %}
  <dl><dt>{{ row.spec_label.value }}</dt><dd>{{ row.spec_value.value }}</dd></dl>
  {% if row.spec_icon.path %}<img src="{{ row.spec_icon.path }}" alt="{{ row.spec_icon.alt }}">{% endif %}
{% endfor %}
```

`fields` の形:

| フィールド | 形 | 書き方 |
|---|---|---|
| 単一の値 | `{ value: 先頭の値, array: [全部の値] }` | `fields.name.value`、複数値は `fields.name.array` を回す |
| 画像・メディアなど接尾辞を持つもの | `{ value: { path, alt, ... }, array: [{ path, alt, ... }, ...] }` | `fields.name.value.path` |
| グループ | 行の配列 `[ 行, 行, ... ]` | `{% for row in fields.グループ名 %}` |
| グループの中の単一の値 | `{ value: 値 }` | `row.name.value` |
| グループの中の画像・メディア | `{ path, alt, ... }`（`value` で包まれない） | `row.name.path` |

- `fields.name` を直接出力・比較しない。`{% if fields.robots == 'noindex' %}` は配列と文字列の比較なので常に偽になる。`fields.robots.value` と書く。
- Twig では画像・メディアの `path` はサイトのルートからのパスになっている。標準テンプレートのように `%{MEDIA_ARCHIVES_DIR}` や `%{ARCHIVES_DIR}` を前に付けない。
- 値は型が自動で変わる。`true` / `false` の文字列は真偽値、数字だけの文字列は整数・小数（先頭が 0 の数字は文字列のまま）、空文字は `null` になる。`is same as` で比べるときや、値を JavaScript に渡すときに気を付ける。
- グループの行は、すべての項目が空でも取り除かれない（標準テンプレートの `:loop` とは違う）。行の中で必要な値の有無を確かめてから出力する。
- フィールドが1つも無いと `fields` は `null` になる。a-blog cms の Twig は未定義の変数を参照しても例外にしない設定なので、`fields.name.value` はそのまま `null` として扱える。

## 空欄で保存したフィールド

- 単一の値のフィールドを空欄で保存すると、その値は保存されない（空文字の行も作られない）。標準テンプレートの `{name}` は空になり、Twig では `fields.name` 自体が無い。`{% if fields.name.value %}` で判定してよい。
- グループは行の添字をそろえて保存するため、途中の行の空の項目は空文字のまま保存されうる（すべての項目が空の行も残りうる）。表示側の扱いは上のとおり標準と Twig で違う。

## 参照先のメディアが削除されたとき

メディアのフィールドには、メディアの ID（`name` と `name@media`）だけが保存される。表示のたびにメディア管理から `path` などを読み込むので、メディア管理でそのメディアを削除すると次のようになる。

- 標準テンプレート: `{name}` には ID が残り、`{name@path}`・`{name@alt}` などは空になる。
- Twig: `fields.name.value` は `{ media: ID, path: null, alt: null, ... }` のような空でない配列になる。

したがって画像・ファイルの有無は必ず `path` で判定する。`{name}` や `fields.name.value` で判定すると、削除後に `<img src="">` や空のリンクが出る。

```html
<!-- 標準テンプレート -->
<!-- BEGIN_IF [{logo@path}/nem] --><img src="%{MEDIA_ARCHIVES_DIR}{logo@path}" alt="{logo@alt}"><!-- ELSE -->%{BLOG_NAME}<!-- END_IF -->
```

```twig
{# Twig #}
{% if fields.logo.value.path %}<img src="{{ fields.logo.value.path }}" alt="{{ fields.logo.value.alt }}">{% else %}{{ BLOG_NAME }}{% endif %}
```

## 画像の出力

### リサイズ

| 校正オプション（Twig ではフィルター） | 動き |
|---|---|
| `resizeImg(幅)` | 縦横比を保って幅に合わせる。元の画像より大きくはしない |
| `resizeImg(幅, 高さ)` | 指定した枠を埋めるように縮小し、はみ出した部分を中央で切り取る。元の画像より大きくはしない |
| `resizeImgFill(幅, 高さ)` | `resizeImg(幅, 高さ)` と同じ切り取り方で、元の画像より大きく指定すれば拡大する |
| `resizeImgFit(幅, 高さ)` | 縦横比を保って枠の中に収め、余白を背景色（第3引数、既定は白）で埋める。拡大もする |

- リサイズした画像は、元の画像と同じディレクトリに別名で保存され、2回目以降はそれが使われる。対象は jpg・jpeg・png・gif・webp。SVG などはそのままのパスが返る。
- 切り取りや余白を付けると元の画像の一部が失われるので、表示側の CSS で足りるならそちらを優先し、使うときは利用者に確かめる。

### width / height

| フィールド | 高さを求める | 幅を求める | 仕組み |
|---|---|---|---|
| メディア | `{name@ratio}[getHeightFromRatio(幅)]` | `{name@ratio}[getWidthFromRatio(高さ)]` | メディアに保存された寸法から計算した比率を使う。ファイルを読まない |
| 画像（archives） | `{name@path}[imageRatioSizeH(幅)]` | `{name@path}[imageRatioSizeW(高さ)]` | 表示のたびに画像ファイルを開いて寸法を読む |

- 画像（archives）には `@ratio` が無いので `getHeightFromRatio` は使えない（空になる）。リサイズせずに出すなら、保存時の寸法 `{name@x}`・`{name@y}` をそのまま使える。
- `resizeImg(800)` で出す画像の `width` には `800` と書き、`height` は同じ幅で計算する。元の画像が 800px より小さいと実際の画像はそれより小さいが、縦横比は同じなので表示は崩れない。
- Twig でも同じ名前のフィルターを使う（`image.ratio|getHeightFromRatio(800)`、`image.path|imageRatioSizeH(800)`）。
