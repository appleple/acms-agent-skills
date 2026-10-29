---
name: acms-admin-frontend-plugin
description: >-
  a-blog cms（acms）の管理画面を JavaScript で拡張するプラグインを作るときの手順と判断基準（Ver. 3.2.29 以降）。
  ACMS.plugins.register によるプラグイン登録、ACMS.events のイベント購読（処理前の確認・処理後の通知）、
  Slot / Fill による UI の差し込み、ユニットやデータビューへの機能登録、npm パッケージ @ablogcms/plugins・@ablogcms/events を扱う。
  「管理画面にボタンを足したい」「メディアのアップロード前に確認を出したい」「独自のユニットを作りたい」と頼まれたときに使う。
  a-blog cms admin plugin, ACMS.plugins, ACMS.events, Slot. PHP 側の拡張は acms-extension-development が担う。
license: MIT
compatibility: a-blog cms Ver. 3.2.29 以上
metadata:
  acms-min-version: "3.2.29"
  status: draft
---

# a-blog cms の管理画面プラグイン

> このスキルは下書きです。拡張ポイントの一覧が公開ドキュメントにまとまるまで、内容は限定的です。

参考:
- npm: `@ablogcms/plugins`（プラグイン登録）、`@ablogcms/events`（イベントの型）。パッケージの README と型定義を読む。

## 基本の形

```ts
import { register } from '@ablogcms/plugins';

register('my-plugin', {
  version: '1.0.0',
  setup(ctx) {
    ctx.events.on('media.upload.before', async (event) => {
      // false を返すと処理を止められる（確認・検証用）
      return event;
    });
    ctx.events.on('media.upload.success', (event) => {
      // 処理後の通知
    });
  },
});
```

- イベント購読・機能登録・UI の差し込みは、すべて `setup(ctx)` の中で `ctx` から行う。プラグインを外したときにまとめて解除されるため。
- 読み込みは、PHP 側（拡張アプリ）から `<script type="module">` を管理画面に差し込んで行う（acms-extension-development）。

## 守ること

- イベント名・Slot 名・レジストリ名は、パッケージの型定義に載っているものだけを使う。載っていない内部の DOM やクラス名に依存しない（バージョンアップで変わるため）。
- 非推奨の `ACMS.addListener` を新しく使わない。`ACMS.events.on`（プラグインの中では `ctx.events.on`）を使う。
- 管理画面の見た目は、管理画面の CSS（`acms-admin-` で始まるクラス）に合わせる。
