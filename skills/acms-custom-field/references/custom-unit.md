# カスタムユニット

## ページ一覧

| 内容 | ページ |
|---|---|
| ユニットの目次 | <https://developer.a-blogcms.jp/document/units/> |
| カスタムユニット | <https://developer.a-blogcms.jp/document/units/custom.html> |
| ユニットを拡張する（`unit#種類_名前`） | <https://developer.a-blogcms.jp/document/units/extend.html> |
| エントリーのユニット設定 | <https://developer.a-blogcms.jp/document/units/unit_setting.html> |

## 位置付け

- ユニットは「種類」と「指定子」で区別される。`custom_product` は種類 `custom`（カスタムユニット）に指定子 `product` を付けたもの。本体は最初の `_` までを種類として扱い、同じ処理（カスタムユニットならカスタムフィールドと同じ保存・出力）を使う。指定子ごとに入力欄と表示のテンプレートを分けられる。
- カスタムユニットは、カスタムフィールドの入力欄を本文の途中に並べられるユニット。値はユニットのデータとしてまとめて保存される（エントリーのカスタムフィールドとは別の場所）。そのため、フィールドの値での絞り込み（URL コンテキストの `field/`）には使えない。キーワード検索の対象にはなる。
- Ver. 3.2 の編集画面のユニットエディターは JavaScript で作られているが、カスタムユニットの入力欄は従来どおり標準テンプレートの HTML で書き、エディターがそれを読み込んでメディア選択・画像のリサイズ・日付入力などの部品を動かす。
- HTML テンプレートとカスタムフィールドで足りないもの（独自の操作 UI を持つユニット）は、管理画面の JavaScript プラグインで作る。acms-admin-frontend-plugin を使う（Ver. 3.2.29 以降）。

## extend.html と custom.html

| | `extend.html`（推奨） | `custom.html` |
|---|---|---|
| 表示のテンプレート | `include/unit/extend.html` に `<!-- BEGIN unit#custom_名前 -->` を並べる | `include/unit/custom.html`（system の `unit#custom` ブロックの中で読み込まれる） |
| 入力欄のテンプレート | `admin/entry/unit/extend.html` に `<!-- BEGIN custom_名前 -->` を並べる | `admin/entry/unit/custom.html` |
| 作れる数 | 名前を変えていくつでも | 種類 `custom` の1つだけ |

`custom.html` で作ると、2つ目のカスタムユニットが必要になったときに作り直しになる。最初から `extend.html` で作る。公式ドキュメントも、1つだけの場合でも拡張と同じ構成で作ることを勧めている。

## 手順

1. 入力欄を作る。カスタムフィールドメーカーで「カスタムユニット」を選んで生成する。カスタムフィールドとは書き方が違い、各フィールド名の後ろに `{id}` を付け、`field[]` の代わりに `unit{id}[]` で保存対象を宣言する。手で書き換えると漏れやすい。
2. `admin/entry/unit/extend.html` に入力欄を置く。

   ```html
   <!-- BEGIN custom_product -->
   （メーカーで生成した入力欄）
   <!-- END custom_product -->
   ```

3. `include/unit/extend.html` に表示を書く。中は通常のカスタムフィールドと同じ変数（`{name}`・`{name@path}`・グループの `:loop`）を使う。

   ```html
   <!-- BEGIN unit#custom_product -->
   <div class="product">
     <p class="product-name">{product_name}</p>
     <!-- BEGIN_IF [{product_image@path}/nem] -->
     <img src="%{MEDIA_ARCHIVES_DIR}{product_image@path}[resizeImg(600)]" width="600"
          height="{product_image@ratio}[getHeightFromRatio(600)]" alt="{product_image@alt}">
     <!-- END_IF -->
   </div>
   <!-- END unit#custom_product -->
   ```

4. 管理画面の「コンフィグ」→「編集設定」の「ユニットメニュー」に、モード `custom_product` とラベルを足して保存する。
5. 「ユニット設定」で、追加したメニューに使うユニットを設定して保存する。ユニット設定が空のメニューは、エントリー編集画面のユニット追加メニューに出ない。
6. エントリー編集画面でユニットを追加し、保存と表示を確かめる。表示されないときはテンプレートキャッシュを疑う。

- 表示側の `extend.html` は、Twig を有効にしたテーマでも標準テンプレートの記法で書く。`V2_Entry_Body` もユニットの HTML は `include/unit.html`（その中で `extend.html` を読む）を標準テンプレートのエンジンで組み立てて返すため。
- 他の種類のユニット（`text_名前`・`image_名前` など）の表示を変えるのも同じ `include/unit/extend.html` に書く。

## 重い処理を含むユニットはインクルードで分ける

`extend.html` は、エントリーの本文を表示するたびに丸ごと読み込まれる。標準テンプレートでは、入れ子のモジュールは内側から先に実行されるので、`unit#custom_名前` ブロックの中に書いたモジュールは、そのユニットがエントリーに無くても実行され、出力が捨てられるだけになる（`BEGIN_IF` で囲んでも止まらないのと同じ理由。acms-template-acms の「実行順序から決まること」）。

モジュールを含むユニットや大きなユニットは、使うブログ・カテゴリーでだけ読み込まれるよう、グローバル変数入りのパスで分ける。

```html
<!-- include/unit/extend.html -->
<!-- BEGIN unit#custom_outline -->
<nav class="outline">...</nav>
<!-- END unit#custom_outline -->

@include("/include/unit/extend/bcd/%{BCD}.html")
@include("/include/unit/extend/ccd/%{CCD}.html")
```

- パスに使うグローバル変数は、テンプレートキャッシュが有効でも解決されるもの（`%{BCD}`・`%{CCD}`・`%{RCCD}` など）から選ぶ（references/admin-field.md）。
- 分けた先に置いたユニットは、そのブログ・カテゴリー以外では表示されない。エントリーを別のカテゴリーに移すとユニットが表示されなくなるので、分け方を利用者に確かめる。
- 入力側（`admin/entry/unit/extend.html`）も同じパスで分けると、編集画面でも使える場所が限られる。分けない場合は、表示側だけ分けたユニットを他のカテゴリーで追加しても表示されないことを伝える。
