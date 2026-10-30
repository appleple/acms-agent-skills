# 会員の画面のテンプレート

会員の画面を作る・直すとき、テンプレートの置き場所や template.yaml のキーを確かめるとき、マイページやヘッダーのログイン表示を作るときに読む。記法は acms-template-acms（標準テンプレート）/ acms-template-twig（Twig）に従う。

## 画面の一覧

既定の URL はブログの URL の後ろに付く。サイトで変えられるので、テンプレートでは右のグローバル変数を使う。

| 画面 | 既定の URL / グローバル変数 | template.yaml のキー → 既定のテンプレート | GET モジュール | POST モジュール |
|---|---|---|---|---|
| サインイン | `signin/` `%{SIGNIN_SEGMENT}` | `tpl_signin` → `_member/signin.html` | `Member_Signin` | `ACMS_POST_Member_Signin`（メール認証でのサインインが有効なら `ACMS_POST_Member_SigninWithEmail` と `ACMS_POST_Member_SigninWithVerifyCode`）、2段階認証は `ACMS_POST_Member_Tfa_Auth` |
| 会員登録 | `signup/` `%{SIGNUP_SEGMENT}` | `tpl_signup` → `_member/signup.html` | `Member_Signup` | `ACMS_POST_Member_Signup_Confirm`（確認へ）→ `ACMS_POST_Member_Signup_Submit`（登録）。修正は `ACMS_POST_Form_Chain` |
| パスワード再設定（メールを送る） | `reset-password/` `%{RESET_PASSWORD_SEGMENT}` | `tpl_reset-password` → `_member/reset-password.html` | `Member_ResetPassword` | `ACMS_POST_Member_ResetPassword` |
| パスワード再設定（メールのリンク先） | `reset-password-auth/` | `tpl_reset-password-auth` → `_member/reset-password-auth.html` | `Member_ResetPasswordAuth` | `ACMS_POST_Member_ResetPasswordAuth` |
| 2段階認証の解除（リカバリーコード） | `tfa-recovery/` `%{TFA_RECOVERY_SEGMENT}` | `tpl_tfa-recovery` → `_member/tfa-recovery.html` | `Member_Tfa_Recovery` | `ACMS_POST_Member_Tfa_Recovery` |
| プロフィール変更 | `mypage/update-profile/` `%{PROFILE_UPDATE_SEGMENT}` | `tpl_update-profile` → `_member/update-profile.html` | `Member_Update_Profile` | `ACMS_POST_Member_Update_Profile` |
| メールアドレス変更 | `mypage/update-email/` `%{EMAIL_UPDATE_SEGMENT}` | `tpl_update-email` → `_member/update-email.html` | `Member_Update_Email` | `ACMS_POST_Member_Update_Email` |
| パスワード変更 | `mypage/update-password/` `%{PASSWORD_UPDATE_SEGMENT}` | `tpl_update-password` → `_member/update-password.html` | `Member_Update_Password` | `ACMS_POST_Member_Update_Password` |
| 2段階認証の設定 | `mypage/update-tfa/` `%{TFA_UPDATE_SEGMENT}` | **`tpl_update-fta`** → `_member/update-tfa.html` | `Member_Update_Tfa` | `ACMS_POST_Member_Tfa_Register` / `_Unregister` |
| 退会 | `mypage/withdrawal/` `%{WITHDRAWAL_SEGMENT}` | `tpl_withdrawal` → `_member/withdrawal.html` | （公式テーマは `Member_Update_Profile` を使う） | `ACMS_POST_Member_Withdrawal` |

- 2段階認証の設定画面のキーは `tpl_update-fta`（tfa ではない）。本体がこの名前で読むので、template.yaml にもこの綴りで書く。
- 既定のファイル名のまま置くなら、template.yaml に書かなくてよい。別の名前にしたいときだけ書く。template.yaml は子テーマ → 親テーマの順に読まれ、管理画面のテーマ設定の「テンプレート選択ファイル（template.yaml）の値を優先する」が有効なとき（既定は有効）に使われる。
- 会員の画面は、`_member/` に無ければ親テーマ、最後に system テーマの同名ファイルが使われる。部品（`_member/parts/...`）も同じ。member テーマを親にした子テーマでは、変えたい部品だけを置けばよい。
- 認証系の画面（サインイン・会員登録・再設定・2段階認証の解除）とマイページ系の画面はページキャッシュされない。
- 管理者向けの画面（`_member-admin/`、`/login/` など）は会員制サイトでは作り替えない。

## 各画面で書くもの

### サインイン（`_member/signin.html`）

- `Member_Signin` の中に、`signin`（入力）・`verifyCode`（メール認証の確認コード）・`tfa`（2段階認証のコード）の3ブロックを書く。使わない認証方法のブロックも残しておくと、管理画面で切り替えたときにそのまま動く。
- 送る項目は `login[]` で登録する（`mail`・`pass`・`redirect`）。`mail` はメールアドレスかユーザーコード。
- エラーは本体が必ず付けるので、テンプレートに検証の指定が無くても `{pass:validator#auth}`（ID・パスワード違い）、`{mail:validator#lock}`（試行回数の超過。`{trialNumber}` `{lockTime}` で回数と分を出せる）、`{mail:validator#restriction}`（ログインを禁止した端末）などで表示できる。一覧は公式の会員サインインのページ。
- `{email_auth_signin}` が `on` かどうかで、パスワードの入力欄とメール認証のボタンを出し分ける（member テーマの書き方）。
- SNS ログインのボタンは `Touch_SnsLogin` と `Member_Sns` の中に置く（member テーマの `_member/parts/signin/sns.html`）。

### 会員登録（`_member/signup.html`）

- `Member_Signup` の中に `step#input`（入力）・`step#confirm`（確認）・`step#result`（仮登録の完了）・`step#auth`（メールのリンクから来たとき）を書く。ステップの考え方はメールフォームと同じ（acms-form）。
- `step#auth` の中には `enableAccount`（登録完了）・`applicationCompleted`（登録時のステータスが「無効」で承認待ち）・`badRequest`・`expired`・`notFound` を書く。
- 項目の足し方は references/signup-fields.md。

### パスワード再設定

- `reset-password.html` は `sendMsg#before`（送信前）・`sendMsg#after`（送信後）で文言を分ける。
- 本体は、入力されたメールアドレスが登録されていなくても「送信しました」と同じ応答を返す（登録の有無を外から調べられないようにするため）。テンプレートに「登録されていません」のような表示を足さない。
- `reset-password-auth.html` は `emailAuthSuccess`（新しいパスワードの入力）・`success`（変更完了）・`badRequest`・`expired`・`form`・`notSuccessful` を書く。

### マイページ

- 本体が用意するのはプロフィール・メールアドレス・パスワード・2段階認証の変更と退会の画面だけで、「マイページのトップ」は無い。member テーマは `mypage` というシークレットのカテゴリーを作り、そこにエントリーを1件置いてトップにしている（`mypage/_entry.html`）。
- マイページ系の画面（プロフィール変更など）は、未ログインだと本体が 404 にする。マイページのトップを置くカテゴリーはシークレットにして、未ログインをサインイン画面へ送る。
- ログイン中の会員の情報は次で出す。

| 出したいもの | 方法 |
|---|---|
| 名前・ユーザーコード・メールアドレス | `%{SESSION_USER_NAME}` `%{SESSION_USER_CODE}` `%{SESSION_USER_MAIL}`（Twig のグローバル変数に `SESSION_USER_MAIL` は無い） |
| 会員自身のカスタムフィールド・アイコン | `Member_Update_Profile` の中で `{項目名}`。ログインしていないと 404 にするモジュールなので、ログインが必要なページ（シークレットのカテゴリーなど）にだけ置く |
| 権限 | `%{SESSION_USER_AUTH}` |

- 「読者ユーザーの場合」のページキャッシュを有効にしたサイトでは、上の値をページに直接書かない。member テーマのヘッダーのように、`ACMS_POST_2GET_Ajax` で `tpl`（表示する部品のテンプレート）と `nocache=yes`（`query[]` にも `nocache`）を送り、名前だけの部品を後から読み込む（references/security.md）。

### 退会

- `ACMS_POST_Member_Withdrawal` を送るフォームを置く。退会理由などの `field[]` はユーザーのカスタムフィールドに保存される（削除のしかたが「論理削除」のとき管理画面で見られる）。
- 次のときは退会できず、`{withdrawal:validator#auth}`（管理ログイン側の権限）・`{withdrawal:validator#entryExists}`（エントリーを持っている）・`{withdrawal:validator#operable}`（ログインしていない）でエラーになる。投稿者を会員にするサイトでは表示を用意する。
- 退会するとセッションを消してブログのトップへ移る。

### サインアウト

- `<button type="submit" name="ACMS_POST_Logout">` を持つフォームを置く。移動先はログイン設定の「ログアウト後ページの指定」（トップページ / ログイン（サインイン）ページ）。

## ログイン後の移動先

本体は次の順で決める。

1. シークレットのページから送られてきた、または `ACMS_POST_Member_SigninRedirect` を通ったときは、元のページ。
2. サインインのフォームの `redirect`（`login[]` に登録する）。パスで書く（`/mypage/` など）。`http(s)://` で始まる値や別のドメインは無視される。
3. ログイン設定の「現在のURLでログイン」が有効なら、サインイン画面のパスを除いた URL（通常はブログのトップ）。
4. それ以外はブログのトップ（管理ログインの場合は「ログイン後ページの指定」）。

「ログインしたらマイページへ」は、サインインのフォームに `redirect` を置くのが簡単。

## Twig のテーマ

- `Member_*` に V2 バージョンは無い。Twig が有効なテーマでも、会員の画面は標準テンプレートの `<!-- BEGIN_MODULE Member_Signin -->` などで書く。Twig の中に書いた `BEGIN_MODULE` は、Twig の処理の後に標準テンプレートとして処理される（acms-template-twig）。
- 会員限定記事の印と続きの有無は、V2 のエントリーのデータ（`isMembersOnly`、`V2_Entry_Body` の `hasSecretUnits`）で分岐できる。続きを差し込む要素の作り方は references/members-only.md。
