# Twig テーマでテンプレートが探され、処理される流れ

「どのファイルが使われているか分からない」「Twig が効かない」「パスがずれる」「書き換えが反映されない」ときに読む。

## Twig が使われる条件

- 現在のテーマの設定 `tpl_twig` が `enabled` のとき、表示に使うルートのテンプレート（`tpl_top` / `tpl_index` / `tpl_detail` / `tpl_admin` などで決まるファイル）を Twig で処理する。
- `tpl_twig` は管理画面のテーマ設定の値が使われ、「テンプレート選択ファイル（template.yaml）の値を優先する」がオンなら `template.yaml` の値が優先される。子テーマでは子 → 親の順に `template.yaml` を探し、最初に値があったものを使う。
- 有効化の手順: <https://developer.a-blogcms.jp/document/twig/settings.html>

## ファイルの探索順

`index.html` のように指定されたとき（URL・`template.yaml`・`include` / `extends` のパスのどれでも同じ）:

| 指定の拡張子 | 1 つのテーマの中で探す順 |
|---|---|
| `.html` または `.twig` | `index.twig` → `index.html.twig` → `index.html` |
| それ以外（`.xml` `.csv` など） | `sitemap.xml.twig` → `sitemap.xml`（`sitemap.twig` は候補にしない） |

- この順で 1 つのテーマを探し、無ければ親テーマ（`blog@site` なら `site`）、最後に `system` で同じ順に探す。したがって、子テーマの `index.html` は親テーマの `index.twig` より優先される。Twig 化した親テーマに、子テーマで古い `.html` が残っていると、そちらが使われる。
- Ver. 3.2.18 より前は、指定した名前そのもの → 名前に `.twig` を足したもの（`index.html` → `index.html.twig`）の順だった。`index.twig` を `index.html` の代わりに置く書き方は Ver. 3.2.18 以降。
- 拡張子の考え方: <https://developer.a-blogcms.jp/document/twig/extension.html>

## 処理の順序

1. ルートのテンプレートを Twig で処理する。`include` / `extends` / `module()` / `touch()` / フィルターはここで評価される。
2. Twig の出力全体を 1 つの標準テンプレートとして扱い、`@include` / `@extends` の展開、`%{VAR}` の置き換え、パスの書き換えをする。
3. 標準テンプレートのモジュール（`<!-- BEGIN_MODULE -->`）を実行し、`BEGIN_IF` を判定する。

ここから次のことが言える。

- Twig から `.html` の部品を `include` してよい（その中の標準テンプレートの記法は 2・3 で処理される）。
- `@include` / `@extends` で読み込んだ先の Twig は処理されない。`@extends` で継承しているテンプレートを Twig の `include` で読み込むこともできない。
- 標準テンプレートの「テンプレートキャッシュが有効なとき、`@include` のパスに使えるグローバル変数が限られる」制約は、Twig の `include` には無い。Twig の `include` のパスはテンプレートの変数を使って実行時に組み立てられる。また Twig が有効なテーマでは、2 の展開にテンプレートキャッシュを使わない。
- 標準テンプレートの `BEGIN_IF` は、中のモジュールを実行してから判定する。Twig の `{% if %}` は、偽なら中の `module()` を実行しない。

併用の説明: <https://developer.a-blogcms.jp/document/twig/template-compatibility.html>

## 画像・CSS・リンクのパス

- 2 のパスの書き換え（`src` `href` `srcset` `url()` などをテーマのファイルへ向け直す）は、Twig の出力全体に対して、ルートのテンプレートの場所を基準に 1 回だけ行う。
- そのため、Twig で `include` した部品の中に書いた相対パス（`../images/logo.png`）は、部品のファイルの場所ではなくルートのテンプレートの場所から解決される。標準テンプレートの `@include` は部品ごとに解決するので、ここが違う。
- Twig の部品では、テーマ内のファイルを `/images/logo.png` のように `/` から書く。`/` から始まるパスは、ドキュメントルートに無ければテーマ（子 → 親 → system）の中から探される。
- `a` の `href` と `form` の `action` の相対パスにはブログのコードが補われる。Ver. 3.2.25 以降は、Twig が有効なときにこの補完をしない設定 `acms_anchor_no_rewrite_if_twig_enabled` がシステムの設定ファイルにある（新規インストールではオン）。リンクの URL がずれるときは、この設定の値を利用者に確認してもらう（設定ファイルはエージェントが開かない）。

## キャッシュ

- Twig はテンプレートを PHP にコンパイルしてキャッシュする。デバッグモードのときだけ、ファイルの更新を検知して作り直す。デバッグモードでないサイトで `.twig` を書き換えたら、管理画面のダッシュボードの「キャッシュクリア」で「テンプレート キャッシュ」をクリアする（ルートブログのダッシュボードに出る）。ページキャッシュを使っているサイトでは、ページキャッシュもクリアする。
- `module()` は、同じリクエストの中で同じ引数（モジュール名・モジュール ID・第3引数）で呼ぶと、前の結果を使い回す。
- モジュール ID の設定でキャッシュ時間を指定した V2 モジュールは、モジュール ID を渡して呼び、ログインしていないときだけキャッシュを使う。

## 管理画面

- 管理画面のページは `tpl_admin`（既定は `admin.html`）をルートにして表示される。Twig が有効なテーマではこのルートも Twig を通るが、system テーマの管理画面レイアウトは各ページ（`admin/` 配下のテンプレート）を標準テンプレートの `@include` で読み込むため、各ページに書いた Twig は処理されない。管理画面のテンプレートは標準テンプレートで書く。
- system テーマには、公開側の Twig から読み込む部品が用意されている。

| 部品 | 用途 |
|---|---|
| `/admin/module/setting.twig` | モジュールの「編集する」ボタン。`{ moduleInfo: 戻り値.moduleInfo }` を渡す |
| `/admin/entry/action.twig` | エントリーの編集ボタン群。`{ entry }` を渡す |
| `/include/pagination.twig` | ページ送り。V2 モジュールの `pagination` などを渡す |

- V2 モジュールごとの最小の書き方は、配布物の `themes/system/acms-code/snippets/v2_*.html` に例がある（HTML エスケープされた状態で入っている）。
