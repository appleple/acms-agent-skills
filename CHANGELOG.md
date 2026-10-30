# Changelog

形式は [Keep a Changelog](https://keepachangelog.com/ja/1.1.0/) に、バージョンは [Semantic Versioning](https://semver.org/lang/ja/) に従います。このリポジトリのバージョンは a-blog cms 本体のバージョンとは独立しています。

## [Unreleased]

## [0.1.0] - 2026-10-30

最初の公開バージョンです。a-blog cms Ver. 3.2 以上を対象に、15 のスキルを 3 つのプラグインに分けて提供します。仕様は a-blog cms Ver. 3.2.38 の本体ソースと公式ドキュメントで確かめています（3.2.x の途中で入った機能には、本文に導入バージョンを注記しています）。

### Added

- `acms-common`（共通）
  - acms-router: a-blog cms に関する依頼を分類し、担当のスキルへ振り分ける
  - acms-project-triage: 作業対象のバージョン・テーマの継承・テンプレートの種類・プラグイン（拡張アプリ）を判定する（`scripts/detect.sh`）
  - acms-upgrade: バージョンアップ（Ver. 3.1 から 3.2 など）の共通の手順と、要修正箇所の洗い出し（`scripts/scan.sh`）
- `acms-site-builder`（サイト制作）
  - acms-static-to-theme: 静的な HTML サイトを a-blog cms のテーマにする（`scripts/inventory.sh`・`scripts/check-blocks.sh`）
  - acms-theme-development: テーマの構成・継承・テンプレートの探索と、大規模サイトの設計・環境間の移行・キャッシュ
  - acms-template-acms: 標準テンプレートの記法
  - acms-template-twig: Twig テンプレートの記法（`acms_link()`・`acms_path()` は Ver. 3.2.39 以降）
  - acms-module-reference: モジュールの選び方とモジュール ID
  - acms-form: メールフォーム
  - acms-custom-field: カスタムフィールド・カスタムユニット
  - acms-member-site: 会員制サイト
  - acms-upgrade-theme: バージョンアップでのテーマの修正
- `acms-plugin-developer`（プラグイン（拡張アプリ）開発）
  - acms-plugin-development: プラグイン（拡張アプリ）の PHP 実装と、独自テーブル・テスト・配布
  - acms-admin-frontend-plugin: 管理画面の JavaScript プラグイン（Ver. 3.2.29 以降）
  - acms-upgrade-plugin: バージョンアップでのプラグイン（拡張アプリ）の修正
- 各スキルの評価シナリオ（`evals/scenarios.json`）
- スキルと marketplace.json の検証スクリプト（`scripts/validate-skills.mjs`）と CI
- GitHub Actions のアクションを更新する Dependabot と、CI 通過後の自動マージ
- タグ（`vX.Y.Z`）の push で、この CHANGELOG の節をリリースノートにした GitHub Release を作るワークフロー

[Unreleased]: https://github.com/appleple/acms-agent-skills/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/appleple/acms-agent-skills/releases/tag/v0.1.0
