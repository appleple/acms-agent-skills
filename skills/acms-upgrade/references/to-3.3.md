# Ver. 3.3 への移行（移行元: Ver. 3.2.x）: 共通

**Ver. 3.3 はプレリリース（Ver. 3.3.0-alpha.1）の段階で、この内容はそのソースで確かめたもの。正式版で変わることがある。** 公式の移行ガイド（developer.a-blogcms.jp の `document/migration/` 配下）はまだ公開されていない。公開されたらそちらを正とし、このファイルを見直す。プレリリース版を本番のサイトに入れない。

テーマだけに関わる変更は acms-upgrade-theme の `references/to-3.3.md`、プラグイン（拡張アプリ）と `extension/acms/` だけに関わる変更は acms-upgrade-plugin の `references/to-3.3.md` にある。チェック ID の定義は `scripts/checks/to-3.3.tsv`（`T-` はテーマ、`P-` はプラグイン）。`要確認` と付いたチェックは、直す箇所ではなく見比べる箇所を出す。

## 前提（移行元・PHP などの要件）

| 項目 | 内容 | 根拠 |
|---|---|---|
| 移行元 | Ver. 3.2.x の最新。3.1 以前からは、先に `references/to-3.2.md` の変更も直す（SKILL.md の手順 2） | ― |
| PHP | **PHP 8.3 以上 8.6 未満**（3.2 は 8.1 以上）。PHP 8.1・8.2 のサーバーでは 3.3 が動かず、オンラインアップデートの候補にも出ない。先に PHP を上げられるか（3.2 がその PHP で動くか）をサーバーの管理者と決める | `v3.3.0-alpha.1:ablogcms/php/Application.php:102-103`、`v3.2.40:ablogcms/php/Application.php:101` |
| オンラインアップデートの範囲 | 3.2 → 3.3 はマイナーバージョンアップ。管理画面の「オンラインアップデート」を「マイナーバージョンも含める」にしないと候補に出ない | `to-3.2.md` と同じ仕組み |
| DB の更新 | 表と列の追加だけで、削除・改名は無い（REST API・OAuth・フィールド定義・リダイレクト・定期実行・パスキーなどの表、2 段階認証の列）。監査ログの表に列とインデックスが足されるので、行の多いサイトでは時間がかかる。アクセスの少ない時間に更新する | `v3.2.40` と `v3.3.0-alpha.1` の `ablogcms/php/config/schema/db.schema.yaml` の比較 |
| 同梱ライブラリ | symfony 7.4、monolog 3、jQuery 4.0、htmx 4 に上がった。プラグインとテーマの JavaScript への影響は、それぞれのスキルの to-3.3.md | `v3.3.0-alpha.1:ablogcms/composer.json` |
| 予約される URL | `rest-api`・`mcp`・`oauth` が、機能を有効にしていなくても URL のセグメントとして予約される。同じコードのブログ・カテゴリー・エイリアス・エントリーは 404 になり、保存もできなくなる。同名のタグは絞り込みが効かない | `v3.3.0-alpha.1:ablogcms/php/ACMS/function.php`（`resolveSegment`） |
| 配布されているプラグイン（拡張アプリ） | 3.3 対応バージョンが出ているかを確かめる（acms-upgrade-plugin） | ― |

## 下位互換性のない変更

| 変更 | 見つけ方 | 直し方 | 根拠 |
|---|---|---|---|
| 予約セグメント `rest-api`・`mcp`・`oauth` | scan.sh では見つけられない（コードは DB にある）。管理画面でブログ・カテゴリー・エントリーのコードを探す | 衝突するコードを変えるか、利用者に `config.server.php` の `REST_API_SEGMENT`・`MCP_SEGMENT`・`OAUTH_SEGMENT` を変えてもらう（エージェントは開かない） | 同上 |
| 公開側のリンクの形: キーワード検索のリンクが `/keyword/foo/` から `?keyword=foo` に変わる（`query_keyword` の既定が on）。管理画面の一覧の URL は常にクエリの形になる | `T-KEYWORD-PATH`（要確認） | ルール・`.htaccess`・アクセス解析・テンプレートの URL の比較を見直す。前の形に戻すなら利用者に `private/config.system.yaml` へ `query_keyword: off` を足してもらう。古い形の URL も読める | `v3.3.0-alpha.1:ablogcms/private/config.system.default.yaml:350` |
| エントリーのファイル名（コード）の初期値がランダムな名前（`entry-` と英数字）になり、タイトルからの命名（設定 `entry_code_title`）・保存時の自動命名・連番ずらしを廃止 | `T-ENTRY-CODE`・`P-ENTRY-CODE` | `entry-<ID>.html` の形を前提にしたルール・JavaScript・プラグインを直す。接頭辞と拡張子は `entry_code_prefix`・`entry_code_extension` で変えられる | `v3.3.0-alpha.1:ablogcms/php/Services/Entry/Helper.php:2591`（`generateRandomEntryCode`） |
| Ping 送信（更新通知）を削除（3.2 で非推奨） | `T-PING` | 設定と記述を消す | `v3.2.40:ablogcms/themes/system/admin/config/property.html:100` にあり 3.3 に無いこと |
| htmx の読み込み戦略 `dynamic` を廃止（既定は `static`） | scan.sh では見つけられない（`private/config.system.yaml` の `htmx_load_strategy: dynamic`） | 利用者に、その行を消すか `static` にしてもらう | `v3.3.0-alpha.1:ablogcms/private/config.system.default.yaml:370` |

## 非推奨になった機能と代替

非推奨の機能は 3.3 でも動く。デバッグモードで監査ログ（notice）に警告が出る。

| 機能 | 代替 | 見つけ方 | 根拠 |
|---|---|---|---|
| ユニットの `getField1()`〜`getField8()` / `setField1()`〜`setField8()` の外からの呼び出し | ユニットごとの取得口（`Text::getText()` など）と `toArray()` | `P-UNIT-GETFIELD` | `v3.3.0-alpha.1:ablogcms/php/Services/Unit/Contracts/Model.php:475,673` |
| `generateEntryCode()`・`generateEntryCodeFromTitleOrId()` | `generateRandomEntryCode()` | `P-ENTRY-CODE` | `v3.3.0-alpha.1:ablogcms/php/Services/Entry/Helper.php:2523-2591` |
| `setIgnoreBlogScope()` | `ignoringBlogScope()`（3.2.40 にもある） | `P-IGNORE-BLOG-SCOPE` | acms-upgrade-plugin の `to-3.3.md` |

## 直す手順

1. 更新前のサイト（3.2）で `sh scripts/scan.sh <設置ディレクトリ> 3.3` を実行し、結果を保存する。
2. サーバーの PHP を 8.3 以上にできるかを決め、3.2 のまま PHP を上げて動作を確かめる（3.2.40 は PHP 8.5 まで動く）。
3. 本体を更新する前に、テーマとプラグイン（拡張アプリ）で 3.2 のままでも直せるもの（`P-` の多く、jQuery 4 で消える API の置き換え）を直す。`T-` は acms-upgrade-theme、`P-` は acms-upgrade-plugin の手順で直す。
4. 予約セグメントと衝突するコードが無いかを管理画面で確かめる。
5. 本体を更新し、DB を更新する（SKILL.md の手順 7）。
6. 更新後に見比べて直すもの（上書きした管理画面・エントリー編集画面・会員のテンプレート、htmx のイベント）を、acms-upgrade-theme の手順で直す。
7. scan.sh をもう一度実行し、`要確認` 以外の検出が 0 件になったことを確かめる。

## 移行後の確認

- 管理画面のユーザー設定でデバッグモードにして、主要なページ（トップ・一覧・詳細・検索・フォーム・会員ページ）をログイン時とログアウト時の両方で見る。キーワード検索とページ送りのリンクの形を確かめる。
- 監査ログに error・warning と非推奨の notice が出ていないか、ブラウザーのコンソールにエラーが出ていないかを見る（jQuery 4・htmx 4）。
- エントリーを新規作成・保存・公開し、ファイル名とカスタムフィールドの保存を確かめる。
- REST API・MCP・OAuth は既定で無効のまま。使うなら acms-rest-api・acms-mcp。
- `scripts/scan.sh` を再実行して、`要確認` 以外が 0 件。

## 参考

- 公式の移行ガイド（Ver. 3.2.x から 3.3.x）: 未公開（Ver. 3.3.0-alpha.1 の時点）
- アップデート方法: <https://developer.a-blogcms.jp/document/update/>
- 動作条件: <https://developer.a-blogcms.jp/document/requirements.html>
