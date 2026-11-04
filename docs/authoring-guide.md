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
- `description` には、記法に見える記号（`<` `>` `{` `}` `[` `]` `@`）を書かず、言葉で書く。claude.ai へのアップロードでは山かっこが XML タグとみなされて受け付けられず、`{% %}`・`{{ }}`・`%{VAR}`・`@include` のようなテンプレートの記法でも弾かれた例があるため。たとえば `<!-- BEGIN_MODULE -->` は「BEGIN_MODULE コメント」、`{{ }}` は「Twig の出力の記法」、`子@親` は「子テーマ名と親テーマ名をつないだディレクトリ名」と書く。本文（frontmatter より下）には書いてよい。`scripts/validate-skills.mjs` が検出する。

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

評価のやり方は、下の「検証」の 3 を見る。

## 検証

スキルの検証は、確かめる範囲の違う 3 つを組み合わせる。どれか 1 つでは足りない（形式が正しくても配布先で受け付けられないことがあり、受け付けられても誤ったコードを書かせることがあるため）。

| 段 | 何を確かめるか | いつ | 手段 |
|---|---|---|---|
| 1. 形式 | Agent Skills の仕様、配布先の制約、社内情報の混入、リンク切れ | 毎回（CI が自動で行う） | `node scripts/validate-skills.mjs`、`claude plugin validate .` と `claude plugin validate skills`（Claude Code の規則）。`gh skill publish --dry-run` は参考 |
| 2. 受け入れ | 配布先で実際に入るか | リリースの前 | claude.ai・Claude Code・`npx skills` で入れてみる |
| 3. 振る舞い | 入れたエージェントが正しく答えるか | スキルの内容を変えたとき | 評価シナリオを解かせて採点する |

### 1. 形式

- `scripts/validate-skills.mjs` を正とする。仕様の参照実装（agentskills の skills-ref）と同じ規則に、claude.ai の制約（description の記法に見える記号）、社内情報、リンク、評価シナリオ、marketplace.json の整合を足してある。
- `gh skill publish --dry-run` は description の長さをバイト数で数えるため、日本語の description では仕様（1024 文字）の範囲内でも警告が出る。エラーが出たときだけ直す。
- 新しい制約が分かったら（今回の claude.ai の記号のように）、`validate-skills.mjs` に規則として足し、この表と frontmatter の節に理由を書く。

### 2. 受け入れ

公式の要件を満たしていても、配布先で受け付けられないことがある。アップロードせずに判定を確かめる手段は公開されていないので、リリースの前に人が入れてみる。

1. `sh scripts/build-claude-ai-zips.sh` で `dist/claude-ai/` にスキルごとの zip を作り、claude.ai の「設定 > Skills > Skills をアップロード」で、変更したスキル（初めてなら全部）を入れる。
2. Claude Code で `claude plugin marketplace add ./` と `claude plugin install <プラグイン>@acms-agent-skills` を行い、スキルが一覧に出るかを見る。
3. `npx skills add ./ --list` で、全スキルが見つかるかを見る。

入らなかったら、エラーの文言を CHANGELOG と Issue に残し、1 の規則に足す。

### 3. 振る舞い

スキルだけを読める解答役（サブエージェント）に `evals/scenarios.json` の `query` を解かせ、別の採点役に `expected_behavior` と突き合わせさせる。解答役に `expected_behavior` を見せない。作業対象のサイトが要るシナリオには、検証用のサイトを用意する（`config.server.php` と `private/` に目印の文字列を置き、回答に出ないことを確かめる）。満たさない項目があれば、スキルを直して全件を解き直す。スキルの本文（references を含む）を変えたら、そのスキルのシナリオを解き直す。
