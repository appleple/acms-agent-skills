# Ver. 3.1 への移行（移行元: Ver. 3.0.x）: テーマ

公式の移行ガイドは <https://developer.a-blogcms.jp/document/migration/301x/>。ガイドにはテーマについて「login.html をカスタマイズしているとログインできなくなる可能性」と「外部サービス連携のモジュールの廃止」しか書かれていないので、このファイルは本体ソースの差分（v3.0.68 と v3.1.80。3.1.x の途中で入ったものは「Ver. 3.1.NN 以降」）から、テーマ（テンプレート・CSS・テーマの JavaScript・`template.yaml`・メールテンプレート・テーマで上書きした管理画面のテンプレート）の修正が要るものを洗い出して整理した。

見つけ方の `T-` で始まる ID は、acms-upgrade の `scripts/scan.sh` のチェック（定義は acms-upgrade の `scripts/checks/to-3.1.tsv`）。acms-upgrade が入っていないときは、「grep:」に挙げた正規表現で `themes/`（`system` を除く）を `grep -rnE` する。`要確認` と付いたチェックは、直す箇所ではなく見比べる箇所を出す。

要件・更新の方法・ライセンス・設定値（`subscriber_access_admin_page`・`signin_page_auth`・`redirect_login_page`・`tpl_*` の既定値・メールの差出人など）・DB・サーバーの設定は acms-upgrade の `references/to-3.1.md` にある。ここではテーマで直すものだけを書く。

## 前提（移行元・PHP などの要件）

| 項目 | 内容 | 根拠 |
|---|---|---|
| 移行元 | Ver. 3.0.x。2.x からは先に 3.0 へ上げる | [移行ガイド 3.0.x → 3.1.x](https://developer.a-blogcms.jp/document/migration/301x/) |
| 更新前にしか取れないもの | 本体を更新すると `themes/system` が 3.1 に置き換わり、3.0 の `login.html`・`_layouts/login.html`・`mail/remind/`・`index.html` などを取れなくなる。3.0 のログイン画面の見た目を参考にするなら、更新前に控えておく | `git diff --diff-filter=D --name-only v3.0.68 v3.1.0 -- ablogcms/themes/system` |
| 直す場所 | テーマ（`themes/<テーマ>/`）だけを直す。`themes/system/` は本体の更新で上書きされるので直さない | [オンラインアップデート](https://developer.a-blogcms.jp/document/update/online-update.html)の「更新されるファイル」 |
| 手本 | 会員の画面は 3.1 で追加された `themes/member` テーマが手本になる（`_member/*.html` 一式、会員限定記事の導線、マイページ）。member テーマは 3.1.x の途中でも直されているので、移行先と同じバージョンのものを使う。管理ログイン画面（`_member-admin/`）は member テーマにもなく、system のものを使う | `git log --diff-filter=A v3.0.28..v3.1.0 -- ablogcms/themes/member` |

## 下位互換性のない変更

変わったものを、テーマの部品ごとに 9 つに分ける。1〜4 がログイン・会員の作り直し、5〜9 がそれ以外。

### 1. 認証系の画面（テンプレート・URL・tpl キー）

3.0 は `/login/` の 1 画面で、`login.html`（中身は `_layouts/login.html` の Login モジュール）を `alt` で切り替えていた。3.1 は画面ごとに URL とテンプレートが分かれ、管理者用（`_member-admin/`、レイアウトは `_layouts/member-admin.html`）と会員用（`_member/`、レイアウトは `_layouts/member.html`）に分かれた。

| 3.0 の画面（URL・Login モジュールのブロック） | 3.1 の URL（既定）とグローバル変数 | 3.1 のテンプレート（tpl キー） | 3.1 の GET モジュール |
|---|---|---|---|
| ログイン `/login/`（`auth`。管理者・読者共通） | 管理者: `/login/`（`%{LOGIN_SEGMENT}`） | `_member-admin/login.html`（`tpl_login`） | `Member_Admin_Login` |
| 同上 | 会員: `/signin/`（`%{SIGNIN_SEGMENT}`） | `_member/signin.html`（`tpl_signin`） | `Member_Signin` |
| 読者登録 `/login/alt/subscribe/`（`subscribe`）と、確認メールのリンク `/login/?type=subscribe` | `/signup/`（`%{SIGNUP_SEGMENT}`）。`subscribe: on` のときだけ表示され、off なら 404 | `_member/signup.html`（`tpl_signup`） | `Member_Signup`（ブロック `step#input`・`step#confirm`・`step#result`・`step#auth`） |
| パスワード再設定 `/login/alt/remind/`（`remind`） | 管理者: `/admin-reset-password/`、会員: `/reset-password/` | `_member-admin/reset-password.html`（`tpl_admin-reset-password`）、`_member/reset-password.html`（`tpl_reset-password`） | `Member_ResetPassword` |
| 再設定のメールのリンク `/login/?type=reset`（`reset`） | `/admin-reset-password-auth/`、`/reset-password-auth/` | `_member-admin/reset-password-auth.html`、`_member/reset-password-auth.html`（`tpl_admin-reset-password-auth`・`tpl_reset-password-auth`） | `Member_Admin_ResetPasswordAuth`・`Member_ResetPasswordAuth` |
| 2 段階認証のリカバリー `/login/alt/recovery/` | `/admin-tfa-recovery/`、`/tfa-recovery/`。`two_factor_auth: off` なら 404 | `_member-admin/tfa-recovery.html`、`_member/tfa-recovery.html`（`tpl_admin-tfa-recovery`・`tpl_tfa-recovery`） | `Member_Tfa_Recovery` |
| ログイン先のブログの選択（`select`。`login_top_anywhere`）、ライセンス切れの表示（`expired`） | 廃止（代わりなし） | — | — |
| 読者が管理画面のユーザー編集でプロフィール・パスワード・2 段階認証を変えていた | マイページ `/mypage/update-profile/`・`update-password/`・`update-email/`・`update-tfa/`・`withdrawal/`（`%{PROFILE_UPDATE_SEGMENT}` など） | `_member/update-profile.html` など（`tpl_update-profile`・`tpl_update-password`・`tpl_update-email`・`tpl_update-fta`・`tpl_withdrawal`）。ログアウト中は 404 | `Member_Update_Profile`・`Member_Update_Password`・`Member_Update_Email`・`Member_Update_Tfa` |

根拠: `v3.0.68:ablogcms/php/ACMS/GET/Login.php:15`、`v3.1.80:ablogcms/php/Services/Login/Helper.php:233-345`（`getAuthSystemTemplate`）、`v3.1.80:ablogcms/php/Services/Login/LoginServiceProvider.php:21-66`、`v3.1.80:ablogcms/private/config.system.default.yaml:233-247`。

| 変更 | 見つけ方 | 直し方 | 根拠 |
|---|---|---|---|
| テーマに 3.0 形式の `login.html`（`@extends("/_layouts/login.html")`）や `_layouts/login.html`（Login モジュール）があると、管理者もログインできなくなる。`_layouts/login.html` が system から消えたので継承元がなくほぼ空白のページになるか、Login モジュールが何も出さずフォームが消える。テーマに `login.html` がなければ、system の `login.html`（`@extends("/_member-admin/login.html")` だけ）が使われるので、公式テーマの `tpl_login: login.html` のままでよい | `T-LOGIN-LAYOUT`（grep: `@extends\(["']?/_layouts/login\.html\|BEGIN_MODULE[[:space:]]+Login([[:space:]]\|-->)`）。テーマに `login.html` と `_layouts/login.html` があるかを `find themes/<テーマ> -name login.html` で見る | 本体を更新する**前に**、テーマの `login.html` と `_layouts/login.html` を消すか名前を変える（更新後にログインできなくなってからでは、FTP などでファイルを直すしかない）。見た目を変えたいなら、3.1 の system の `_member-admin/login.html`・`_layouts/member-admin.html` をテーマに写して直す | [incompatible.html](https://developer.a-blogcms.jp/document/migration/301x/incompatible.html)、`v3.1.80:ablogcms/themes/system/login.html:1`、`v3.1.80:ablogcms/php/ACMS/function.php:4902-4909`（継承元がないとき）、`v3.1.80:ablogcms/php/ACMS/function.php:6013-6015`（存在しないモジュール） |
| `/login/alt/subscribe/` などの `alt` による切り替えがなくなった。3.1 では `alt` は無視され、どれも管理ログイン画面になる | `T-AUTH-LINK`（grep: `LOGIN_SEGMENT\}/alt/\|/login/alt/\|[?&]type=(reset\|subscribe)`） | 会員向けは `%{BLOG_URL}%{SIGNUP_SEGMENT}/`・`%{RESET_PASSWORD_SEGMENT}/`・`%{TFA_RECOVERY_SEGMENT}/`、管理者向けは `%{ADMIN_RESET_PASSWORD_SEGMENT}/`・`%{ADMIN_TFA_RECOVERY_SEGMENT}/` にする | `v3.1.80:ablogcms/php/Services/Login/Helper.php:246-248` |
| `/login/` は管理者用になり、読者（会員）はログインできない（`signin_page_auth` の既定 `subscriber` のとき、`/login/` に入れるのは管理者・編集者・投稿者） | `T-LOGIN-SEGMENT`（要確認。grep: `%\{LOGIN_SEGMENT\}/?([^/a]\|$)`） | 会員向けのログインのリンクを `%{SIGNIN_SEGMENT}` にする。管理者向けのリンクはそのまま | `v3.1.80:ablogcms/php/Services/Login/Helper.php:621-641` |
| 読者は管理画面に入れない（`subscriber_access_admin_page` の既定が空。設定は acms-upgrade） | `T-SUBSCRIBER-ADMIN`（要確認。grep: `admin/user_(edit\|password\|tfa)`）。編集者向けの編集ボタンなら直さなくてよい | 会員向けのリンクをマイページ（`%{PROFILE_UPDATE_SEGMENT}` など）にし、`_member/update-*.html` を用意する | `v3.1.80:ablogcms/php/Services/Login/Helper.php:130-136` |
| シークレットブログ・シークレットカテゴリーを未ログインで開くと、既定（`redirect_login_page: signin`）で会員のサインイン画面（`tpl_signin`）が出る | scan.sh・grep では見つけられない。管理画面 > コンフィグ > ログイン設定 | 会員向けなら `_member/signin.html` をテーマの見た目で用意する。管理者向けにするなら設定を変える（acms-upgrade） | `v3.1.80:ablogcms/php/Services/Login/Helper.php:293-320` |
| 2 段階認証の設定画面の tpl キーは `tpl_update-fta`（`tfa` ではない。本体のつづりのまま） | `template.yaml` に `tpl_update-tfa` と書いていないか | `tpl_update-fta` と書く | `v3.1.80:ablogcms/php/Services/Login/Helper.php:339` |

### 2. 認証系のモジュールとフォーム

| 3.0 | 3.1 管理者用 | 3.1 会員用 |
|---|---|---|
| GET `Login` | `Member_Admin_Login` | `Member_Signin` |
| GET `Admin_User_Sns` | — | `Member_Sns`（ブロック名・変数は同じ） |
| GET `Admin_User_Tfa`（変数 `{step}`） | — | `Member_Update_Tfa`（ブロック `step#registered`・`step#unregistered`） |
| POST `ACMS_POST_Login_Auth` | `ACMS_POST_Member_Admin_Login` | `ACMS_POST_Member_Signin` |
| 同上の 2 段階認証の段（hidden `tfa=on`） | `ACMS_POST_Member_Admin_Tfa_Auth` | `ACMS_POST_Member_Tfa_Auth` |
| POST `ACMS_POST_Login_Remind` | `ACMS_POST_Member_Admin_ResetPassword` | `ACMS_POST_Member_ResetPassword` |
| POST `ACMS_POST_Login_ResetPassword` | `ACMS_POST_Member_Admin_ResetPasswordAuth` | `ACMS_POST_Member_ResetPasswordAuth` |
| POST `ACMS_POST_Login_Tfa_Recovery` | `ACMS_POST_Member_Admin_Tfa_Recovery` | `ACMS_POST_Member_Tfa_Recovery` |
| POST `ACMS_POST_Login_Subscribe` | — | `ACMS_POST_Member_Signup_Confirm` → `ACMS_POST_Member_Signup_Submit`（確認画面つき） |
| POST `ACMS_POST_Login_Tfa_Register`・`ACMS_POST_Login_Tfa_UnRegister` | `ACMS_POST_Member_Tfa_Register`・`ACMS_POST_Member_Tfa_Unregister`（共用） | 同左 |
| （なし） | `ACMS_POST_Member_Admin_LoginWithEmail`（パスワードを使わないメール認証） | `ACMS_POST_Member_SigninWithEmail`、`ACMS_POST_Member_Update_*`・`ACMS_POST_Member_Withdrawal` |
| 残るもの | `ACMS_POST_Login_TerminalRestriction`、`ACMS_POST_Logout` | 同左 |

根拠: `git diff --name-status v3.0.68 v3.1.80 -- ablogcms/php/ACMS/GET ablogcms/php/ACMS/POST`。各モジュールの説明は [ログイン・会員機能](https://developer.a-blogcms.jp/document/auth/) にある（ページ名に「〜 Ver. 3.0」と付いたものは旧モジュール）。

| 変更 | 見つけ方 | 直し方 | 根拠 |
|---|---|---|---|
| 認証系の GET モジュールの削除（`Login` は 1 の `T-LOGIN-LAYOUT`、ほかは `Admin_User_Sns`・`Admin_User_Tfa`・`Ios_Login`・SNS のコールバック）。何も出力されなくなる | `T-AUTH-MODULE`（grep: `BEGIN_MODULE[[:space:]]+(Admin_User_Sns\|Admin_User_Tfa\|Ios_Login\|Api_[A-Za-z]+_OAuth(Login)?Callback\|Api_Twitter_AdminOAuth)([[:space:]]\|-->)`） | 上の表の 3.1 のモジュールへ置き換える。ブロック名が変わったもの（`Member_Update_Tfa`）は 3.1 の system のテンプレートを手本にする | `v3.0.68:ablogcms/php/ACMS/GET/Admin/User/Tfa.php`、`v3.1.80:ablogcms/php/ACMS/GET/Member/Update/Tfa.php` |
| 認証系・外部サービス連携の POST モジュールの削除。送信しても処理されない（エラーも出ない） | `T-AUTH-POST`（grep: `ACMS_POST_Login(_(Auth\|Subscribe\|Remind\|ResetPassword\|Tfa_[A-Za-z]+))?([^A-Za-z0-9_]\|$)\|ACMS_POST_Api_[A-Za-z_]+`） | 上の表の 3.1 の POST に置き換える。フォームは 3.1 の system の `_member/`・`_member-admin/` を写して作り直す方が確実（ボタンの分け方・hidden が変わった） | `v3.1.80:ablogcms/php/main.php:1654-1655` |
| フォームの書き方の変化: hidden の `type`（login・signup）、`persistent`、2 段階認証の `tfa=on` がなくなり、押すボタン（POST の名前）で分けるようになった。送る値は `login[]`（`mail`・`pass`・`redirect`・`code`）のまま。会員登録は `user[]` と hidden `step`、戻るは `ACMS_POST_Form_Chain` | grep: `name="(type\|persistent\|tfa)"` | 3.1 の system の `_member/signin.html`・`signup.html`・`parts/signup/*.html` と見比べる | `v3.0.68:ablogcms/themes/system/_layouts/login.html`、`v3.1.80:ablogcms/themes/system/_member/` |
| 変数の変化: `{login:takeover}` は `{signin:takeover}`、`{tfaRecovery}` は `Member_Tfa_Recovery` の `success`・`notSuccessful` ブロック | `T-AUTH-VARS`（grep: `\{login:takeover\}\|\{tfaRecovery\}`） | 置き換える | `v3.1.80:ablogcms/themes/system/_member/signin.html` |
| `ACMS_POST_Member_Tfa_UnRegister` は Ver. 3.1.54 で `ACMS_POST_Member_Tfa_Unregister`（r が小文字）に変わった。3.1.0〜3.1.53 の書き方を写したテーマは動かない | `T-TFA-UNREGISTER`（grep: `Member_Tfa_UnRegister`） | `Unregister` と書く | `git log v3.1.53..v3.1.54 -- ablogcms/php/ACMS/POST/Member/Tfa` |
| パスワード再設定画面のエラー表示 `mail:validator#exist`・`#confirmed`・`notFound` は Ver. 3.1.75 で system のテンプレートから外れた（アカウントの有無を推測させないため） | grep: `mail:validator#(exist\|confirmed)` | 同じ方針にするなら、テーマの再設定画面からも外す | `git diff v3.1.74 v3.1.75 -- ablogcms/themes/system/_member` |

### 3. SNS ログイン

| 変更 | 見つけ方 | 直し方 | 根拠 |
|---|---|---|---|
| コールバックのテンプレート `callback/signin/{google,facebook,line,twitter}.html` のパスは同じで、中のモジュールが `Api_*_OAuthLoginCallback` から `Member_Sns_Callback_*` に変わった。テーマで上書きしていると SNS ログインが完了しない | `T-AUTH-MODULE`。`ls themes/<テーマ>/callback` | テーマの `callback/signin/*.html` を消して system のものを使う | `git diff v3.0.68 v3.1.80 -- ablogcms/themes/system/callback/signin/` |
| SNS のボタンの POST が、ログイン・登録・連携・解除ごとに分かれた（`ACMS_POST_Api_*_OAuth_Login` の hidden `type` から、`ACMS_POST_Member_Sns_*_Signin`・`_Signup`・`_Register`・`_Unregister`、管理者は `ACMS_POST_Member_Admin_Login_*`） | `T-AUTH-POST` | 3.1 の system の `_member/parts/signin/sns.html`・`parts/signup/sns.html`・`parts/profile/sns.html`・`_member-admin/parts/login/sns.html` を手本に作り直す | `v3.1.80:ablogcms/themes/system/_member/parts/` |
| 結果の表示がクエリ（`?auth=failed` など）から `Member_Sns_Message` のブロックに変わった | grep: `auth=failed\|login=failed\|auth=double` | `_member/parts/sns-message.html` を手本にする | `v3.0.68:ablogcms/php/ACMS/GET/Api/Facebook/OAuthLoginCallback.php:33-37` |
| 管理ログイン画面の SNS ボタンは `Touch_SnsAdminLogin` で囲む。既定の `snslogin_auth: subscriber` では出ない | grep: `Touch_SnsLogin` | 管理者に SNS ログインをさせるなら、ログイン設定の SNS ログインの対象権限を変える | `v3.1.80:ablogcms/php/ACMS/GET/Touch/SnsAdminLogin.php` |

各サービス（Google・LINE・X・Facebook）に登録したコールバック URL は、パスが同じなので原則として変えなくてよい。3.1 の LINE・X は、サイトが SSL のとき https の URL を送るので、http で登録していた場合は https にする（3.0 で実際に http を送っていたかは未確認）。

### 4. メールテンプレート

| 変更 | 見つけ方 | 直し方 | 根拠 |
|---|---|---|---|
| パスワード再設定メールが `mail/remind/` から `mail/reset-password/` に移り、本文の変数は `{resetUrl}` から `{authUrl}` になった。テーマの `mail/remind/` は使われない（差出人などの設定の改名は acms-upgrade） | `T-MAIL-REMIND`（grep: `\{resetUrl\}\|%\{MAIL_REMIND_FROM\}`）。`ls themes/<テーマ>/mail` | `mail/reset-password/{subject.txt,body.txt,body.html}` に移し、`{resetUrl}` を `{authUrl}` にする | `v3.1.80:ablogcms/private/config.system.default.yaml:354-361`、`v3.1.80:ablogcms/php/Services/Login/Traits/CreateAuthUrl.php:160` |
| 会員登録の確認メール `mail/subscribe/` はパス・変数とも同じ（リンク先は変数で入る） | — | 不要 | `v3.1.80:ablogcms/php/ACMS/POST/Member/Signup/Submit.php:199-217` |
| `mail/updateuser/` のリンク先が管理画面のユーザー編集からマイページに変わった | `ls themes/<テーマ>/mail/updateuser` | 上書きしているなら、3.1 の system の同じファイルと見比べる | `git diff v3.0.68 v3.1.80 -- ablogcms/themes/system/mail/updateuser` |
| 新しいメール: `mail/auth-login/`・`mail/auth-signin/`（メール認証のログイン）、`mail/update-email/`（メールアドレスの変更） | — | 文面を変えたいときだけテーマに置く | `v3.1.80:ablogcms/themes/system/mail/` |

### 5. 会員以外の削除されたモジュール

存在しないモジュールは、エラーにならずに何も出力しない。Touch モジュールは囲んだ中身が常に消える。POST は送っても処理されない。

| 変更 | 見つけ方 | 直し方 | 根拠 |
|---|---|---|---|
| 外部サービス連携の廃止（`Api_Twitter_*`・`Api_Bing_*`・`Api_GoogleAnalytics_Ranking`）。GA ランキングはプラグイン（拡張アプリ）へ | `T-REMOVED-MODULE`（grep: `BEGIN_MODULE[[:space:]]+(Api_(Bing\|GoogleAnalytics)_[A-Za-z_]+\|Api_Twitter_(Statuses\|Search\|List\|Users)[A-Za-z_]*)`）。POST は `T-AUTH-POST` | ブロックごと外すか、外部サービスの埋め込みなど別の方法にする | [incompatible.html](https://developer.a-blogcms.jp/document/migration/301x/incompatible.html) |
| 旧ショップ（`Shop`・`Shop_*`。Ver. 3.1.12 以降）、翻訳（`Google_Translate`。Ver. 3.1.12 以降）、iOS（`Ios_*`）・`BackLink`・`Analytics_Mobile`・`Utility_Message`・`Utility_ArchiveZipList`・CRM の Touch（Ver. 3.1.14 以降）、`Touch_Role_ModuleEdit`・`Touch_Role_NotModuleEdit`（Ver. 3.1.37 以降）。cart@blog テーマの `Shop2_*` は残っている | `T-REMOVED-MODULE` | ブロックごと外す。`Touch_Role_ModuleEdit` で囲んだ編集ボタンは、別の Touch モジュール（`Touch_SessionWithCompilation` など）で囲み直す | `git diff --diff-filter=D --name-only v3.0.68 v3.1.80 -- ablogcms/php/ACMS/GET` |
| POST の削除（`ACMS_POST_Shop_*`・`ACMS_POST_Ios_*`・`ACMS_POST_Entry_Apply`・`ACMS_POST_Entry_Confirm`・`ACMS_POST_Cache_Save`・`ACMS_POST_Blog_Index_Config`） | `T-REMOVED-POST`（grep: `ACMS_POST_(Shop_[A-Za-z_]+\|Ios_[A-Za-z_]+\|Entry_(Apply\|Confirm)\|Cache_Save\|Blog_Index_Config)([^A-Za-z0-9_]\|$)`） | フォーム・ボタンごと外す | `git diff --diff-filter=D --name-only v3.0.68 v3.1.80 -- ablogcms/php/ACMS/POST` |

### 6. テンプレートの解決・変数・記法

| 変更 | 見つけ方 | 直し方 | 根拠 |
|---|---|---|---|
| `tpl_top`・`tpl_detail` などの既定が `_top.html`・`_entry.html` になった（設定値の決まり方は acms-upgrade）。`template.yaml` にも DB にも値がなく、テーマに `top.html`・`entry.html` しかないと 404 | `grep -nE '^(tpl_(top\|detail\|entry_edit\|entry_add)\|load_yaml_tpl)' themes/*/template.yaml` と、テーマに `_top.html`・`_entry.html` があるか | `template.yaml` に `tpl_top`・`tpl_detail`・`tpl_entry_edit`・`tpl_entry_add` を書くか、ファイル名をそろえる | `v3.1.80:ablogcms/private/config.system.default.yaml:222-232` |
| `themes/system/index.html`（仮のインデックスページ）を削除。継承のどこにも `index.html` がないテーマは、一覧などが 404 になる | テーマ（親テーマを含む）に `index.html` があるか | テーマに `index.html` を置く | `git log --diff-filter=D v3.0.28..v3.1.0 -- ablogcms/themes/system/index.html` |
| グローバル変数 `%{CONFIG_SET_ID}` と、`Entry_Body` の `{trackbackAmount}`・`{trackbackUrl}` を廃止。空になる | `T-REMOVED-VARS`（grep: `%\{CONFIG_SET_ID\}\|\{trackback(Amount\|Url)\}`） | 記述を消す。`%{CONFIG_SET_NAME}` は残っている | `v3.0.68:ablogcms/php/ACMS/GET/Entry/Body.php:181-198` |
| `@include` の引数で空文字を渡すと、Ver. 3.1.5 から渡していない扱いになり、受け側の `{{ key \| default('...') }}` の既定値が出る | `T-INCLUDE-EMPTY-ARG`（要確認。grep: `@include\([^)]*"[A-Za-z0-9_-]+"[[:space:]]*:[[:space:]]*""`） | 空にしたいなら受け側の `default` を外すか、`BEGIN_IF` で分ける | `git log v3.1.4..v3.1.5 -- ablogcms/php/ACMS/function.php` |
| `acms://` で読み込んだ先が 200 以外のとき、3.0 は応答の本文を差し込み、3.1 は空にする | grep: `acms://` | 表示を確かめる | `git log v3.0.28..v3.1.0 -- ablogcms/php/ACMS/function.php`（8ea3d52f83） |

`@include`・`@extends`・`@section`・校正オプション・検証オプションの記法は変わっていない。

### 7. 組み込み JS・CSS・画像

| 変更 | 見つけ方 | 直し方 | 根拠 |
|---|---|---|---|
| 今いるページへのリンクを自動で外す機能が、既定で無効になった（`viewingEraseMark` が `a:not(.js-viewing-indelible)` から `a.js-viewing-erase` に）。3.0 ではナビの現在地のリンクがテキストになっていたが、3.1 ではリンクのまま | scan.sh・grep では見つけられない（クラスを付けていなくても効いていたため）。ナビ・パンくずを目で見る | 外したいリンクに `js-viewing-erase` を付けるか、テーマの JavaScript で `ACMS.Config({ viewingEraseMark: 'a:not(.js-viewing-indelible)' })` と書いて 3.0 の動きに戻す（どちらも 3.0 のままで書いてよい） | `v3.0.68:ablogcms/js/config.js:1188`、`v3.1.0:ablogcms/js/config.js:1196` |
| 翻訳（`.js-translate`。Ver. 3.1.12 以降）と、管理画面のカスタムフィールドのカラーピッカー（`.js-acms-color-picker`。Ver. 3.1.59 以降）を廃止 | `T-REMOVED-BUILTIN-JS`（grep: `js-translate\|googleTranslateMark\|js-acms-color-picker`） | 翻訳は外す。カラーピッカーは `<input type="color">` にする（3.1 の blog テーマと同じ） | `git log -S js-acms-color-picker v3.1.58..v3.1.59 -- ablogcms/js` |
| `acms-base.min.css`・`acms-fonts.min.css` をビルドの対象から外した（Ver. 3.1.23 以降）。system の画像 `images/banner/a-blogcmsM.gif`・`a-blogcmsS.gif`・`images/loginLogo.gif`・`loginLogo.png`・`images/default/nofile.pdf` を削除（Ver. 3.1.17 以降） | `T-REMOVED-ASSETS`（grep: `acms-(base\|fonts)(\.min)?\.css\|images/(banner/a-blogcms[MS]\.gif\|loginLogo\.(gif\|png)\|default/nofile\.pdf)`） | `acms.min.css` に替えるか、必要なスタイル・画像をテーマに置く | `v3.1.22:ablogcms/themes/system/webpack.common.js` と `v3.1.23` の比較 |
| `acms.css` のボタン・アラート・バッジなどの配色が変わった（3.1.0） | grep: `acms-(btn\|alert\|badge\|label)` | 見た目を確かめ、必要ならテーマの CSS で色を指定する | `git log v3.0.28..v3.1.0 -- ablogcms/themes/system/src/scss`（a6e0f7d5b2） |

### 8. ユニット・エントリーの出力

| 変更 | 見つけ方 | 直し方 | 根拠 |
|---|---|---|---|
| 引用ユニットの HTML で、`site_name:veil` が `description:veil` の中にあり、説明が空だとサイト名も消えていた（Ver. 3.1.17 で system を修正） | `T-QUOTE-VEIL`（要確認。grep: `BEGIN description:veil -->[[:space:]]*<!-- BEGIN site_name:veil`） | 上書きしたユニットのテンプレートを 3.1 の `themes/system/_layouts/unit.html` の `unit#quote` と見比べ、`site_name:veil` を外に出す | `git log v3.1.16..v3.1.17 -- ablogcms/themes/system/_layouts/unit.html`（ecb1aa4bbe） |
| メディアユニットのリサイズに `{resizeWidth}`・`{resizeHeight}` が増えた（Ver. 3.1.21 以降）。古い `[resizeImg({x})]` も動く | grep: `resizeImg\(\{x2?\}\)` | 任意。3.1 に上げた後で、3.1 の system の `unit.html` に合わせる | `git log v3.1.20..v3.1.21 -- ablogcms/themes/system/_layouts/unit.html` |
| ユニットの描画の作り直し（Ver. 3.1.23 以降）。変数名・ブロック名は保たれている | 上書き一覧（scan.sh の最後の節） | 表示を確かめる | `git log v3.1.22..v3.1.23 -- ablogcms/php/Services/Unit` |

### 9. 管理画面のテンプレートを上書きしている場合

`admin/entry/field.html`・`field_foot.html`・`include/unit/extend.html` の読み込まれ方は変わっていない。

| 変更 | 見つけ方 | 直し方 | 根拠 |
|---|---|---|---|
| `@section(reapply-alert)` は Ver. 3.1.65 で使われなくなった。カテゴリー・タグの選択欄は Ver. 3.1.23 で部品（`admin/include/{category,sub-category,tag}/select.html`）になり、`.acms-admin-select2` のスタイルが削除された | `T-ADMIN-OVERRIDE`（要確認。grep: `@section\(["']?reapply-alert\|acms-admin-select2`） | 3.1 の `themes/system/admin` の同じファイルと見比べる | `git log v3.1.64..v3.1.65 -- ablogcms/themes/system/admin`（d603be1f32） |
| `admin/_layouts/admin-unit.html` を上書きしていると、会員限定の区切り（`js-members-only-delimiter`）が出ない | 上書き一覧 | 3.1 の system の同じファイルと見比べる | `v3.1.80:ablogcms/themes/system/admin/_layouts/admin-unit.html` |

## 非推奨になった機能と代替

3.1 で非推奨になったテーマの機能はない（GET モジュールに非推奨の警告はない）。会員限定記事（`Entry_Body` の `membersOnly`・`continueLink`、`include/members-only.html`）は 3.1 の新機能で、使うときだけテーマに足す。

## 直す手順

1. 更新前のサイト（3.0）で acms-upgrade の `sh scripts/scan.sh <設置ディレクトリ> 3.1` を実行し、結果を保存する（acms-upgrade がなければ、上の表の「grep:」で `themes/` を探す）。
2. 本体を更新する前に直す（3.0 のままでよいもの）。
   - `T-LOGIN-LAYOUT`: テーマの `login.html`・`_layouts/login.html` を消すか名前を変える。更新後に管理者がログインできなくなるのを防ぐため、必ず更新の前に行う。
   - `T-REMOVED-MODULE`・`T-REMOVED-POST`・`T-REMOVED-VARS`・`T-REMOVED-ASSETS`・`T-REMOVED-BUILTIN-JS`: 外すか置き換える。
   - 3 章のテーマの `callback/signin/*.html` を消す。
   - 7 章の `viewingEraseMark`: 3.0 の動きを保つなら、`ACMS.Config` を先に書く。
   - 6 章の `tpl_*` と `index.html`: `template.yaml` とファイル名を確かめる。
3. 本体を更新した後に、3.1 のモジュールとテンプレートで作り直すもの。
   - 会員の画面（`_member/*.html`）とレイアウト（`_layouts/member.html`）。3.1 の system か member テーマを写して直す。旧 `_layouts/login.html` の会員向けの部分（`subscribe`・`remind`）の内容を移す。
   - `T-AUTH-MODULE`・`T-AUTH-POST`・`T-AUTH-LINK`・`T-AUTH-VARS`・`T-LOGIN-SEGMENT`・`T-SUBSCRIBER-ADMIN`・`T-TFA-UNREGISTER`。
   - `T-MAIL-REMIND`: `mail/reset-password/` へ移す。
   - `T-INCLUDE-EMPTY-ARG`・`T-QUOTE-VEIL`・`T-ADMIN-OVERRIDE` と上書き一覧: 3.1 の system と見比べる。
4. 更新後にもう一度 scan.sh を実行し、`T-` のうち `要確認` 以外の検出が 0 件になったことを確かめる。

記法の書き方は acms-template-acms、会員サイトの作り方（画面ごとのモジュール、会員限定にする単位、ページキャッシュ）は acms-member-site を使う。

## 移行後の確認

ログアウトした状態と、読者・投稿者・管理者でログインした状態のそれぞれで見る。

- 管理ログイン（`/login/`）、会員のサインイン（`/signin/`）、会員登録（`/signup/`）、パスワード再設定（`/reset-password/`・`/admin-reset-password/`）、2 段階認証、SNS ログインが、テーマの見た目で表示され、最後まで通るか。
- ヘッダーなどのログイン・マイページ・ログアウトのリンクが、会員と管理者で正しい画面に行くか。
- シークレットブログ・シークレットカテゴリーで、意図したログイン画面が出るか。
- ナビ・パンくずの現在地の表示（7 章の `viewingEraseMark`）。
- ボタン・アラートの配色、引用ユニット、メディアユニットの画像。
- ブラウザーの開発者ツールで、CSS・画像・JavaScript に 404 がないか。
- scan.sh を再実行して、`T-` のうち `要確認` 以外が 0 件。

## 参考

- 移行ガイド（Ver. 3.0.x から 3.1.x）: <https://developer.a-blogcms.jp/document/migration/301x/>
- 下位互換性のない変更点: <https://developer.a-blogcms.jp/document/migration/301x/incompatible.html>
- ログイン・会員機能: <https://developer.a-blogcms.jp/document/auth/>
- ログイン・会員機能の基本: <https://developer.a-blogcms.jp/document/auth/Introduction.html>
