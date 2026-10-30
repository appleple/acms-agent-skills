# Ver. X.Y への移行（移行元: Ver. X.(Y-1).x）: プラグイン（拡張アプリ）

<!--
新しい移行先を足すときの、acms-upgrade-plugin（プラグイン）の雛形。このファイルを to-X.Y.md としてコピーする。
同じ版の acms-upgrade の references/to-X.Y.md と scripts/checks/to-X.Y.tsv、acms-upgrade-theme の references/to-X.Y.md も揃える
（手順は acms-upgrade の references/_template.md と docs/compatibility.md）。SKILL.md の「移行先ごとのファイル」の表に 1 行足し、
evals/scenarios.json に、その版のプラグインの修正で失敗しやすい依頼を 1 件以上足す。

このファイルに書くもの: プラグイン（拡張アプリ）と extension/acms のユーザー拡張（PHP・管理画面の JavaScript）だけに関わる変更と、
テーマとプラグインの両方に関わる変更のうちプラグイン側の直し方。PHP の要件はプラグインのコードに関わる範囲で書き、
オンラインアップデートや DB の更新の詳細は acms-upgrade の to-X.Y.md に任せる。

書き方の決まり（AGENTS.md・docs/authoring-guide.md・docs/compatibility.md も読む）
- 公式の移行ガイドの本文・表を写さない。何を直すか・どう見つけるか・どう直すかに絞り、説明はリンクする。
- 書く内容は本体ソースで確かめる（php/ の差分、削除されたファイル、^function の比較、SQL ヘルパー・ファサード・Hook の変化）。
  移行ガイドに載っていない変更が多いので、ソースの比較を省かない。
- 「見つけ方」には、acms-upgrade の scan.sh のチェック ID（P-）と、acms-upgrade が入っていない環境のための grep で探せる文字列（「grep: `...`」）の両方を書く。
- 根拠の列には「本体ソースのパス:行（タグ付き）」か developer サイトの URL を書く。URL は curl で 200 を確かめる。
- 移行先の系列の途中で入った変更は「Ver. X.Y.NN 以降」と書く。
- 見出しは下の 6 つで固定する（3 スキルの to-X.Y.md で同じ見出しを使い、tsv の section 列と SKILL.md がこの名前を使う）。
-->

公式の移行ガイドは <!-- 版ごとの移行ガイドの URL -->。

見つけ方の `P-` で始まる ID は、acms-upgrade の `scripts/scan.sh` のチェック（定義は acms-upgrade の `scripts/checks/to-X.Y.tsv`）。acms-upgrade が入っていないときは、「grep:」に挙げた文字列で `extension/` を探す。`要確認` と付いたチェックは、直す箇所ではなく見比べる箇所を出す。

## 前提（移行元・PHP などの要件）

<!-- 移行元の版、PHP の範囲とプラグインのコードへの影響、配布プラグインの対応状況、直す場所。表の列: 項目 | 内容 | 根拠 -->

| 項目 | 内容 | 根拠 |
|---|---|---|

## 下位互換性のない変更

<!-- 更新すると動かなくなる PHP・JavaScript の書き方（SQL ヘルパー、削除された関数・クラス・モジュール、Hook の変化など）。1 行 1 変更。表の列: 変更 | 見つけ方（チェック ID と grep の文字列） | 直し方 | 根拠 -->

| 変更 | 見つけ方 | 直し方 | 根拠 |
|---|---|---|---|

## 非推奨になった機能と代替

<!-- 今は動くが将来消えるクラス・モジュールの継承や利用。表の列: 機能 | 代替 | 見つけ方 | 根拠 -->

| 機能 | 代替 | 見つけ方 | 根拠 |
|---|---|---|---|

## 直す手順

<!-- 作業の順番。配布プラグインの対応版の確認 → scan.sh（または grep）で P-* を直す → PHP の版の違いの確認 → scan.sh の再実行。実装の書き方は acms-plugin-development / acms-admin-frontend-plugin に任せる。 -->

## 移行後の確認

<!-- デバッグモードでのエラー・警告、監査ログ、scan.sh の再実行など、プラグイン側で観察できる確認項目。 -->

## 参考

<!-- 公式の移行ガイドのうちプラグインに関わるページと、動作条件のページの URL。 -->
