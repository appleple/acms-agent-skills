---
name: acms-admin-frontend-plugin
description: >-
  a-blog cms（acms）の管理画面を JavaScript で拡張するプラグインを作るときの手順と判断基準（Ver. 3.2.29 以降）。
  ACMS.plugins.register と setup(ctx) によるプラグイン登録、ACMS.events のイベント（処理前に止める・値を変えるゲートと、処理後の通知）、
  Slot / Fill による UI の差し込み、ユニット・ブロック・エントリー一覧への機能登録、ctx.config、
  プラグイン JS の読み込み方とビルド（React などを本体と共有する externals）、npm の @ablogcms/plugins・@ablogcms/events を扱う。
  「管理画面にボタンを足したい」「メディアのアップロード前に確認を出したい」「独自のユニットやブロックを作りたい」
  「エントリー一覧に操作を足したい」「ACMS.addListener を置き換えたい」と頼まれたときに使う。
  a-blog cms admin JavaScript plugin, ACMS.plugins, ACMS.events, Slot, Fill.
  PHP 側（ServiceProvider・Hook・アセットの登録）は acms-plugin-development が担う。
license: MIT
compatibility: a-blog cms Ver. 3.2.29 以上（管理画面の JavaScript 拡張基盤は Ver. 3.2.29 で追加）
metadata:
  acms-min-version: "3.2.29"
  status: stable
---

# a-blog cms の管理画面プラグイン（JavaScript）

管理画面の JavaScript 拡張は、`ACMS.plugins.register(name, { version, setup(ctx) })` で登録する。
イベント購読・機能登録・UI の差し込みはすべて `setup(ctx)` の中で `ctx` から行う。
`ACMS.plugins.unregister(name)` を呼ぶと、`ctx` 経由で登録したものがまとめて解除されるため。

参考（公開されているもの）:
- アセット API（JS の読み込み）: https://developer.a-blogcms.jp/document/develop_apps/asset-api.html
- テンプレートの挿入（InjectTemplate）: https://developer.a-blogcms.jp/document/develop_apps/entry-2912.html
- 従来の組み込み JS: https://developer.a-blogcms.jp/document/javascript/js-edit.html 、イベント: https://developer.a-blogcms.jp/document/javascript/eventhandler.html
- npm: `@ablogcms/plugins`（登録 API と `PluginContext` の型）、`@ablogcms/events`（イベントバスの型）。
  拡張ポイントの正確な名前と引数は、使っている a-blog cms と同じバージョンのパッケージの型定義（`dist/*.d.ts`）で確かめる。
  developer サイトには拡張ポイントの一覧ページがまだない（Ver. 3.2.38 時点）。

## まず決めること

| やりたいこと | 使うもの |
|---|---|
| 管理画面の操作の前に止める・送信内容を変える、操作の後に連携する | `ACMS.events` のイベント（references/by-purpose.md） |
| 管理画面の決まった場所にボタンや入力欄を足す | `ctx.ui.fill(Slot 名, ...)`（同上） |
| 独自のユニット・ブロック、エントリー一覧の列の型・行の操作を足す | `ctx.unitEditor` / `ctx.blockEditor` / `ctx.dataview`（同上） |
| 組み込み JS の設定値（`ACMS.Config.xxx`）を変える | 従来どおり `ACMS.Ready` の中で `ACMS.Config` を上書きする（js-edit.html） |
| 公開側のページの JavaScript | `ACMS.plugins` は使えない（管理画面用の `admin.js` が作るため）。`ACMS.Ready` を使う |
| エントリー一覧の列の並び替え・削除 | `ACMS.Config.entryAdminConfig.getColumns`（代わりの API がない） |

一覧にない場所や操作は拡張ポイントがない。管理画面の DOM やクラス名を直接書き換えて実現しない（バージョンアップで壊れる）。
必要なら本体への要望として伝える。

## 基本の形（ビルドなしの JavaScript）

```js
// 管理画面に <script type="module"> で読み込むファイル
const setup = () => {
  ACMS.plugins.register('my-plugin', {
    version: '1.0.0',
    setup(ctx) {
      // 通知: 処理の後に呼ばれる。戻り値は使われない
      ctx.events.on('media.upload.success', (payload) => {
        console.log(`${payload.items.length} 件アップロードされました`);
      });
      // UI: メディア編集モーダルにパネルを足す（DOM コールバック。戻り値は後片付け）
      ctx.ui.fill('media.edit-modal.fields', (el) => {
        el.textContent = 'my-plugin のパネル';
        return () => { el.textContent = ''; };
      });
    },
  });
};

// admin.js は async で読み込まれるため、この時点で ACMS.plugins がまだ無いことがある
if (window.ACMS?.plugins) {
  setup();
} else {
  window.ACMS?.adminReady?.(setup);
}
```

- 登録は読み込み時に同期的に行う（`setTimeout` や `fetch` の後で登録しない）。本体は読み込み後に登録内容を読み出すため。
- `ACMS.adminReady` で待った場合、イベントと Slot は後からの登録でも効くが、ユニット定義などのレジストリは
  読み出しが済んだ画面では反映されないことがある。登録した機能が実際に出るかを管理画面で確かめる。
- 同じ名前で 2 回 `register` すると例外になる。レジストリに同じ名前を登録しても例外になる。名前はプラグイン名を含めて重ならないようにする。

## ゲート（処理を止める・値を変える）

処理の前に呼ばれるイベント（ゲート）では、ハンドラの第 2 引数の `cancel(reason)` で止め、`payload` のプロパティを直接書き換えて値を変える。

```js
// Ver. 3.2.38 時点では ctx.events.on がゲートの第 2 引数を渡さないため、止めるゲートは ACMS.events.on で購読する
const off = ACMS.events.on('media.upload.before', (payload, gate) => {
  if (payload.files.some((file) => /[^\x20-\x7e]/.test(file.name))) {
    if (!window.confirm('ファイル名に半角英数字以外が含まれています。アップロードしますか？')) {
      gate.cancel(); // メディア・エントリー・モジュールのゲートは、理由を渡すと（gate.cancel('…')）本体がその文字列を表示する
    }
  }
});
```

- `return false` では止まらない（Ver. 3.2.33 以降。戻り値は無視される）。Ver. 3.2.29〜3.2.32 は止め方が違うので、そのバージョンの型定義に従う。
- ハンドラが例外を投げるとゲートは止まり、理由は表示されない。止めたいときは `cancel` を呼ぶ。
- 通知イベント（`.success` / `.after` / `.change` など）は止められない。ゲートかどうかは名前でなく型定義で決まる
  （`unit-editor.command.before` は名前が `.before` でも通知）。
- `ACMS.events.on` で購読したものは `unregister` で解除されないので、戻り値の関数（`off`）を自分で保持する。
- ハンドラは登録順に 1 つずつ実行され、Promise を返すと待つ。重い処理を入れると操作が止まって見える。

## ビルドする場合（TypeScript・JSX・npm パッケージ）

- `import { register, withFillProps } from '@ablogcms/plugins'` は `window.ACMS.plugins` へ処理を渡すだけの薄い層なので、同梱してよい。
  上と同じく、`ACMS.plugins` ができる前に呼ぶと例外になる。
- React・react-dom・Tiptap は同梱しない。本体と同じものを `ACMS.Library.*` から使うよう externals に指定し、出力は IIFE にする。
  詳しくは references/loading-and-build.md を読む。
- npm パッケージのバージョンは、対象の a-blog cms と同じバージョン（例: 3.2.37）に揃える。

## 読み込み（PHP 側）

プラグイン（拡張アプリ）の PHP から、管理画面に `<script type="module">` を出力する。
Ver. 3.2.29 以降はアセット API（`Asset::script(..., ['attrs' => ['type' => 'module']])`）を使う。
出力する場所・条件の選び方と `ctx.config` への値の渡し方は references/loading-and-build.md、
ServiceProvider や Hook の書き方は acms-plugin-development を読む。

## 守ること

- イベント名・Slot 名・レジストリ名は、型定義または references/by-purpose.md にあるものだけを使う。
  型定義にない名前でも TypeScript はエラーにしない（独自イベント扱いになる）ため、名前の打ち間違いに気づけない。動かして確かめる。
- `ACMS.addListener` / `ACMS.dispatchEvent` を新しく使わない。型定義で非推奨になっている（動作は維持され、削除予定は示されていない）。
  同じ内容のイベントが `ACMS.events` にあればそちらを購読する（references/by-purpose.md の「従来のイベントとの対応」）。
- `ctx.config` に API キーなどの秘密情報を渡さない。URL のクエリとしてブラウザに見える。秘密が要る処理は PHP 側で行う。
- 管理画面の見た目は、管理画面の CSS（`acms-admin-` で始まるクラス）や `ACMS.Library.components` の部品に合わせる。
- ユニットの type 名に `_` を使わない（`_` より前だけが type として扱われる）。独自ユニットは PHP 側の登録も要る（references/by-purpose.md）。

## 確かめ方

1. ブラウザの開発者ツールで `ACMS.plugins.getAll()` を実行し、プラグイン名と `registrations`（登録した内容）を見る。
2. `ACMS.events.handlerCount('イベント名')` で購読数を見る。
3. 本体の画面で対象の操作をして、止まる・表示される・連携されることを確かめる。コンソールに `[@ablogcms/plugins]` や `[ACMS.events]` で始まるエラーが出ていないかも見る。
