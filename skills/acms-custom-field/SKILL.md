---
name: acms-custom-field
description: >-
  a-blog cms（acms）のカスタムフィールドとカスタムユニットを、管理画面の入力欄の定義からテンプレートでの出力まで扱う。
  ブログ・カテゴリー・エントリー・ユーザー・モジュールの入力欄を置くファイル（admin/entry/field.html・field_foot.html など）、
  ブログやカテゴリーごとの入力欄の出し分け、カスタムフィールドメーカー、入力の種類の選び方（画像・ファイル・メディア、
  テキストエリア・ブロックエディター）、フィールドグループ、{name@path} などの出力と Twig の fields.name.value、
  画像のリサイズと width / height、カスタムユニット（include/unit/extend.html、unit#custom_名前）、検索の対象外にする :search を扱う。
  「エントリーに入力欄を足したい」「画像フィールドを作って」「カスタムフィールドが表示されない」「カスタムユニットを作りたい」と頼まれたときに使う。
  a-blog cms custom field, custom unit, field group, media field, image field.
  記法一般は acms-template-acms / acms-template-twig、フォームは acms-form、モジュール選びは acms-module-reference が担う。
license: MIT
compatibility: a-blog cms Ver. 3.2 以上
metadata:
  acms-min-version: "3.2"
  status: stable
---

# a-blog cms のカスタムフィールドとカスタムユニット

公式ドキュメント:
- カスタムフィールド: <https://developer.a-blogcms.jp/document/customfield/>
- ユニット: <https://developer.a-blogcms.jp/document/units/>
- カスタムフィールドメーカー: <https://developer.a-blogcms.jp/tools/custom-field.html>（管理画面の「コンフィグ」にも同じツールがある）

## 書く前に

- テーマが標準テンプレートか Twig かを確かめる（acms-project-triage）。**管理画面の入力欄は、どちらのテーマでも標準テンプレートの記法で書く**（下記）。出力側だけがテーマの記法に従う。
- 入力欄の HTML は手で書かず、カスタムフィールドメーカーで生成してから直す。`field[]`・`:extension`・`@old` などの隠し項目の書き漏れを防げるため。
- フィールド名は Twig から `fields.name` で参照するので、ハイフンを使わず英数字とアンダースコアにする（ハイフンを含む名前は Twig のドット記法で書けない）。

## 1. 入力欄をどこに書くか

自分のテーマに次のファイルを置く。system テーマの管理画面テンプレートが `@include` で読み込むので、ファイルが無ければ何も出ない（エラーにもならない）。

| 対象 | ファイル | 管理画面での位置 |
|---|---|---|
| エントリー | `admin/entry/field.html` | タイトル・カテゴリーなどの下、ユニットの上 |
| エントリー | `admin/entry/field_foot.html` | ユニットの下 |
| ブログ | `admin/blog/field.html` | ブログ管理のカスタム設定タブ |
| カテゴリー | `admin/category/field.html` | カテゴリー編集のカスタム設定タブ |
| ユーザー | `admin/user/field.html` | ユーザー編集のカスタム設定タブ |
| モジュール | `admin/module/field.html` | モジュール ID 編集のカスタム設定タブ |

- `admin/entry/edit.html` などの編集画面全体を自分のテーマに複製して入力欄を書き足す方法は古い。複製するとテーマ側が優先されて system の編集画面の更新が届かなくなるので、`field.html` を使う。既存テーマに複製された `edit.html` があれば、入力欄を `field.html` に移すことを提案する。
- `field.html` の中では Twig は処理されない。system の標準テンプレートから `@include` で読み込まれ、`@include` の先は標準テンプレートとして処理されるため。`field.twig` を置いても読み込まれない。
- 入力欄の出し分け（ブログ・カテゴリーごと）は `field.html` からグローバル変数入りのパスでインクルードする。使える変数と、保存時に値が消える落とし穴は references/admin-field.md を読む。

## 2. 入力の種類を選ぶ

| 入れたいもの | 選ぶ種類 | 理由 |
|---|---|---|
| 画像・PDF などのファイル | **メディア** | メディア管理の画像・ファイルを ID で参照する。差し替えや代替テキストの修正がすべての使用箇所に反映され、焦点・比率（`@ratio`）も使える。ファイルはダウンロードの公開範囲を設定できる |
| 改行のあるプレーンテキスト | テキストエリア | 出力でエスケープして改行を `<br>` にするだけでよい |
| 見出し・リスト・リンク・画像を含む本文 | ブロックエディター | 構造のある HTML を保存し、出力時に画像のリサイズなどの処理が入る |
| 太字・リンクだけの短い文 | ブロックエディター | ライトエディターは Ver. 3.2 で本体の JavaScript に非推奨と明記されている。新しく使わない |

画像・ファイル（保存先 archives）は、メディア管理を使わないサイトや既存のフィールドとの互換のときだけ選ぶ。種類ごとの違いの詳細は references/input-types.md を読む。

## 3. 出力する

| テンプレート | 単一の値 | 画像・メディア | グループ |
|---|---|---|---|
| 標準 | `{name}` | `{name@path}`・`{name@alt}` など接尾辞付きの変数 | `<!-- BEGIN group:loop -->` 〜 `<!-- END group:loop -->` |
| Twig（V2 モジュール） | `fields.name.value`（複数値は `.array`） | `fields.name.value.path`・`.value.alt` | `fields.group` は行の配列。行の中は `row.name.value`、画像・メディアは **`row.name.path`（`.value` が付かない）** |

必ず守ること:

- Twig で `fields.name` をそのまま比較・出力しない。`{value, array}` の形の配列なので、`.value` を付け忘れると比較が常に偽になる。
- **画像・メディアの有無は `path` で判定する**（標準は `<!-- BEGIN_IF [{name@path}/nem] -->`、Twig は `{% if fields.name.value.path %}`）。参照先のメディアが削除されると、フィールドにメディアの ID だけが残り、`path` などは空になる。`{% if fields.name.value %}` は真のままなので `<img src="">` が出る。判定を直すときは、同じフィールドを出している箇所をテーマ全体で探し、標準テンプレートの部品（`{name@path}`）と Twig（`.value.path`）の両方を揃える。Twig のテーマでも `@include` で読む標準テンプレートの部品が混ざっていることがあるため。
- エントリーの一覧系モジュール（`Entry_Summary` など）でエントリーのカスタムフィールドを出すには、モジュール ID の設定でエントリーフィールドの出力を有効にする。モジュールのカスタムフィールドは、モジュール ID の「カスタムフィールド」を有効にしたときだけ出る。
- 画像は `resizeImg(幅)` で縮小して出す。`height` は、メディアなら `{name@ratio}[getHeightFromRatio(幅)]`、画像（archives）なら `{name@path}[imageRatioSizeH(幅)]` で求める。

標準・Twig の出力例、空欄で保存したときの扱い、値の型の自動変換、画像の校正オプションの違いは references/output.md を読む。

## 4. カスタムユニット

- 表示側は `include/unit/extend.html` に `<!-- BEGIN unit#custom_名前 -->` 〜 `<!-- END unit#custom_名前 -->` を書き、入力側は `admin/entry/unit/extend.html` に `<!-- BEGIN custom_名前 -->` 〜 `<!-- END custom_名前 -->` を書く。管理画面の編集設定の「ユニットメニュー」にモード `custom_名前` を足し、ユニット設定でそのメニューの中身を設定する（ユニット設定が空のメニューは編集画面に出ない）。
- `include/unit/custom.html`・`admin/entry/unit/custom.html` は種類 `custom` の1つしか作れないので使わず、`extend.html` で作る。
- カスタムユニットの入力欄は、カスタムフィールドと名前の付け方が違う（`{id}` を付ける、`field[]` ではなく `unit{id}[]`）。カスタムフィールドメーカーの「カスタムユニット」で生成する。
- 表示側の `extend.html` は Twig のテーマでも標準テンプレートの記法で書く（ユニットの HTML は Twig のテーマでも標準テンプレートのエンジンで組み立てられる）。
- モジュールなど重い処理を含むユニットは、`extend.html` からグローバル変数入りのパスでインクルードして、使うブログ・カテゴリーだけで読み込む。

仕組みと手順、出し分けの理由は references/custom-unit.md を読む。JavaScript で独自のユニットを登録したいときは acms-admin-frontend-plugin（Ver. 3.2.29 以降）を使う。

## 5. 検索

- カスタムフィールドの値は既定でキーワード検索の対象になる。対象から外すには、入力欄に `<input type="hidden" name="name:search" value="0">` を足す。名前に `@` を含むフィールド（`name@alt` など）は既定で対象外。
- フィールドの値での絞り込み（URL コンテキストの `field/`、`Field_Search` モジュール）は <https://developer.a-blogcms.jp/document/customfield/field_search.html> を読む。カスタムユニットの値はユニットの中に保存されるので、フィールドでの絞り込みには使えない（キーワード検索の対象にはなる）。

## よくある誤り

- `field[]` の隠し項目を書き忘れて保存されない（メーカーで生成すれば起きない）。
- Twig で `fields.name == 'on'` と書いて常に偽になる（`.value` を付ける）。グループの中の画像に `.value.path` と書いて何も出ない（グループ内は `row.name.path`）。
- 画像の有無を `{% if fields.name.value %}` で判定して、メディアが削除されたときに空の `<img>` が出る。
- 標準テンプレートでメディアの画像を `{name@path}` だけで出してリンクが切れる（`%{MEDIA_ARCHIVES_DIR}{name@path}`。画像（archives）は `%{ARCHIVES_DIR}{name@path}`）。
- カテゴリーごとに入力欄を出し分けたあと、入力欄が出ていない状態で保存して値が消える（references/admin-field.md）。
- `field.html` に Twig を書いて動かない。
