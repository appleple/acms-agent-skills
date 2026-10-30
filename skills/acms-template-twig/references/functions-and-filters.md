# Twig で使える a-blog cms の関数・フィルター・変数

`module()` の引数や戻り値で迷うとき、a-blog cms 独自の関数やフィルターを使うとき、値が空になる・エラーになる原因を探すときに読む。

## module()

```twig
{% set data = module('V2_Entry_Summary', 'news_list', { cid: 3, limit: 5 }) %}
```

| 引数 | 内容 |
|---|---|
| 第1引数 | V2 モジュール名（`V2_` で始まる）。必須 |
| 第2引数 | モジュール ID の識別子。省略するか `null` |
| 第3引数 | URL コンテキストのハッシュ。キーは `bid` `cid` `eid` `uid`（数値か数値の配列）、`page` `limit`、`keyword` `tag` `field` `order` `start` `end` |

- 戻り値は配列。HTML は返さない。中身（`items`、`pagination` など）はモジュールごとに違うので、デバッグモードの変数表（`Ctrl + K` → `#`）か、配布物の `themes/system/acms-code/snippets/v2_*.html` で確かめる。
- モジュール ID は、現在のブログのもの、または親ブログでグローバルに設定された公開中のものから探す。見つからなくてもエラーにはならず、モジュールの既定の設定で動く。設定が効かないときは、識別子・公開状態・ブログを確かめる。
- モジュール ID の設定画面で引数（ブログ・カテゴリーなど）を指定していると、第3引数より優先される。テンプレートで渡した値が効かないときは、モジュール ID の設定を確かめる。
- モジュール ID が指すエントリー・ブログを閲覧できない状態のときは、空の配列が返る。
- 存在しないモジュール名（打ち間違い）を渡すと、エラーにならず空の配列が返る。従来のモジュール名（`Entry_Summary` など）は呼べない。
- 戻り値の `moduleInfo` は管理者としてログインしているときだけ入る。`/admin/module/setting.twig` に渡して編集ボタンを出すのに使う。
- 同じ管理画面の設定を複数の場所で使い分けたいとき、キャッシュを効かせたいとき、編集ボタンからその場所の設定を開きたいときは、モジュール ID を作って第2引数に渡す（ID が無いと設定を場所ごとに持てない）。

公式: <https://developer.a-blogcms.jp/document/twig/module.html>、モジュール ID: <https://developer.a-blogcms.jp/document/moduleid/>

### カスタムフィールドの値

V2 モジュールが返すフィールドは、1 項目ごとに `{ value: 最初の値, array: すべての値 }` の形になる。

- 出力・比較には `.value` を付ける（`fields.color.value == 'red'`）。`fields.color == 'red'` は常に偽になる。
- チェックボックスなど複数の値は `.array` をループする。
- メディアやグループなどの形は acms-custom-field を読む。

## touch()

- `touch('Touch_Login')` のようにモジュール名だけを渡し、真偽値を受け取る。モジュール ID や引数は渡せない。
- 標準テンプレートのタッチモジュールはすべて呼べる。Twig の条件式なので `and` / `or` / `not` やグローバル変数と組み合わせられる。
- タッチモジュールの一覧: <https://developer.a-blogcms.jp/document/reference/touch.html>

## そのほかの関数・タグ

| 名前 | 内容 |
|---|---|
| `include(パス, 変数, with_context, ignore_missing)` | Twig 標準の `include` を a-blog cms が置き換えたもの。引数は同じ。デバッグモードでは前後にパスの HTML コメントを出す（Ver. 3.2.15 以降）。ignore_missing は名前付きで渡す（`ignore_missing = true`）か、タグで `{% include '/x.twig' ignore missing %}` と書く |
| `vite(エントリー, オプション)` / `viteReactRefresh()` | Vite でビルドしたアセットの読み込みタグを出す。標準テンプレートの `@vite()` にあたる。<https://developer.a-blogcms.jp/document/vite.html> |
| `acms_link(クエリ, オプション)` / `acms_path(クエリ, オプション)` | URL・パスを組み立てる（Ver. 3.2.39 以降）。下の「acms_link() と acms_path()」 |
| `acms_config(スコープ)` | コンフィグの値を読むオブジェクトを返す（Ver. 3.2.24 以降）。下の「acms_config()」 |
| `{% markdown %}…{% endmarkdown %}` | 囲んだ Markdown を HTML にして出す |
| `dump()` | 変数の中身を出す。デバッグモードのときだけ出力される |

## acms_link() と acms_path()

Ver. 3.2.39 以降。PHP の `acmsLink()` / `acmsPath()` を Twig から呼ぶ関数。

```twig
<a href="{{ acms_link({ bid: BID, cid: 3 }, { inherit: false }) }}">お知らせ</a>
<a href="{{ acms_link({ page: 2 }) }}">次へ</a>
<a href="{{ acms_link({ bid: BID, cid: cid, admin: 'category_edit' }, { inherit: false }) }}">編集する</a>
```

まず、URL が既にあるならそれを使う。V2 モジュールの戻り値の `url`（`entry.url` など）や `BLOG_URL` などのグローバル変数で足りるなら、関数で組み立て直さない。使うのは、戻り値に URL が無いとき、ID からカテゴリー・エントリーへのリンクを作るとき、今のページを基にページ番号やタグだけ変えるとき、管理画面へのリンク（編集ボタンなど）を作るとき。`/bid/1/admin/…` のように URL を文字列で直書きすると、セグメント名（`bid` `admin` など）やブログのコード・ドメインを変えたサイトで壊れるので、この関数で組み立てる。

| | `acms_link(クエリ, オプション)` | `acms_path(クエリ, オプション)` |
|---|---|---|
| 戻り値 | プロトコル・ドメインを含む URL（文字列）。必要に応じて末尾の `/`、`?…`、`#…` も付く | ドメインもサブディレクトリも含まないパス（先頭と末尾の `/` なし、例 `news/2026`）。`query` と `fragment` は付かない |
| 今のページの URL の引き継ぎ | 既定であり（`inherit: true`） | なし（渡したものだけ） |
| オプション（すべて `true` / `false`） | `inherit`（既定 `true`）、`explicitTpl`、`ignoreTplIfAjax`（既定 `true`） | `admin`、`baseId`（どちらも ID 形式のパス `bid/1/cid/3` にする）、`explicitTpl` |
| 使う場面 | `href` など、リンクに出す URL はこちら | ドメイン抜きのパスが要るとき（他の値と比べる・連結するなど）。サブディレクトリに置いたサイトでは `/` を付けても正しいリンクにならないので、リンクには `acms_link` を使う |

- クエリはハッシュで渡す。主なキーは `bid` `cid` `eid` `uid` `tag` `keyword` `page` `order` `limit` `tpl` `admin`（管理画面のページ名）、`acms_link` だけで効くものに `query`（`{ query: { a: 'b' } }` が `?a=b` になる）と `fragment`。
- `inherit: true`（既定）の挙動: `bid` も `cid` も `eid` も渡さないと、今のページのブログ・カテゴリー・エントリー・テンプレートに加えて、タグ・キーワード・並び順・フィールド検索・クエリ文字列まで引き継ぐ。`eid` だけを渡すと、ブログとカテゴリーはそのエントリーから決まり、タグ・キーワード・クエリ文字列などは今のページから引き継ぐ。`cid` だけを渡すと、ブログはそのカテゴリーから決まり、検索条件は引き継がない。ページ送りや絞り込みのリンク（`{ page: 2 }`）には便利だが、決まった場所への固定リンクに検索条件が混ざる。固定リンクは `{ inherit: false }` にして `bid` を必ず渡す（`inherit: false` で `bid` が無いと空文字が返る）。
- 第2引数は必ずハッシュ。PHP の `acmsLink($query, false)` のような真偽値・位置引数の旧形式、未対応のオプション名、`true` / `false` 以外の値（`'false'` や `1`）を渡すと、空になるのではなくエラーでページが表示されなくなる。第1引数も配列以外（文字列・`null`）はエラー。
- `admin` を渡すと管理画面の URL になる。ログインしている投稿者以上のときはパスが ID 形式（`bid/1/cid/3/admin/…`）になる。`admin: 'entry-edit'` / `'entry_editor'` は、エントリー編集画面の設定（管理画面で編集するか、ページ上で編集するか）に合わせて読み替えられる。URL を作るだけで権限は確かめないので、管理画面へのリンクは `touch('Touch_SessionWithContribution')` などで囲み、ログインしていない人に出さない（開けるかどうかはリンク先で判定される）。
- 戻り値は「安全」扱いではないので `{{ }}` で自動エスケープされる（`&` が `&amp;` になる）。属性値としてはそれで正しいので `|raw` は付けない。
- 同じサイトからの Ajax リクエストで読み込んだ部品の中では、既定（`ignoreTplIfAjax: true`）で `tpl` は URL に付かない。

## acms_config()

Ver. 3.2.24 以降。コンフィグ（ブログやコンフィグセットの設定値）を読むオブジェクトを返す。公開側のテーマでもプラグイン（拡張アプリ）の管理画面でも使える。

```twig
{% set config = acms_config() %}
{% if config.boolean('my_flag') %}…{% endif %}
<p>{{ config.persisted.get('site_title', '') }}</p>
```

| 引数 | 参照するコンフィグ |
|---|---|
| なし | 今のページに効いている値（ブログ・ルール・コンフィグセットなどを重ねた結果）。Ver. 3.2.24 では今のブログの保存済みの値だけで、ルールなどは重ならない |
| `{ blogId: 2 }`（Ver. 3.2.25 以降） | 指定したブログの保存済みの値（システムの既定値に重ねたもの）。ルールやモジュール ID の上書きは今のブログを基準に解決されるので、別のブログのルールの値は取れない |
| `{ configSetId: …}` / `{ ruleId: … }` / `{ moduleId: … }` | そのコンフィグセット・ルール・モジュール ID の値。`moduleId` を渡すと `configSetId` は無視される |

- 値の取り出し: `get(キー, 既定値)`、型をそろえるなら `string` `integer` `float` `boolean`（Ver. 3.2.25 以降。`boolean` は `on` / `off` などを真偽値にする）、複数値は `array(キー)`、`{ value, array }` の形で欲しいときは `field(キー)`、グループは `group(名前)`。どれも第1引数はコンフィグのキー名。
- 既定では、フォームから `config[]` の値が送信されたリクエストで、送信された値が保存済みの値より優先される（設定画面の再表示のため）。公開側で表示に使うだけなら `config.persisted.get(…)` にすると、送信された値が混ざらない。
- 権限を確かめずに値を返す。コンフィグには外部サービスの認証キーやシークレット、Basic 認証のパスワードなどの秘密の値も入るので、テンプレートでは必要なキーだけを出す。`all()` や `dump(config.all)` の結果をページに出さない。
- 戻り値を `{{ }}` で出すと自動エスケープされる。`selected()` / `checked()` は属性をそのまま出す（設定画面のフォーム用。プラグイン（拡張アプリ）の設定画面の作り方は acms-plugin-development）。
- 公式: <https://developer.a-blogcms.jp/document/twig/acms-config.html>

## フィルター（校正オプション）

- 校正オプションは、システムのもの・`extension/acms/Corrector.php` で足したもののどちらも、同じ名前のフィルターとして使える。校正オプションの引数はフィルターの引数として並べる（`|resizeImg(640)`、`|mb_trim(20, '…')`）。
- Twig 標準のフィルターと名前が重なるもの（Ver. 3.2.38 時点で `date` `escape` `nl2br` `number_format` `split` `striptags` `trim`）は Twig 側になる。a-blog cms バージョンは `acms_` を付けて呼ぶ。`acms_` 付きの名前は、重ならない校正オプションにも用意されている（`safe_html` を除く）。
- 校正オプション由来のフィルターの出力は、`safe_html` を除いて自動エスケープの対象になる。HTML を返すものの後ろには `|safe_html` を付ける。
- 校正オプションの一覧: <https://developer.a-blogcms.jp/document/reference/proofreading.html>、独自の校正オプション: <https://developer.a-blogcms.jp/document/user_corrector/>、Twig での使い方: <https://developer.a-blogcms.jp/document/twig/filter.html>

## グローバル変数

- 標準テンプレートの `%{BLOG_NAME}` は、Twig では `{{ BLOG_NAME }}`（`%{` `}` を外した名前）。条件式やフィルターにもそのまま使える。
- 値は文字列のものが多い（`IS_ADMIN` は `'1'` / `'0'`）。`{% if IS_ADMIN %}` は `'0'` を偽として扱うのでそのまま使える。
- 一覧: <https://developer.a-blogcms.jp/document/reference/global_variable.html>

## Twig の設定と、起きやすい誤り

a-blog cms の Twig は、自動エスケープが HTML、`strict_variables` が無効（既定のまま）、デバッグはデバッグモードに連動する。

- `strict_variables` が無効なので、存在しない変数や `a.b.c` の途中が無いものはエラーにならず空になる。変数名の打ち間違いに気付きにくいので、値が出ないときは変数表で名前を確かめる。前段の存在チェック（`{% if a and a.b %}`）は要らない。
- 否定は `!` ではなく `not`、論理演算は `&&` `||` ではなく `and` `or`、文字列の連結は `+` ではなく `~`。
- `|default('x')` が効くのは、未定義・`null`・空文字・`false`・空配列のとき。`0` には効かない。
- `{% for %}` の中で初めて `set` した変数は、ループの外では空になる。ループの後で使う値は、ループの前で `set` しておく（中で書き換えた値は外に残る）。
- ブロック名に使えるのは英数字とアンダースコアだけ（`head-js` は不可）。
