# テンプレートの決まり方

URL からどのテンプレートファイルが選ばれるかの要点。カテゴリー別・エントリー別のテンプレートを置くとき、「なぜこのテンプレートが表示されるのか」を調べるときに読む。

## 1 つのファイル名をテーマの中で探す順番

- 割り当てられたテーマ → 親テーマ → … → `system` の順に、同じ相対パスのファイルを探す。
- Twig が有効なテーマでは、`foo.html` を探すときに同じテーマの中で `foo.twig` → `foo.html.twig` → `foo.html` の順に見てから親テーマへ進む（Ver. 3.2.18 以降）。そのため、子テーマの `foo.html` は親テーマの `foo.twig` より優先される。
- テンプレートとして読まれる拡張子は `html`・`htm`・`twig`・`csv`・`xml`・`json` と、設定 `allow_template_extension` に書いたものに限られる（Ver. 3.2.22 以降）。`config.system.default.yaml` の既定値には `css`・`yaml`・`txt`・`js` も入っている。

## ページの種類ごとの基本テンプレート

| ページ | 使うキー（既定値） |
|---|---|
| ブログのトップ | `tpl_top`（`_top.html`） |
| 一覧（カテゴリーのトップ、タグ・キーワード・フィールドの検索結果など） | `tpl_index`（`index.html`） |
| エントリーの詳細 | `tpl_detail`（`_entry.html`） |
| 見つからないとき | `tpl_404`（`404.html`） |

公式テーマには `tpl_top` を `index.html` にしているものもある。実際の値は template.yaml とテーマ設定で確かめる。

## URL から探す順番（トップ・一覧・詳細）

ブログコードより後ろの URL のパス（以下 P）と、上の表のファイル名（以下 V）を使って、次の順に探し、最初に見つかったものを使う。

1. **P そのもの**: P と同じパスのファイルがテーマにあれば、それを使う。詳細ページで P に拡張子が無ければ `.html` を補う。
2. **P の末尾に V を付けたもの**: `P/V` を探し、無ければ P の末尾の階層を 1 つずつ削りながら探す（設定 `tpl_find_from_ascendants_ccd` が on のとき。既定は on）。
3. **テーマ直下の V**。
4. どれも無ければ `tpl_404` を 404 で表示する。

例: カテゴリー `sports/baseball` のエントリー `championship.html` の詳細ページ（V = `_entry.html`）

| 順番 | 探すファイル |
|---|---|
| 1 | `sports/baseball/championship.html` |
| 2 | `sports/baseball/championship.html/_entry.html` → `sports/baseball/_entry.html` → `sports/_entry.html` → `_entry.html` |

## カテゴリー別・エントリー別のテンプレート

| したいこと | 置くファイル |
|---|---|
| あるカテゴリーの一覧を変える | `<カテゴリーのパス>/<tpl_index の値>`（例: `news/index.html`） |
| あるカテゴリーの詳細を変える | `<カテゴリーのパス>/<tpl_detail の値>`（例: `news/_entry.html`） |
| 子カテゴリーにも同じテンプレートを使う | 親カテゴリーのディレクトリにだけ置く。上の 2 の遡りで子カテゴリーにも使われる |
| あるエントリーだけ変える | `<カテゴリーのパス>/<エントリーコード>`（例: `news/hello.html`）。カテゴリーが無いエントリーはテーマ直下に置く |
| 条件で部分的に出し分ける | ファイルを分けず、テンプレート内でタッチモジュール（Twig なら `touch()`）を使う |

- カテゴリーのパスは URL に現れるカテゴリーコードの並び。`category_order_strict_mode` が on（新規インストール時の既定）なら、子カテゴリーの URL は親からのパスになるので、ディレクトリも `sports/baseball/` のように入れ子にする。
- `tpl_detail` が `_entry.html` 以外のテーマでは、カテゴリー別のファイル名もその値に合わせる。

## URL とファイル名が一致すると、継承をたどって表示される

上の 1 により、P と同じパスのファイルがテーマの継承のどこかにあれば、それが表示される。ブログ・カテゴリー・エントリーに当たらない URL でも、テーマにファイルがあれば表示される。

このため、土台のテーマ `base` をルートブログに直接割り当て、ルートブログ専用の `campaign.html` を `base` に置くと、`news@base` を割り当てた子ブログの `/news/campaign.html` でも表示される（`news@base` の継承に `base` が含まれるため）。

- 設定 `forbid_tpl_inheritance_when_path_unresolved` を on にしても防げない。この設定が効くのは、ブログ・カテゴリーを解決した後に残った部分（`/news/sports/campaign.html` の `campaign.html` など）を探す経路だけで、上の 1 の経路は対象外。
- ファイル名の先頭を `_` にすると URL から開けなくなるが、ルートブログでも開けなくなる。
- 確実なのは、ブログに割り当てる子テーマ（`root@base`）を作り、ルートブログ専用のテンプレートをそこに置くこと。子ブログのテーマ（`news@base`）の継承に `root@base` は含まれないので、子ブログからは見えない。

## 直接表示を止める設定

設定は `private/config.system.yaml` に書く（`config.system.default.yaml` はアップデートで上書きされる）。

| 設定 | 働き | 既定 |
|---|---|---|
| `forbid_direct_access_tpl` | パスのどこかの階層がこの正規表現に一致するテンプレートを URL から直接表示しない。エントリー別のテンプレートには効かない | 新規インストールの `config.system.yaml` は `/^_/`。設定が無ければ off |
| `html_format_validate` | `<html>` と `<body>` を含まない出力を 404 にする。投稿者以上でログイン中は効かない | on |
| `forbid_direct_access_file` | `package.json`、ドットで始まるファイル、`*.config.js` などをテーマから表示しない（Ver. 3.2.9 以降） | 既定の一覧あり |
| `forbid_tpl_url_context` | URL の `tpl/...` によるテンプレート指定を、Ajax 以外では許さない | 新規インストールの `config.system.yaml` は on |
| `allow_tpl_path` | 上の制限から外すテンプレートの一覧 | 空 |

`/tpl/` 指定と Ajax の関係は <https://developer.a-blogcms.jp/document/security/forbid_tpl_url_context.html> を参照する。

## template.yaml で本体が読むキー

キーごとに子テーマ → 親テーマの順に template.yaml を見て、最初に値があるものを使う。どの template.yaml にも無ければテーマ設定（管理画面）の値、それも無ければ `config.system.default.yaml` の既定値になる。

| キー | 使われる場面 |
|---|---|
| `tpl_top` / `tpl_index` / `tpl_detail` | 上の表 |
| `tpl_404` | 見つからないとき |
| `tpl_admin` | 管理画面（未設定なら `admin.html`） |
| `tpl_twig` | `enabled` で Twig テンプレートを有効にする |
| `tpl_login` | 管理者のログインページ |
| `tpl_admin-reset-password` / `tpl_admin-reset-password-auth` / `tpl_admin-tfa-recovery` | 管理者のパスワード再設定・二段階認証の復旧 |
| `tpl_signin` / `tpl_signup` / `tpl_reset-password` / `tpl_reset-password-auth` / `tpl_tfa-recovery` | 一般会員のサインイン・登録・パスワード再設定・二段階認証の復旧 |
| `tpl_update-profile` / `tpl_update-password` / `tpl_update-email` / `tpl_update-fta` / `tpl_withdrawal` | 一般会員のマイページ（`tpl_update-fta` は二段階認証の設定。キー名のつづりはこのとおり） |

- 上の表に無いキー（`tpl_entry_edit` など）は Ver. 3.2.38 の本体では読まれない。書いても効かない。
- 403・500 などのエラー用テンプレート（`tpl_403`・`tpl_500` など）は template.yaml からは読まれない。変えるときは `private/config.system.yaml` に書く。
