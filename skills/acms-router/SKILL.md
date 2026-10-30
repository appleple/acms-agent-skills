---
name: acms-router
description: >-
  a-blog cms（acms）に関する依頼を分類し、どのスキルとどの公式ドキュメントを使うかを決める入口。
  a-blog cms のサイト制作・テーマ・テンプレート（標準テンプレート / Twig）・モジュール・フォーム・カスタムフィールド・
  カスタムユニット・プラグイン（拡張アプリ）・管理画面の JavaScript・バージョンアップについて依頼されたとき、どこから手を付けるか迷うとき、
  リポジトリが a-blog cms かどうか分からないときに最初に使う。a-blog cms, acms, ablogcms, theme, template, Twig, form, custom field, plugin.
license: MIT
compatibility: a-blog cms Ver. 3.2 以上
metadata:
  acms-min-version: "3.2"
  status: stable
---

# a-blog cms の依頼の振り分け

## 最初にすること

1. 作業対象が a-blog cms かを確かめる。`themes/` と `extension/` が並ぶディレクトリ、`themes/system/css/acms.css`、テーマ直下の `template.yaml` があれば a-blog cms と見てよい。
2. バージョン・テーマ・テンプレートの種類が分からないまま書き始めない。`acms-project-triage` で判定する。標準テンプレートと Twig テンプレートは記法がまったく違い、取り違えると動かないため。フォーム・カスタムフィールド・バージョンアップなど、どの依頼でも、回答の最初の手順として「`acms-project-triage` でバージョンとテンプレートの種類を判定する」とスキル名を挙げて示す（利用者や後続の作業が同じ手順を踏めるようにするため）。
3. 下の表で担当スキルを選ぶ。複数に当たるときは、上の行（土台になるもの）から順に使う。

## 振り分け表

| 依頼の内容 | 使うスキル |
|---|---|
| 静的な HTML サイトを a-blog cms のテーマにする（CMS 化する）、既存の HTML をテンプレートに移す | `acms-static-to-theme` |
| テーマを作る・継承する、template.yaml、どのテンプレートが表示に使われるか、acms.js や管理用 CSS の読み込み | `acms-theme-development` |
| `.html` のテンプレートに `<!-- BEGIN_MODULE ... -->`、`{var}`、`%{GLOBAL}`、`BEGIN_IF`、`@include` を書く・直す | `acms-template-acms` |
| `.twig` のテンプレート、`module('V2_...')`、`touch()`、`{% extends %}` を書く・直す | `acms-template-twig` |
| 「新着一覧を出したい」のように、何を表示したいかは決まっているがモジュールが分からない。モジュール ID の設定が効かない | `acms-module-reference` |
| お問い合わせなどのメールフォーム、バリデーター（`:v#`）、コンバーター（`:c`）、確認画面、メールテンプレート | `acms-form` |
| ブログ・カテゴリー・エントリーなどのカスタムフィールド、画像・メディアの入力欄、フィールドグループ、カスタムユニット | `acms-custom-field` |
| 会員制サイト（会員登録・ログイン・マイページ・会員限定のコンテンツ・退会）、ログインの有無での出し分け | `acms-member-site` |
| プラグイン（拡張アプリ）の PHP、Hook、独自モジュール、校正オプション・検証オプションの追加、グローバル変数の追加 | `acms-plugin-development` |
| 管理画面の JavaScript プラグイン、`ACMS.plugins`、`ACMS.events`、Slot | `acms-admin-frontend-plugin` |
| a-blog cms のバージョンアップ（3.1 から 3.2 など）の進め方。版の判定・移行先の決定・要件（PHP・MySQL）・バックアップ・検証環境・要修正箇所の洗い出し（scan.sh）・本体の更新・本番への反映 | `acms-upgrade` |
| バージョンアップに伴うテーマの修正。非推奨・削除されたモジュール、組み込み JS、ユニットの HTML と acms.css の変更、更新後の表示崩れ | `acms-upgrade-theme` |
| バージョンアップに伴うプラグイン（拡張アプリ）・`extension/acms/` の修正。PHP の要件、SQL ヘルパー、削除された関数・クラス、Hook の変化 | `acms-upgrade-plugin` |

バージョンアップでは、全体の手順を `acms-upgrade` で進め、修正の中身はテーマなら `acms-upgrade-theme`、プラグイン（拡張アプリ）なら `acms-upgrade-plugin` を使う（両方あれば両方）。修正に使う記法・実装の書き方は、それぞれ `acms-template-acms` / `acms-template-twig`、`acms-plugin-development` に従う。

記法を書くスキル（`acms-template-acms` / `acms-template-twig`）は、テンプレートの種類に合わせてどちらか一方だけを使う。フォームやカスタムフィールドの依頼でも、テンプレートの記法はこの2つのどちらかに従う。

どれにも当たらない場合（ルール、キャッシュ、セキュリティ設定など）は、公式ドキュメント <https://developer.a-blogcms.jp/> から該当ページを探して読む（`/document/` はトップページへ転送される）。推測で書かない。主な入口は次のとおり。

| 分野 | ページ |
|---|---|
| ユニット | <https://developer.a-blogcms.jp/document/units/> |
| ルール | <https://developer.a-blogcms.jp/document/rule/> |
| URL コンテキスト | <https://developer.a-blogcms.jp/document/urlcontext/> |
| キャッシュ | <https://developer.a-blogcms.jp/document/cache/> |
| セキュリティ | <https://developer.a-blogcms.jp/document/security/> |
| トラブルシューティング | <https://developer.a-blogcms.jp/document/trouble-shooting/> |

## 守ること

- 仕様の正は公式ドキュメント（developer.a-blogcms.jp）と、作業対象のサイトで実際に動く挙動。記憶にある記法と食い違ったらドキュメントに従い、ドキュメントと挙動が違えば挙動を優先して利用者に伝える。
- 対象は Ver. 3.2 以上。3.2 より前のサイトなら、そのことを利用者に伝え、スキルの内容をそのまま当てはめない。バージョンを上げる依頼、または 3.2 より前のサイトで作業する前に上げるかを決めるときは `acms-upgrade` を使う（テーマ・プラグイン（拡張アプリ）の修正は `acms-upgrade-theme`・`acms-upgrade-plugin`）。3.2.x の途中で入った機能（各スキルに「Ver. 3.2.NN 以降」と注記がある）は、判定したバージョンと照らしてから使う。
- `config.server.php` と `private/` 配下には DB の接続情報や秘密鍵があるため、読み込まない・出力しない。
- a-blog cms 本体のファイル（`php/`、`js/`、`themes/system/` など）は書き換えない。挙動を変えたいときは、テーマ・プラグイン（拡張アプリ）・設定で実現する。本体を書き換えるとバージョンアップで消えるため。管理画面の入力欄・ログイン画面など、`themes/system` にあるテンプレートに関わる依頼では、「`themes/system` は直接書き換えず、作業中のテーマに同じパスでファイルを置く」と置き場所を回答に明記する。
- モジュール ID・フォーム ID・テーマの割り当てなど、管理画面で作る設定は DB に保存され、ファイルを置くだけでは作られない。必要な管理画面の操作を利用者に伝える。
