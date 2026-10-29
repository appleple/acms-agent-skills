# acms-agent-skills

[a-blog cms](https://www.a-blogcms.jp) でサイト制作やプラグイン（拡張アプリ）開発を行う AI エージェント（Claude Code、GitHub Copilot、Codex、Cursor など）向けのスキル集です。[Agent Skills](https://agentskills.io/specification) の形式で書いているので、この形式に対応したエージェントならどれでも使えます。

## 対象

- a-blog cms **Ver. 3.2 以上**
- テーマ・テンプレートを制作する方（標準テンプレートと Twig テンプレートの両方）
- プラグイン（拡張アプリ）を開発する方

a-blog cms 本体の開発用ではありません。

## スキル一覧

| スキル | 内容 |
|---|---|
| [acms-router](skills/acms-router/SKILL.md) | a-blog cms に関する依頼を分類し、適切なスキルへ振り分ける |
| [acms-project-triage](skills/acms-project-triage/SKILL.md) | 作業対象のバージョン・テーマ・テンプレートの種類・プラグイン（拡張アプリ）を判定する |
| [acms-theme-development](skills/acms-theme-development/SKILL.md) | テーマの構成・継承・template.yaml・テンプレートの探索 |
| [acms-template-acms](skills/acms-template-acms/SKILL.md) | 標準テンプレート（BEGIN_MODULE、ブロック、変数、校正オプション、@include） |
| [acms-template-twig](skills/acms-template-twig/SKILL.md) | Twig テンプレート（module()、touch()、フィルター、include / extends） |
| [acms-module-reference](skills/acms-module-reference/SKILL.md) | 目的に合うモジュールの選び方、モジュール ID、変数表の引き方 |
| [acms-form](skills/acms-form/SKILL.md) | メールフォーム（フォーム ID、バリデーター、コンバーター、確認画面、メールテンプレート） |
| [acms-custom-field](skills/acms-custom-field/SKILL.md) | カスタムフィールド・画像やメディアの入力欄・フィールドグループ・カスタムユニット |
| [acms-plugin-development](skills/acms-plugin-development/SKILL.md) | プラグイン（拡張アプリ）の PHP 実装（ServiceProvider、Hook、独自モジュール） |
| [acms-admin-frontend-plugin](skills/acms-admin-frontend-plugin/SKILL.md) | 管理画面 JavaScript プラグイン（ACMS.plugins、ACMS.events、Slot） |

スキルの詳しい内容は、公式ドキュメント [developer.a-blogcms.jp](https://developer.a-blogcms.jp/) を正としています。スキル自体は判断の手順とドキュメントへの案内に絞っています。

## インストール

### npx skills

```bash
npx skills add appleple/acms-agent-skills
```

一部だけ入れる場合は `--skill acms-template-twig` のように指定します。

### GitHub CLI（v2.90.0 以降）

```bash
gh skill install appleple/acms-agent-skills acms-template-twig --agent claude-code --pin v0.1.0
```

`--pin` でリリースタグに固定できます。

### Claude Code のプラグイン

```bash
claude plugin marketplace add appleple/acms-agent-skills
claude plugin install acms-site-builder@acms-agent-skills
claude plugin install acms-plugin-developer@acms-agent-skills
```

| プラグイン | 含まれるスキル |
|---|---|
| `acms-common` | acms-router、acms-project-triage（下の2つを入れると依存関係として自動で入ります） |
| `acms-site-builder` | acms-theme-development、acms-template-acms、acms-template-twig、acms-module-reference、acms-form、acms-custom-field |
| `acms-plugin-developer` | acms-plugin-development、acms-admin-frontend-plugin |

### 手動

`skills/` 配下の必要なディレクトリを、利用しているエージェントのスキル用ディレクトリ（Claude Code なら `.claude/skills/`）へコピーします。

## スクリプトの実行と外部通信

- `acms-project-triage` は、作業対象のファイルを読むシェルスクリプト（`scripts/detect.sh`）を含みます。読むのはテーマ・CSS・プラグイン（拡張アプリ）のディレクトリだけで、DB 接続情報を含む `config.server.php` は読みません。外部への通信もしません。
- その他のスキルはスクリプトを含みません。エージェントが公式ドキュメント（developer.a-blogcms.jp）を Web から読むことがあります。

## フィードバック

不具合や要望は [Issue](https://github.com/appleple/acms-agent-skills/issues) でお知らせください。Pull Request は現在、社内からのみ受け付けています（[CONTRIBUTING.md](CONTRIBUTING.md)）。

## ライセンス

[MIT](LICENSE)。a-blog cms 本体のライセンスとは別です。
