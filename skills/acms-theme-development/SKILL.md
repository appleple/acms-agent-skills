---
name: acms-theme-development
description: >-
  a-blog cms（acms）のテーマを作る・複製する・継承する・構成を直すときの手順と判断基準。
  テーマのディレクトリ構成、子テーマ（blog@site の @ 記法）と system へのフォールバック、template.yaml、
  カテゴリー別・エントリー別テンプレート、どのテンプレートが表示に使われているかの調べ方を扱う。
  「新しいテーマを作って」「このページのテンプレートはどれ？」「system の管理画面テンプレートを直したい」と頼まれたときに使う。
  theme, child theme, template.yaml. テンプレートの記法は acms-template-acms（標準）/ acms-template-twig（Twig）が担う。
license: MIT
compatibility: a-blog cms Ver. 3.2 以上
metadata:
  acms-min-version: "3.2"
  status: draft
---

# a-blog cms のテーマ開発

公式ドキュメント: <https://developer.a-blogcms.jp/document/themes/>

## テーマの探索と継承

- テンプレートは「作業中のテーマ → 親テーマ → … → `system`」の順に探される。
- `子@親` のディレクトリ名で継承する（`blog@site`）。`president@blog@site` のような多段継承もできる。
- 子テーマには、親と違うファイルだけを置く。親のファイルを丸ごとコピーすると、親の修正が届かなくなるため。
- `system`（管理画面や `login.html`・`404.html` の既定）は直接編集しない。変えたいファイルだけを自分のテーマの同じパスにコピーして直す。`system` はアップデートで上書きされるため。

## template.yaml

テーマ直下に置き、ページの種類ごとに使うテンプレートを指定する。管理画面のテーマ設定でテンプレート設定を有効にしたときに優先して読まれる。

```yaml
tpl_top    : index.html   # トップページ
tpl_index  : index.html   # 一覧ページ
tpl_detail : entry.html   # 詳細ページ
tpl_404    : 404.html     # エラーページ
tpl_twig   : enabled      # Twig テンプレートを有効にする（Ver. 3.2 以降）
```

ほかのキー（管理ページ、エントリー編集ページ、ログインページなど）は既存テーマの `template.yaml` か公式ドキュメント（<https://developer.a-blogcms.jp/document/themes/config.html>）で確認してから書く。

## ページごとにテンプレートを変える

| したいこと | 方法 |
|---|---|
| あるカテゴリーだけ一覧・詳細を変える | テーマ内にカテゴリーコードと同名のディレクトリを作り、テンプレートを置く（例: `news/index.html`、`news/entry.html`） |
| あるエントリーだけ変える | エントリーコードと同名のテンプレートファイルを置く |
| 条件で部分的に出し分ける | テンプレート内でタッチモジュール（Twig なら `touch()`）を使う |

## 使われているテンプレートを調べる

推測でファイルを直さない。次のどちらかで、実際に使われているファイルを確かめてから直す。

- デバッグモード（`DEBUG_MODE` を 1）にすると、管理ボタンから使用中のテンプレートを確認でき、インクルードしたファイルのパスも HTML コメントに出る。`config.server.php` の書き換えは利用者に依頼する（DB 接続情報を含むファイルのため、エージェントは開かない）。
- 上の探索順に沿って、作業中のテーマ → 親テーマ → `system` の順にファイルの有無を見る。

## テーマを新しく作るとき

1. 一から作らず、既存のテーマ（公式テーマ一覧: <https://developer.a-blogcms.jp/document/themes/official-2025.html>）を親にした子テーマで始められないか検討する。
2. 標準テンプレートと Twig のどちらで書くかを決める。既存サイトのテーマを継承するなら、親テーマに合わせる（Twig のテンプレートから標準テンプレートを読むことはできるが、逆はできないため。詳しくは acms-template-twig）。
3. どのブログにどのテーマを使うかは、管理画面の「テーマ > テーマ設定」でブログごとに設定する。ファイルの配置だけでは切り替わらない。
