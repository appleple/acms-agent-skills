# ページと要素を a-blog cms の機能に割り当てる

手順 4 で、静的サイトのページと要素を a-blog cms のどの機能で管理するかを決めるときに読む。モジュールの変数・設定・スニペットは書かない。モジュール名から acms-module-reference と、記法のスキル（acms-template-acms / acms-template-twig）に進む。

## まず決めること: 何を更新できるようにするか

利用者に「誰が・どのくらいの頻度で・どこを更新するか」を聞き、次の 3 つに分ける。全部を CMS 化すると、テンプレートも管理画面の作業も増える。

| 区分 | 例 | 扱い |
|---|---|---|
| 頻繁に増える・変わる | お知らせ、ブログ、実績、イベント、採用情報 | エントリーにする |
| たまに変わる 1 か所だけの値 | サイト名、電話番号、SNS の URL、メインビジュアル、トップの紹介文 | ブログのフィールドかモジュール ID のフィールドにする |
| ほとんど変わらない | 会社概要、プライバシーポリシー、LP の固定の説明 | 静的なまま残すか、1 件のエントリーにする（下の「固定ページ」） |

## ページの対応

| 静的サイトのページ | a-blog cms での形 | テンプレート |
|---|---|---|
| トップ（ルートの `index.html`） | ブログのトップ | `tpl_top`（既定 `_top.html`） |
| 一覧（`news/index.html` など） | カテゴリーの一覧。ディレクトリ名をカテゴリーコードにすると URL が変わらない | `<カテゴリーコード>/` の `tpl_index`（既定 `index.html`） |
| 一覧の 2 ページ目以降（`page2.html`、`page/2/` など） | 一覧のページャー（URL は a-blog cms の形になる） | 作らない。一覧のテンプレートでページャーを出す |
| 詳細（`news/2025xxxx.html` など） | エントリー。カテゴリーに入れる | `<カテゴリーコード>/` の `tpl_detail`（既定 `_entry.html`）。静的な詳細ページ 1 枚をひな形にする |
| 固定ページ（会社概要など） | 更新しないなら静的なまま同じパスに置く。運用者が本文を直すなら、1 件のエントリーにして、エントリーコードを元のファイル名にする | 静的なままならそのファイル。エントリーにするならエントリー別・カテゴリー別のテンプレート（acms-theme-development の references/template-resolution.md） |
| フォームの入力・確認・完了の 3 ファイル | フォーム ID 1 つ。1 つのテンプレートの中でステップを切り替える | acms-form |
| 言語ごとのディレクトリ（`/en/` など） | 言語ごとの子ブログが基本（references/site-types.md の「多言語」） | 子ブログ用のテーマ（acms-theme-development） |
| 404 ページ | 静的サイトのものを使うなら `tpl_404`（既定 `404.html`）として置く | テーマ直下 |

- カテゴリーかブログか迷ったら、acms-theme-development の references/large-site.md の「子ブログにするか、カテゴリーにするか」で決める。
- 一覧と詳細の候補は、scripts/inventory.sh の「リンクの構造」に出る。

## 要素の対応

| 要素（静的 HTML の中） | 機能 | 標準テンプレート / Twig | 担当 |
|---|---|---|---|
| 記事の一覧（同じ形の `li`・`article` の繰り返し） | エントリーの一覧 | `Entry_Summary` / `V2_Entry_Summary` | acms-module-reference |
| 記事の本文・日付・カテゴリー・タグ | エントリーの詳細 | `Entry_Body` / `V2_Entry_Body` | acms-module-reference |
| 一覧のサムネイル | エントリーの画像のカスタムフィールド（モジュール ID の表示設定で、一覧のメイン画像に使うフィールドを選ぶ） | 同上 | acms-custom-field |
| 一覧の「もっと見る」「次へ」・ページ番号 | 一覧のモジュールのページャー（モジュール ID で URL のページ番号を受け取る設定が要る） | 同上 | acms-module-reference |
| `<title>`・パンくずの記事名・カテゴリー名 | グローバル変数（`%{ENTRY_TITLE}` など）かパンくずのモジュール | `Topicpath` / `V2_Topicpath` | acms-template-acms / acms-template-twig |
| サイト名 | ブログの名前（グローバル変数 `%{BLOG_NAME}`） | Twig は `{{ BLOG_NAME }}` | acms-template-* |
| キャッチコピー・連絡先・SNS の URL など、サイト全体で 1 つの値 | ブログのフィールド（`admin/blog/field.html`） | `Blog_Field` / `V2_Blog_Field` | acms-custom-field |
| メインビジュアル・トップの紹介文など、1 か所だけの値 | モジュール ID のフィールド（`admin/module/field.html`） | `Module_Field` / `V2_Module_Field` | acms-custom-field |
| スライダー・バナー | バナーのモジュール、またはモジュール ID のフィールドのグループ | `Media_Banner` / `V2_Media_Banner` | acms-module-reference |
| グローバルナビゲーション | 項目が変わらないなら静的なまま。運用者が項目を変えるならナビゲーションのモジュール | `Navigation` / `V2_Navigation` | acms-module-reference |
| 現在地の印（`aria-current`・active の class） | グローバル変数（`%{CCD}` など）の比較 | 標準は IF ブロック、Twig は `{% if %}` | acms-template-* |
| トップだけ・下層だけで違う部分（見出しの h1 など） | タッチモジュール | `Touch_Top` / `Touch_NotTop`（Twig は `touch()`） | acms-module-reference |
| カテゴリーの一覧・絞り込み | カテゴリーの一覧のモジュール | `Category_List` / `V2_Category_Tree` | acms-module-reference |
| お問い合わせフォーム | フォーム ID とフォームのモジュール | `Form` / `V2_Form` | acms-form |
| 外部サービスに送っているフォーム（action が外部の URL） | 利用者に確かめる。外部サービスを続けるならそのまま残す | ― | ― |
| サイトマップ・RSS | 本体のもの（system テーマの `sitemap.xml`・`rss2.xml`） | 静的なファイルはテーマに置かない | acms-theme-development |

## 割り当て表の形（利用者に見せる）

次の形で書き、合意を取ってから手順 5 に進む。

```markdown
| 静的サイト | a-blog cms | 作るもの（管理画面） | 優先 |
|---|---|---|---|
| news/index.html, news/*.html | カテゴリー news のエントリー | カテゴリー news、モジュール ID 2 つ | 1 |
| index.html のお知らせ一覧 | V2_Entry_Summary（news_top） | モジュール ID news_top | 1 |
| ヘッダーの電話番号 | ブログのフィールド tel | admin/blog/field.html の入力欄 | 3 |
| company.html | 静的なまま | なし | ― |
```

モジュール ID・フォーム ID の名前は、どのページのどの部分かが分かる名前にする（管理画面の一覧で見分けるため）。同じ名前の ID が親ブログにグローバルであると作れない・インポートされないので、子ブログを使う構成では acms-module-reference の references/module-id.md を読んで決める。
