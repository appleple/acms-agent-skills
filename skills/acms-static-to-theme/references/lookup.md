# 変数名・ブロック名・設定キーを確かめる場所

テンプレートを書く前、モジュール ID の設定手順書を書く前に読む。推測で書いた名前は、エラーにならずに空になるだけなので気付きにくい。developer サイトは最新バージョンの説明なので、設置されているバージョンと食い違ったら、設置ディレクトリのファイルを正とする。

## 設置ディレクトリの中で読むファイル

どれも配布物に入っている公開のファイル。`config.server.php`・`.env`・`private/` は読まない（SKILL.md の「守ること」）。`grep` は `themes/` の下に絞ってかける。

| 知りたいこと | ファイル | 読み方 |
|---|---|---|
| 標準テンプレートのモジュールで使える変数・ブロック名 | `themes/system/acms-code/vars/<モジュール名>.html`（例: `Entry_Summary.html`） | `<legend>` がブロック名、`<var>` が変数名。ブロックの入れ子が、変数を使える範囲 |
| モジュールの最小の書き方 | `themes/system/acms-code/snippets/<モジュール名の小文字>.html`。V2 モジュールは `v2_<…>.html` | HTML エスケープされた状態で入っている |
| モジュール ID の表示設定の項目とキー | `themes/system/admin/config/` の下の `*_body.html`（例: `entry/summary_body.html`、`topicpath_body.html`）。V2 モジュールは `admin/config/v2/` の下 | `name` 属性が設定のキー、`<option>` / `value` が取りうる値、`<th>` が画面の項目名。`_body` の付かない同名のファイルは外枠だけ |
| モジュール ID の条件設定（引数・階層）の項目名 | `themes/system/include/module/edit.html` | 画面の表記（「カテゴリーID（cid）」「CIDのURLコンテキストを優先する」など）をそのまま取る |
| モジュールの選択肢の表記 | `themes/system/admin/module/select.html` | 「サマリー ( Entry_Summary )」のように、画面での名前とモジュール名の組 |
| ユニットの表示の部品の名前 | `themes/system/_layouts/unit.html` の `@section(…)` | 下の「ユニット」と references/theme-parts.md |
| そのバージョンで実際に動く書き方 | `themes/` にある公式テーマ（配布物に入っているもの。`blog` など） | 変数表に載らない書き方（`:veil` の使い方、インクルードの分け方）を見る |

- 標準テンプレートでは、変数表で名前と使える範囲を決め、公式テーマで書き方を確かめる、の 2 段で確かめる。
- Twig（V2 モジュール）には変数表のファイルが無い。デバッグモードのユーザーでログインし、`Ctrl + K`（Mac は `⌘ + K`）→ `#` で、そのページで呼んだ V2 モジュールの戻り値を見る（acms-module-reference）。snippets の `v2_*.html` も書き方の見本になる。
- 表示設定のキーは、標準のモジュールと V2 モジュールで同じ名前のもの（`entry_summary_*`）を使う。画面は別のファイル（`admin/config/v2/`）なので、項目の有無はそちらで確かめる。

## キーの名前はモジュールごとに揃っていない

同じ意味の設定でも、モジュールが違うとキーの名前の作り方が違う。一方の名前から他方を推測しない。代表例は references/admin-checklist.md の「表示設定」の表にある。

## developer サイト

- ビルトインモジュール（各モジュールの変数表・スニペットへの入口）: <https://developer.a-blogcms.jp/document/reference/built_in.html>
- モジュール ID の各項目: <https://developer.a-blogcms.jp/document/moduleid/setting.html>、引数: <https://developer.a-blogcms.jp/document/moduleid/argument.html>
