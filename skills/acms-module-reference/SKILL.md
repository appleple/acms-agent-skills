---
name: acms-module-reference
description: >-
  a-blog cms（acms）で「何を表示したいか」から使うモジュールを選び、標準モジュールと V2 モジュールの対応、
  Ver. 3.2 で非推奨になったモジュールと代替、モジュール ID の仕組み（見つからないときの挙動・ブログをまたぐスコープ・
  URL コンテキストと ctx の優先関係・キャッシュ）、編集ボタン、重いモジュール、タッチモジュールの選び方を案内する。
  エントリー一覧・詳細・カテゴリー一覧・タグ・パンくず・ナビゲーション・バナー・カスタムフィールドなどを表示したいが
  どのモジュールを使えばよいか分からないとき、モジュール ID を作る・付けるとき、
  「出るはずのモジュールが出ない」「件数や絞り込みが効かない」「別のページと同じ内容が出る」ときに使う。
  a-blog cms module, V2 module, module ID, ctx, URL context, Touch module, deprecated module.
  モジュールを置く記法は acms-template-acms（標準テンプレート）/ acms-template-twig（Twig）が担う。
license: MIT
compatibility: a-blog cms Ver. 3.2 以上。V2 モジュールは Twig が有効なテーマでだけ使える。
metadata:
  acms-min-version: "3.2"
  status: stable
---

# a-blog cms のモジュールの選び方

公式ドキュメント（変数表・スニペット・設定項目はここで確かめる）:
- ビルトインモジュール一覧（標準・V2・非推奨の印つき）: <https://developer.a-blogcms.jp/document/reference/built_in.html>
- タッチモジュール一覧: <https://developer.a-blogcms.jp/document/reference/touch.html>
- フィールドモジュール: <https://developer.a-blogcms.jp/document/reference/field.html>
- モジュール ID: <https://developer.a-blogcms.jp/document/moduleid/>
- Twig でのモジュールの使い方: <https://developer.a-blogcms.jp/document/twig/module.html>
- Ver. 3.2.x で推奨されなくなる機能: <https://developer.a-blogcms.jp/document/migration/302x/deprecated.html>

## 手順

1. テンプレートの種類を確かめる（acms-project-triage）。標準テンプレートか Twig かで、使うモジュールの名前が変わる。
2. 表示したいものに合うモジュールを、下の判断表から選ぶ。表にないものは references/module-catalog.md、それでもなければビルトインモジュール一覧で探す。記憶にあるモジュール名は、一覧に実在するか確かめてから使う。
3. 非推奨のモジュール（`Entry_List`・`Entry_Headline`・`Entry_Photo`・`Category_EntryList`・`Banner`・`User_Profile` など）を新しく書かない。既存のテンプレートにあれば代替を案内する（references/module-catalog.md）。
4. 件数・並び順・絞り込みを運用者が管理画面で変えられるようにするなら、モジュール ID を使う（下記）。
5. 変数名・ブロック名を確かめる。
   - 標準テンプレート: ビルトインモジュール一覧から各モジュールの変数表・スニペットを開く。
   - Twig: V2 モジュールには変数表がない。管理者でログインし、デバッグモードで `Ctrl + K`（Mac は `⌘ + K`）→ `#` を入力すると、そのページで呼んだ V2 モジュールの戻り値が見られる。

## 判断表（よく使うもの）

| 表示したいもの | 標準テンプレート | Twig |
|---|---|---|
| エントリーの一覧（新着、カテゴリー別、検索結果、タグの絞り込み結果） | `Entry_Summary` | `V2_Entry_Summary` |
| エントリーの詳細（本文のユニット） | `Entry_Body` | `V2_Entry_Body` |
| カテゴリーの一覧（階層つき / 階層なし） | `Category_List` / `Category_Flat` | `V2_Category_Tree` / `V2_Category_Flat` |
| カテゴリーごとのエントリー一覧 | `Category_EntrySummary` | `V2_Category_EntrySummary` |
| 月別アーカイブ | `Entry_ArchiveList` | `V2_Entry_ArchiveList` |
| タグの一覧 / 選択中のタグ | `Tag_Cloud` / `Tag_Filter` | `V2_Tag_Cloud` / `V2_Tag_Filter` |
| 同じタグを持つ関連エントリー | `Entry_TagRelational` | `V2_Entry_TagRelational` |
| パンくず | `Topicpath` | `V2_Topicpath` |
| グローバルナビゲーション | `Navigation` | `V2_Navigation` |
| バナー | `Media_Banner` | `V2_Media_Banner` |
| リンク集 | `Links` | `V2_Links` |
| ブログ / カテゴリー / エントリー / ユーザーのカスタムフィールド | `Blog_Field` / `Category_Field` / `Entry_Field` / `User_Field` | `V2_` を付けた同名 |
| モジュール ID に持たせたカスタムフィールド | `Module_Field` | `V2_Module_Field` |
| ログイン中だけ・トップだけ、などの出し分け | タッチモジュール（`BEGIN_MODULE Touch_...`） | `touch('Touch_...')` |

- Twig の `module()` に渡せるのは `V2_` で始まるモジュールだけ。`module('Entry_Summary')` のように従来の名前を渡しても動かない。
- V2 モジュールは名前が似ていても、従来のモジュールと変数名や構造が違う。標準テンプレートの変数名をそのまま Twig に持ち込まない。
- Twig のテーマでも、テンプレートに書いた `<!-- BEGIN_MODULE ... -->` は Twig の処理のあとに従来のエンジンで処理されるので動く。ただし V2 があるモジュールは V2 を使う。V2 のないモジュール（`Entry_Calendar` など）が必要なときだけ BEGIN_MODULE を使う。

## モジュール ID

モジュール ID は、管理画面（モジュール ID 管理）で作る DB の設定。テンプレートに書いただけでは作られない。

- モジュール ID を使う回答では、毎回「この ID はテンプレートに書くだけでは作られないので、管理画面で作る（またはインポートする）必要がある」と利用者に明示する。管理画面での操作は利用者がするので、書かないと ID の無いまま動いて気付かれないため。
- テンプレートに ID を書いたら、管理画面にその ID が実在するかを利用者に確かめてもらう。無ければ作成の手順を伝える（モジュール ID のエクスポート・インポートで別環境から持ち込むこともできる）。
- ID が見つからなくてもエラーにはならない。ID の設定がないまま、ブログのコンフィグの設定で動く。そのため「出るはずのものが出ない」「件数や絞り込みが効かない」ときは、まず ID の実在を疑う。
- ID は「モジュール名と ID の組」で探される。`Entry_Summary` 用に作った ID は `V2_Entry_Summary` からは見つからない。
- 子ブログから親ブログの ID を使えるのは、親の ID で「グローバル」（下の階層のブログが利用することを許可する）にチェックがあるときだけ。

見つからない条件の一覧、ブログをまたぐスコープ、ID の名前の付け方、キャッシュ、編集ボタンは references/module-id.md を読む。

## URL コンテキストと ctx

モジュールが表示する対象（ブログ・カテゴリー・エントリー・ページなど）は、次の順で決まる。

1. モジュール ID の設定値が、テンプレートの指定（標準の `ctx="..."`、Twig の `module()` 第3引数）より優先される。
2. その項目の「〜の URL コンテキストを優先する」（画面では「タグのURLコンテキストを優先する」「EIDのURLコンテキストを優先する」のように項目ごと。引数のチェック）が有効で、URL に値があれば URL の値が使われる。無効なら URL の値は使われない。
3. ID がないときのチェックの既定値はモジュールごとに違う（`Entry_Body` は URL に従い、`Entry_Summary` は従わない）。

そのため、テンプレートで ctx を変えても効かないときは ID の設定値を、ページ送りやカテゴリーが URL に追従しないときは引数のチェックを確かめる。詳しい表と Twig だけの注意（第3引数の `limit`）は references/module-id.md を読む。

## 重いモジュールと出し分け

- エントリーの本文（ユニット）が要らない一覧に `Entry_Body` を使わない。`Entry_Body` は一覧でもエントリーごとにユニットを組み立てる。一覧は `Entry_Summary` を使う。
- モジュール ID の表示設定で、使わない項目（関連エントリー、各種カスタムフィールド、ページャーなど）は無効にする。有効な項目ごとに取得処理が増える。
- どのモジュールが重いかは推測せず、ユーザーのモードを「デバッグモード & ベンチマークモード」にして、モジュールごとの実行時間とクエリ数を見る。
- 出し分けにはタッチモジュールを使う。`Touch_Login` はプレビュー中は偽になる、`Touch_Category` はカテゴリーに属するエントリーの詳細ページでも真になる、などの細部は references/module-catalog.md を読む。

## 守ること

- モジュール名・変数名を推測で書かない。一覧と変数表（Twig はデバッグモードの変数一覧）で実在を確かめる。
- 非推奨のモジュールを新しく使わない。
- テンプレートに書いた ID が管理画面にあるかを確かめずに完了としない。無い場合は「管理画面で作る必要がある」と明示する。
- モジュール ID のキャッシュを、URL によって内容が変わるモジュールに勧めない（キャッシュはモジュール名と ID だけで共有される。references/module-id.md）。
