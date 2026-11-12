# Ver. 3.3 での会員機能の変化

このファイルは、作業対象の a-blog cms が Ver. 3.3 以上のときだけ読む。Ver. 3.2 のサイトには当てはめない。Ver. 3.3.0-alpha.1 のソースで確かめた内容で、正式版で変わることがある。公開側のパスキーの書き方（クラス名・要素）は正式版までに変わる可能性が高い。作る前に、使っているバージョンの `themes/system/_member/` を見る。

## 増えたもの

| 機能 | テンプレート | 設定 |
|---|---|---|
| パスキーでのサインインと登録 | サインインに `_member/parts/signin/passkey.html` のインクルード、登録の画面 `_member/update-passkey.html` | 管理画面のログイン設定 |
| メールの確認コードによる 2 段階認証 | サインインと 2 段階認証の設定の画面にブロック `tfaEmail` など。メールの雛形は system の `mail/tfa-email/` | `tfa_email_code_lifetime`・`tfa_email_resend_interval` など |
| 2 段階認証の手段の切り替え | サインインにブロック `tfaAlternativeTotp`・`tfaAlternativeEmail`・`tfaAlternativePasskey` | ― |
| 重要な操作の前の本人確認（パスキーの登録など） | `_member/verify.html`（`tpl_verify`） | `sudo_mode_lifetime`（確認を省く分数） |

画面ごとのモジュールは `Member_Verify`（本人確認）・`Member_Update_Passkey`（パスキーの登録）・`Member_Passkey_Check`（パスキーを使えるか）。system の `_member/` のテンプレートが置いているので、テーマで作るときはそれを手本にする。

## 既存の会員テーマへの影響

- 会員テーマで `_member/signin.html`・`_member/update-tfa.html` を上書きしていると、上の新しいブロックが無い。メールの 2 段階認証を使うユーザーには何も出ず、サインインできなくなる。3.3 の `themes/system/_member/` の同じファイルと見比べてブロックを取り込む（acms-upgrade-theme の `to-3.3.md`）。
- 同梱の member テーマを継承しているなら、3.3 の member テーマに新しいファイルが入っている。上書きしていないファイルは対応不要。
- 新しく 2 段階認証やパスキーを有効にする前に、検証環境でサインイン・確認コードのメール・手段の切り替え・本人確認の流れを一通り試す。メールの送信元の設定が無いと確認コードが届かない。
