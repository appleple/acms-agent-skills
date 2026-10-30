# Twig（V2_Form）でフォームを書く

公式: <https://developer.a-blogcms.jp/document/form/basic.html>、ステップの考え方は <https://developer.a-blogcms.jp/document/form/form-practice2.html>。Twig の記法一般は acms-template-twig を読む。

## データの取り方

```twig
{% set form = module('V2_Form') %}
{% set f = form.fields %}

{% if form.step in ['step', 'reapply'] %}
<form action="" method="post" class="js-validator">
  <input type="text" name="name" value="{{ f.name.value ?? '' }}" data-validator="name">
  <input type="hidden" name="field[]" value="name">
  <input type="hidden" name="name:v#required" id="name-v-required">
  <p data-validator-label="name-v-required" class="validator-result-{{ (f.name.v.required ?? false) ? '0' }}">お名前を入力してください</p>
  {# ... #}
  <input type="hidden" name="step" value="confirm">
  <input type="hidden" name="id" value="contact">
  <button type="submit" name="ACMS_POST_Form_Confirm">確認へ</button>
</form>
{% elseif form.step == 'confirm' %}
  <p>{{ f.name.value }}</p>
  {# 送信フォームの takeover は {{ f.takeover }} #}
{% elseif form.step == 'result' %}
  ...
{% elseif form.step in ['forbidden', 'repeated'] %}
  ...
{% endif %}
```

| 欲しいもの | 書き方 |
|---|---|
| 表示するステップ | `form.step`（`step` / `reapply` / `confirm` / `result` / `forbidden` / `repeated` など、送った値そのまま） |
| 入力値（1 つ目） | `form.fields.項目名.value` |
| 入力値（すべて。チェックボックスなど） | `form.fields.項目名.array` |
| 項目のどれかの検証が失敗した | `form.fields.項目名.invalid` |
| 特定の検証が失敗した | `form.fields.項目名.v.検証名`（失敗なら true） |
| 全体のエラー | `form.error`（`form.error.formID`、失敗した項目名の配列 `form.error.fields`） |
| 確認画面から送る takeover | `form.fields.takeover` |

- 初期表示では `form.fields` に項目が無い。`f.name.value ?? ''`、`f.name.v.required ?? false` のように `??` で受ける。
- `include('/contact/form/input.twig', form.fields)` のように `form.fields` を渡すと、部品の中では `name.value` のように項目名を直接使える。
- 標準テンプレートと違い、知らない `form.step` の値は入力画面にフォールバックしない。`error` の hidden や `?step=reapply` を送るなら `reapply` も受ける。
- 値は型が変換されて渡る（数値に見える文字列は数値、`true` / `false` は真偽値。先頭が 0 の数字は文字列のまま）。比べるときに引用符付きの文字列と `===` 相当で比べると一致しない。

## ハイフンを含む項目名

`first-name` のような名前は Twig の変数名として書けない。添字で読む。

```twig
{{ form.fields['first-name'].value ?? '' }}
```

`include` で `form.fields` を渡した部品の中では `_context['first-name'].value` になる。新しく作るフォームでは、項目名にハイフンを使わないほうが読みやすい（標準テンプレートとの互換は保たれる）。

## checked / selected

標準テンプレートの `{項目名:checked#値}` は Twig には無い。校正オプション由来の `|checked('値')` / `|selected('値')` フィルターで出す。

```twig
<input type="checkbox" name="topics[]" value="採用" {{ f.topics.array|checked('採用') }}>
<option value="1" {{ f.plan.value|selected('1') }}>プラン 1</option>
```

- 値と引数を文字列として比べる。配列（`.array`）を渡すと、いずれかの要素と一致すれば出す。数値に変換された値（`1`）と `'1'` も一致し、真偽値は `'true'` / `'false'` として比べる。
- 先頭が 0 の値（`'01'` など）は数値に変換されず文字列のまま渡るので、`'1'` とは一致しない。選択肢の値と引数は、同じ書き方にそろえる。
- 初期表示で項目が無いときに備えて、`f.topics.array ?? []` のように `??` で受けてもよい。
- Twig の `in`（`{{ '採用' in (f.topics.array ?? []) ? 'checked' }}`）でも書ける。`in` は型をゆるく比べる。

## エスケープ

- `{{ }}` は自動でエスケープされる。入力値に `|raw` を付けない。改行は `{{ f.inquiry.value|nl2br }}`（Twig の `nl2br` はエスケープ後に改行を `<br>` にする）。
- hidden の値（`To[]` など）も `{{ f.email.value }}` のままでよい。
