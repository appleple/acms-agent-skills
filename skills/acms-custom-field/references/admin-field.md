# 管理画面の入力欄の定義

## ページ一覧

| 内容 | ページ |
|---|---|
| カスタムフィールドの目次 | <https://developer.a-blogcms.jp/document/customfield/> |
| エントリーのカスタムフィールド | <https://developer.a-blogcms.jp/document/customfield/entry.html> |
| ブログのカスタムフィールド | <https://developer.a-blogcms.jp/document/customfield/blog.html> |
| カテゴリーのカスタムフィールド | <https://developer.a-blogcms.jp/document/customfield/category.html> |
| ユーザーのカスタムフィールド | <https://developer.a-blogcms.jp/document/customfield/user.html> |
| モジュールのカスタムフィールド | <https://developer.a-blogcms.jp/document/customfield/entry-2136.html> |
| 入力欄の種類ごとの書き方 | <https://developer.a-blogcms.jp/document/customfield/customfield_basic.html> |
| カスタムフィールドグループ | <https://developer.a-blogcms.jp/document/customfield/group.html> |
| カスタムフィールドメーカーの使い方 | <https://developer.a-blogcms.jp/document/customfield/customfieldmaker.html> |
| 表示されていない値を消さない（updateField） | <https://developer.a-blogcms.jp/document/customfield/updateField.html> |

## 読み込まれる仕組み

- system テーマの各編集画面が `@include("/admin/entry/field.html")` のように読み込む。インクルードはテーマの継承の順（自分のテーマ → 親テーマ → system）にファイルを探し、どこにも無ければ空になる。
- エントリーの編集画面だけ `field.html`（ユニットの上）と `field_foot.html`（ユニットの下）の2か所がある。ブログ・カテゴリー・ユーザー・モジュールは `field.html` だけ。
- `@include` の先は標準テンプレートとして処理される。Twig を有効にしたテーマでも、`field.html` に書いた `{% %}` や `{{ }}` は処理されない。`@include` は `.twig` の候補を探さないので、`field.twig` を置いても使われない。
- 入力欄の値は、標準テンプレートの変数 `{name}`、`{name@path}`、`{name:checked#値}` などで入力欄に戻す。

## 入力欄の基本の書き方

メーカーで生成したものを直すのが基本。手で直すときに崩しやすい点だけ挙げる。

| 書くもの | 意味 |
|---|---|
| `<input type="hidden" name="field[]" value="name">` | このフィールドを保存対象にする。無いと保存されない |
| `name:extension` に `media` / `image` / `file` / `block-editor` | 種類ごとの保存処理を有効にする |
| `<input type="hidden" name="@グループ名[]" value="name">`、入力欄の name を `name[]` に | フィールドグループ。グループに属するフィールドを宣言し、行ごとに同じ添字で保存される |
| `name:v#required` など | 入力チェック。書き方はフォームと共通なので acms-form を見る |
| `name:search` に `0` | キーワード検索の対象から外す |

自分で書いた最小の例（エントリーのテキストとメディア）:

```html
<table class="acms-admin-table-admin-edit">
  <tr>
    <th>サブタイトル</th>
    <td>
      <input type="text" name="entry_subtitle" value="{entry_subtitle}" class="acms-admin-form-width-full">
      <input type="hidden" name="field[]" value="entry_subtitle">
    </td>
  </tr>
</table>
```

メディア・画像・グループは隠し項目が多いので、必ずメーカーで生成する。

## ブログ・カテゴリーごとに入力欄を変える

`field.html` には共通の項目だけを書き、出し分けたい項目はグローバル変数入りのパスでインクルードする。インクルード先が無ければ何も出ないので、必要なカテゴリーの分だけファイルを置けばよい。

```html
<!-- admin/entry/field.html -->
@include("/admin/entry/field-common.html")
@include("/admin/entry/bcd/%{BCD}.html")
@include("/admin/entry/ccd/%{CCD}.html")
@include("/admin/entry/rccd/%{RCCD}.html")
```

- インクルードのパスで使うグローバル変数は、テンプレートキャッシュが有効でも解決される `%{BCD}`・`%{PBCD}`・`%{RBCD}`・`%{CCD}`・`%{PCCD}`・`%{RCCD}`・`%{ECD}`・`%{MODULE_NAME}`・`%{MODULE_ID}`・`%{ADMIN_PATH}` などから選ぶ。`%{CID}` などそれ以外はキャッシュが有効な環境で解決されない（acms-template-acms の「実行順序から決まること」と同じ規則）。
- サブカテゴリーもまとめたいときは `%{RCCD}`（ルートのカテゴリーコード）や `%{PCCD}`（親）を使う。
- モジュールの入力欄は `admin/module/field.html` から `@include("/admin/module/id-%{MODULE_ID}.html")` や `name-%{MODULE_NAME}.html` で分ける。`%{MODULE_ID}`・`%{MODULE_NAME}` はモジュール ID の編集画面（URL に `mid` があるとき）で値が入る。
- 値はどれも URL のコンテキスト（表示中のブログ・カテゴリー・エントリー）から決まる。エントリーの編集画面では、URL にカテゴリーが含まれていなければ `%{CCD}` は空になる。

### 出し分けたときに値が消える

保存すると、そのエントリー（ブログ・カテゴリーなど）のカスタムフィールドを一度すべて削除してから、送信された値を登録する。出し分けで入力欄が表示されていない状態で保存すると、表示されていなかったフィールドの値は消える。

- カテゴリーを変えたエントリー、URL にカテゴリーが無い状態で開いた編集画面などで起きる。出し分けを提案するときは、このことを利用者に伝える。
- 送信したフィールドだけを更新させるには、フォームの中に次の2行を書く（`updateField`）。送信されなかったフィールドは残る。

```html
<input type="hidden" name="updateField" value="on">
<input type="hidden" name="field[]" value="updateField">
```

## カスタムフィールドメーカー

- 管理画面の「コンフィグ」のガイドライン / ツールにある「カスタムフィールドメーカー」と、developer サイトの <https://developer.a-blogcms.jp/tools/custom-field.html> は同じツール。
- 「カスタムフィールド」「カスタムフィールドグループ」「カスタムユニット」を切り替えて生成する。カスタムユニット用は名前の付け方が違うので、取り違えない。
- 「出力用コード」タブで標準テンプレートの出力例も得られる。Twig のテーマではそのまま使えないので、references/output.md の対応で書き直す。
