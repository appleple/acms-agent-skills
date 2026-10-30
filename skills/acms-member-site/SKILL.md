---
name: acms-member-site
description: >-
  a-blog cms（acms）で会員制サイト（member site / membership）を作るときの構成と手順の判断基準。
  会員登録（signup）・サインイン（login / signin）・サインアウト・パスワードの再設定・マイページ（プロフィール・メールアドレス・パスワードの変更）・退会、
  会員の権限（読者・投稿者）、会員限定にする単位（ブログ・カテゴリーのシークレット、会員限定記事のエントリーの一部）と、
  一覧・検索・フィード・OGP などからの漏れ、認証系ページのテンプレート（_member/、template.yaml の tpl_signin など）と member テーマ、
  Member_* モジュールと ACMS_POST_Member_*、Touch_Login と組み込み JS（js-login-show）、ページキャッシュとログイン状態、
  会員情報の項目の追加、管理画面のログイン設定・メール設定を扱う。
  「会員制サイトを作りたい」「会員だけが見られるページを作って」「ログインフォームを作って」「会員登録の項目を足したい」
  「ログインしたら名前を出したい」「ログアウトしても会員限定ページが見える」と頼まれたときに使う。
  a-blog cms member site, login, signin, signup, membership, members only, auth, secret category.
  テーマの作り方は acms-theme-development、記法は acms-template-acms / acms-template-twig、
  フォームの検証の書き方は acms-form、ユーザーのカスタムフィールドの入力欄と出力は acms-custom-field が担う。
license: MIT
compatibility: a-blog cms Ver. 3.2 以上（会員機能は Ver. 3.1 で現在の形になった）。全エディションで使える。
metadata:
  acms-min-version: "3.2"
  status: stable
---

# a-blog cms の会員制サイト

公式ドキュメント:
- ログイン・会員機能の基本（認証系ページの URL・テンプレート・権限の分け方）: <https://developer.a-blogcms.jp/document/auth/Introduction.html>
- 会員サインイン: <https://developer.a-blogcms.jp/document/auth/signin.html>、会員登録: <https://developer.a-blogcms.jp/document/auth/signup.html>、メール認証によるサインイン: <https://developer.a-blogcms.jp/document/auth/signin-with-email.html>
- member テーマの使い方: <https://developer.a-blogcms.jp/document/themes/member.html>

`/document/auth/` の配下には Ver. 3.0 以前のページ（Login モジュール・Login_Auth・Login_Subscribe・Login_Remind など。ページ名に「~ Ver. 3.0」）も残っている。Ver. 3.1 で廃止されたので、それらを手本にしない。

## 書く前に

- 版とテーマの種類（標準テンプレート / Twig）、テーマの継承を確かめる（acms-project-triage）。
- 会員の画面の URL（`signin`・`signup`・`mypage/update-profile` など）はサイトごとに変えられる。テンプレートには `%{SIGNIN_SEGMENT}` `%{SIGNUP_SEGMENT}` `%{RESET_PASSWORD_SEGMENT}` `%{PROFILE_UPDATE_SEGMENT}` `%{WITHDRAWAL_SEGMENT}` などのグローバル変数で書き、パスを直書きしない。設定ファイル（config.server.php）は読まない。
- 管理画面の設定（会員登録の受け付け・登録時の権限・メールの送信元など）はエージェントが変えず、references/admin-settings.md の表を使って利用者に依頼する。

## 仕組みの要点

- 「会員」は既定では**読者**権限のユーザー。読者は一般サインイン画面（`/signin/`）からだけ、管理者・編集者・投稿者は管理ログイン画面（`/login/`）からだけログインできる。ログイン設定の「一般サインイン権限」を投稿者にすると、投稿者も一般サインイン側に移る。
- 会員の画面は URL で決まる専用のページで、本体が template.yaml の `tpl_*` キー（既定は `_member/*.html`）のテンプレートを表示する。テーマに無ければ親テーマ → system テーマの同名ファイルが使われる。
- 画面の中身は GET の `Member_*` モジュール（`Member_Signin`・`Member_Signup`・`Member_Update_Profile` など）と、送信先の POST モジュール（`ACMS_POST_Member_Signin` など）で作る。**`Member_*` には V2 版が無い**ので、Twig のテーマでも会員の画面は標準テンプレートの `BEGIN_MODULE` で書く（混在の注意は acms-template-twig）。
- サインイン・会員登録・パスワード再設定の画面は、ログイン中に開くとブログのトップへ戻される。マイページ系（プロフィール・メールアドレス・パスワード・2段階認証の変更、退会）はログインしていないと 404 になり、会員の所属ブログでしか開けない。

## 構成の判断

| 決めること | 選び方 |
|---|---|
| 登録させる権限 | 閲覧だけの会員は**読者**（既定）。会員にもエントリーを書かせるときだけ投稿者にし、「一般サインイン権限」も投稿者に合わせる。投稿者以上は管理画面に入れるうえ、エントリーを持つと退会できない |
| 登録の受け付け | 「ユーザー登録の外部申請」を有効にしないと `/signup/` は 404。メールアドレスの確認（既定は確認する）、承認制にするなら登録時のステータスを「無効」 |
| ブログ全体を会員限定 | ブログのステータスを**シークレット**。未ログインはサインイン画面へ送られる |
| カテゴリー単位で会員限定 | カテゴリーのステータスを**シークレット**。子カテゴリーにも同じステータスを付ける（後述） |
| エントリーの続きだけ会員限定 | エントリーの「会員限定記事にする」を付け、「続きを読む」のバーを会員限定にしたいユニットの直前に置く。バーより後のユニットはログイン後に JavaScript で読み込まれる |
| ログイン状態で表示を変える | 本文などの内容を隠すのは上の3つで行う。ボタンや案内の出し分けだけを Touch モジュールまたは組み込み JS（`js-login-show` など）で行う |

単位ごとの細かい挙動、漏れる経路、出し分けの方法の選び方は references/members-only.md を読む。

## 会員限定の内容が漏れる経路（必ず確認する）

- **会員限定記事に「続きを読む」のバーが無い**と、本文のユニットはすべて誰にでも表示される（会員限定の印が付くだけ）。
- 会員限定記事でも、タイトル・エントリーのカスタムフィールド・メイン画像は誰にでも表示される。会員限定にしたい内容はバーより後のユニットに置く。
- エントリー一覧（Entry_Summary など）の本文の抜粋と、OGP の description（エントリーのフィールドが空のとき）は、**バーより後のユニットも含めた本文**の先頭から作られる。公開部分が短いと会員限定の文が出る。キーワード検索の対象にも入る。Unit_List はバーより後のユニットも並べる。
- シークレットのカテゴリー・ブログのエントリーは、未ログインの一覧・検索・フィード・サイトマップから除かれる。ただしモジュールの設定で「シークレットエントリー」を有効にすると、未ログインでも一覧に出る。
- `js-login-show` などの組み込み JS は**表示を切り替えるだけ**で、中の HTML は誰にでも配られる。会員限定の内容を入れない。

## テンプレート

| 画面 | テンプレート（tpl キー） | 置くもの |
|---|---|---|
| サインイン | `_member/signin.html`（`tpl_signin`） | `Member_Signin`、`ACMS_POST_Member_Signin` |
| 会員登録 | `_member/signup.html`（`tpl_signup`） | `Member_Signup`、`ACMS_POST_Member_Signup_Confirm` → `_Submit` |
| パスワード再設定 | `_member/reset-password.html` / `reset-password-auth.html` | `Member_ResetPassword` / `Member_ResetPasswordAuth` |
| プロフィール変更 | `_member/update-profile.html`（`tpl_update-profile`） | `Member_Update_Profile`、`ACMS_POST_Member_Update_Profile` |
| メールアドレス・パスワード変更 | `_member/update-email.html` / `update-password.html` | `Member_Update_Email` / `Member_Update_Password` |
| 退会 | `_member/withdrawal.html`（`tpl_withdrawal`） | `ACMS_POST_Member_Withdrawal` |
| 会員限定記事の続き | 詳細ページの `Entry_Body` の中 | `continueLink` ブロックと `js-members-only-entry` の要素 |
| サインアウト | ヘッダーなど | `ACMS_POST_Logout` のボタン |

全画面の一覧（2段階認証を含む）、template.yaml のキー（2段階認証の設定は `tpl_update-fta` と綴る）、ブロック、ログイン後の移動先、マイページの作り方は references/templates.md を読む。

### member テーマを親にするか

- 会員の画面をひととおり作り込んだ公式テーマ。会員制サイトを新しく作るなら、`member` を親にした子テーマ（`mysite@member`）で始め、変えたいファイルだけを子テーマに置く。登録項目は `_member/parts/signup/field-input.html` と `field-confirm.html`、プロフィールの項目は `_member/parts/profile/field.html` を置き換えれば足せる。
- 既存のサイトに会員機能を足すときは、親を変えずに member テーマの `_member/` と `include/parts/members-only.html` を参考に、必要な画面だけを自分のテーマへ写す。写さなかった画面は system テーマの既定のテンプレートで表示される。
- テーマの継承・割り当ての手順は acms-theme-development。

## 必ず守ること

- **ログイン中のページはページキャッシュされない。ただし「読者ユーザーの場合」のキャッシュを有効にすると、読者向けのページは全読者で同じキャッシュを共有する。** その設定では会員ごとの値（名前など）をサーバー側でページに出さず、member テーマのように Ajax（`nocache`）や組み込み JS で後から出す。Ver. 3.2.37 以前はこの設定で読者向けのキャッシュが未ログインにも返るので、会員制サイトでは無効のままにする。詳しくは references/security.md。
- 会員が入力した値（名前・プロフィールなど）は `[raw]` / `|raw` を付けずに出す。`%{SESSION_USER_NAME}` などのグローバル変数はエスケープされて出る。
- **会員が POST できるユーザーのカスタムフィールドに、権限や会員種別（有料会員かどうかなど）を置かない。** 会員登録・プロフィール変更は送られてきた `field[]` の項目をすべて保存するので、会員が任意の項目名で書き換えられる。
- 会員の個人情報をユーザーのカスタムフィールドに置くなら、公開側のページに User_Field・User_Search を置かない（URL の uid を変えれば他人の値を出せる。User_Search の既定の対象は読者）。自分の情報は `Member_Update_Profile` で出す。
- パスワード再設定・会員登録の確認メールのテンプレートでは、`{authUrl}` / `{subscribeUrl}` を消さない。送信元（From）は利用者に自サイトのドメインのアドレスへ変えてもらう（既定値は `info@example.com`）。

## 会員情報の項目を足す

- 名前・メールアドレス・パスワードなどの基本の項目は `user[]`、それ以外（会社名など）はユーザーのカスタムフィールドとして `field[]` で送る。
- 足す場所は 4 つ: 登録画面（入力と確認）、プロフィール変更画面、管理画面のユーザー編集（`admin/user/field.html`）、必要ならメールのテンプレート。
- `field[]` の入力チェックはテンプレートの `:v#`（`:validator#`）だけで行われ、管理画面で強制する設定は無い。
- 手順と例は references/signup-fields.md。入力チェックの書き方は acms-form、管理画面の入力欄と出力の記法は acms-custom-field。

## エディション

会員機能（登録・サインイン・マイページ・退会・SNS ログイン・会員限定記事）はスタンダード版でも使える。会員がプロフィールを変えたときの通知メール（メール設定の「ユーザ情報変更」）だけはプロフェッショナル版以上で送られる。

## 詳しくはここを読む

| 作業 | 読むもの |
|---|---|
| 会員限定の単位の選び方、漏れる経路、ログイン状態での出し分け | references/members-only.md |
| 画面ごとのテンプレート・モジュール・ブロック、マイページ、ログイン後の移動先 | references/templates.md |
| 利用者に依頼する管理画面の設定 | references/admin-settings.md |
| ページキャッシュ、エスケープ、メール、ログイン試行の制限、退会 | references/security.md |
| 会員登録・プロフィールに項目を足す | references/signup-fields.md |

## よくある誤り

- 会員限定記事にしたのに「続きを読む」のバーを置かず、本文が全部見えている。
- 会員限定記事の詳細テンプレートに `continueLink` ブロックが無く、ログインしても続きが出ない。
- `js-login-show` の中に会員限定の内容を書いて、ソースを見れば読める。
- 「読者ユーザーの場合」のページキャッシュを有効にしたまま `%{SESSION_USER_NAME}` を出し、別の会員の名前が出る。
- 親カテゴリーだけをシークレットにして、子カテゴリーのエントリーが未ログインでも見える。
- `/signin/` `/mypage/` などのパスをテンプレートに直書きし、URL を変えたサイトでリンクが切れる。
- Ver. 3.0 以前の Login モジュール・`ACMS_POST_Login_Subscribe` の記事を手本にする。
- 会員登録の画面だけ作って、管理画面のユーザー編集（`admin/user/field.html`）に同じ項目を置かず、管理者が値を見られない。
