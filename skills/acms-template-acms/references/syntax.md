# 標準テンプレートの記法の詳細

迷ったら公式ドキュメントの該当ページを読む。ここには判断に必要な要点だけを置く。

## ページ一覧

| 内容 | ページ |
|---|---|
| テンプレートの基本 | <https://developer.a-blogcms.jp/document/template/> |
| テンプレートの種類 | <https://developer.a-blogcms.jp/document/template/type-of-template.html> |
| パスの書き換え | <https://developer.a-blogcms.jp/document/template/entry-1443.html> |
| インクルード | <https://developer.a-blogcms.jp/document/template/include.html> |
| テンプレートの継承 | <https://developer.a-blogcms.jp/document/template/entry-2850.html> |
| IF ブロック | <https://developer.a-blogcms.jp/document/template/if.html> |
| veil ブロック | <https://developer.a-blogcms.jp/document/template/veil.html> |
| 実行順序 | <https://developer.a-blogcms.jp/document/template/execution-order.html> |
| テンプレートの探し方 | <https://developer.a-blogcms.jp/document/template/entry-2313.html> |
| テンプレート変数表 | <https://developer.a-blogcms.jp/document/template/varstable.html> |
| グローバル変数 | <https://developer.a-blogcms.jp/document/reference/global_variable.html> |
| 校正オプション | <https://developer.a-blogcms.jp/document/reference/proofreading.html> |

## 実行順序と、そこから来る制約

おおまかに、グローバル変数 → インクルード → タッチモジュール → モジュール（内側から）→ IF ブロック の順に処理される。

- インクルードのパスにグローバル変数を使える（グローバル変数が先に解決されるため）。
- IF ブロックはモジュールより後に評価されるので、モジュールの変数を条件に使える。逆に、IF ブロックで囲んでもモジュールの処理自体は走る。表示しないモジュールを IF で囲んで負荷を減らすことはできない。
- 入れ子のモジュールは内側から処理される。外側のモジュールの値を内側で使いたいときは、エスケープ（`\{var\}`、`<!-- BEGIN\ x -->`）で処理を遅らせる。

## ブロック

| ブロック | 使いどころ | 注意 |
|---|---|---|
| `x:loop` | 一覧の繰り返し | ブロック名は変数表で確かめる（`entry:loop` など） |
| `x:glue` | カンマ区切りなど、最後以外に出すもの | `:loop` の中に置く |
| `x:veil` | 値が無いときに見出しごと消す | 囲んだ変数が「すべて」空のときだけ消える |
| `x:touch#値` | 変数がある値のときだけ出す | ブロックの中に変数を置くと正しく動かない |
| `notFound` など | モジュールが用意した特別なブロック | モジュールの変数表で確かめる |

## IF ブロック

- 書式は `[基準値/演算子/比較値]`。基準を左、比較する値を右に書く。
- 値に改行が入りうる変数は `[delnl]` を付けてから比較する。
- `<!-- ELSE_IF [...] -->` と `<!-- ELSE -->` が使える。

## インクルードの引数

```html
@include("/include/parts/heading.html", {"title": "お知らせ", "level": "2"})
```

インクルード先では `{{title}}` で参照し、`{{title | default("見出し")}}` で既定値を付けられる。旧記法の `<!--#include file="..."-->` も動くが、新しく書くときは `@include` を使う。
