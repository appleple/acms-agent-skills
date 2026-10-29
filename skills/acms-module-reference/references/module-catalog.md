# モジュールの対応表と非推奨のモジュール

SKILL.md の判断表で足りないとき、標準テンプレートを Twig に移すとき、非推奨のモジュールを置き換えるときに読む。
変数表・スニペット・設定項目は書かない。ビルトインモジュール一覧（<https://developer.a-blogcms.jp/document/reference/built_in.html>）から各モジュールのページを開く。

## 標準モジュールと V2 モジュールの対応

Ver. 3.2.38 の本体に実在する V2 モジュールの全件。注記のないものは Ver. 3.2.0 からある。

| 標準モジュール | V2 モジュール | 用途 |
|---|---|---|
| `Entry_Summary` | `V2_Entry_Summary` | エントリーの一覧 |
| `Entry_Body` | `V2_Entry_Body` | エントリーの詳細・本文 |
| `Entry_Continue` | `V2_Entry_MoreContent` | 「続きを読む」以降の本文 |
| `Entry_ArchiveList` | `V2_Entry_ArchiveList` | 月別アーカイブ |
| `Entry_TagRelational` | `V2_Entry_TagRelational` | 同じタグを持つエントリー |
| `Entry_GeoList` | `V2_Entry_GeoList` | 位置情報を持つエントリー |
| `Entry_Field` | `V2_Entry_Field` | エントリーのカスタムフィールド |
| `Unit_List` | `V2_Entry_UnitList` | ユニットの一覧 |
| `Category_List` | `V2_Category_Tree` | カテゴリーの一覧（階層つき） |
| `Category_Flat` | `V2_Category_Flat` | カテゴリーの一覧（階層なし）。標準・V2 とも Ver. 3.2.20 以降 |
| `Category_EntrySummary` | `V2_Category_EntrySummary` | カテゴリーごとのエントリー一覧 |
| `Category_Field` | `V2_Category_Field` | カテゴリーのカスタムフィールド |
| `Category_GeoList` | `V2_Category_GeoList` | 位置情報を持つカテゴリー |
| `Blog_ChildList` | `V2_Blog_ChildList` | 子ブログの一覧 |
| `Blog_Field` | `V2_Blog_Field` | ブログのカスタムフィールド |
| `Blog_GeoList` | `V2_Blog_GeoList` | 位置情報を持つブログ |
| `User_Search` | `V2_User_Search` | ユーザーの一覧 |
| `User_Field` | `V2_User_Field` | ユーザーのカスタムフィールド |
| `User_GeoList` | `V2_User_GeoList` | 位置情報を持つユーザー |
| `Tag_Cloud` | `V2_Tag_Cloud` | タグの一覧 |
| `Tag_Filter` | `V2_Tag_Filter` | 絞り込み中のタグ |
| `Calendar_Month` | `V2_Calendar` | 月のカレンダー |
| `Calendar_Year` | `V2_CalendarYear` | 年間カレンダー |
| `Schedule` | `V2_Schedule` | スケジュール |
| `Topicpath` | `V2_Topicpath` | パンくず |
| `Navigation` | `V2_Navigation` | ナビゲーション |
| `Links` | `V2_Links` | リンク集 |
| `Media_Banner` | `V2_Media_Banner` | バナー |
| `Module_Field` | `V2_Module_Field` | モジュール ID のカスタムフィールド |
| `Field_ValueList` | `V2_Field_ValueList` | カスタムフィールドの値の一覧 |
| `Field_Search` | `V2_Field_Search` | カスタムフィールド検索のフォーム。V2 は Ver. 3.2.1 以降 |
| `Sitemap` | `V2_Sitemap` | XML サイトマップ |
| `Ogp` | `V2_Ogp` | OGP の値 |
| `Js` | `V2_Js` | acms.js の読み込みに使う値 |
| `Form` | `V2_Form` | フォーム |
| `Json_2Tpl` | `V2_Json2Tpl` | JSON の取得と表示 |
| （なし） | `V2_GlobalVars` | グローバル変数をまとめて得る |

- `V2_Field_Search`・`V2_Form`・`V2_Js` はモジュール ID 管理の選択肢に出ない（ID を作れない）。ビルトインモジュール一覧にも載っていないので、名前は上の表で確かめる。
- V2 のない標準モジュールの例: `Entry_Calendar`、`Tag_Assist`、`Unit_Fetch`、`Comment_Body`、`Comment_List`、`Feed_Rss2`、`Feed_ExList`、`Alias_List`。Twig のテーマで使うときは、Twig のテンプレートに `<!-- BEGIN_MODULE ... -->` で書く（Twig の処理のあとに従来のエンジンで処理される）。
- Twig から読み込んだ部品に BEGIN_MODULE を書くのはよいが、`@include` で読み込んだ先の Twig は処理されない（併用の規則は acms-template-twig）。

## Ver. 3.2 で非推奨になったモジュール

新しく使わない。既存のテンプレートにあれば代替へ移すよう提案する（動作は続くので、急いで消す必要はない）。

| 非推奨 | 代替 |
|---|---|
| `Entry_List` / `Entry_Headline` / `Entry_Photo` | `Entry_Summary`（Twig は `V2_Entry_Summary`） |
| `Category_EntryList` | `Category_EntrySummary` |
| `Banner` | `Media_Banner` |
| `User_Profile` | `User_Search` |
| `Plugin_Schedule` | `Schedule` |
| `Shop2_` で始まるカート関連のモジュール | Shopping Cart プラグイン（拡張アプリ） |

- 根拠と最新の一覧: <https://developer.a-blogcms.jp/document/migration/302x/deprecated.html>。モジュール ID 管理の選択肢にも【非推奨】と出る。
- デバッグモードのとき、非推奨のモジュールが動くと監査ログに「非推奨の機能です」という通知が残る（`User_Profile` は除く）。置き換え漏れを探すときに使える。
- 置き換えたら、変数名とブロック名が変わるので、代替モジュールの変数表で書き直す。モジュール ID も代替のモジュール名で作り直す（ID はモジュール名と組で探されるため）。

## タッチモジュールの細部

一覧: <https://developer.a-blogcms.jp/document/reference/touch.html>。Twig では `touch('Touch_...')` で、すべてのタッチモジュールを真偽値として呼べる（`module()` と違い `V2_` は付かない）。

取り違えやすいもの:

| モジュール | 真になる条件 | 注意 |
|---|---|---|
| `Touch_Login` / `Touch_Unlogin` | ログインしている / していない | プレビュー中は「ログインしていない」側として扱われる |
| `Touch_SessionWithAdministration` | 管理者でログイン中 | プレビュー中は偽。権限の段階ごとに `SessionWith...` がある |
| `Touch_Top` | トップページ | |
| `Touch_Entry` | エントリーの詳細ページ（管理画面を除く） | |
| `Touch_Index` | トップでも詳細でもないページ（一覧ページ） | |
| `Touch_Category` | URL にカテゴリーがある | カテゴリーに属するエントリーの詳細ページでも真 |
| `Touch_Tag` / `Touch_Keyword` | タグ / キーワードで絞り込み中 | |
| `Touch_NotPreview` | プレビュー・タイムマシンでない | 編集ボタンを出す部品で使われている |

否定は `Touch_NotEntry` のような `Not` 付きのモジュールを使う（Twig なら `not touch(...)` でもよい）。
