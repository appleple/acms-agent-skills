# 目的別の拡張ポイント

Ver. 3.2.38 時点で本体にある拡張ポイントを、目的から引けるようにまとめた判断表。
名前・引数（ペイロード）の正確な型は、対象バージョンの `@ablogcms/plugins` / `@ablogcms/events` などの型定義で確かめる。
注記のないものは Ver. 3.2.29 からある。

## イベント（`ctx.events.on` / `ACMS.events.on`）

ゲートは「止める（`cancel`）・`payload` を書き換える・Promise で待たせる」ことができる。通知は受け取るだけ。
ゲートを `cancel` で止めたいときは、SKILL.md のとおり `ACMS.events.on` で購読する（Ver. 3.2.38 時点）。

| 目的 | イベント | 種別と注意 |
|---|---|---|
| メディアのアップロード前に検査する・一部を除外する・中止する | `media.upload.before` | ゲート。`payload.files` は元の配列から**除外するだけ**。新しい `File` に差し替えても反映されない |
| アップロードの完了後に連携する | `media.upload.success` | 通知 |
| メディアの保存前に検査する・送信内容を変える | `media.update.before`（別名保存は `media.update-as-new.before`） | ゲート。`payload.formData` を書き換える。保存後は `.success` |
| メディアの削除前に止める | `media.delete.before` | ゲート。`payload.mediaIds` を書き換えても実際の削除対象は変わらない。除外したいときは止める |
| エントリーをゴミ箱へ移す前に止める | `entry.trash.before` | ゲート。後は `entry.trash.success` |
| エントリー・モジュールの一括公開／非公開の前に止める・送信内容を変える | `entry.bulk-status.before` / `module.bulk-status.before` | ゲート。`payload.formData` を書き換える |
| 複製・一括操作の後に連携する | `entry.duplicate.success` / `entry.bulk-trash.success` / `entry.bulk-duplicate.success` | 通知（複製には前のゲートがない） |
| プレビュー共有 URL の発行前に止める | `preview.share.before`（後は `preview.share.success`） | ゲート |
| プレビュー・タイムマシンの切り替えを知る | `preview.mode.change` / `timemachine.mode.change` | 通知 |
| カテゴリー・サブカテゴリー・タグ・関連エントリーの選択の変更を知る | `category.select.change` / `sub-category.select.change` / `tag.select.change` / `related-entry.select.change` | 通知。画面内の全インスタンスの変更が届くので `payload.target` で絞る |
| メイン画像の変更、メディアフィールド・メディアユニットの変更を知る | `entry.main-image.change` / `media-field.change` / `media-unit.change` | 通知 |
| ダイアログ・タブ・カスタムフィールドグループの追加などで現れた要素を初期化する | `dialog.open.after` / `tab.show.after` / `field-group.add.after` / `admin.delayed-contents.change` | 通知 |
| ユニットエディターの生成・操作を知る | `unit-editor.create.after` / `unit-editor.command.before` / `unit-editor.command.success` | 通知。`unit-editor.command.before` は名前に反して止められない |
| 管理画面のフォーム検証の結果を知る | `validator.valid.after` / `validator.invalid.after` / `validator.validated.after` / `validator.submit-fail.after` | 通知 |

- 発火済みのイベントは後から購読しても再生されない。
- 独自のイベント名を自分で発火してもよい（`ACMS.events.notify` / `ACMS.events.gate`）。型定義にない名前は型の検査が緩くなる。

### 従来のイベントとの対応

従来の DOM イベントや `ACMS.addListener` のイベントは今も発火する（新しいイベントと二重に発火する）。新しく書くなら右側を使う。

| 従来 | 新しいイベント |
|---|---|
| `acms.media-updated` | `media.update.success` |
| `acms.category.change` / `acms.tag.change` などの `acms.*.change` | 上の表の `*.select.change` / `*.change` |
| `acms.set-main-image` | `entry.main-image.change` |
| `acmsDialogOpened` / `acmsAddCustomFieldGroup` / `acmsAdminDelayedContents` | `dialog.open.after` / `field-group.add.after` / `admin.delayed-contents.change` |
| `acmsUnitEditorCreate` | `unit-editor.create.after` |
| `acmsAdminReady` | `ACMS.adminReady(fn)`（完了済みならすぐ呼ばれる。`acms.state.admin-ready` を直接 `on` しない） |
| `acmsReady` | `ACMS.Ready(fn)` |

`acmsAddUnit` には新しいイベントがない。

## UI の差し込み（`ctx.ui.fill(Slot 名, entry)`）

`entry` には次のどれかを渡す。

- 引数のない React コンポーネント
- `withFillProps(Component)` で包んだコンポーネント（Slot が渡す値 `fillProps` を受け取りたいとき。ビルドなしなら `ACMS.plugins.withFillProps`）
- DOM コールバック `(el) => { ...; return 後片付け関数 }`（React を使わないとき）

props を受け取る関数コンポーネントをそのまま渡さない。引数の数で DOM コールバックと区別しているため、DOM コールバックとして扱われる。
同じ Slot に複数登録すると登録順に並ぶ。

| 目的 | Slot 名 | 受け取れる値（fillProps） |
|---|---|---|
| メディア編集モーダルの代替テキスト欄の隣にボタンを置く（AI 生成など） | `media.edit-modal.field.alt` | `item` / `previewSrc` / `getAlt()` / `setAlt(value)`。代替テキスト欄を表示しない設定では Slot ごと出ない |
| メディア編集モーダルに独自のパネルを足す | `media.edit-modal.fields` | `item` |
| メディア編集モーダルの保存ボタンの隣に操作を足す | `media.edit-modal.footer` | `item` / `getFormData()` |
| メディア一覧の一括操作にボタンを足す | `media.list.bulk-actions` | `selectedItems` |
| プレビュー画面の操作ボタンを足す | `preview.actions` | なし |
| ユニットの共通ツールバーにボタンを足す | `unit-editor.unit-toolbar` | `editor` / `unit` |
| ユニットエディターの上・下に UI を置く | `unit-editor.top` / `unit-editor.bottom` | `editor` |
| ブロックエディターにメニューを足す | `block-editor.menus` | `editor` / `appendTo` |
| ブロックツールバーに UI だけを足す | `block-editor.block-menu`（全ブロック共通）、`block-editor.block-menu.text` / `.image` / `.file` / `.linkButton` / `.table`（その種類のブロックを選んでいるときだけ） | `editor` / `variant`（Ver. 3.2.36 以降） |

メディア編集モーダルはメディア管理だけでなく、カスタムフィールド・ブロックエディター・ユニットなどから開く画面にも共通で使われる。

## 種類の登録（レジストリ）

| 目的 | API | 注意 |
|---|---|---|
| 独自のユニットを足す | `ctx.unitEditor.registerUnitDefinition(type, 定義)` | 編集画面の表示だけ。保存・表示には PHP 側でモデルを登録する必要があり、無いと保存したユニットが黙って消える（acms-plugin-development）。type 名に `_` を使わない。既存の `custom` を同じ名前で登録すると全カスタムユニットの表示が置き換わる |
| 独自のブロックを足す | `ctx.blockEditor.registerBlockDefinition(type, (tiptap) => 定義)` と、新しいノードなら `ctx.blockEditor.registerExtension(name, (tiptap) => 拡張)` | 値でなく関数を渡す（ブロックエディターは後から読み込まれるため）。メニューに出すかは管理者が編集設定で選ぶ（登録した type が選択肢に出る）。独自のタグ・属性は保存時に除去されることがあり、許可は PHP 側で行う |
| ブロックツールバーにノードと一緒にボタンを足す | `registerExtension` で返す Tiptap 拡張の `addOptions()` に `blockMenu` を書く | Ver. 3.2.36 以降。UI だけなら上の Slot を使う |
| エントリー一覧・モジュール一覧の行の操作・一括操作・メニューを足す | `ctx.dataview.registerAction` / `registerBulkAction` / `registerMenu`（第 1 引数は `'entry'` か `'module'`） | 本体の項目の後ろに追加される。従来の `ACMS.Config.entryAdminConfig.getActions` などにも渡る |
| 一覧の列の型を足す | `ctx.dataview.registerColumnType(name, 定義)` | 列の並び替え・削除は `ACMS.Config.entryAdminConfig.getColumns`（代わりがない） |
| 翻訳を足す | `ctx.i18n.addResources(言語, リソース)` | Ver. 3.2.36 以降。名前空間はプラグイン名になり、`ACMS.i18n('my-plugin:key')` で引く |
| キーボードショートカット一覧に載せる | `ctx.keyboardShortcuts.registerCategory` / `registerShortcut` | Ver. 3.2.36 以降。ショートカットの `categoryId` は同じプラグインで登録したカテゴリーの id |

- 同じ名前を 2 回登録すると例外になる（警告で済まない）。
- ブロックの関数が例外を投げると、そのブロックだけ読み込まれず、コンソールにエラーが出る。
