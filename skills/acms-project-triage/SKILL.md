---
name: acms-project-triage
description: >-
  作業対象の a-blog cms（acms）について、バージョン、テーマの一覧と継承の順、各テーマが標準テンプレートか
  Twig テンプレートか、配置済みのプラグイン（拡張アプリ）を scripts/detect.sh で判定する。
  a-blog cms のテーマ・テンプレート・プラグイン（拡張アプリ）を書き始める前、バージョンやテンプレートの種類が分からないとき、
  「このサイトの構成を調べて」「a-blog cms のバージョンは？」と頼まれたときに使う。
  a-blog cms version detection, theme inheritance, Twig or standard template, plugins.
  テーマの作り方・継承の使い方は acms-theme-development が担う。
license: MIT
compatibility: a-blog cms Ver. 3.2 以上（Ver. 3.2 未満も判定はでき、対象外と伝える）。POSIX シェル（sh）で動き、Node.js や PHP の CLI は不要。外部通信はしない。
metadata:
  acms-min-version: "3.2"
  status: stable
---

# a-blog cms の構成の判定

## 手順

1. a-blog cms の設置ディレクトリ（`index.php`・`themes/`・`extension/` が並ぶディレクトリ）を探す。リポジトリ直下とは限らない（`public/`・`htdocs/`・`ablogcms/` など）。
2. 判定スクリプトを実行する。スクリプトのパスは、このスキルのディレクトリからの相対パス。

   ```sh
   sh scripts/detect.sh <設置ディレクトリ>
   ```

3. 出力を読み、次を利用者に短く報告してから作業に入る。
   - バージョン（「推定」や「不明」なら、管理画面で正確な版を確認してもらう。3.2.x の途中で入った機能を使うかどうかは正確な版で決まるため）
   - 作業するテーマと、その継承の順（`chain`）
   - そのテーマが Twig か標準テンプレートか（`template`）
   - 配置されているプラグイン（拡張アプリ）

## 出力の読み方

```text
## a-blog cms
version: 3.2.38 (themes/system/css/acms.css の先頭コメント)

## themes
- blog@site
  chain: blog@site > site > system
  template: standard (template.yaml に tpl_twig なし)

## plugins
- SamplePlugin
```

| 項目 | 判定の根拠 | 判定できないこと |
|---|---|---|
| `version` | `themes/system/css/acms.css`（無ければ `acms.min.css`）の先頭コメント `@ablogcms/acms.css Ver. x.y.z`。ビルド時に本体の版が入るのは Ver. 3.2.29 以降 | 3.2.28 以前は先頭コメントが CSS 自体の版（`acms.css Ver. 2.1.x`）で、本体の版ではない。その場合は配布物にあるファイルの有無で系列だけを推定する（`php/Services/Template/Twig.php` があれば 3.2.0〜3.2.28、`php/ACMS/GET/Admin/Config/Set/Theme.php` があれば 3.1 系、`php/ACMS/GET/Admin/Webhook/Index.php` があれば 3.0 系、どれも無ければ 2.x 以前）。推定のときは正確な版を管理画面で確かめてもらう。配布版の PHP は一部が難読化されているため、PHP の中身からは読まない |
| `chain` | ディレクトリ名の `@` の右側を親として、本体と同じ規則で並べたもの。テンプレートはこの順に探され、最後に `system` が使われる | 親のディレクトリが無ければ `warning` を出す |
| `template` | 継承の順に `template.yaml` の `tpl_twig` を見て、最初に値があったもの（本体も template.yaml をキーごとに子 → 親の順で読む）。`enabled` なら Twig | template.yaml に無くても、管理画面のテーマ設定で Twig を有効にしている場合がある。`.twig` ファイルがあれば `standard?` と出すので、利用者に確認する。テーマ設定で template.yaml を優先しない設定にしていると、template.yaml の値は使われない |
| `plugins` | `extension/plugins/` 配下のディレクトリ。`ServiceProvider.php` が無いものは本体がプラグインとして扱わない | 有効にしているかどうかは DB にあるため分からない |

## 守ること

- `config.server.php`・`private/` 配下は読まない。DB の接続情報や秘密鍵があるため。スクリプトもこれらを読まない。
- どのブログ・カテゴリーにどのテーマが割り当てられているか（テーマセット）は DB に保存されており、ファイルからは分からない。利用者に確認する。テーマが複数あるときは、作業するテーマを推測で決めない。
- バージョンが 3.2 未満なら、acms-agent-skills の内容をそのまま当てはめず、そのことを伝える（Twig テンプレートは Ver. 3.2 から）。バージョンを上げるなら acms-upgrade を使う。
- スクリプトが失敗したり出力が想定と違ったりしたら、推測で補わず、どの項目が判定できなかったかを利用者に伝える。
