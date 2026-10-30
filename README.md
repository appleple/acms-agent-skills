# acms-agent-skills

[a-blog cms](https://www.a-blogcms.jp) でサイト制作やプラグイン（拡張アプリ）開発を行う AI エージェント向けのスキル集です。Claude Code・Codex・GitHub Copilot・Cursor・Gemini CLI など、[Agent Skills](https://agentskills.io/specification) の形式に対応したエージェントで使えます。

## スキルとは

スキルは、エージェントが作業の途中で読み込む指示書（`SKILL.md`）です。エージェントは依頼の内容に合うスキルを自分で選んで読み込むので、入れたあとは「トップにお知らせの一覧を出して」のように、いつもどおり依頼するだけで使えます。

このスキル集は、a-blog cms の仕様を本体ソース（Ver. 3.2.38）と公式ドキュメント [developer.a-blogcms.jp](https://developer.a-blogcms.jp/) で確かめて書いています。変数表やチュートリアルは書き写さず、「どれを選ぶか」の判断と、間違えやすい点と、公式ドキュメントへの案内に絞っています。

## 対象

- a-blog cms **Ver. 3.2 以上**（バージョンアップのスキルは、3.2 へ上げる前の 3.1 以前のサイトも扱います）
- テーマ・テンプレートを制作する方（標準テンプレートと Twig テンプレートの両方）
- プラグイン（拡張アプリ）を開発する方

a-blog cms 本体の開発用ではありません。

## スキル一覧

スキルは3つのプラグインに分かれています。サイトを制作する方は `acms-site-builder`、プラグイン（拡張アプリ）を開発する方は `acms-plugin-developer` を入れてください。`acms-common` はどちらにも依存関係として入ります。

### acms-common（共通）

| スキル | 内容 |
|---|---|
| [acms-router](skills/acms-router/SKILL.md) | a-blog cms に関する依頼を分類し、適切なスキルへ振り分ける |
| [acms-project-triage](skills/acms-project-triage/SKILL.md) | 作業対象のバージョン・テーマの継承・テンプレートの種類（標準 / Twig）・プラグイン（拡張アプリ）を判定する |
| [acms-upgrade](skills/acms-upgrade/SKILL.md) | バージョンアップ（Ver. 3.1 から 3.2 など）の共通の手順（版の判定・バックアップ・検証環境・本体の更新・本番への反映）と、要修正箇所の洗い出し |

### acms-site-builder（サイト制作）

| スキル | 内容 |
|---|---|
| [acms-static-to-theme](skills/acms-static-to-theme/SKILL.md) | 静的な HTML サイトを a-blog cms のテーマにする（CMS 化する）作業を最初から最後まで導く。静的サイトの調査スクリプト付き |
| [acms-theme-development](skills/acms-theme-development/SKILL.md) | テーマの構成・継承・template.yaml・テンプレートの探索、大規模サイトの設計と運用（子ブログ、環境間の移行、キャッシュ） |
| [acms-template-acms](skills/acms-template-acms/SKILL.md) | 標準テンプレート（BEGIN_MODULE、ブロック、変数、校正オプション、BEGIN_IF、@include） |
| [acms-template-twig](skills/acms-template-twig/SKILL.md) | Twig テンプレート（module()、touch()、フィルター、エスケープ、include / extends） |
| [acms-module-reference](skills/acms-module-reference/SKILL.md) | 目的に合うモジュールの選び方、モジュール ID、変数表の引き方 |
| [acms-form](skills/acms-form/SKILL.md) | メールフォーム（フォーム ID、バリデーター、コンバーター、確認画面、メールテンプレート） |
| [acms-custom-field](skills/acms-custom-field/SKILL.md) | カスタムフィールド・画像やメディアの入力欄・フィールドグループ・カスタムユニット |
| [acms-member-site](skills/acms-member-site/SKILL.md) | 会員制サイト（会員登録・ログイン・マイページ・会員限定のカテゴリーと記事・会員情報の項目・退会）と、会員限定の内容が漏れる経路 |
| [acms-upgrade-theme](skills/acms-upgrade-theme/SKILL.md) | バージョンアップでのテーマの修正（非推奨・削除されたモジュール、組み込み JS、ユニットの HTML と acms.css、表示崩れ） |

### acms-plugin-developer（プラグイン（拡張アプリ）開発）

| スキル | 内容 |
|---|---|
| [acms-plugin-development](skills/acms-plugin-development/SKILL.md) | プラグイン（拡張アプリ）の PHP 実装（ServiceProvider、Hook、独自モジュール、校正・検証オプション）、独自テーブル・テスト・配布 |
| [acms-admin-frontend-plugin](skills/acms-admin-frontend-plugin/SKILL.md) | 管理画面 JavaScript プラグイン（ACMS.plugins、ACMS.events、Slot）。Ver. 3.2.29 以降 |
| [acms-upgrade-plugin](skills/acms-upgrade-plugin/SKILL.md) | バージョンアップでのプラグイン（拡張アプリ）と extension/acms の修正（PHP の要件、SQL ヘルパー、削除された関数・クラス、Hook） |

### 依頼の例

- 「この静的サイトを a-blog cms のテーマにして」（[公式チュートリアル](https://developer.a-blogcms.jp/document/tutorial/)の題材でも試せます）
- 「トップページにお知らせの新着を5件出して」
- 「お問い合わせフォームを作って。電話番号は全角でも受け付けたい」
- 「エントリーにメイン画像の入力欄を足して」
- 「このテーマを Twig に移したい」
- 「会員だけが見られるお知らせのカテゴリーを作って」
- 「エントリーを公開したら Slack に通知するプラグインを作って」
- 「このサイトを 3.1 から 3.2 に上げたい」

## インストール

使っているエージェントに合わせて、どれか1つの方法で入れてください。

| エージェント | おすすめの方法 | ほかの方法 |
|---|---|---|
| Claude Code | [プラグイン](#claude-code) | [npx skills](#npx-skills)・[gh skill](#github-cligh-skill)・[手動](#手動) |
| Codex | [npx skills](#npx-skills) | [gh skill](#github-cligh-skill)・[手動](#手動) |
| GitHub Copilot | [gh skill](#github-cligh-skill) | [npx skills](#npx-skills)・[手動](#手動) |
| Cursor | [npx skills](#npx-skills) | [gh skill](#github-cligh-skill)・[手動](#手動) |
| Gemini CLI | [npx skills](#npx-skills) | [gh skill](#github-cligh-skill)・[手動](#手動) |
| そのほかの Agent Skills 対応エージェント | [npx skills](#npx-skills) | [手動](#手動) |

どの方法でも中身は同じ `skills/` です。インストールや更新のあとは、新しいセッションを始めると読み込まれます。

### Claude Code

このリポジトリは Claude Code の[プラグインのマーケットプレイス](https://code.claude.com/docs/en/discover-plugins)として追加できます。

```bash
# 1. マーケットプレイスとして追加する
claude plugin marketplace add appleple/acms-agent-skills

# 2. 必要なプラグインを入れる（acms-common は依存関係として自動で入ります）
claude plugin install acms-site-builder@acms-agent-skills
claude plugin install acms-plugin-developer@acms-agent-skills
```

セッションの中では `/plugin marketplace add appleple/acms-agent-skills` と `/plugin install acms-site-builder@acms-agent-skills` でも同じことができます。スキルは `/acms-site-builder:acms-form` のようにプラグイン名付きで表示されます。

- 既定では、自分のユーザー単位（すべてのプロジェクト）に入ります。リポジトリの全員で使うなら `--scope project` を付けます。
- 特定のリリースに固定するなら、マーケットプレイスをタグ付きで追加します（`claude plugin marketplace add appleple/acms-agent-skills#v0.1.0`）。

### npx skills

[Skills CLI](https://github.com/vercel-labs/skills) は、Claude Code・Codex・Cursor・GitHub Copilot・Gemini CLI など多くのエージェントのスキル置き場に入れられます。

```bash
# 入れられるスキルの一覧を見る（インストールはしない）
npx skills add appleple/acms-agent-skills --list

# すべてのスキルを入れる（入れ先のエージェントは対話で選ぶ）
npx skills add appleple/acms-agent-skills

# エージェントを指定して入れる
npx skills add appleple/acms-agent-skills -a codex
npx skills add appleple/acms-agent-skills -a cursor -a github-copilot

# 一部のスキルだけ入れる
npx skills add appleple/acms-agent-skills --skill acms-router --skill acms-project-triage --skill acms-form

# ユーザー単位（すべてのプロジェクト）に入れる
npx skills add appleple/acms-agent-skills -g -a codex
```

エージェント名は `claude-code`・`codex`・`cursor`・`github-copilot`・`gemini-cli` などです（[一覧](https://github.com/vercel-labs/skills/blob/main/docs/agents.md)）。一部だけ入れるときも、振り分けと構成の判定を担う `acms-router` と `acms-project-triage` は一緒に入れてください。ほかのスキルがこの2つを前提にしているためです。

### GitHub CLI（gh skill）

GitHub CLI v2.90.0 以降の `gh skill` で、スキルを1つずつ入れられます（GitHub CLI 側ではプレビュー機能です）。

```bash
# 入れる前に中身を確かめる
gh skill preview appleple/acms-agent-skills acms-form

# 1つのスキルを入れる（プロジェクト単位）
gh skill install appleple/acms-agent-skills acms-form --agent github-copilot

# ユーザー単位（すべてのプロジェクト）に入れる
gh skill install appleple/acms-agent-skills acms-form --agent codex --scope user

# リリースタグに固定して入れる
gh skill install appleple/acms-agent-skills acms-form --agent claude-code --pin v0.1.0

# すべてのスキルを入れる
gh skill install appleple/acms-agent-skills --all --agent cursor
```

`--agent` には `claude-code`・`codex`・`github-copilot`・`cursor`・`gemini-cli` などを指定できます（`gh skill install --help` で一覧が出ます）。

### Codex

Codex は、ユーザー単位では `~/.agents/skills/`、リポジトリ単位では `.agents/skills/` のスキルを読み込みます（[Codex のドキュメント](https://learn.chatgpt.com/docs/build-skills)）。[npx skills](#npx-skills)（`-a codex`）か [gh skill](#github-cligh-skill)（`--agent codex`）で入れるのが簡単です。手で置く場合は[手動](#手動)を見てください。

### GitHub Copilot

Copilot（Copilot CLI、VS Code などの agent mode、GitHub 上の Copilot cloud agent）は、リポジトリの `.github/skills/`・`.agents/skills/`・`.claude/skills/` と、個人用の `~/.copilot/skills/`・`~/.agents/skills/` を読み込みます（[GitHub のドキュメント](https://docs.github.com/en/copilot/concepts/customizations/agent-skills)）。チームで使うなら、リポジトリの `.github/skills/` に入れてコミットするのが確実です。

```bash
gh skill install appleple/acms-agent-skills --all --agent github-copilot
```

### Cursor

Cursor は `.cursor/skills/`・`.agents/skills/`（プロジェクト）と `~/.cursor/skills/`・`~/.agents/skills/`（ユーザー）を読み込みます。互換のため `.claude/skills/` も読み込みます（[Cursor のドキュメント](https://cursor.com/docs/skills)）。

```bash
npx skills add appleple/acms-agent-skills -a cursor
```

### Gemini CLI

Gemini CLI は `~/.gemini/skills/`・`~/.agents/skills/`（ユーザー）と `.gemini/skills/`・`.agents/skills/`（ワークスペース）を読み込みます（[Gemini CLI のドキュメント](https://geminicli.com/docs/cli/skills/)）。

```bash
npx skills add appleple/acms-agent-skills -a gemini-cli
```

Gemini CLI は Antigravity CLI への移行が案内されています。Antigravity でのスキルの置き場所は、Antigravity の公式ドキュメントで確かめてください。

### 手動

リポジトリを clone して、`skills/` 配下の必要なディレクトリを、エージェントのスキル置き場にコピーします。

```bash
git clone https://github.com/appleple/acms-agent-skills.git
cd acms-agent-skills

# Claude Code（プロジェクト単位 / ユーザー単位）
mkdir -p /path/to/project/.claude/skills && cp -r skills/* /path/to/project/.claude/skills/
mkdir -p ~/.claude/skills && cp -r skills/* ~/.claude/skills/

# Codex・Cursor・GitHub Copilot・Gemini CLI で共通に読まれる置き場所（ユーザー単位）
mkdir -p ~/.agents/skills && cp -r skills/* ~/.agents/skills/

# GitHub Copilot（リポジトリ単位）
mkdir -p /path/to/project/.github/skills && cp -r skills/* /path/to/project/.github/skills/
```

一部だけコピーするときも、`acms-router` と `acms-project-triage` は一緒にコピーしてください。

## 更新

スキルは、入れた方法ごとに更新の手順が違います。新しい版が出たかは [Releases](https://github.com/appleple/acms-agent-skills/releases) と [CHANGELOG](CHANGELOG.md) で確かめられます。

### Claude Code

このマーケットプレイスは、既定では**自動で更新されません**（Anthropic 公式以外のマーケットプレイスは、自動更新が既定でオフのため）。

```bash
# マーケットプレイスの一覧を最新にする
claude plugin marketplace update acms-agent-skills

# 入れているプラグインを更新する
claude plugin update acms-site-builder@acms-agent-skills
claude plugin update acms-plugin-developer@acms-agent-skills
claude plugin update acms-common@acms-agent-skills
```

- セッションの中で `/plugin` を開き、**Marketplaces** タブで `acms-agent-skills` を選んで **Update marketplace** を選ぶと、一覧の更新と、入れているプラグインの更新がまとめて行われます。
- 同じ画面の **Enable auto-update** を選ぶと、自動更新がオンになります。
- 更新しても、開いているセッションは読み込み済みの版を使い続けます。`/reload-plugins` を実行するか、新しいセッションを始めてください。
- `claude plugin update` が最新だと答えるのに内容が古いときは、先にマーケットプレイスの一覧を更新してください（上の1つ目のコマンド）。

### npx skills

```bash
# 入れているスキルをまとめて更新する
npx skills update

# 特定のスキルだけ更新する
npx skills update acms-form

# ユーザー単位（-g）・プロジェクト単位（-p）だけを更新する
npx skills update -g
```

### GitHub CLI（gh skill）

```bash
# 更新があるかだけ確かめる
gh skill update --all --dry-run

# 入れているスキルをまとめて更新する
gh skill update --all

# 入れているスキルの一覧
gh skill list
```

`--pin` で固定したスキルは更新の対象外です。固定を外して更新するときは `--unpin` を付けます。

### 手動

手動で入れた場合は自動では更新されません。`git pull` してから、同じ手順でコピーし直してください。

## バージョン

- このリポジトリは a-blog cms 本体とは独立した [Semantic Versioning](https://semver.org/lang/ja/) で、`vX.Y.Z` のタグと GitHub Release を作ります。スキルの削除・改名はメジャー、スキルの追加はマイナー、内容の修正はパッチです。
- スキルは a-blog cms Ver. 3.2.38 の本体ソースで確かめています。3.2.x の途中で入った機能には「Ver. 3.2.29 以降」のように注記しています。
- バージョンの扱いの詳細は [docs/compatibility.md](docs/compatibility.md) にあります。

## スクリプトの実行と外部通信

- `acms-project-triage` は、作業対象のファイルを読むシェルスクリプト（`scripts/detect.sh`）を含みます。読むのはテーマ・CSS・プラグイン（拡張アプリ）のディレクトリと、版を推定するための本体のファイルの有無だけで、DB 接続情報を含む `config.server.php` と `private/` は読みません。外部への通信もしません。
- `acms-upgrade` は、バージョンアップで直す箇所を洗い出すシェルスクリプト（`scripts/scan.sh`）を含みます。テーマ（`T-` で始まるチェック）とプラグイン（拡張アプリ）（`P-` で始まるチェック）の両方を調べ、それぞれの直し方は `acms-upgrade-theme`・`acms-upgrade-plugin` にあります。読むのは `themes/`（`system` を除く）と `extension/` だけで、`config.server.php`・`.env`・`private/` は読みません。外部への通信もしません。`acms-upgrade-theme`・`acms-upgrade-plugin` はスクリプトを含まず、`acms-upgrade` が入っていない環境では grep で探す文字列を案内します。
- `acms-static-to-theme` は、静的サイトの構成を調べるシェルスクリプト（`scripts/inventory.sh`）を含みます。読むのは指定した静的サイトのディレクトリだけで、外部への通信もしません。
- その他のスキルはスクリプトを含みません。エージェントが公式ドキュメント（developer.a-blogcms.jp）を Web から読むことがあります。

## フィードバック

不具合や要望は [Issue](https://github.com/appleple/acms-agent-skills/issues) でお知らせください。報告には、a-blog cms のバージョン、使ったエージェントとスキル、依頼した内容と、出力のうち誤っていた部分を書いてください。顧客名・サイトの URL・ログイン情報・`config.server.php` の内容は書かないでください。Pull Request は現在、社内からのみ受け付けています（[CONTRIBUTING.md](CONTRIBUTING.md)）。

## 参考リンク

- [Agent Skills の仕様](https://agentskills.io/specification)
- [a-blog cms 公式ドキュメント](https://developer.a-blogcms.jp/)
- [Claude Code のプラグイン](https://code.claude.com/docs/en/discover-plugins)
- [Skills CLI（npx skills）](https://github.com/vercel-labs/skills)

## ライセンス

[MIT](LICENSE)。a-blog cms 本体のライセンスとは別です。
