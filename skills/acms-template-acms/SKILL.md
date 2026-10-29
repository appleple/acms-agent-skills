---
name: acms-template-acms
description: >-
  a-blog cms（acms）の標準テンプレート（従来の独自記法）を書く・直す・読むときの記法と判断基準。
  <!-- BEGIN_MODULE --> によるモジュール配置、ブロック（:loop / :veil / :glue / :touch）、変数 {var} とグローバル変数 %{VAR}、
  BEGIN_IF の条件分岐、@include / @extends、校正オプション [option] とエスケープ、モジュール ID を扱う。
  Twig が有効でないテーマの .html テンプレートを編集するとき、BEGIN_MODULE や {var}[escape] を含むファイルを触るときに使う。
  a-blog cms standard template syntax. Twig テンプレート（.twig、module('V2_...')）は acms-template-twig が担う。
license: MIT
compatibility: a-blog cms Ver. 3.2 以上
metadata:
  acms-min-version: "3.2"
  status: draft
---

# a-blog cms の標準テンプレート

公式ドキュメント: <https://developer.a-blogcms.jp/document/template/>

## 書く前に

- テーマが Twig（`template.yaml` の `tpl_twig: enabled`）でないことを確かめる。Twig のテーマなら acms-template-twig を使う。
- 何を表示するモジュールを使うか決まっていなければ、acms-module-reference で選ぶ。
- 変数名は推測しない。モジュールごとの変数表（acms-module-reference から辿る）か、同じテーマの既存テンプレートで確かめる。

## 記法の要点

```html
<!-- BEGIN_MODULE Entry_Summary id="news_list" ctx="bid/1/cid/2" -->
<!-- BEGIN entry:loop -->
<a href="{url}">{title}</a>
<!-- END entry:loop -->
<!-- BEGIN notFound -->記事がありません<!-- END notFound -->
<!-- END_MODULE Entry_Summary -->

<!-- BEGIN_IF [%{PAGE}/gte/2] -->2ページ目以降<!-- END_IF -->
@include("/include/parts/card.html", {"title": "見出し"})
```

| 記法 | 意味 |
|---|---|
| `<!-- BEGIN_MODULE 名前 id="..." ctx="..." -->` | モジュールの配置。`id` はモジュール ID、`ctx` は URL コンテキストの上書き |
| `<!-- BEGIN x:loop -->` | 繰り返し |
| `<!-- BEGIN x:glue -->` | ループの最後以外で出力（区切り文字） |
| `<!-- BEGIN x:veil -->` | 囲んだ変数がすべて空なら、囲み全体を出さない |
| `{var}` / `%{VAR}` | モジュール内の変数 / グローバル変数（テンプレートのどこでも使える） |
| `<!-- BEGIN_IF [{a}/eq/b] -->` | 条件分岐。演算子は `eq` `neq` `gt` `gte` `lt` `lte` `lk` `nlk` `re` `nre` `em` `nem` など。`_and_` / `_or_` で連結 |
| `@include("/path", {...})` | インクルード。先頭の `/` はテーマのディレクトリが基準。テーマの継承に沿って探される |
| `@extends` / `@section` / `@parent` | テンプレートの継承 |

ブロックの詳しい書き方・実行順序・エスケープ（`\{var\}` で処理を遅らせる）は references/syntax.md を読む。

## 校正オプションとエスケープ（必ず守る）

- `{var}` は既定で `escape` される。`[nl2br]` や `[trim(20)]` のように他の校正オプションを付けても、`raw`・`escape`・`resizeImg` のいずれも含まなければ `escape` が自動で先頭に付く。
- `[raw]` はエスケープを外すだけで、HTML の無害化ではない。システム設定 `strip_dangerous_tag` が on のときは危険なタグが取り除かれるが、off の環境もある。
- `[raw|allow_dangerous_tag]` は script や iframe もそのまま出す。使うのは、管理者だけが入力する値で、かつ利用者が明示的に求めたときに限る。
- フォームの入力値など、不特定の人が入力した値には `raw` を付けない。
- 変数名が `selected` `checked` `disabled` `class` `attr`、または `:selected` / `:checked` で終わる変数には `raw` が自動で付く。ここにユーザーの入力値を入れない。

校正オプションの一覧: <https://developer.a-blogcms.jp/document/reference/proofreading.html>

## よくある誤り

- モジュールの外で `{var}` を使う（モジュールの変数はその `BEGIN_MODULE` の中でしか値が入らない）。
- `BEGIN` と `END` のブロック名やモジュール名が一致していない。
- 同じモジュールを複数置いたのにモジュール ID を分けず、管理画面の設定が混ざる。
- Twig のテーマに BEGIN_MODULE を書く（Twig テーマでは V2 モジュールを `module()` で呼ぶ）。

## 確認

- デバッグモードでは、インクルードしたテンプレートのパスが HTML コメントに出る。表示されたページの HTML で、意図したファイルが使われているか確かめる。
- 変数が空になるときは、変数表で名前と、どのブロックの中で使えるかを確かめる。
