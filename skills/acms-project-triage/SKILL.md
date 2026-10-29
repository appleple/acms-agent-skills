---
name: acms-project-triage
description: >-
  作業対象の a-blog cms（acms）について、バージョン、テーマの一覧と継承関係、各テーマが標準テンプレートか
  Twig テンプレートか、導入済みのプラグイン（拡張アプリ）を scripts/detect.sh で判定する。
  a-blog cms のテーマ・テンプレート・プラグイン（拡張アプリ）を書き始める前、バージョンやテンプレートの種類が分からないとき、
  「このサイトの構成を調べて」と頼まれたときに使う。version detection, theme, Twig or standard template.
license: MIT
compatibility: a-blog cms Ver. 3.2 以上。POSIX シェル（sh / bash）で動く。外部通信はしない。
metadata:
  acms-min-version: "3.2"
  status: draft
---

# a-blog cms の構成の判定

## 手順

1. a-blog cms の設置ディレクトリ（`index.php`・`themes/`・`extension/` があるディレクトリ）を探す。リポジトリ直下とは限らない（`public/`・`htdocs/`・`ablogcms/` など）。
2. 判定スクリプトを実行する。

   ```bash
   sh scripts/detect.sh <設置ディレクトリ>
   ```

   スクリプトのパスは、このスキルのディレクトリからの相対パス。

3. 出力を読み、次を利用者に短く報告してから作業に入る。
   - バージョン（判定できなければ「不明」と書き、管理画面のフッターなどで確認してもらう）
   - 作業するテーマ名と、その親テーマ
   - そのテーマが Twig（`tpl_twig: enabled`）か標準テンプレートか
   - 導入済みのプラグイン（拡張アプリ）

## 判定の根拠

| 項目 | 見るもの |
|---|---|
| バージョン | `themes/system/css/acms.css` の先頭コメント（`@ablogcms/acms.css Ver. x.y.z`）。PHP のソースは配布版では難読化されているため使わない |
| テーマの継承 | ディレクトリ名 `子テーマ@親テーマ`。テンプレートは子 → 親の順に探される |
| Twig か標準か | テーマ直下の `template.yaml` の `tpl_twig: enabled`。テーマ単位の設定で、管理画面のテーマ設定でも切り替えられるため、`template.yaml` に無くても Twig の場合がある。`.twig` ファイルの有無も合わせて見る |
| プラグイン（拡張アプリ） | `extension/plugins/` 配下のディレクトリ |

## 守ること

- `config.server.php`・`private/` 配下は読まない。DB の接続情報や秘密鍵があるため。スクリプトもこれらを読まない。
- どのテーマが実際に使われているか（ブログごとのテーマ設定）は DB に保存されており、ファイルだけでは分からない。利用者に確認する。
- バージョンが 3.2 未満なら、スキルの内容をそのまま当てはめず、そのことを伝える。
