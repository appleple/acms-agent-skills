# Ver. 3.1 への移行（移行元: Ver. 3.0.x）: 共通

公式の移行ガイドは <https://developer.a-blogcms.jp/document/migration/301x/>。ガイドに書かれているのは「login.html をカスタマイズしているとログインできなくなる可能性」と「外部サービス連携の廃止」の 2 点だけなので、このファイルと acms-upgrade-theme・acms-upgrade-plugin の `references/to-3.1.md` は、本体ソースの差分（3.0 系の最新 v3.0.68 と 3.1 系の最新 v3.1.80。3.1.x の途中で入ったものは「Ver. 3.1.NN 以降」）から、移行で直す・確かめるものを洗い出して整理した。

次の項目は、配布パッケージで 3.0.68 のサイトを作り、3.1.80 へ手動アップデートして実機（PHP 8.1・MySQL 8.0）でも確かめた: テーマの 3.0 形式の `login.html` で管理者がログインできなくなること、メールを確認していない会員が `/signin/` からログインできること、読者が管理画面で 403 になること、更新前に送ったパスワード再設定のリンクが使えないこと、`mail_remind_from` が読まれず差出人が既定に戻ること、`signin` カテゴリーのトップがサインイン画面になること、https のアクセスで `SSL_ENABLE` が 0 だと Facebook・LINE に http のコールバック URL を送ること（3.0.68 では https）、`SSL_ENABLE` を 1 にすると https になること、DB の設定が `private/config.system.yaml` より優先されること、Hook の `beforePostFire` は会員系の POST でも呼ばれ、`afterPostFire` はリダイレクトで終わる POST（ログインの成功など）では呼ばれないこと。

このファイルには、テーマにもプラグイン（拡張アプリ）にも当てはまるもの（要件・更新の方法・ライセンス・DB・設定値・サーバーの設定）を書く。テンプレート・CSS・テーマの JavaScript・メールテンプレートは acms-upgrade-theme、`extension/` の PHP は acms-upgrade-plugin の `references/to-3.1.md` にある。1 つの変更は 3 ファイルのどれか 1 か所にだけ書き、ほかからは名前で参照する。チェック ID の定義は `scripts/checks/to-3.1.tsv`（`T-` はテーマ、`P-` はプラグイン）。`要確認` と付いたチェックは、直す箇所ではなく見比べる箇所を出す。

## 前提（移行元・PHP などの要件）

| 項目 | 内容 | 根拠 |
|---|---|---|
| 移行元 | Ver. 3.0.x。2.x からは先に 3.0 へ上げる（[Ver. 2.11.x から 3.0.x](https://developer.a-blogcms.jp/document/migration/300x/)） | [移行ガイド 3.0.x → 3.1.x](https://developer.a-blogcms.jp/document/migration/301x/) |
| PHP | 3.1.80 は PHP 7.3.0 以上 8.4.0 未満（最低 7.3 は Ver. 3.1.7 以降、8.2・8.3 対応は Ver. 3.1.14 以降）。3.0.68 は 7.2.5 以上 8.2.0 未満。両方で動くのは 7.3〜8.1 なので、PHP 7.2 のサイトは本体の更新の前に PHP を上げる。8.2 以上へは 3.1 に上げた後で上げる | `v3.0.68:ablogcms/php/Application.php:92-93`、`v3.1.80:ablogcms/php/Application.php:99-100`、[動作条件](https://developer.a-blogcms.jp/document/requirements.html) |
| MySQL | 3.0 と同じ範囲（変更なし） | [動作条件](https://developer.a-blogcms.jp/document/requirements.html) |
| オンラインアップデートでは 3.1 に上げられない | 3.0 の更新処理は、配信情報（update.json）を新しい順に見て、条件に合う最初のバージョン 1 つだけを候補にする。2026-11-06 時点の配信情報は 3.2.39 → 3.1.80 → 3.0.68 の順なので、「マイナーバージョンも含める」にすると、PHP 8.1 なら 3.1 を飛ばして 3.2 が候補になり、PHP 8.1 未満なら何も出ない（3.1.80 には下りない）。3.1 で止めるなら、簡単アップデート（`update.php`）か手動アップデートで 3.1.80 のパッケージを使う。オンラインアップデートで 3.2 へ直接上げるなら、この to-3.1 と to-3.2 の両方の変更を直してから更新する | `v3.0.68:ablogcms/php/Services/Update/System/CheckForUpdate.php:272-300,354-375,474-488`（`checkAcmsVersion` が最初の 1 件を返す）、<https://www.a-blogcms.jp/api/update.json> |
| ライセンス | 3.1 は `SYSTEM_MAJOR_VERSION` が 301。プラン契約でなく、ライセンスの対応バージョンが 301 未満のライセンスは「旧ライセンス」と判定され、トライアル・開発モードの扱いになる。更新の前に、ライセンスが 3.1 に対応しているかを利用者に確かめてもらう（エージェントは `license.php` を開かない） | `v3.1.80:ablogcms/php/Application.php:101`、`v3.1.80:ablogcms/php/ACMS/function.php:7978-7987`（`isOldLicense`）、`v3.1.80:ablogcms/php/main.php:1374-1385` |
| DB の更新 | テーブル・列の追加だけで、削除・型の変更・データの変換はない（下の「データベース」）。DB の更新は、本体のファイルを置いた後にメンテナンス画面か管理画面 > 更新で行う | `v3.1.80:ablogcms/php/Services/Update/Engine.php:142-155`、`v3.1.80:ablogcms/php/Services/Update/Database/Rule.php:39-77` |
| 配布されているプラグイン（拡張アプリ） | 3.1 対応バージョンが出ているかを配布元で先に確かめる。確かめ方は acms-upgrade-plugin | — |

## 下位互換性のない変更

更新すると挙動が変わるものを、設定値・管理画面・データベース・サーバーの設定・機能の廃止の 5 つに分ける。テンプレート側の直し方は acms-upgrade-theme、PHP 側は acms-upgrade-plugin の `references/to-3.1.md` にある。

### 設定値の決まり方（既定値の変更が効くかどうか）

既定値が変わっても、既存のサイトで新しい値が効くとは限らない。値は「`config.system.default.yaml` ← `private/config.system.yaml` ← DB（ブログ・コンフィグセット・テーマセット・編集画面セット・カテゴリー・ルール・モジュール）」の順に重なり、後のものが勝つ。`tpl_*` だけは、テーマの継承をたどった `template.yaml` の値が DB より優先される（`load_yaml_tpl: on` のとき）。DB に行があるのは、管理画面でそのキーを含むページを一度保存したものだけ。

| キーの種類 | 既存のサイトで効く値 | 確かめ方 |
|---|---|---|
| 管理画面に入力欄があり、そのページを保存したことがある | DB の古い値のまま（新しい既定値は効かない） | 管理画面 > コンフィグ > エクスポートの YAML にキーがあるか |
| 管理画面に入力欄がない | `private/config.system.yaml` に書いていなければ新しい既定値 | 利用者に `private/config.system.yaml` にキーがあるかを見てもらう（エージェントは開かない） |
| 3.1 で増えたキー | 既定値。ページを保存すると、そのとき画面に出ていた値が DB に入る | 管理画面の該当ページ |
| `tpl_*` | テーマ（親テーマを含む）の `template.yaml` の値、なければ DB、なければ既定値 | テーマの `template.yaml`（エージェントが読める）とエクスポートの YAML |

根拠: `v3.1.80:ablogcms/php/Services/Config/Helper.php:102-166,206-222`、`v3.1.80:ablogcms/php/main.php:301-303,779-786`、`v3.1.80:ablogcms/php/ACMS/function.php:2454-2474`（`tplConfig`）、`v3.1.80:ablogcms/php/Services/Config/Export.php:62-82`。

### 設定値（既定値の変更・新しいキー・削除・改名）

既存のサイトの挙動が変わりうるものだけを挙げる。新機能の既定値（`withdrawal_*`・`category_select_limit` など）は省く。

| 変更 | 影響 | 確かめ方 | 直し方 | 根拠 |
|---|---|---|---|---|
| `subscriber_access_admin_page` の既定が `[top, user_edit, user_password, user_tfa]` から `[]` になった | 入力欄がないキーなので、ほぼすべての既存サイトで効く。読者（会員）は管理画面に入れなくなる（プロフィール・パスワード・2 段階認証の変更もできない） | 利用者に `private/config.system.yaml` にこのキーがあるかを見てもらう。テーマの導線は `T-SUBSCRIBER-ADMIN` | 会員の変更画面はマイページ（`/mypage/update-profile/` など）へ移す（テンプレートは acms-upgrade-theme） | `v3.0.68:ablogcms/private/config.system.default.yaml:19`、`v3.1.80:同:32`、`v3.1.80:ablogcms/php/Services/Login/Helper.php:130-136` |
| ログインの入口が管理者用（`/login/`）と会員用（`/signin/`）に分かれ、`signin_page_auth`（既定 `subscriber`）で入れる権限が決まる | `/login/` には管理者・編集者・投稿者しか入れない（読者は入れない）。`/signin/` には既定で読者しか入れない | 管理画面 > コンフィグ > ログイン設定 | 会員の導線を `/signin/` に変える（acms-upgrade-theme）。投稿者も `/signin/` から入れたいなら `signin_page_auth: contributor` | `v3.1.80:ablogcms/private/config.system.default.yaml:66`、`v3.1.80:ablogcms/php/Services/Login/Helper.php:621-641` |
| `redirect_login_page`（既定 `signin`）を追加 | シークレットブログ・シークレットカテゴリーを未ログインで開くと、3.0 は管理ログイン画面（`tpl_login`）、3.1 は会員のサインイン画面（`tpl_signin`）を出す。既定では読者しか入れないので、投稿者以上がシークレットブログの画面からログインしていた運用は入れなくなる。3.1 ではシークレットカテゴリーも対象になった | 管理画面 > コンフィグ > ログイン設定 | 管理者向けなら `redirect_login_page: login`。会員向けならテーマに会員のサインイン画面を用意する | `v3.0.68:ablogcms/php/main.php:1438-1441`、`v3.1.80:ablogcms/php/Services/Login/Helper.php:293-320` |
| 会員のサインインの IP 制限が `signin_white_hosts` / `signin_black_hosts` に分かれた | 3.0 の `login_white_hosts` などは会員を含むすべてのログインにかかっていた。3.1 では管理ログインだけにかかり、会員のサインインは既定で制限なし | 管理画面 > コンフィグ > アクセス設定 | 会員にも制限をかけていたなら signin 側にも設定し、`.htaccess` で制限しているなら `/signin/` なども対象にする | `v3.1.80:ablogcms/php/Services/Login/Helper.php:183,193` |
| `tpl_top`・`tpl_detail`・`tpl_entry_edit`・`tpl_entry_add` の既定が `top.html`・`entry.html` から `_top.html`・`_entry.html` に、`tpl_login` が `_member-admin/login.html` になった | `template.yaml` にも DB にも値がないテーマで、テーマに `top.html`・`entry.html` しかないと、トップ・詳細が 404 になる。3.0・3.1 の公式テーマは `template.yaml` に書いているので影響しない。`tpl_login` は acms-upgrade-theme | テーマの `template.yaml`、エクスポートの YAML の `tpl_*` | `template.yaml` にキーを書くか、ファイル名を `_top.html`・`_entry.html` にそろえる（acms-upgrade-theme） | `v3.0.68:ablogcms/private/config.system.default.yaml:188-198`、`v3.1.80:同:222-233` |
| `mail_remind_*` が `mail_reset_password_*` に改名（パスワード再設定メール） | DB の値は引き継がれない。差出人などが既定（`info@example.com`）に戻る。テンプレートは acms-upgrade-theme | 管理画面 > コンフィグ > メール設定 | パスワード再設定メールと、新しく増えたメール（メールアドレスの変更、メール認証のログイン・サインイン）の差出人などを設定し直す | `v3.0.68:ablogcms/private/config.system.default.yaml:289-296`、`v3.1.80:同:354-361`、`v3.1.80:ablogcms/php/ACMS/POST/Member/ResetPassword.php:36-76` |
| `permission_dir` / `permission_file`（0777 / 0666）を削除し、`config.server.php` の `CHMOD_DIR` / `CHMOD_FILE`（0775 / 0664 から umask を引いた値）を使う（Ver. 3.1.17 以降） | 新しく作るファイルとディレクトリが全員書き込み可でなくなる。PHP が作ったファイルは、PHP の実行ユーザーと同じグループに入っていない FTP のユーザーからは書き換え・削除できなくなる（3.0 の 0666 / 0777 では誰でも書き換えられた）。`private/config.system.yaml` の `permission_*` は無視される | 利用者に、`config.server.php` の `CHMOD_*` と `private/config.system.yaml` の `permission_*` を見てもらう | 必要なら `config.server.php` の `CHMOD_*` を調整してもらう | `v3.0.68:ablogcms/php/main.php:116-117`、`v3.1.80:ablogcms/php/Services/Storage/StorageServiceProvider.php:24-29` |
| `image_jpeg_quality` の既定が 85 から 75 に（Ver. 3.1.21 以降） | 編集設定を保存していないサイトでは、新しくアップロードした JPEG の画質が下がる | エクスポートの YAML | 85 のままにしたいなら管理画面 > コンフィグ > 編集設定で設定する | `v3.0.68:ablogcms/private/config.system.default.yaml:897`、`v3.1.80:同:973` |
| `allow_template_extension`（Ver. 3.1.12 以降）、`forbid_direct_access_file`（Ver. 3.1.62 以降）を追加 | 一覧にない拡張子のテンプレートと、`package.json`・ドットファイル・`*.config.*` などは URL から表示されなくなる | テーマに、URL で開かせている `.html`・`.htm`・`.csv`・`.xml`・`.json`・`.css`・`.yaml`・`.txt`・`.js` 以外のファイルがあるか | 必要なら利用者に `private/config.system.yaml` へ足してもらう | `v3.1.80:ablogcms/private/config.system.default.yaml:12,128`、`v3.1.80:ablogcms/php/main.php:1944-1949` |
| `entry_lock_enable: on`（エントリーの排他ロック）を追加 | 他のユーザーが編集中のエントリーに警告・ロックが出る | — | 運用に合わなければ管理画面 > コンフィグ > 機能設定で変える | `v3.1.80:ablogcms/private/config.system.default.yaml:131-133` |
| `log_access`（アクセスログ）・`login_top_anywhere`・`google_analytics_mobile_*`・`yahoo_search_api_key`・`action_direct_*`・`shop_receipt_*`・`shop_customer_*` を削除 | 値を設定していても使われない。`login_top_anywhere`（ログイン後のブログ選択）は代わりがない | — | 外す（`private/config.system.yaml` に書いているなら利用者に消してもらう） | `v3.0.68:ablogcms/private/config.system.default.yaml:72-73,129,219-223,983-986,1918-1928` |
| `ajax_security_level`（既定 1）を追加（Ver. 3.1.17 以降） | `forbid_tpl_url_context: on` でも、条件を満たす Ajax のリクエストなら `/tpl/` を読める（緩和）。条件と確かめ方は acms-theme-development の `references/template-resolution.md` | — | 不要。新規インストールと同じにするなら `ajax_security_level: 2` を `private/config.system.yaml` に足してもらう | `v3.1.80:ablogcms/php/main.php:1719-1740`、`v3.1.80:ablogcms/private/config.system.yaml` |

### 管理画面の設定ページ

| 変更 | 影響 | 直し方 | 根拠 |
|---|---|---|---|
| SNS ログインの認証情報（`google_login_client_id`・`facebook_app_id`・`line_app_id`・`twitter_sns_login_consumer_key` など）が「プロパティ」から「ログイン設定」へ移った | キー名は同じなので値はそのまま使われる | 不要。設定の場所が変わったと伝える | `git grep 'name="config\[\]" value=' v3.0.68 / v3.1.80 -- ablogcms/themes/system/admin/config` の比較 |
| コンフィグセットが「コンフィグセット（基本）」「テーマセット」「編集画面セット」の 3 つに分かれ、3.0 の「テーマ設定」「編集設定」「ユニット設定」「一括変更」は「レガシー設定」にまとめられた | 既存のコンフィグセットは「基本」として変換なしで使われる。テーマセット・編集画面セットを割り当てると、レガシー設定の値は使われない | 新しいセットに移すかは任意。移すときはブログ・カテゴリーへの割り当ても見直す | `v3.1.80:ablogcms/themes/system/admin/config/index.html:74-100`、`v3.1.80:ablogcms/php/ACMS/GET/Admin/Config/Set/Index.php:11,64` |
| 外部サービス連携の設定（`twitter_consumer_key`・`google_api_client_id_key_location`・`google_translate_api_key`・`bing_search_api_key` などと、Twitter のアクセストークン）の入力欄を削除 | 値は DB とエクスポートの YAML に残り続け、同じページを保存しても消えない | 各サービス側でキーとトークンを無効化する。DB の行を消すのは任意（消すならバックアップの後） | `v3.0.68:ablogcms/themes/system/admin/config/property.html`、`v3.0.68:ablogcms/php/ACMS/Services/Twitter.php:18-31` |

### データベース

| 変更 | 影響 | 直し方 | 根拠 |
|---|---|---|---|
| テーブル・列の追加（`audit_log`・`cache_data`・`cache_tag`・`token`、user の `user_mode`・`user_withdrawal_datetime`、blog・category のテーマセット・編集画面セット、entry の `entry_members_only`・ロックの列など）。3.1.x の途中でも足される | DB の更新で足される | 管理画面 > 更新で、データベースが「一致」になったことを確かめる | `ablogcms/php/config/schema/db.schema.yaml` の v3.0.68 と v3.1.80 の比較 |
| 定義から外れたもの（`log_access` テーブル、`shop_receipt*` テーブル、user の `user_confirmation_token`・`user_reset_password_token` 列）は DROP されずに残る | 3.1 はこれらを読まない。アクセスログは監査ログに置き換わり、旧データは管理画面で見られない | 消すかは任意（消すならバックアップの後）。DB の更新の最後の画面に、使われなくなった列（`user_confirmation_token`・`user_reset_password_token` など）が一覧で出て、選ぶと削除できる。メールを確認していない会員を調べる前（下の ★）には選ばない | `v3.1.80:ablogcms/php/Services/Update/Database/Schema.php:319-343`。3.0.68 → 3.1.80 の更新を実機で確認 |
| パスワード再設定・会員登録の確認のトークンが、user テーブルの列（`user_reset_password_token`・`user_confirmation_token`）から `token` テーブルに移った（データの移し替えはない） | 更新前に送ったパスワード再設定・会員登録の確認メールのリンク（`/login/?type=reset&...`・`/login/?type=subscribe&...`）は使えない。3.1 の `/login/` は管理ログイン画面で `type` を読まず、トークンも `token` テーブルでしか照合しないため | 更新の作業時間を案内し、パスワード再設定は更新後にやり直してもらう | `v3.0.68:ablogcms/php/ACMS/POST/Login/Remind.php:92-105`、`v3.1.80:ablogcms/php/Services/Login/Traits/ValidateAuthUrl.php`（`validateToken`）、`git grep user_reset_password_token v3.1.80 -- ablogcms/php` が 0 件 |
| ★ 3.0 で会員登録してメールを確認していない会員（状態は `open` のまま、`user_confirmation_token` が空でない）が、3.1 ではメールを確認しないままログインできる。3.0 のログインはトークンが空のユーザーだけを通していたが、3.1 はこの列を見ず、未確認を状態 `pseudo` で表す。DB の更新はこの変換をしない。同じメールアドレスでの登録し直しも「すでに存在するメールアドレス」で断られる | 更新の**前に**、利用者（DB の管理者）に `SELECT user_id, user_mail FROM <テーブルの接頭辞>user WHERE user_confirmation_token <> ''` で該当する会員を調べてもらう | 該当する会員は、更新の前に削除するか、管理画面のユーザー編集で「有効」のチェックを外す（状態が close になり、3.1 でもログインできない）。3.0 の確認リンクは更新後には使えないので、登録し直しを案内する | `v3.0.68:ablogcms/php/ACMS/POST/Login/Auth.php:200-214`（`user_confirmation_token = ''` の条件）、`v3.1.80:ablogcms/php/ACMS/POST/Member/Signin.php:198-213`（条件なし）、`v3.1.80:ablogcms/php/ACMS/POST/Member/Signup/Confirm.php:130-145`（`doubleMail`） |

### サーバーの設定（`.htaccess`・`config.server.php`・URL）

| 変更 | 影響 | 直し方 | 根拠 |
|---|---|---|---|
| ルートの `htaccess.txt` の変更（エンコードされたパスの扱い `has_encoded_query`、末尾スラッシュの付与と `index.html` の除去のリダイレクト先が `%{REQUEST_SCHEME}`） | 更新で `.htaccess` は置き換わらないので、取り込まないと入らない。必須ではない | 利用者に 3.1.80 の `htaccess.txt` と見比べて取り込んでもらう。`%{REQUEST_SCHEME}` は Apache が受けた接続のスキームなので、TLS を終端するプロキシ（ロードバランサー・CDN）の後ろのサーバーでは http になり、https のサイトでも http へリダイレクトされる。その構成ではこの規則を取り込まないか、リダイレクト先を https に固定する | `v3.1.80:ablogcms/htaccess.txt:233-235,265,301-311` |
| `config.server.php` に定数が足される（`CHMOD_DIR`・`CHMOD_FILE`・`PROXY_IP`・`PROXY_PORT`・会員系の URL の `*_SEGMENT`） | DB の更新のときに、ない定数が既定値で足される（既存の値は保たれる） | 不要 | `v3.1.80:ablogcms/php/Services/Update/System/ConfigServer.php:15-48` |
| 会員系の URL（`signin`・`reset-password`・`reset-password-auth`・`tfa-recovery`・`admin-reset-password`・`admin-reset-password-auth`・`admin-tfa-recovery`）が予約語に加わった（`login`・`signup` は 3.0 から予約語） | 同じコードのブログ・カテゴリーは保存時にエラーになる。3.0 で作った同じコードのものは、URL の解析でパスの末尾のセグメントが認証系の画面として先に取られるので、そのブログ・カテゴリーのトップ（例: コードが `signin` のカテゴリーの `/signin/`）が認証系の画面（会員のサインインなど）になる。その下のエントリー（`/signin/entry.html`）は今までどおり表示される（3.0.68 → 3.1.80 の更新を実機で確認） | 管理画面でブログ・カテゴリーのコードを確かめ、ぶつかるならコードを変えるか、`config.server.php` の `*_SEGMENT` を変えてもらう | `v3.0.68:ablogcms/php/ACMS/function.php:2315-2343`（3.0 の予約語）、`v3.1.80:ablogcms/php/ACMS/function.php:2608-2621`（3.1 の予約語）、`v3.1.80:ablogcms/php/ACMS/function.php:6960-7034` の `parseAcmsPath` の `aryBool`（`'@(?:^\|/)' . $Seg[$key] . '/?$@'` で末尾を先に取り除く）、`v3.1.80:ablogcms/php/Services/Login/LoginServiceProvider.php:21-66` |
| Facebook・LINE・X の SNS ログインのコールバック URL のスキームが、アクセス中のスキームから `config.server.php` の `SSL_ENABLE`（既定 0）で決まるようになった（Google はアクセス中のスキームのまま）。3.0 の LINE・X に書かれていた `'_protocol' => 'http'` は `acmsLink` が読まないキーで、効いていなかった | https で配信していて `SSL_ENABLE` が 0 のサイトでは、3.1 で Facebook・LINE・X に `http://…/callback/signin/*.html` を送り、各サービスに登録した https の URL と一致せずにログインできない | https のサイトなら、利用者に `config.server.php` の `SSL_ENABLE` が 1 かを確かめてもらう（エージェントは開かない）。パスは同じなので、各サービスに登録した URL は変えなくてよい | `v3.0.68:ablogcms/php/Services/SocialLogin/Line.php:158`、`v3.0.68:ablogcms/php/ACMS/function.php` の `acmsLink`（`protocol` だけを読む）、`v3.1.80:ablogcms/php/Services/SocialLogin/Facebook.php:126-129`・`Line.php:153-157`・`Twitter.php:72-76`・`Google.php:109` |

### 機能の廃止

テーマとプラグインの両方に修正が出るもの。

| 変更 | 見つけ方 | 直し方 | 根拠 |
|---|---|---|---|
| ログイン・会員の仕組みの作り直し（Login モジュール・`ACMS_POST_Login_*` を削除し、`Member_*` に置き換え） | テーマ: `T-LOGIN-LAYOUT`・`T-AUTH-MODULE`・`T-AUTH-POST`・`T-AUTH-LINK`・`T-AUTH-VARS`・`T-LOGIN-SEGMENT`・`T-SUBSCRIBER-ADMIN`・`T-MAIL-REMIND`・`T-TFA-UNREGISTER`。プラグイン: `P-REMOVED-AUTH-CLASS` | テーマは acms-upgrade-theme、プラグインは acms-upgrade-plugin。設定は上の「設定値」 | [incompatible.html](https://developer.a-blogcms.jp/document/migration/301x/incompatible.html)、[ログイン・会員機能の基本](https://developer.a-blogcms.jp/document/auth/Introduction.html) |
| 外部サービス連携（Twitter・Bing・Google Analytics ランキングの API）の廃止。SNS ログイン・SNS 会員登録と Google Maps は残る | テーマ: `T-REMOVED-MODULE`・`T-AUTH-POST`。プラグイン: `P-REMOVED-AUTH-CLASS` | モジュール・フォーム・クラスの利用ごと外す。GA ランキングはプラグイン（拡張アプリ）へ移す | [incompatible.html](https://developer.a-blogcms.jp/document/migration/301x/incompatible.html) |
| 旧ショップ機能（`Shop_*`。Ver. 3.1.12 以降）、iOS アプリ連携・CRM・翻訳（Ver. 3.1.12〜3.1.14 以降）などの廃止。cart@blog テーマの `Shop2_*` は残る | テーマ: `T-REMOVED-MODULE`・`T-REMOVED-POST`・`T-REMOVED-BUILTIN-JS`。プラグイン: `P-REMOVED-CLASS` | 外す | `git diff --diff-filter=D --name-only v3.0.68 v3.1.80 -- ablogcms/php/ACMS` |

## 非推奨になった機能と代替

3.1 で非推奨の警告を出すようになった GET モジュールはない。管理画面の「テーマ設定」「編集設定」「ユニット設定」「一括変更」は「レガシー設定」になり、テーマセット・編集画面セットを割り当てると使われない（上の「管理画面の設定ページ」）。移行の作業に含める必要はない。

## 直す手順

1. 更新前のサイト（3.0）で `sh scripts/scan.sh <設置ディレクトリ> 3.1` を実行し、結果を保存する。3.2 まで上げるなら `3.2` でも実行する。
2. 要件を確かめる。PHP が 7.3〜8.1 か（7.2 なら先に上げる）、ライセンスが 3.1 に対応しているか、配布プラグインの 3.1 対応版があるか。
3. 利用者に、管理画面 > コンフィグ > エクスポートの YAML と、`private/config.system.yaml` の該当キーの有無（`subscriber_access_admin_page`・`permission_*`・`tpl_*`）を確かめてもらい、上の「設定値」のどれが効くかを決める。会員登録を使っているサイトでは、メールを確認していない会員を調べて削除か無効にする（上の「データベース」の ★）。SNS ログインを使っている https のサイトでは、`SSL_ENABLE` を確かめてもらう（上の「サーバーの設定」）。
4. 本体を更新する前に、テーマとプラグインで 3.0 のままでも直せるもの（削除されたモジュール・クラスの利用を外す、3.0 形式の `login.html` を退避する）を直す。`T-` は acms-upgrade-theme、`P-` は acms-upgrade-plugin の手順で直す。
5. 簡単アップデートか手動アップデートで 3.1 系の最新のパッケージを置き、DB を更新する（SKILL.md の手順 7）。オンラインアップデートでは 3.1 が候補に出ない（「前提」）。
6. 更新後に、会員の画面（`_member/`）を作り、設定（ログイン設定・メール設定・アクセス設定）を見直す。
7. scan.sh をもう一度実行し、`要確認` 以外の検出が 0 件になったことを確かめる。

## 移行後の確認

本体側の確認。テーマの表示は acms-upgrade-theme、プラグインの動作は acms-upgrade-plugin の「移行後の確認」を続けて見る。

- ログアウトした状態で、管理者が `/login/` から、会員が `/signin/` からログインできるか。2 段階認証を使っているユーザーでも試す。
- パスワード再設定（管理者は `/admin-reset-password/`、会員は `/reset-password/`）のメールが届き、差出人が正しいか。
- 会員登録（`subscribe: on` のとき `/signup/`）の確認メールが届き、登録が完了するか。
- 読者でログインして、マイページ（`/mypage/update-profile/` など）でプロフィールとパスワードを変えられるか。
- 3.0 でメールを確認していなかった会員が、ログインできないか（更新前に削除か無効にしたか）。
- SNS ログイン（Facebook・LINE・X）で、各サービスの画面から戻ってこられるか。
- シークレットブログ・シークレットカテゴリーを未ログインで開いたとき、意図したログイン画面が出るか。
- 管理画面 > 更新で、データベースが「一致」になっているか。監査ログに error・warning が出ていないか。
- 新しくアップロードした画像の画質と、作られたファイルの書き込み権限。
- `scripts/scan.sh` を再実行して、`要確認` 以外が 0 件。

## 参考

- 移行ガイド（Ver. 3.0.x から 3.1.x）: <https://developer.a-blogcms.jp/document/migration/301x/>
- 下位互換性のない変更点: <https://developer.a-blogcms.jp/document/migration/301x/incompatible.html>
- ログイン・会員機能の基本: <https://developer.a-blogcms.jp/document/auth/Introduction.html>
- アップデート方法: <https://developer.a-blogcms.jp/document/update/>
- 動作条件: <https://developer.a-blogcms.jp/document/requirements.html>
