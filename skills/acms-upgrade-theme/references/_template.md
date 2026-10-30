# Ver. X.Y への移行（移行元: Ver. X.(Y-1).x）: テーマ

<!--
新しい移行先を足すときの、acms-upgrade-theme（テーマ）の雛形。このファイルを to-X.Y.md としてコピーする。
同じ版の acms-upgrade の references/to-X.Y.md と scripts/checks/to-X.Y.tsv、acms-upgrade-plugin の references/to-X.Y.md も揃える
（手順は acms-upgrade の references/_template.md と docs/compatibility.md）。SKILL.md の「移行先ごとのファイル」の表に 1 行足し、
evals/scenarios.json に、その版のテーマの修正で失敗しやすい依頼を 1 件以上足す。

このファイルに書くもの: テーマ（テンプレート・CSS・テーマの JavaScript・template.yaml・管理画面のカスタムフィールド定義など）だけに
関わる変更と、テーマとプラグインの両方に関わる変更のうちテーマ側の直し方。要件や DB の更新は acms-upgrade の to-X.Y.md に書く。

書き方の決まり（AGENTS.md・docs/authoring-guide.md・docs/compatibility.md も読む）
- 公式の移行ガイドの本文・表を写さない。何を直すか・どう見つけるか・どう直すかに絞り、説明はリンクする。
- 書く内容は本体ソース（themes/system・js/config.js・php/ACMS/GET の差分と削除されたファイル）で確かめる。
- 「見つけ方」には、acms-upgrade の scan.sh のチェック ID（T-）と、acms-upgrade が入っていない環境のための grep で探せる文字列（「grep: `...`」）の両方を書く。
  scan.sh でも grep でも見つけられないものは、そう書き、どこで確かめるか（管理画面・表示）を書く。
- 根拠の列には「本体ソースのパス:行（タグ付き）」か developer サイトの URL を書く。URL は curl で 200 を確かめる。
- 移行先の系列の途中で入った変更は「Ver. X.Y.NN 以降」と書く。
- 見出しは下の 6 つで固定する（3 スキルの to-X.Y.md で同じ見出しを使い、tsv の section 列と SKILL.md がこの名前を使う）。
-->

公式の移行ガイドは <!-- 版ごとの移行ガイドの URL -->。

見つけ方の `T-` で始まる ID は、acms-upgrade の `scripts/scan.sh` のチェック（定義は acms-upgrade の `scripts/checks/to-X.Y.tsv`）。acms-upgrade が入っていないときは、「grep:」に挙げた文字列で `themes/`（`system` を除く）を探す。`要確認` と付いたチェックは、直す箇所ではなく見比べる箇所を出す。

## 前提（移行元・PHP などの要件）

<!-- 移行元の版、本体の更新前にしか取れないもの（旧 system のファイルなど）、直す場所。要件の詳細は acms-upgrade に任せる。表の列: 項目 | 内容 | 根拠 -->

| 項目 | 内容 | 根拠 |
|---|---|---|

## 下位互換性のない変更

<!-- 更新すると表示が変わる・効かなくなるテーマの記述。1 行 1 変更。表の列: 変更 | 見つけ方（チェック ID と grep の文字列） | 直し方 | 根拠 -->

| 変更 | 見つけ方 | 直し方 | 根拠 |
|---|---|---|---|

## 非推奨になった機能と代替

<!-- 今は動くが将来消えるモジュール・組み込み JS など。代替が移行元の版にもあるなら、本体更新の前に置き換えてよいと書く。表の列: 機能 | 代替 | 見つけ方 | 根拠 -->

| 機能 | 代替 | 見つけ方 | 根拠 |
|---|---|---|---|

## 直す手順

<!-- 作業の順番。scan.sh（または grep）→ 本体更新の前にできること → 更新後に見比べて直すこと（ユニットの HTML・上書き一覧）→ scan.sh の再実行。チェック ID で上の表を参照する。記法は acms-template-* に任せる。 -->

## 移行後の確認

<!-- 表示（ユニット・OGP など）・ブラウザーのコンソール・監査ログ・scan.sh の再実行など、テーマ側で観察できる確認項目。 -->

## 参考

<!-- 公式の移行ガイドのうちテーマに関わるページの URL。 -->
