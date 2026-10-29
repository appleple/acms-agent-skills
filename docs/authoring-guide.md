# スキルの書き方

## 置き場所の判断

| 書きたいもの | 置き場所 |
|---|---|
| いつ使うか、手順、確認方法 | `SKILL.md`（500 行以内。短いほどよい） |
| 判断表、記法の対応表、よくある誤り | `references/*.md`（`SKILL.md` から「〜のときは references/x.md を読む」と案内する） |
| 毎回同じ結果になってほしい処理（環境の判定など） | `scripts/`（POSIX シェルで書き、利用者の環境に Node.js や PHP の CLI がなくても動くようにする） |
| 変数の一覧、モジュールの仕様、チュートリアル | 書かない。developer.a-blogcms.jp のページへリンクする |

## frontmatter

```yaml
---
name: acms-template-twig            # ディレクトリ名と一致させる。小文字・数字・ハイフン、64 文字以内
description: >-                     # 1024 文字以内。何をするか＋いつ使うか。英語の語も入れる
  ...
license: MIT
compatibility: a-blog cms Ver. 3.2 以上。...   # 500 文字以内
metadata:
  acms-min-version: "3.2"           # 値は文字列
  status: draft                     # draft / stable
---
```

- `description` は、エージェントがスキルを読み込むかどうかを決める唯一の材料になる。「何を扱うか」を先に、「どんな依頼・どんなファイルのときに使うか」を後に書く。英語で依頼されても発動するよう、`a-blog cms`、`acms`、`template`、`Twig` のような語を入れる。
- 隣のスキルとの境界（「Twig の記法は acms-template-twig が担う」など）を最後に書くと、誤発動が減る。

## 本文

- エージェントへの指示として書く（「〜する」「〜しない」）。理由を一言添えると、想定外の状況でも判断がぶれにくい。
- 古い情報や推測を書かない。確認していない挙動は「未確認」と書く。
- セキュリティに関わる箇所（エスケープを外す、HTML をそのまま出す）は、必ず安全な既定とその理由を書く。

## 評価シナリオ

`evals/scenarios.json` に、スキルなしだと失敗しやすい依頼を置く。

```json
[
  {
    "query": "Twig テーマでエントリー一覧を出したい",
    "expected_behavior": ["V2_Entry_Summary を module() で呼ぶ", "..."],
    "source": "このシナリオを作った理由（スキルなしで実際に起きた失敗など）"
  }
]
```

評価は今のところ手動で行う。新しいセッションでスキルを入れた状態と入れない状態で `query` を依頼し、`expected_behavior` を満たすかを見る。
