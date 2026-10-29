---
name: acms-form
description: >-
  a-blog cms（acms）のメールフォーム（お問い合わせフォーム）を作る・直す・レビューするときの仕組みと判断基準。
  フォーム ID と入力 → 確認 → 送信のステップ、POST モジュール（ACMS_POST_Form_Confirm / Submit / Chain）、field[] による値の登録、
  バリデーター（:v#、validator）とコンバーター（:c、converter、mb_convert_kana）、JavaScript のバリデーターとエラー表示（data-validator-label）、
  標準テンプレートの Form モジュールと Twig の V2_Form、メールテンプレート（mail template、自動返信・管理者宛）、
  宛先・送信元の hidden（To[] / AdminFrom[] / AdminReply-To[]）と管理画面のフォーム設定、CSRF・二重送信・改ざんへの備え、送信データの確認を扱う。
  「お問い合わせフォームを作って」「確認画面が出ない」「メールが届かない・迷惑メールになる」「入力チェックを足したい」と頼まれたとき、
  ACMS_POST_Form や BEGIN_MODULE Form、module('V2_Form') を含むテンプレートを触るときに使う。
  a-blog cms form, contact form, validator, converter, mail template.
  テンプレートの記法一般は acms-template-acms / acms-template-twig、エントリーなどのカスタムフィールドは acms-custom-field が担う。
license: MIT
compatibility: a-blog cms Ver. 3.2 以上
metadata:
  acms-min-version: "3.2"
  status: stable
---

# a-blog cms のメールフォーム

公式ドキュメント:
- フォーム: <https://developer.a-blogcms.jp/document/form/>
- フォームオプション（バリデーター・コンバーターの一覧）: <https://developer.a-blogcms.jp/document/reference/form_option.html>

## 書く前に

- テーマが標準テンプレートか Twig か確かめる（acms-project-triage）。標準テンプレートは `<!-- BEGIN_MODULE Form -->`、Twig は `module('V2_Form')` で書き方がまったく違う。
- 管理画面の「フォーム」でフォーム ID（英数字・`_`・`-`、64 文字以内）を作る。テンプレートの `<input type="hidden" name="id" value="...">` に書くのはこのフォーム ID。管理画面に無い ID を送ると処理が止まる（後述）。
- 宛先・送信元・メールテンプレートのパス・サーバー側の入力チェックは、管理画面のフォーム設定に置く。テンプレートの hidden は利用者が書き換えられるため。

## 仕組み

1. 入力画面のフォームを `ACMS_POST_Form_Confirm` で送る → サーバーで検証 → エラーなら入力画面、なければ確認画面。
2. 確認画面から `ACMS_POST_Form_Submit` で送る → 管理画面の入力チェックでもう一度検証し、投稿データの保存とメールの送信を行う → 完了画面。
3. 確認画面の「修正する」は `ACMS_POST_Form_Chain`（検証結果を消して入力画面に戻す）。

| POST モジュール | 役割 | 送るもの |
|---|---|---|
| `ACMS_POST_Form_Confirm` | 検証して確認画面へ | 入力値、`field[]`、`:v#` / `:c`、`id`、`step=confirm` |
| `ACMS_POST_Form_Chain` | 入力画面へ戻る | `takeover`、`step=reapply` |
| `ACMS_POST_Form_Submit` | 検証・保存・送信 | `takeover`、`id`、`step=result`、宛先の hidden（`To[]` など） |

- 表示するステップは hidden の `step` で決まる。検証エラーのときは hidden の `error`（なければ action の `?step=`）の値になる。どれも無ければ初期の `step`。
- 標準テンプレートは `<!-- BEGIN step#名前 -->` が無いと `step`（入力画面）にフォールバックする。Twig の `form.step` はフォールバックしないので、送りうる値（`step` `reapply` `confirm` `result` `forbidden` `repeated`）をすべて `{% if %}` で受ける。
- フォーム ID が見つからない（空・誤記・別のブログの ID）と、確認・送信の処理は止まって `forbidden` になり、監査ログに critical で記録される。「不正なアクセス」と出て送れないときは、まず監査ログの critical を見る。
- `forbidden`（フォーム ID が無い、送信時の CSRF トークンの不一致・外部サイトからの送信など）と `repeated`（二重送信）のステップを必ず書く。書かないと標準テンプレートでは入力画面が黙って出直し、利用者には原因が分からない。

## 必ず守ること

- **値は `field[]` で登録したものしか送られない。** 入力欄ごとに `<input type="hidden" name="field[]" value="項目名">` を置く。忘れた項目は確認画面にもメールにも出ず、エラーにもならない。
- **サーバー側の入力チェックは管理画面のフォーム設定にも書く。** テンプレートの `:v#` は hidden なので消して送れば検証を外せるうえ、送信（Submit）時の再検証では使われない。管理画面の「入力チェック」に書いた検証は確認・送信の両方で必ず走る。
- **管理者宛メールの送信元（AdminFrom）は管理画面で自サイトのドメインのアドレスに固定し、「テンプレート指定を無効」にする。** 返信先は `AdminReply-To[]` に入力されたアドレスを入れる。AdminFrom が空だと本体は To（＝利用者が入力したアドレス）を送信元に使う。
- **入力値を確認画面・HTML メールに出すときは `[raw]` / `|raw` を付けない。** テキストメール（.txt）に限り `[raw]` を付けてよい。メールテンプレートについて答えるときは、この区別（テキストメールはよい・確認画面と HTML メールは不可）を両方とも利用者に伝える。 改行は `{inquiry}[nl2br]`（標準）/ `{{ inquiry.value|nl2br }}`（Twig）。
- **メールテンプレートは、管理画面のフォーム設定でパスを指定したファイルだけが使われる。** body.txt などを書く・直す・名前を変えるときは、フォーム設定のパス（テーマのディレクトリ基準）と一致しているかを利用者に確かめてもらう。
- **フォーム ID は各ステップに固定値で書く。** JavaScript で `id` を組み立てない（戻る・再読み込みで空のまま送られる）。

## 最小例（標準テンプレート）

```html
<!-- BEGIN_MODULE Form -->
<!-- BEGIN step -->
<form action="" method="post" class="js-validator">
  <input type="text" name="name" value="{name}" data-validator="name">
  <input type="hidden" name="field[]" value="name">
  <input type="hidden" name="name:v#required" id="name-v-required">
  <input type="hidden" name="name:c" value="KV">
  <p data-validator-label="name-v-required" class="validator-result-{name:v#required}">お名前を入力してください</p>
  <input type="hidden" name="step" value="confirm">
  <input type="hidden" name="id" value="contact">
  <button type="submit" name="ACMS_POST_Form_Confirm">確認へ</button>
</form>
<!-- END step -->
<!-- BEGIN step#confirm -->
<p>{name}</p>
<form action="" method="post">
  <input type="hidden" name="takeover" value="{takeover}">
  <input type="hidden" name="step" value="reapply">
  <button type="submit" name="ACMS_POST_Form_Chain">修正する</button>
</form>
<form action="" method="post">
  <input type="hidden" name="takeover" value="{takeover}">
  <input type="hidden" name="To[]" value="{email}">
  <input type="hidden" name="AdminReply-To[]" value="{email}">
  <input type="hidden" name="step" value="result">
  <input type="hidden" name="id" value="contact">
  <button type="submit" name="ACMS_POST_Form_Submit">送信する</button>
</form>
<!-- END step#confirm -->
<!-- BEGIN step#result --><p>送信しました。</p><!-- END step#result -->
<!-- BEGIN step#forbidden --><p>はじめからやり直してください。</p><!-- END step#forbidden -->
<!-- BEGIN step#repeated --><p>すでに送信済みです。</p><!-- END step#repeated -->
<!-- END_MODULE Form -->
```

- CSRF トークン（`formToken`）は本体が `</form>` の直前に自動で入れる。`</form>` を JavaScript で後から作る・別ファイルの出力に分けると入らず、送信が止まる。
- この例は `step#reapply` を書かず、エラー時は `step` にフォールバックさせている。入力欄の部品を `@include` で共有すれば、`step#reapply` を分けてもよい。

## 詳しくはここを読む

| 作業 | 読むもの |
|---|---|
| 入力チェック・全角半角の変換・エラー表示・JavaScript のバリデーター | references/validator-converter.md |
| Twig（`V2_Form`）で書く、checked / selected、ハイフンを含む項目名 | references/twig.md |
| メールテンプレート、宛先・送信元の設定、迷惑メール扱い・届かない | references/mail.md |
| フォーム ID の改ざん・切り替え、戻るボタン、CSRF・二重送信、送信データの保存と確認 | references/security-and-data.md |

## よくある誤り

- `field[]` を書き忘れて、その項目だけ確認画面・メールに出ない。
- テンプレートの `:v#` だけで入力チェックし、管理画面のフォーム設定に書いていない。
- `AdminFrom[]` に利用者のメールアドレスを入れる（送信元ドメインの認証に失敗し、迷惑メール扱いや受信拒否になる）。
- 確認画面で `{inquiry}[raw]` と書く。
- `step#forbidden` / `step#repeated` を書かず、送信できない原因が利用者にも運営者にも分からない。
- 送信先を分けるために `id` を入力値や JavaScript で切り替える（references/security-and-data.md）。
- 公式の `maxLength` 表記をそのまま使う。JavaScript のバリデーターは名前の大文字・小文字を区別するので `maxlength` と書く。
