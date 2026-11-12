# Ver. 3.3 への移行（移行元: Ver. 3.2.x）: テーマ

**Ver. 3.3 はプレリリース（Ver. 3.3.0-alpha.1）の段階で、この内容はそのソースで確かめたもの。正式版で変わることがある。** 公式の移行ガイドはまだ公開されていない。

見つけ方の `T-` で始まる ID は、acms-upgrade の `scripts/scan.sh` のチェック（定義は acms-upgrade の `scripts/checks/to-3.3.tsv`）。acms-upgrade が入っていないときは、「grep:」に挙げた文字列で `themes/`（`system` を除く）を探す。`要確認` と付いたチェックは、直す箇所ではなく見比べる箇所を出す。

PHP の要件（8.3 以上）、DB の更新、予約される URL など、テーマに限らない前提は acms-upgrade の `references/to-3.3.md` にある。

## 前提（移行元・PHP などの要件）

| 項目 | 内容 | 根拠 |
|---|---|---|
| 移行元 | Ver. 3.2.x の最新 | ― |
| 直す場所 | テーマ（`themes/<テーマ>/`）だけを直す。`themes/system/` は本体の更新で上書きされるので直さない | ― |
| 見比べる相手 | 上書きしたテンプレートは、3.3 の `themes/system` の同じパスのファイルと見比べる。更新前に 3.2 の `themes/system` を取っておくと差分を取りやすい | ― |

## 下位互換性のない変更

| 変更 | 見つけ方 | 直し方 | 根拠 |
|---|---|---|---|
| jQuery 3.7 から 4.0 になった（jQuery Migrate 4、jQuery UI 1.13.3）。jQuery 3.0 で消えた API は Migrate 4 では補われない | `T-JQUERY4`（grep: `.size()`・`$.isFunction`・`jQuery.expr.filters`・`.bind(`・`.unbind(`・`jquery-3.`・`jquery-migrate-3`・`ui_1.13.2`） | `.size()` は `.length`、`.bind()` / `.unbind()` は `.on()` / `.off()`、`$.isFunction(x)` は `typeof x === 'function'` にする。jQuery の読み込みのパスは版番号を直書きせず、`%{JS_LIB_JQUERY_DIR_VERSION}` を使う | `v3.2.40:ablogcms/themes/system/include/jsbanner.html:64`（`.size()`）が 3.3 で直っていること |
| htmx 2 から 4 になった。イベント名・拡張の API・設定が変わった | `T-HTMX4`（grep: `htmx:afterSwap`・`htmx:configRequest`・`htmx:beforeRequest`・`defineExtension`・`historyCacheSize`・`allowEval`） | 既存サイトは互換の拡張 `htmx-2-compat` が既定で読み込まれ、旧イベントも発火する。新しく書くものはスワップ後の再初期化を `htmx:after:settle` で行う。互換の拡張を外す（`htmx_extensions: []`）前に、旧イベントを使う箇所を移す。htmx 4 の書き方は htmx 公式の移行ガイドで確かめる | `v3.3.0-alpha.1:ablogcms/private/config.system.default.yaml:372`、`private/config.system.yaml:12`（新規インストールは `[]`） |
| `ACMS.Config.htmxMark`・`htmxConfig` を削除 | `T-HTMX-CONFIG`（grep: `htmxMark`・`htmxConfig`） | htmx の設定はシステム設定 `htmx_config`、またはテンプレートの `<meta name="htmx-config">` に書く | ― |
| 管理画面の jQuery のドロップダウン（`js-acms-dropdown-toggle` など）を削除 | `T-ADMIN-DROPDOWN`（grep: `js-acms-dropdown-toggle`・`js-acms-dropdown-btn`） | 上書きした管理画面のテンプレートを `<acms-dropdown-menu>` に書き換えるか、上書きをやめる | `v3.2.40:ablogcms/themes/system/admin/topicpath.html` にあり 3.3 に無いこと |
| 管理画面のテンプレートの部品（`admin/entry/js.html`・`module-id-header`・`schedule/parts/header`）を削除 | `T-ADMIN-REMOVED-PARTS`（grep: `admin/entry/js.html`・`module-id-header`・`schedule/parts/header`） | インクルードを外し、上書きしたテンプレートを 3.3 の system と見比べる | ― |
| エントリーの編集画面を作り直した（上のバーがフォームの中に入り、2 カラムになった。カスタムフィールド定義の入力欄が出る） | scan.sh の上書き一覧（`admin/entry/edit.html`・`admin/_layouts/entry/edit.html`）、`T-ENTRY-FIELD-SECTION`（要確認。grep: `@section("entry-field")`） | 上書きをやめるのが確実。上書きしたままだと、カスタムフィールド定義の入力欄が出ないのに公開時に必須が効いて保存できなくなる。`field.html`・`field_foot.html` はそのまま使える。サイドバー用に `field_side.html`・`field_side_foot.html` が増えた。再読み込みなしで保存したとき、`field.html` の中の script は再実行されない | ― |
| 会員のサインインに、メールの 2 段階認証とパスキーのブロック（`tfaEmail`・`tfaPasskey` など）が増えた | scan.sh の上書き一覧（`_member/signin.html`・`_member/update-tfa.html`） | 上書きしているなら 3.3 の system と見比べてブロックを取り込む（無いと、メールの 2 段階認証を使うユーザーに何も出ない）。`verify.html`・`update-passkey.html` も追加されている（acms-member-site） | ― |
| キーワード検索のリンクの形が変わる | `T-KEYWORD-PATH`（要確認。grep: `/keyword/`） | テンプレート・JavaScript で URL の `/keyword/` を前提にした比較や組み立てを見直す（acms-upgrade の `to-3.3.md`） | ― |
| Ping 送信を削除 | `T-PING`（grep: `ping_weblog`・`PingWeblogUpdate`・`weblog-updates-ping`） | 記述を消す | ― |
| エントリーのファイル名の初期値がランダムな名前になった | `T-ENTRY-CODE`（grep: `entry_code_title`、`entry-` と数字の `.html`） | ファイル名の形を前提にしたルール・JavaScript を直す | ― |
| 一覧の一括変更で更新できる項目を、標準の項目（ステータス・カテゴリー・タグ・日時など）に絞った | `T-BULK-CHANGE`（grep: `name="action_entry[`） | 独自の項目を送る画面を作っているなら、プラグイン（拡張アプリ）の Hook `extendsBulkChangeEntryActions` で項目を許可する（acms-upgrade-plugin）。許可しない項目は無視され、監査ログに警告が残る | `v3.3.0-alpha.1:ablogcms/extension/acms/Hook.php` |

## 非推奨になった機能と代替

テーマに関わる新しい非推奨は無い（Ver. 3.3.0-alpha.1 の時点）。3.2 で非推奨になったもの（`to-3.2.md`）は引き続き非推奨。

## 直す手順

1. 本体を更新する前に、3.2 の `themes/system` を取っておく（上書きしたテンプレートの差分を取るため）。
2. `T-JQUERY4` の項目を直す（3.2 の jQuery 3.7 でも動く書き方なので、更新前に直せる）。
3. 本体を更新したら、`要確認` の項目（編集画面・会員・キーワードのリンク）を 3.3 の `themes/system` と見比べて直す。
4. htmx を使っているページで、画面の部分更新・戻る・進むを確かめる。
5. scan.sh を再実行する。

## 移行後の確認

- ブラウザーのコンソールにエラーが出ていないか（jQuery 4・htmx 4）。
- htmx を使うページ（部分更新・無限スクロール・絞り込み）の動作。
- エントリーの編集画面で、カスタムフィールドの入力・保存・公開ができるか。
- 会員のサインイン・2 段階認証（使っていれば）。
- キーワード検索・ページ送りのリンク。

## 参考

- 公式の移行ガイド（Ver. 3.2.x から 3.3.x）: 未公開（Ver. 3.3.0-alpha.1 の時点）
- htmx の移行ガイド（htmx 2 から 4）: <https://htmx.org/>
- jQuery 4.0 のアップグレードガイド: <https://jquery.com/upgrade-guide/4.0/>
