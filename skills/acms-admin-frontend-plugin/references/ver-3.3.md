# Ver. 3.3 での管理画面の JavaScript の変化

このファイルは、作業対象の a-blog cms が Ver. 3.3 以上のときだけ読む。Ver. 3.2 のサイトには当てはめない。Ver. 3.3.0-alpha.1 のソースと、同梱の `packages/frontend/plugins/HOOKS.md` で確かめた内容で、正式版で変わることがある。イベントの正確な名前と引数は、使っている a-blog cms と同じバージョンのパッケージの型定義で確かめる。

## 増えたもの

| したいこと | 使うもの |
|---|---|
| カスタムフィールド定義のテンプレート型の入力欄を、JavaScript で初期化・片付けする | `field-definition.field.rendered` / `field-definition.field.remove`（対で使う。`detail.definition.type` で型を判定する） |
| JavaScript から編集画面のカスタムフィールド定義の値を書き換える | `ACMS.events.notify('field-definition.value.set', { entityType, key, values })`。入力欄の DOM の value を直接書き換えない（再描画で戻るため）。信頼が要る値は PHP の Hook `extendsFieldDefinitionValue` で決める |
| 定義の項目のラベルを書き換える | ゲート `field-definition.label.before` |
| 定義の変更（キーの変更・インポート・使わない）を受け取る | `field-definition.key.change`・`field-definition.import.success`・`field-definition.suppress.change` など |
| リダイレクト一覧に行の操作・一括操作を足す | `ctx.dataview.registerAction('redirect', ...)`・`registerBulkAction('redirect', ...)`。上の階層のブログのルールも並ぶので、自ブログのルールに限るなら `condition: (row) => row.isMine` |
| 管理画面から REST API を呼ぶ | ベース URL は `ACMS.Config.restApiBaseUrl`。ログイン中のセッションで呼べる（acms-rest-api） |

- JavaScript でカスタムフィールド定義の型を登録する口は無い（型は PHP かテーマの `field-type.json`。acms-field-definition）。
- 定義の管理画面の部品（npm パッケージ `@ablogcms/field-definition`）は公開 API ではない。import しない。

## 変わったもの

- エントリーの編集画面に「再読み込みなしの保存」が入った（設定 `entry_edit_save_without_reload`。既定は off）。有効なサイトでは、保存の後に本文（`#admin-main`）の中身が置き換わり、そのとき `admin.delayed-contents.change` が新しい本文を `target` にして発火する。編集画面の DOM に後付けした処理は、このイベントで `target` の中を再初期化する（`DOMContentLoaded` だけで初期化していると、保存の後に動かなくなる）。
- 管理画面のドロップダウンは `<acms-dropdown-menu>`（カスタム要素）になり、jQuery のドロップダウン（`js-acms-dropdown-toggle`）は削除された。
- jQuery が 4.0 になった。管理画面のプラグインで jQuery の古い API（`.size()`・`.bind()` など）を使っていたら直す（acms-upgrade-theme の `to-3.3.md`）。
