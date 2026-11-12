# テーマでフィールド定義を宣言する（Ver. 3.3 以降）

Ver. 3.3.0-alpha.1 のソースで確かめた内容。

## 置き場所と書式

- `themes/<テーマ>/admin/field-definitions/<対象>.json`。対象は `entry`・`category`・`blog`・`user`・`module`・`component`。
- **JSON だけ**（YAML は読まれない）。書式は管理画面のフィールド定義のエクスポートと同じ。手で書くより、GUI で作ってエクスポートした JSON を置くほうが誤りが少ない。
- 最上位は `version`（`1`）・`entityType`・`sets`。`sets` の各要素がフィールドセットで、`fields` に項目を並べる。
- 項目に書けるキー: `key`・`label`・`labels`（多言語）・`type`・`description`・`status`・`parentKey`・`search`・`config`・`validation`・`conditions`。宣言ファイルでだけ、並び順の整数 `sort` も書ける。
- ID は書かない。参照はコードで書く（カテゴリーは `親のコード/子のコード`、ブログは `/` から始まるパス、ロールは名前）。解決できない参照は、表示が広がらない側に倒して読まれる。

最小の例（エントリーの「イベント」セット。カテゴリー `news/event` とその子孫でだけ、本文の下に出す）:

```json
{
  "version": 1,
  "entityType": "entry",
  "sets": [
    {
      "code": "event",
      "label": "イベント",
      "scope": "local",
      "layout": { "placement": "foot" },
      "conditions": { "or": [ { "and": [
        { "subject": "category", "operator": "in", "value": ["news/event"], "axis": "descendant-or-self" }
      ] } ] },
      "fields": [
        { "key": "event_place", "label": "会場", "type": "text",
          "validation": { "required": "publish", "rules": [ { "method": "maxlength", "arg": "100" } ] } },
        { "key": "event_type", "label": "形式", "type": "select",
          "config": { "options": [ { "value": "online", "label": "オンライン" }, { "value": "offline", "label": "会場" } ] } },
        { "key": "event_url", "label": "配信 URL", "type": "url",
          "conditions": { "or": [ { "and": [ { "field": "event_type", "operator": "eq", "value": "online" } ] } ] } }
      ]
    }
  ]
}
```

- 条件は「OR の中に AND を並べる」2 段の形。フィールドの条件の演算子は `eq`・`neq`・`in`・`contains`・`empty`・`notEmpty`・`gt`・`lt`・`matches`。
- 箱（`row`・`tabs`/`tab`・`accordion`）や繰り返し（`group`）の中の項目は、`parentKey` で親のキーを指す。

## DB の定義と重ねる規則

| 場面 | 結果 |
|---|---|
| 同じキーが宣言と DB（管理画面で作った定義）の両方にある | DB が勝つ |
| 同じ code のセットが宣言と DB にある | 1 つに重ね、セットの設定は DB が勝つ |
| 子テーマと親テーマに同じ code のセットがある | 子テーマのセットがセットごと置き換える |
| 並び順 | テーマだけのセット → DB のセット。セットの中はテーマ由来 → DB 由来。`sort` を書いたものだけ数値で割り込む |
| 管理画面でテーマ由来の項目を直す | できない。「使わない」にだけできる（DB に印が残る） |
| テーマを切り替える | 宣言の定義は消え、値は孤児値として残る |

- 効くのは、そのテーマを使っているブログだけ。
- 読めない部分（JSON として壊れている、`version`・`entityType` が違う、1 MiB を超える）は、ファイル・セット・項目の単位で警告ログを残して捨てられ、画面はエラーにならない。入力欄が出ないときは監査ログの警告を見る。
- 宣言はファイルの更新日時と大きさでキャッシュされる。書き換えれば反映される。

## 同じディレクトリに置けるもの

| ファイル | 用途 |
|---|---|
| `admin/field-definitions/placements.json` | 独自の表示場所。`{"version":1,"placements":{"entry":[{"name":"...","label":"...","hint":"..."}]}}` の形で、編集テンプレートに `<acms-custom-fields-slot placement="名前">` を置く。本体の場所は `foot`（本文の下）と `side` |
| `admin/field-definitions/patterns/*.json` | フィールドパターン（管理画面から挿入する項目のひな形。挿入したものはコピーで、パターンを直しても追従しない） |
| `admin/field-types/<ディレクトリ>/field-type.json` | テーマの独自の型。`label`・`icon`・`template`・`configFields`・`validators`。キーは `vendor.type` の形にする（本体の型と重ならないため） |

## 確かめ方

1. 宣言を置いたら、管理画面「フィールド定義」の対象のタブで、セットと項目がテーマ由来として出るかを見る。
2. 表示条件に合うエントリー（上の例なら `news/event` のエントリー）の編集画面で入力欄が出るか、合わないエントリーで出ないかを見る。
3. 公開時に必須の項目を空にして、下書きなら保存でき、公開では止まるかを見る。
4. 出なければ、監査ログの警告（捨てられたファイル・セット・項目）を見る。
