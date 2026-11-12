# Ver. 3.3 でのテーマの変化

このファイルは、作業対象の a-blog cms が Ver. 3.3 以上のときだけ読む。Ver. 3.2 のサイトには当てはめない。Ver. 3.3.0-alpha.1 のソースで確かめた内容で、正式版で変わることがある。

3.2 のテーマを 3.3 に上げるときに直すもの（jQuery 4・htmx 4・上書きした管理画面など）は acms-upgrade-theme の `references/to-3.3.md` にある。

## テーマに置けるものが増えた

| ファイル | 用途 | 詳しくは |
|---|---|---|
| `admin/field-definitions/<対象>.json` | カスタムフィールド定義の宣言（JSON だけ）。テーマと一緒に入力欄を配布できる | acms-field-definition の references/theme-declaration.md |
| `admin/field-definitions/placements.json`、`patterns/*.json` | 定義の入力欄の表示場所、フィールドパターン | 同上 |
| `admin/field-types/<ディレクトリ>/field-type.json` | テーマの独自の入力型 | 同上 |
| `admin/entry/field_side.html`・`field_side_foot.html` | エントリー編集画面のサイドバーに出す入力欄（従来の `field.html` と同じ書き方） | acms-custom-field |
| `410.html`・`451.html`（`template.yaml` の `tpl_410`・`tpl_451`） | リダイレクトの管理で「削除済み（410）」「法的理由で表示できない（451）」にしたページのテンプレート。`404.html` と同じように作る | ― |
| `_member/verify.html`・`_member/update-passkey.html`（`tpl_verify` など） | 本人確認とパスキーの登録の画面 | acms-member-site の references/ver-3.3.md |

テーマの切り替えでカスタムフィールド定義の宣言が消える（値は残る）。テーマを作り直すときは宣言ファイルも移す。

## htmx 4

- 本体が読み込む htmx が 4 になった。既存サイトは互換の拡張 `htmx-2-compat` が既定で読み込まれ（システム設定 `htmx_extensions`）、htmx 2 のイベント名も動く。新規インストールは互換の拡張なし。
- 新しく書く JavaScript は htmx 4 の書き方にする。部分更新の後の再初期化は `htmx:after:settle` で行う。htmx 4 のイベント名・属性は htmx 公式のドキュメントで確かめる（記憶の htmx 2 の書き方で書かない）。
- htmx の設定は、システム設定 `htmx_config`（JSON か HCON）か、テンプレートの `<meta name="htmx-config">` に書く（meta が優先）。`ACMS.Config.htmxConfig` は削除された。
- 読み込み戦略 `htmx_load_strategy` は `static`（既定）か `off`。`dynamic` は廃止された。ページ単位で読み込ませないなら、そのテンプレートに `<meta name="acms-htmx" content="disable">` を書く。

## 公開側の URL の形（クエリ）

- 公開側で、キーワード・タグ・フィールド・並び順・ページ・件数・期間をクエリ（`?keyword=`・`?tag=`・`?page=` など）でも受け付けられるようになった。キーごとにシステム設定 `query_keyword`・`query_tag`・`query_field`・`query_order`・`query_page`・`query_limit`・`query_span` で決まり、on のキーはリンク（`acmsLink`）もクエリの形で作られる。
- 既存サイトからの更新では `query_keyword` だけが on（キーワード検索のリンクが `?keyword=foo` になる）。新規インストールではページ以外が on。ページ送りは既定でパス（`/page/2/`）のまま（静的書き出しと CDN のキャッシュをそろえるため）。
- テンプレートや JavaScript で URL を組み立てたり、URL の形で比較したりしない。リンクは本体の変数・校正オプションが出す URL を使う。キーの設定はサイトごとに違うため。
- 管理画面の一覧の URL は、設定によらずクエリの形になる。

## 予約される URL

`rest-api`・`mcp`・`oauth` は、REST API などを使っていなくても予約された URL のセグメントになる。ブログ・カテゴリー・エントリーのコードに使わない（acms-rest-api）。
