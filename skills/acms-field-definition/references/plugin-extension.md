# プラグイン（拡張アプリ）からフィールド定義を拡張する（Ver. 3.3 以降）

Ver. 3.3.0-alpha.1 のソースで確かめた内容。プラグイン（拡張アプリ）の構成・ServiceProvider・Hook の登録の基本は acms-plugin-development に従う。本体のソースが手元にあるときは、`extension/acms/Hook.php` のフィールド定義の Hook のコメントと、`Acms\Services\Facades\FieldDefinition` の docblock を先に読む（そのバージョンで使える API を表している）。

## どれを使うか

| したいこと | 使うもの |
|---|---|
| 独自の入力型を足す | `FieldDefinition::registerFieldType()`（`ServiceProvider::init()` で呼ぶ）。テーマだけで済むならテーマの `admin/field-types/` |
| 独自の表示場所を足す | `FieldDefinition::registerPlacement()`。テーマなら `placements.json` |
| 表示条件の判定材料を足す | `FieldDefinition::registerLocationSubject()` |
| プラグインに定義やパターンを同梱する | `registerThemeDefinitionDirectory()`・`registerPatternDirectory()`（テーマより優先度が低い） |
| 自前の画面・API で受けた値を定義どおりに検証する | `FieldDefinition::validateValues()`。結果の `isValid()`・`errors()`・`unmetRequired()` を読む |
| 保存前に値を加工する | Hook `extendsFieldDefinitionValue` |
| 編集画面・強制に渡す定義を加工する | Hook `extendsFieldDefinitions`（テーマの宣言なら `extendsThemeFieldDefinitions`、継承分は `extendsInheritedFieldDefinitions`） |
| 見せる・隠すを独自に決める | Hook `extendsFieldVisibility` |
| キーの変更に追従する（独自テーブルにキーを持っている） | Hook `extendsKeyRenamed` |
| 参照型の候補の絞り込み・参照切れの扱い | Hook `extendsRelationPickerQuery`・`extendsRelationBrokenReference` |
| 定義の取り込みで ID を読み替える | Hook `extendsFieldDefinitionImportRoleId` など |
| エクスポート・インポートする JSON を加工する | Hook `extendsFieldDefinitionExport`・`extendsFieldDefinitionImport` |
| 対象ごとに選べる型を絞る・増やす | Hook `extendsFieldTypePolicy`（エディションで使えない型は緩められない。既にある定義は消えない） |
| 検索対象の変更を全文検索へ反映する前後に処理を挟む | Hook `extendsFieldDefinitionSearchReindexBefore`・`extendsFieldDefinitionSearchReindexAfter` |

- `registerEntityType()`（定義を付けられる対象を足す）は試験的な API で、正式版で変わり得る。配布するプラグインでは使わない。
- 管理画面の部品の npm パッケージ `@ablogcms/field-definition` は公開 API ではない（HOOKS.md に載っていない）。直接 import しない。

## 管理画面の JavaScript

カスタムフィールド定義のイベント（テンプレート型の入力欄の初期化と片付け、値の書き換え、ラベルの書き換え、定義の変更の通知）は、acms-admin-frontend-plugin の references/ver-3.3.md にまとめてある。守ることは 2 つ。

- JavaScript から値を変えるときは `field-definition.value.set` を使い、入力欄の DOM を直接書き換えない（再描画で戻るため）。
- JavaScript で型を登録する口は無い。型は PHP かテーマの `field-type.json` で登録する。

## テンプレート型を書くときの注意

- 値の入力欄だけを `name="{name}"`（複数なら `{name}[]`）で書き、現在の値は `{values.0}` で読む。
- カスタムフィールドメーカーの生成コードをそのまま貼らない。現在の値が空のまま描画され、保存すると既存の値を空で上書きする。
- `<input type="file">` を置かない（保存が止まる）。
- 選択状態の出し分けが要るなら `.twig` で書く（標準テンプレートの型では BEGIN_IF が使えない）。
- Hook `beforePostFire` からは定義の入力欄の値が見えず、書き換えても保存に効かない。値の加工は `extendsFieldDefinitionValue` で行う。
