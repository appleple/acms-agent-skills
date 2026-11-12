# Ver. 3.3 で増えたプラグイン（拡張アプリ）の拡張点

このファイルは、作業対象の a-blog cms が Ver. 3.3 以上のときだけ読む。Ver. 3.2 のサイトには当てはめない。Ver. 3.3.0-alpha.1 のソースで確かめた内容で、正式版で変わることがある。本体のソースが手元にあるときは、`extension/acms/Hook.php` の各 Hook のコメントを先に読む。

3.2 から 3.3 へ上げるときに既存のプラグインで直すもの（削除された protected メソッド、PHP 8.3 など）は acms-upgrade-plugin の `references/to-3.3.md` にある。

## ひな型とテスト基盤

新しく作るときのひな型 acms-plugin-skeleton は、Ver. 3.3.0-alpha.1 の時点で Ver. 3.3 での動作が確かめられていない（README に「3.3 is not tested yet」とある）。テスト基盤 `ablogcms/testing-framework` も、Packagist には 3.2 系しか無い（2026-11-12 に確認）。3.3 向けに作るときは、ひな型から作ったうえで、テスト基盤の 3.3 系が出るまでは 3.3 の検証環境で動作を手で確かめ、`require-dev` の版を本体のマイナーバージョンに合わせて更新する。

## どれを使うか

| したいこと | 使うもの | 詳しくは |
|---|---|---|
| 外部のシステムや AI エージェントにプラグインの機能を API で出す | `RestApi::routes()`・`RestApi::scopes()`（足したルートは MCP のツールにもなる） | acms-rest-api の references/plugin-routes.md |
| コアの REST API の応答（エントリーなど）に項目を足す | `RestApi::extendResource()` | 同上 |
| MCP にだけ独自の操作を出す | `Mcp::tools()`（REST のルート 1 本に当たらない処理だけ） | acms-mcp |
| 入力欄の型・表示場所・表示条件を足す、保存前の値を加工する | `FieldDefinition::register*()`、Hook `extendsFieldDefinitionValue` など | acms-field-definition の references/plugin-extension.md |
| 自前の画面で受けた値を、カスタムフィールド定義どおりに検証する | `FieldDefinition::validateValues()` | 同上 |
| 定期的に処理を動かす | Scheduler（下記） | ― |
| リダイレクトの判定を変える | Hook `extendsRedirectMatch` | Hook.php のコメント |
| エントリーの CSV エクスポートに列を足す | Hook `extendsEntryCsvExportColumns`・`extendsEntryCsvExportRow` | 同上 |
| 一覧の一括変更で独自の項目を変えられるようにする | Hook `extendsBulkChangeEntryActions`（3.3 から、許可しない項目は無視される） | 同上 |

## 定期実行（Scheduler）

サーバーの cron を設定できない環境でも、アクセスをきっかけにした内部のリクエスト（ループバック）で定期処理を動かせる。cron を使える環境では `cron/scheduler.php` を cron から呼ぶ。

1. `Acms\Services\Scheduler\Contracts\ScheduledTask` を実装したクラスを作る。`getName()`（重ならない名前。プラグイン名を接頭辞にする）、`getSchedule()`（`Schedule::everyMinutes(n)`・`hourly()`・`daily()`・`dailyAt('03:00')`）、`handle(TaskContext $context)` を書く。
2. `ServiceProvider::init()` で `App::make('scheduler.tasks')->register(new MyTask())` するか、Hook `registerScheduledTasks($registry)` で `$registry->register(...)` する。

守ること:

- 処理は何度実行しても結果が同じになるように書く。途中で止まると再実行されるため。
- ログイン状態やブログの文脈（BID など）は引き継がれない。対象のブログは処理の中で明示する。
- 1 回の処理を短くする（アクセスの応答の後に動くため）。大量の処理は分割して、次の回に続きを行う。
- 例外は `handle()` の中で受けて記録する（acms-plugin-development の「守ること」と同じ）。
- サーバーから自分の公開 URL に届かない環境（リバースプロキシ・CDN の後ろ）では、利用者に定数 `SCHEDULER_LOOPBACK_URL` を設定してもらうか、Hook `extendsSchedulerLoopbackRequest` で送信先を変える。

## 管理画面のテンプレート

- 管理画面の上のバーは `<header class="acms-admin-edit-bar">`、ドロップダウンは `<acms-dropdown-menu>`（`<acms-dropdown-menu-item>`・`<acms-dropdown-menu-group>`、開くボタンは `slot="trigger"`）。jQuery のドロップダウン（`js-acms-dropdown-toggle`）は削除された。プラグインの設定画面もこの書き方に合わせる。
- エントリーの編集画面に、サイドバー用の差し込み口（`field_side.html`・`field_side_foot.html`、InjectTemplate の `admin-entry-field-side`）が増えた。
