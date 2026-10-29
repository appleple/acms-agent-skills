# バリデーター・コンバーター・エラー表示

公式: <https://developer.a-blogcms.jp/document/form/validator_converter.html>、一覧は <https://developer.a-blogcms.jp/document/reference/form_option.html>、JavaScript のバリデーターは <https://developer.a-blogcms.jp/document/form/entry-2389.html>。

## 書き方の要点

```html
<input type="text" name="tel" value="{tel}" data-validator="tel">
<input type="hidden" name="field[]" value="tel">
<input type="hidden" name="tel:c" value="a">
<input type="hidden" name="tel:v#required" id="tel-v-required">
<input type="hidden" name="tel:v#regex" value="@^[0-9-]+$@" id="tel-v-regex">
```

- `項目名:v#検証名`（`:validator#` と同じ）。引数が要る検証は `value` に書く。1 項目に複数並べてよい。
- `項目名:c`（`:converter` と同じ）。値は PHP の `mb_convert_kana` のオプション文字（`r R n N a A s S k K h H c C V`）。それ以外の文字を含むと値が空になる（ログに記録される）。
- 変換は検証より先に行われる。全角で入力された数字を `n` / `a` で半角にしてから `digits` や `regex` で検証できる。
- ファイル・画像の必須チェックは `photo@path:v#required` のように `@path` を付ける（公式の説明どおり）。

## テンプレートの検証と管理画面の検証

| 書く場所 | いつ効くか | 使いどころ |
|---|---|---|
| テンプレートの `:v#` / `:c`（hidden） | 確認（Confirm）時に、送られてきた hidden の分だけ。消して送れば効かず、送信（Submit）時の再検証でも使われない | エラー表示を出すため、JavaScript のバリデーターを動かすため |
| 管理画面のフォーム設定「入力チェック」 | 送信内容に関係なく、確認・送信の両方で必ず効く | 必須・形式など、守らせたい検証すべて。`duplication`（過去に送られたメールアドレスか）はここでしか使えない |

- 同じ検証を両方に書く。管理画面にだけ書いた検証も、送信後の表示（`{name:v#required}` やエラー表示のブロック）には反映される。ただし JavaScript のバリデーターはテンプレートの hidden しか読まないので、入力中の即時チェックは出ない。
- 管理画面の入力チェックでもコンバーター（converter）を指定できる。テンプレートの `:c` を消されても正規化したい項目はこちらにも書く。

## 検証を選ぶ判断表

正確な挙動・引数は公式の一覧で確かめる。ここでは選び方だけを示す。

| 入力欄 | 使う検証 | 注意 |
|---|---|---|
| 必須の入力・選択 | `required` | 前後の空白（全角を含む）だけの値は空とみなす。チェックボックス・ラジオも未選択なら失敗する |
| メールアドレス | `email`、確認用の 2 つ目に `equalTo`（値に比べる項目名） | 全角で入力されることがあるので `:c` に `a` を付ける |
| 電話番号・郵便番号 | `regex`（`@` 区切り） | `digits` は PHP が数値として読める値を通す（`090-1234-5678` は失敗、`1e3` や `-1` は通る）。番号の形を決めたいなら `regex` |
| 文字数 | `maxlength` / `minlength`（値に文字数） | 小文字で書く。改行は 1 文字として数える |
| 数値の範囲 | `min` / `max` | 整数として比べる |
| ふりがな | `hiragana` / `katakana` | 空白も不可。姓と名の間に空白を入れる欄なら項目を分けるか `regex` を使う |
| 選択肢の値 | `in`（値にカンマ区切りの選択肢） | カンマ区切りの文字列で指定できるのは Ver. 3.2.24 以降。それより前のバージョンでは必ず失敗するので使わない |
| チェックボックスの選択数 | `all_minChecked` / `all_maxChecked` / `all_justChecked` | `field[]` と同じ名前の `name="hobby[]"` で送る |
| 日付・時刻 | `dates` / `times` | 書式の許容範囲は公式の一覧で確かめる |

- 空の値は `required` 以外の検証を通る。任意項目に形式チェックだけ付けてよい。
- 本体に無い検証名（綴り違いを含む）を書くと、サーバー側では `value` が空なら常に失敗、空でなければ常に成功として扱われる。エラーが消えない・効かないときは綴りを疑う。
- `maxLength` のような大文字混じりは、サーバー側では効くが JavaScript のバリデーターでは無視される。

## コンバーターを選ぶ判断表

| 入力欄 | 値 | 理由 |
|---|---|---|
| 名前・会社名・住所・自由記述 | `KV` | 半角カタカナを全角にし、濁点を 1 文字にまとめる |
| ふりがな（ひらがなで受ける） | `HVc` | 半角カタカナ・全角カタカナをひらがなにそろえてから `hiragana` で検証 |
| フリガナ（カタカナで受ける） | `KVC` | 半角カタカナ・ひらがなを全角カタカナにそろえてから `katakana` で検証 |
| メールアドレス・URL | `a` | 全角の英数字・記号を半角にする |
| 電話番号・郵便番号 | `a`（数字だけなら `n`） | `a` は全角のハイフン（－）も半角にする。長音記号（ー）は変換されないので `regex` で弾くか案内する |
| 数量などの数字 | `n` | 全角数字を半角にしてから `digits` / `min` / `max` |

各文字の意味は PHP のマニュアル（<https://www.php.net/manual/ja/function.mb-convert-kana.php>）を読む。

## エラー表示の仕組み

### サーバー側（常に効く）

- 検証に失敗した項目は、標準テンプレートでは変数 `{項目名:v#検証名}` が `0` になり、ブロック `<!-- BEGIN 項目名:v#検証名 -->` / `<!-- BEGIN 項目名:validator -->`（その項目のどれかが失敗）が出る。成功・未検証のときは変数が空。
- そのため `class="validator-result-{name:v#required}"` は、エラーのとき `validator-result-0`、それ以外は `validator-result-` になる。
- Twig では `form.fields.項目名.invalid`（どれかが失敗）と `form.fields.項目名.v.検証名`（失敗なら true）を使う（references/twig.md）。
- フォーム全体のエラーは標準テンプレートの `<!-- BEGIN error -->`（`{formID}` `{errorKey}`）、Twig の `form.error`。

### JavaScript のバリデーター（acms.js がある場合だけ）

- `<form class="js-validator">` を、acms.js が読み込み時に見つけて動かす。acms.js が無いページでは何も起きず、エラーは送信後にサーバーから返る表示だけになる（サーバー側の検証は変わらず効く）。
- フォーム内の `項目名:v#検証名` の hidden を読み、その hidden の **id** と同じ値を `data-validator-label` に持つ要素（無ければ `<label for="その id">`）の class を `validator-result-0` / `validator-result-1` に切り替える。hidden に id が無い、id と `data-validator-label` が食い違うと、メッセージが切り替わらない。
- `data-validator="項目名"` を付けた要素には `valid` / `invalid` の class が付く。入力欄にはさらに `aria-invalid` が付く。
- 送信時に失敗があれば送信を止める。送信ボタンに `data-acms-formnovalidate` を付けるとそのボタンでは止めない。
- JavaScript 側にある検証は `required` `minlength` `maxlength` `min` `max` `regex` `regexp` `digits` `email` `url` `equalTo` `dates` `times` `katakana` `hiragana` `all_justChecked` `all_minChecked` `all_maxChecked` `filesize`。`in` などそれ以外はサーバー側でだけ検証される。
- 表示・非表示の CSS（`.validator-result-` と `.validator-result-1` を隠し、`.validator-result-0` を出す）はテーマ側で書く。system の公開側 CSS（acms.css）には入っていない。CSS が無いと、全部のエラーメッセージが最初から見えてしまう。
- 入力画面（`step`）と再入力画面（`step#reapply`）で同じ部品を `@include` / `include` し、エラー表示の書き方をそろえる。
