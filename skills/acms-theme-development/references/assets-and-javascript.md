# テーマ内のパスと JavaScript・CSS の読み込み

テンプレートに書いた画像・CSS・JavaScript のパスが合わないとき、acms.js や管理用 CSS の読み込み方を変えるときに読む。

公式ドキュメント:
- パスの書き換え: <https://developer.a-blogcms.jp/document/template/entry-1443.html>
- 読み込みが必要な JavaScript ファイル: <https://developer.a-blogcms.jp/document/template/entry-1434.html>
- 読み込みが必要な CSS ファイル: <https://developer.a-blogcms.jp/document/template/entry-1433.html>
- 組み込み JS: <https://developer.a-blogcms.jp/document/reference/builtinjs/>

## パスの書き換え

テンプレートを表示するとき、本体はテンプレートの中のパスをテーマの実際の場所に書き換える。対象は `src`・`srcset`・`<link href>`・`poster`・`background`・インクルードのパス・テンプレート内の `style` 属性と `<style>` の `url()`・OGP などの `<meta content>`・SVG の `<image>` / `<use>` の `href` など。対象の一覧はドキュメントにある。

| 書き方 | 書き換え |
|---|---|
| `https://...` など `://` を含む | しない |
| `/` から始まり、ドキュメントルートからたどってファイルがある | しない |
| `/` から始まり、a-blog cms の設置ディレクトリからたどってファイルがある | 設置ディレクトリのパスを補う |
| `/` から始まり、上のどちらにも無い | テーマ直下からのパスとして、テーマ → 親テーマ → … → `system` の順に探し、見つかった場所（`/themes/<テーマ>/...`）に書き換える |
| `/` から始まらない（`images/a.png`、`./`、`../`） | そのパスを書いたテンプレートファイルの場所からの相対パスとして、同じく継承の順に探す |
| どこにも見つからない | しない（書いたまま出力される） |

書き換えたパスには、ファイルの更新日時のクエリ（`?date=...`）が付く。

### よくある誤り

- **CSS ファイルの中の `url()` は書き換わらない。** 書き換えるのはテンプレートの中だけ。外部 CSS の中は、ブラウザがその CSS ファイルの場所から解決する。
- **ドキュメントルートにある同名のパスが優先される。** `/js/...`・`/acms.js` のように a-blog cms 本体のファイルと同じパスを書くと、テーマのファイルではなく本体のファイルが読まれる。テーマのファイルには本体と重ならないパスを使う。
- **インクルードした部品の中の相対パス。** 標準テンプレートでは、その部品ファイルの場所が基準になる（`include/header.html` の `images/logo.png` は `include/images/logo.png` を探す）。Twig テンプレートでは、`include` した部品の中も含めてページのテンプレート全体を最後にまとめて書き換えるため、部品の場所は基準にならない。
- 上の理由から、テーマ内のファイルは公式テーマと同じく `/` から始まるテーマ直下からのパス（`/images/logo.png`、`/css/acms.min.css`）で書くと、どのテンプレートから書いても同じ結果になる。

### リンク（`<a href>`・`<form action>`）

`/` から始まるリンクには、表示中のブログのブログコードが補われる（子ブログ `news` の中の `<a href="/">` は `/news/` になる）。補ってほしくないリンクには `acms_no_rewrite` を付ける。Twig が有効なテーマでは、設定 `acms_anchor_no_rewrite_if_twig_enabled: on` でリンクの書き換えをまとめて止められる（Ver. 3.2.25 以降。新規インストール時の `config.system.yaml` は on）。

## acms.js と組み込み JS

- `acms.js` は Js モジュール（標準テンプレートは `<!-- BEGIN_MODULE Js -->`、Twig は `module('V2_Js')`）で `<head>` 内に出力する。モジュールが付ける引数（`{arguments}`）を落とさない。
- Js モジュールを出力したページには、本体が `</head>` の直前に組み込み JS 本体（`js/dest/index.js` など）を差し込む。
- ログイン中の投稿者以上には、Js モジュールが無くても本体が `acms.js` と管理画面用の JavaScript を差し込む。編集・管理ボックスはこれで動く。
- ログインしていない閲覧者には、Js モジュールを出力したときだけ組み込み JS が読み込まれる。

### Js モジュールをログイン時だけにする構成の影響

Js モジュールを `Touch_SessionWithContribution`（Twig なら `touch('Touch_SessionWithContribution')`）で囲むと、閲覧者の画面では組み込み JS が一切読み込まれない。次のような、クラス名や属性を付けるだけで動く機能が閲覧者の画面で動かなくなる。

- `form.js-validator` のフォームの入力チェック（送信自体はでき、サーバー側の検証は働く）
- 画像のライトボックス（`data-rel="SmartPhoto"`・`.js-smartphoto`）、`.js-lazy-load` の遅延読み込み
- 地図ユニット・`.js-open-street-map` の地図表示
- `.js-login-show` / `.js-logout-show` などのログイン状態による出し分け
- `ACMS.Ready` や `ACMS.Config` を使うテーマ側の JavaScript

ページの表示を軽くするためにこの構成を選ぶなら、上の機能をテーマ側の JavaScript で用意するか使わないと決めてから行う。テンプレートに `js-validator` などのクラスが残っていないかも確かめる。どの機能がどのクラスで動くかは組み込み JS のドキュメントで確かめる。

## 管理用 CSS

- `acms-admin.min.css` は管理ボックス・エントリーの編集画面など、ログイン中に出る UI の見た目に使う。公式テーマ（`site`）はログイン中だけ読み込んでいる。
- 閲覧者向けの見た目（ユニットのレイアウトなど）は、テーマが読み込む `acms.min.css` などの公開用 CSS が受け持つ。管理用 CSS をログイン時だけにするときは、公開側のテンプレートで `acms-admin-` で始まるクラスを使っていないか確かめる。
- `themes/system/css/` の CSS を直接直さない（アップデートで上書きされる）。変えるときは自分のテーマに上書き用の CSS を置き、後から読み込む。
