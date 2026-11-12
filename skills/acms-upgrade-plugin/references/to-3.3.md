# Ver. 3.3 への移行（移行元: Ver. 3.2.x）: プラグイン（拡張アプリ）

**Ver. 3.3 はプレリリース（Ver. 3.3.0-alpha.1）の段階で、この内容はそのソースで確かめたもの。正式版で変わることがある。** 公式の移行ガイドはまだ公開されていない。

見つけ方の `P-` で始まる ID は、acms-upgrade の `scripts/scan.sh` のチェック（定義は acms-upgrade の `scripts/checks/to-3.3.tsv`）。acms-upgrade が入っていないときは、「grep:」に挙げた文字列で `extension/` を探す。

PHP の要件（8.3 以上）、DB の更新など、プラグインに限らない前提は acms-upgrade の `references/to-3.3.md` にある。

## 前提（移行元・PHP などの要件）

| 項目 | 内容 | 根拠 |
|---|---|---|
| PHP | 8.3 以上 8.6 未満。プラグインの `composer.json` の `require.php` と、使っている構文・関数を確かめる | `v3.3.0-alpha.1:ablogcms/php/Application.php:102-103` |
| 同梱ライブラリ | symfony 6.4 → 7.4、monolog 2 → 3、doctrine/dbal 4.4。本体同梱のこれらを直接使うプラグインは、各ライブラリのアップグレードガイドで API の変化を確かめる（影響の範囲は未確認） | `v3.3.0-alpha.1:ablogcms/composer.json` |
| 配布しているプラグイン | 3.3 での動作を確かめて、対応バージョンを宣言し直す（acms-plugin-development の references/production-plugin.md） | ― |

## 下位互換性のない変更

| 変更 | 見つけ方 | 直し方 | 根拠 |
|---|---|---|---|
| `ACMS_POST_Entry_Insert`・`Entry_Update`・`Entry_Duplicate`・`Revision_Duplicate`・`Approval_Comment` の protected メソッド（`insertEntry`・`updateEntry`・`saveUnit`・`saveTag` など）を削除。保存の処理はサービスに移った | `P-POST-ENTRY-EXTENDS`（grep: `extends ACMS_POST_Entry_Insert` など）、`P-POST-ENTRY-METHODS`（grep: `saveUnit`・`insertEntry`・`updateEntry`・`saveTag`・`relationDupe`・`getNotifyAddreses`） | POST モジュールを継承して保存処理を差し替えるのをやめる。保存の後の処理は Hook `saveEntry`、保存前の値の加工は Hook（カスタムフィールド定義の値なら `extendsFieldDefinitionValue`）で行う。保存処理そのものを変えるときだけ、サービスコンテナの `entry.save-service`・`entry.duplicator` を `override()` / `extend()` で差し替える（acms-plugin-development の references/plugin-structure.md。差し替えは本体の更新の影響を受けやすいので最後の手段にする）。継承しているだけで削除されたメソッドを呼ばないなら、そのまま動く | `v3.2.40:ablogcms/php/ACMS/POST/Entry/Update.php:413,557,581` にあり 3.3 に無いこと |
| 名前空間の無いグローバルの `RestApi` クラスが、本体のファサードと衝突して致命的なエラーになる | `P-RESTAPI-CLASS`（grep: `class RestApi`） | クラス名を変えるか名前空間を付ける | ― |
| ユニットのモデルに取得口と `toArray()` が足された。同じ名前のメソッドを持つ独自ユニットは致命的なエラーになる | `P-UNIT-GETFIELD`（grep: `getField1` 〜 `getField8`・`setField1` 〜 `setField8`、独自ユニットの `toArray`） | 独自ユニットのメソッド名を変える | `v3.3.0-alpha.1:ablogcms/php/Services/Unit/Contracts/Model.php` |
| 一覧の一括変更で更新できる項目を、標準の項目に絞った | `P-BULK-CHANGE`（grep: `action_entry`） | 独自の項目は Hook `extendsBulkChangeEntryActions` で足す | `v3.3.0-alpha.1:ablogcms/extension/acms/Hook.php` |
| Ping 送信を削除 | `P-PING`（grep: `PingWeblogUpdate`・`ping_weblog`） | 呼び出しを消す | ― |

## 非推奨になった機能と代替

| 機能 | 代替 | 見つけ方 | 根拠 |
|---|---|---|---|
| ユニットの `getField1()`〜`getField8()` / `setField1()`〜`setField8()` の外からの呼び出し（今は転送され、デバッグモードで非推奨のログが出る） | ユニットごとの取得口（`Text::getText()` など）、`toArray()` | `P-UNIT-GETFIELD` | `v3.3.0-alpha.1:ablogcms/php/Services/Unit/Contracts/Model.php:475,673` |
| `generateEntryCode()`・`generateEntryCodeFromTitleOrId()`（動作は残る） | `generateRandomEntryCode()` | `P-ENTRY-CODE`（grep: `generateEntryCode`・`entry_code_title`） | `v3.3.0-alpha.1:ablogcms/php/Services/Entry/Helper.php:2523-2591` |
| `setIgnoreBlogScope()` | `ignoringBlogScope(fn () => ...)`（3.2.40 にもあるので更新前に移せる） | `P-IGNORE-BLOG-SCOPE`（grep: `setIgnoreBlogScope`） | ― |
| `Common::validateLockPost()`・`logLockPost()`・`unlockPost()` | サービス `security.post-rate-limiter` | `P-LOCK-POST`（grep: `validateLockPost`・`logLockPost`・`unlockPost`） | ― |

## 直す手順

1. 更新前に、`P-IGNORE-BLOG-SCOPE` などの 3.2 でも使える代替へ移す。
2. `P-POST-ENTRY-*` が出たら、継承をやめて Hook かサービスの上書きで書き直す（3.2 のうちに書き直せる）。
3. 本体を更新し、デバッグモードで監査ログに非推奨の notice と error が出ないかを見る。
4. 配布しているプラグインは、3.3 で動作を確かめて対応バージョンを更新する。

## 移行後の確認

- プラグインの管理ページで、有効化・設定の保存・アップデートができるか。
- Hook を使う処理（エントリーの保存・公開・メディアの登録など）を一通り動かし、監査ログに error が出ないか。
- 独自ユニットの表示と保存。
- 3.3 の新しい拡張点（REST API のルート・MCP のツール・フィールド定義・定期実行）を使うなら、acms-plugin-development の references/ver-3.3.md。

## 参考

- 公式の移行ガイド（Ver. 3.2.x から 3.3.x）: 未公開（Ver. 3.3.0-alpha.1 の時点）
- Symfony のアップグレード: <https://symfony.com/doc/current/setup/upgrade_major.html>
- Monolog 3 の変更: <https://github.com/Seldaek/monolog/blob/main/UPGRADE.md>
