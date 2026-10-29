# 読み込み・ビルド・設定値の受け渡し

## 管理画面に読み込む（PHP 側）

管理画面の JavaScript プラグインは、プラグイン（拡張アプリ）の PHP から `<script type="module">` として出力する。
ServiceProvider・Hook の書き方は acms-plugin-development を読む。

| 方法 | 使うとき | 注意 |
|---|---|---|
| アセット API `Asset::script($handle, $src, ['position' => 'body_end', 'attrs' => ['type' => 'module']])`（Ver. 3.2.29 以降） | 基本はこれ。ServiceProvider の `init()` から呼べば全ページ、Hook の `afterBuild()` から呼べばページの種類などで出し分けられる | 管理画面以外のページにも出力される。JS 側で `ACMS.plugins` の有無を確かめる（SKILL.md の基本の形）か、PHP 側で出す条件を絞る |
| テンプレートの挿入 `InjectTemplate::singleton()->add('admin-main', ...)` | 管理画面のテンプレート（`admin-main` などの差し込み位置）があるページだけに出したいとき | 渡すのはテンプレートのパスか HTML を返す関数（関数は Ver. 3.2.24 以降）。中に `<script type="module" src="...">` を書く |

- `type="module"` を付ける。HTML の解析が終わってから出力順に実行されるため、本体が登録内容を読み出す前に登録が済む。
- 複数のプラグインは、出力した順（アセット API なら呼んだ順）に登録され、イベントのハンドラもその順に実行される。
- 本体の `admin.js` は `async` で読み込まれるので、プラグインの方が先に実行されて `ACMS.plugins` がまだ無いことがある。
  `ACMS.plugins` が無ければ `ACMS.adminReady(fn)` で待つ（SKILL.md の基本の形）。
- `ACMS.plugins` は投稿権限のあるユーザーでログインしているときに読み込まれる `admin.js` が作る。ログインしていない閲覧者のページには無い。
- 本体のアセット（`acms-admin` など）を `Asset::dequeue()` で止めない。管理画面が動かなくなる。

## ビルドの要否

| 書き方 | ビルド |
|---|---|
| 素の JavaScript で `ACMS.plugins.register(...)`、UI は DOM コールバックか `ACMS.Library.React.createElement` | 不要 |
| TypeScript・JSX を使う、npm の型定義を使う、公式 Tiptap 拡張を使う | 必要（webpack / Vite など） |

ビルドするときは、本体と同じインスタンスを共有しなければならないものを externals にする。同梱すると二重になり、
React はフックが動かず（Invalid hook call）、Tiptap は選択範囲の判定などが壊れる。

| 依存 | externals の宛先 | 使える版 |
|---|---|---|
| `react` | `ACMS.Library.React` | Ver. 3.2.29 以降 |
| `react/jsx-runtime` | `ACMS.Library.ReactJsxRuntime` | Ver. 3.2.36 以降 |
| `@tiptap/core` / `@tiptap/react` / `@tiptap/suggestion` / `@tiptap/pm/*` | `ACMS.Library.tiptap.core` / `.react` / `.suggestion` / `.pm.state` など | Ver. 3.2.36 以降。中身が入るのはブロックエディターの読み込み後なので、`registerBlockDefinition` / `registerExtension` に渡す関数の中でだけ使う |
| `react-dom` / `react-dom/client` | `ACMS.Library.ReactDom` / `ACMS.Library.ReactDomClient` | Ver. 3.2.38 以降 |
| `@ablogcms/components/<サブパス>` | `ACMS.Library.components.<サブパス>`（ハイフンを含む名前は `components['button-v2']`） | Ver. 3.2.38 以降。`dataview` / `date-picker` / `time-picker` / `syntax-highlight` / `rich-select` / `select` / `device-mode` / `icon-picker` は共有されていない |

- 出力形式は IIFE にする。ESM で出力すると `import ... from "react"` が残り、ブラウザで解決できない。
- 配布物は production ビルドにする（開発用の `react/jsx-dev-runtime` は共有されていない）。
- 公式 Tiptap 拡張（`@tiptap/extension-*`）は、登録する関数の中で `await import()` する。関数は Promise を返してよい。
  トップレベルで import して評価すると Tiptap 一式が同梱されるか、読み込み前の Tiptap に触れて例外になる。
- 公式 Tiptap 拡張のバージョンは、本体が使っている Tiptap のバージョンに合わせる。
- `@ablogcms/plugins` と `@ablogcms/events` は、グローバル（`window.ACMS`）へ処理を渡すだけなので同梱してよい。

## PHP から設定値を渡す（`ctx.config`）

PHP の `jsModule($key, $value)` で渡した値は `ACMS.Config[$key]` に入り、`ctx.config` は
**プラグイン名をキャメルケースにしたキー**（`my-plugin` → `myPlugin`）を読む。キーが合っていないと `ctx.config` は空の `{}` になる（例外にならない）。

値は `acms.js` の URL のクエリとして渡るため、次の制約がある。

- 数値・真偽値は文字列になる（`42` → `"42"`、`true` → `"1"`、`false` → `"0"`）。
- `null` のキーは消える。
- 入れ子は 5 段まで。深い設定はキーを平らにするか、JSON 文字列 1 つにして JS 側で `JSON.parse` する。
- ブラウザから見えるので、API キー・トークンなどの秘密情報を渡さない。秘密が要る処理は PHP 側（Hook や独自のエンドポイント）で行う。

## 従来のカスタマイズとの使い分け

| 従来の書き方 | 今も使う場面 | 新しい書き方へ移す場面 |
|---|---|---|
| `ACMS.Ready(fn)` 内で `ACMS.Config.xxx` を上書き | 組み込み JS（公開側・管理画面）の設定値を変える | — |
| `ACMS.Dispatch(要素)` | 後から挿入した HTML に組み込み JS を適用し直す | — |
| `ACMS.addListener('acmsXxx', fn)` | 新しいイベントに同等のものが無いとき（`acmsAddUnit` など） | 同等のイベントがあれば `ACMS.events.on`（by-purpose.md の対応表） |
| `ACMS.Config.entryAdminConfig.getActions` / `getBulkActions` / `getMenus` | 既存のコードはそのまま動く | 新しく足すなら `ctx.dataview.registerAction` などのレジストリ |
| 管理画面の DOM を直接書き換える | 使わない | イベント・Slot・レジストリ。無ければ本体への要望にする |
