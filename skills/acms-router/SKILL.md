---
name: acms-router
description: >-
  a-blog cms（acms）に関する依頼を分類し、どのスキルとどの公式ドキュメントを使うかを決める入口。
  a-blog cms のサイト制作・テーマ・テンプレート（標準テンプレート / Twig）・モジュール・カスタムフィールド・
  拡張アプリ（プラグイン）・管理画面の JavaScript について依頼されたとき、どこから手を付けるか迷うとき、
  リポジトリが a-blog cms かどうか分からないときに最初に使う。a-blog cms, acms, ablogcms, theme, template, Twig, plugin.
license: MIT
compatibility: a-blog cms Ver. 3.2 以上
metadata:
  acms-min-version: "3.2"
  status: draft
---

# a-blog cms の依頼の振り分け

## 最初にすること

1. 作業対象が a-blog cms かを確かめる。`themes/` と `extension/` が並ぶディレクトリ、`themes/system/css/acms.css`、テーマ直下の `template.yaml` があれば a-blog cms と見てよい。
2. バージョン・テーマ・テンプレートの種類が分からないまま書き始めない。`acms-project-triage` で判定する。標準テンプレートと Twig テンプレートは記法がまったく違い、取り違えると動かないため。
3. 下の表で担当スキルを選ぶ。複数に当たるときは、上の行（土台になるもの）から順に使う。

## 振り分け表

| 依頼の内容 | 使うスキル |
|---|---|
| テーマを作る・複製する・継承する、template.yaml、どのテンプレートが表示に使われるか | `acms-theme-development` |
| `.html` のテンプレートに `<!-- BEGIN_MODULE ... -->`、`{var}`、`%{GLOBAL}`、`@include` を書く・直す | `acms-template-acms` |
| `.twig` のテンプレート、`module('V2_...')`、`touch()`、`{% extends %}` を書く・直す | `acms-template-twig` |
| 「新着一覧を出したい」のように、何を表示したいかは決まっているがモジュールが分からない | `acms-module-reference` |
| 拡張アプリ（プラグイン）の PHP、Hook、独自モジュール、校正オプションの追加 | `acms-extension-development` |
| 管理画面の JavaScript プラグイン、`ACMS.plugins`、`ACMS.events`、Slot | `acms-admin-frontend-plugin` |

どれにも当たらない場合（カスタムフィールド、ユニット、ルール、フォーム、キャッシュなど）は、公式ドキュメントの目次 <https://developer.a-blogcms.jp/document/> から該当ページを探して読む。推測で書かない。主な入口は次のとおり。

| 分野 | ページ |
|---|---|
| カスタムフィールド | <https://developer.a-blogcms.jp/document/customfield/> |
| ユニット | <https://developer.a-blogcms.jp/document/units/> |
| ルール | <https://developer.a-blogcms.jp/document/rule/> |
| フォーム | <https://developer.a-blogcms.jp/document/form/> |
| URL コンテキスト | <https://developer.a-blogcms.jp/document/urlcontext/> |
| キャッシュ | <https://developer.a-blogcms.jp/document/cache/> |
| セキュリティ | <https://developer.a-blogcms.jp/document/security/> |
| トラブルシューティング | <https://developer.a-blogcms.jp/document/trouble-shooting/> |

## 守ること

- 公式ドキュメント（developer.a-blogcms.jp）を正とする。記憶にある記法と食い違ったらドキュメントに従う。
- 対象は Ver. 3.2 以上。3.2 より前のサイトなら、そのことを利用者に伝え、スキルの内容をそのまま当てはめない。
- `config.server.php` には DB の接続情報があるため、読み込まない・出力しない。
- a-blog cms 本体のファイル（`php/` 配下など）は書き換えない。挙動を変えたいときは、テーマ・拡張アプリ・設定で実現する。本体を書き換えるとバージョンアップで消えるため。
