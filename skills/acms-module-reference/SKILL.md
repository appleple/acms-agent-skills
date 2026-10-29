---
name: acms-module-reference
description: >-
  a-blog cms（acms）で「何を表示したいか」から使うモジュールを選び、モジュール ID・URL コンテキスト・変数表の引き方を案内する。
  エントリー一覧・詳細・カテゴリー一覧・タグ・パンくず・ナビゲーション・バナー・カスタムフィールドなどを表示したいが
  どのモジュールを使えばよいか分からないとき、モジュールの変数名やブロック名を調べるとき、
  標準テンプレートと Twig（V2 モジュール）のどちらのモジュールを使うか決めるときに使う。
  a-blog cms module, module ID, variables. モジュールを置く記法は acms-template-acms / acms-template-twig が担う。
license: MIT
compatibility: a-blog cms Ver. 3.2 以上
metadata:
  acms-min-version: "3.2"
  status: draft
---

# a-blog cms のモジュールの選び方

公式ドキュメント:
- モジュール: <https://developer.a-blogcms.jp/document/module/>
- モジュール ID: <https://developer.a-blogcms.jp/document/moduleid/>
- ビルトインモジュール一覧: <https://developer.a-blogcms.jp/document/reference/built_in.html>
- タッチモジュール一覧: <https://developer.a-blogcms.jp/document/reference/touch.html>
- フィールドモジュール: <https://developer.a-blogcms.jp/document/reference/field.html>

## 手順

1. テンプレートの種類を確かめる（acms-project-triage）。Twig なら `V2_` で始まるモジュールだけが使える。
2. 表示したいものに合うモジュールを、上のビルトインモジュール一覧から選ぶ。記憶にあるモジュール名を使う前に、一覧に実在するかを確かめる。
3. 変数名とブロック名を確かめる。
   - 標準テンプレート: 一覧の各モジュールのページにある変数表とスニペット
   - Twig: 管理者でログインし、デバッグモードで `Ctrl + K`（Mac は `⌘ + K`）→ `#` で、そのページの V2 モジュールの変数表を見る
4. 件数・並び順・絞り込みなどの設定が要るなら、モジュール ID を作って管理画面で設定する（下記）。

## モジュール ID を使うかどうか

| 状況 | 判断 |
|---|---|
| 同じ種類のモジュールを1ページに複数置く | ID を分ける。分けないと設定が共通になる |
| 件数・並び順・対象カテゴリーなどを、運用者が管理画面で変えられるようにしたい | ID を作る |
| どのページでも同じ設定でよい、またはテンプレートの記述だけで決めたい | ID を使わず、URL コンテキスト（標準は `ctx`、Twig は第3引数）で指定する |

モジュール ID は DB に保存される設定なので、ファイルを置くだけでは作られない。新しい ID が必要なときは、管理画面で作る手順を利用者に伝える（または設定のエクスポート・インポートで持ち込む）。

## 表示の出し分け

ログイン中だけ・トップページだけ・カテゴリーページだけ、のような出し分けにはタッチモジュール（`Touch_Login`、`Touch_Top`、`Touch_Category` など）を使う。Twig では `touch('Touch_Login')` で真偽値を得る。

## 守ること

- モジュール名・変数名を推測で書かない。一覧と変数表で実在を確かめる。
- 一つのページに重いモジュール（全件を数える一覧など）を必要以上に置かない。
