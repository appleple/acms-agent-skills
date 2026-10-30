# 会員登録・プロフィールに項目を足す

「会員登録に会社名を足したい」「マイページで住所を変えられるようにしたい」と頼まれたときに読む。入力チェックとコンバーターの書き方は acms-form、管理画面の入力欄と出力の記法は acms-custom-field に従う。

## 基本の項目とカスタムフィールド

| 種類 | 送り方 | 項目 |
|---|---|---|
| ユーザーの基本の項目 | `<input type="hidden" name="user[]" value="項目名">` | `name`（必須）・`mail`（必須）・`pass` と `retype_pass`（メール認証でのサインインが無効なとき必須）・`code`・`url`・`mail_magazine` など |
| ユーザーのカスタムフィールド | `<input type="hidden" name="field[]" value="項目名">` | 上以外のすべて（会社名・電話番号・住所・同意のチェックなど） |

- 基本の項目の検証は本体が決めている（名前とメールアドレスの必須、メールアドレスの重複、パスワードポリシーなど）。テンプレートに書いた `name:validator#required` などはサーバー側では置き換えられ、エラーの表示と JavaScript のバリデーターに使われる。
- カスタムフィールドの検証は、テンプレートの `項目名:v#...`（`:validator#...` と同じ）だけで行われる。確認（`ACMS_POST_Member_Signup_Confirm`）と登録（`_Submit`）の両方で、送られてきた指定で検証する。hidden なので外して送れば検証を外せ、メールフォームのような管理画面の入力チェックは無い。必須にしたい値でも「無いことがある」前提で使う。
- 送った `field[]` の項目は、登録時にそのユーザーのカスタムフィールドとして保存される。同意のチェックボックスなど保存しなくてよい項目も保存される。

## 会社名を足す例

### 1. 会員登録の入力

member テーマを親にしているなら `_member/parts/signup/field-input.html`（空のファイル。入力欄の `<ul class="form-group-list">` の中に読み込まれる）を子テーマに置く。そうでなければ `_member/parts/signup/input.html` を自分のテーマに写して足す。

```html
<li class="form-group">
  <label for="input-text-company">会社名</label>
  <input type="text" name="company" value="{company}" id="input-text-company">
  <input type="hidden" name="field[]" value="company">
  <input type="hidden" name="company:v#required" id="company-v-required">
  <p data-validator-label="company-v-required" class="validator-result-{company:validator#required}">会社名を入力してください</p>
</li>
```

### 2. 会員登録の確認

member テーマを親にしているなら `_member/parts/signup/field-confirm.html`（確認の表の中に読み込まれる）、system テーマの画面を使っているなら `_member/parts/field-confirm.html` に書く。

```html
<tr><th>会社名</th><td>{company}</td></tr>
```

確認から登録へは `takeover` で引き継がれるので、確認画面に hidden を足す必要はない。

### 3. プロフィール変更

会員自身に変えさせるなら、プロフィール変更の画面にも同じ名前で置く（member テーマなら `_member/parts/profile/field.html` を写して足す）。`Member_Update_Profile` の中なら `{company}` に保存済みの値が入る。プロフィール変更は送られた項目だけを置き換えるので、画面に置かなかった項目は消えない。

### 4. 管理画面

管理者が見て直せるように、`admin/user/field.html`（ユーザー編集のカスタム設定）にも同じ名前で入力欄を置く（acms-custom-field）。member テーマを親にしているなら、親の `admin/user/field.html` を写してから足す（子テーマに置くと親のファイルは使われない）。

### 5. メール

会員登録のメール（`mail/subscribe/` の本文、管理者宛を含む）では、カスタムフィールドの値も `{company}` で使える。テキストのメールでは `[raw]` を付けてよいが、HTML のメールでは付けない。

## 決めておくこと

- 項目名はブログ・カテゴリー・エントリーのフィールドと同じ書き方（英数字と `_`）。会員登録・プロフィール変更・管理画面・メールで同じ名前にする。
- 会員に変えさせたくない値（会員種別・管理用のメモなど）は、会員登録とプロフィール変更の画面に置かないだけでは守れない（references/security.md）。
- 一覧や検索で会員を絞り込む予定があるなら、値の形（選択肢の値など）を先に決める。
- 個人情報を足すときは、どこに表示されうるか（User_Field・User_Search、退会後の保存期間）を利用者と確かめる。
