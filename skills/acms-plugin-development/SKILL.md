---
name: acms-plugin-development
description: >-
  a-blog cms（acms）のプラグイン（拡張アプリ）と、extension/acms 配下のユーザー拡張を PHP で開発するときの手順と判断基準。
  プラグイン（拡張アプリ）のディレクトリ構成と ServiceProvider、Hook（保存・表示などの処理に割り込む）、独自の GET / POST モジュール、
  校正オプション・検証オプションの追加、Twig による管理画面の設定ページを扱う。
  「エントリー保存時に処理を足したい」「独自モジュールを作りたい」「プラグインを作って」と頼まれたときに使う。
  a-blog cms plugin, Hook, ServiceProvider. 管理画面の JavaScript プラグインは acms-admin-frontend-plugin が担う。
license: MIT
compatibility: a-blog cms Ver. 3.2 以上
metadata:
  acms-min-version: "3.2"
  status: draft
---

# a-blog cms のプラグイン（拡張アプリ）開発

> このスキルは下書きです。手順の詳細は公式ドキュメントを読んで確かめてから書いてください。

公式ドキュメント:
- プラグイン（拡張アプリ）: <https://developer.a-blogcms.jp/document/develop_apps/>
- Hook: <https://developer.a-blogcms.jp/document/user_hook/>
- 校正オプションの追加: <https://developer.a-blogcms.jp/document/user_corrector/>
- 検証オプションの追加: <https://developer.a-blogcms.jp/document/user_validator/>
- 管理画面の設定ページを Twig で書く（Ver. 3.2.24 以降）: <https://developer.a-blogcms.jp/document/develop_apps/twig-admin.html>

## どこに書くか

| したいこと | 置き場所 |
|---|---|
| 複数のサイトで使い回す・配布する | プラグイン（拡張アプリ）。置き場所は `extension/plugins/<名前>/`。管理画面からインストール・有効化する |
| そのサイトだけの小さな処理 | `extension/acms/` 配下のユーザー拡張（`Hook.php`、`Corrector.php`、`Validator.php`、`GET/`、`POST/`） |

本体のファイル（`php/` 配下）は書き換えない。アップデートで上書きされるため。

## 守ること

- Hook は既存の処理の流れに割り込むので、例外を外へ投げて本体の処理を止めない。失敗したら記録して続ける。
- POST モジュールでは本体の CSRF 検証を外さない。
- ユーザーの入力値を出力するときは、テンプレート側のエスケープに任せる（acms-template-acms / acms-template-twig）。
- 外部 API の URL やキーをコードに直書きせず、プラグイン（拡張アプリ）の設定から読む。
- 名前空間・クラス名は、既存のプラグイン（拡張アプリ）や公式ドキュメントのサンプルに合わせる。

## 確認

- プラグイン（拡張アプリ）は管理画面でインストールと有効化をしないと動かない。動かないときは、まず有効になっているかを確かめる。
- デバッグモードでエラーを表示させて確かめる（`config.server.php` の変更は利用者に依頼する）。
