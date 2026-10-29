# Hook の選び方

公式ドキュメント:
- フック処理（引数と戻り値のリファレンス）: <https://developer.a-blogcms.jp/document/user_hook/user_hook.html>
- プラグイン（拡張アプリ）からの Hook の登録: <https://developer.a-blogcms.jp/document/develop_apps/entry-2910.html>

引数の型や書き方はリファレンスと、本体の `extension/acms/Hook.php`（そのバージョンで使える Hook がすべてコメント付きで並ぶ）で確かめる。ここでは「どれを選ぶか」と「どこで呼ばれるか」だけを書く。

## 前提

- Hook は `config.server.php` の `HOOK_ENABLE` が `1` のときだけ呼ばれる（既定は `0`）。ユーザー拡張もプラグイン（拡張アプリ）も同じ。
- ユーザー拡張は `extension/acms/Hook.php`（`Acms\Custom\Hook`）に書けば自動で登録される。プラグイン（拡張アプリ）は `ServiceProvider::init()` で `HookFactory::singleton()->attach('名前', new Hook())` する。
- 同じ Hook を複数のクラスが実装していると、登録順にすべて呼ばれる。参照渡しの引数は順に受け渡されるので、代入で上書きせず追記・加工する。
- `HookFactory::call()` は例外を受け止めない。呼び出し側も多くは受け止めないので、Hook の中で `catch (\Throwable $e)` して記録する。

## プラグイン（拡張アプリ）から受け取れない Hook

本体は、リクエストの処理の途中でプラグイン（拡張アプリ）の `ServiceProvider::init()` を呼ぶ。それより前に呼ばれる次の Hook は、プラグイン（拡張アプリ）の Hook クラスに書いても呼ばれない。ユーザー拡張の `Hook.php` に書く。

| Hook | 本体の呼び出し箇所 |
|---|---|
| `init` | `php/main.php`（起動直後）。プラグイン（拡張アプリ）では `ServiceProvider::init()` がこの代わりになる |
| `beforeAuthenticate` / `afterAuthenticate` | `php/main.php`（ログイン判定の前後） |
| `restrictionAuthority` | `php/main.php`（権限の確認） |
| `customRuleValue` | `php/main.php`（ルールの判定） |

`query`（SQL の発行前）も、`init()` より前に発行された SQL では呼ばれない。

## したいことから選ぶ

| したいこと | Hook | 本体の呼び出し箇所・注意 |
|---|---|---|
| エントリーの保存・公開に合わせて処理する（外部への通知など） | `saveEntry($eid, $revisionId)` | エントリーの作成・更新・公開・非公開・削除（ゴミ箱）・複製、ユニットの追加・更新、インポートで呼ばれる（`php/ACMS/POST/Entry/*.php` など）。「公開したとき」だけに絞るなら、エントリーのステータス（`ACMS_RAM::entryStatus($eid)`）を見て判定する。バージョンとして保存したときは `$revisionId` にリビジョン ID が入る。公開開始日時が来たときに呼ばれる Hook は無い |
| エントリーの複製の前後 | `beforeDuplicateEntry` / `afterDuplicateEntry` | Ver. 3.2.24 以降 |
| メディアの登録・更新 | `saveMedia($mid, $method, $isUpload)` | `php/ACMS/POST/Media/Upload.php` などの `try` の中で呼ばれる。例外を投げると、メディアは登録済みなのに画面には失敗と出る |
| ファイルの作成・削除を外部（CDN など）へ同期する | `mediaCreate($path)` / `mediaDelete($path)` | 画像・ファイル・メディアの保存と削除のたびに呼ばれる |
| フォームの送信後に処理する | `formSubmit($mail, $mailAdmin)` | 投稿データの保存後に呼ばれる。メールの送信に失敗しても呼ばれるので、送信結果は各メールの `status` で見る |
| 自動返信メールを条件で止める・変える | `beforeSendAutoReply` | Ver. 3.2.10 以降 |
| 投稿データのメール再送の前後 | `beforeResendFormMail` / `formMailResent` | Ver. 3.2.37 以降 |
| 承認の通知を差し替える | `approvalNotification($data, &$send)` | 承認の依頼・承認・却下・コメントで呼ばれる |
| テンプレート全体を書き換える | `beforeBuild(&$tpl)`（モジュール解決前） / `afterBuild(&$res)`（解決後） | `php/main.php`。ページキャッシュを返すときは呼ばれない |
| レスポンスの HTML を最後に加工する | `beforeResponse(&$res)` | `php/main.php`。ページキャッシュを返すときも呼ばれる（毎回走るので軽くする） |
| HTTP ヘッダーを足す | `header($cache)` | ページキャッシュを返すときは `true`、通常の描画では `false` で呼ばれる |
| ページキャッシュを条件で分ける | `addCacheRule(&$customRuleString)` | 値ごとに別のキャッシュになる。値の種類を増やしすぎない |
| 標準テンプレートの GET モジュールの前後に割り込む | `beforeGetFire(&$tpl, $module)` / `afterGetFire(&$res, $module)` | `php/ACMS/GET.php`。V2 モジュールでは呼ばれない |
| V2 モジュールの結果を加工する | `afterV2GetFire(array &$response, $module)` | `php/Modules/Get/V2/Base.php` |
| POST モジュールの前後に割り込む | `beforePostFire($module)` / `afterPostFire($module)` | `php/ACMS/POST.php`。CSRF の検証に通ったあとでだけ呼ばれる |
| グローバル変数を足す | `extendsGlobalVars(&$globalVars)` | references/corrector-validator-global-variables.md |
| インクルードのパスで使えるグローバル変数を足す | `addGlobalVarsInIncludePath(&$globalVarNames)` | テンプレートキャッシュが効きにくくなる。同上 |
| Twig の Filter / Function を足す | `extendsTwig($twig)` | Ver. 3.2.24 以降 |
| HTMLPurifier（危険なタグの除去）の許可を調整する | `extendsHtmlPurifierConfig` / `extendsHtmlPurifierDefinition` | Ver. 3.2.25 以降。定義はキャッシュされるので、変えたらキャッシュをクリアする |
| htmx の設定を変える | `extendsHtmxConfig(array &$config)` | Ver. 3.2.29 以降 |
| 埋め込みユニット・ビデオユニットの HTML や ID を差し替える | `extendsEmbedUnit`（Ver. 3.2.29 以降） / `extendsVideoUnit` | `extendsEmbedUnit` はブロックエディターの埋め込みブロックでは呼ばれない |
| ブロックエディターの出力 HTML を加工する | `filterBlockEditorHtml(&$html, $options)` | Ver. 3.2.24 以降。公開側の描画のときだけ呼ばれる |
| 全文検索の対象を調整する | `filterEntryFulltext` などの `filter*Fulltext` / `extendsSearchNormalization`（Ver. 3.2.29 以降） | `php/Services/Fulltext/Helper.php` |
| キャッシュのクリアに合わせて処理する | `cacheClear` / `cacheRefresh` | `php/ACMS/POST/Cache.php` |
| 本体が `unserialize` で復元してよいクラスを足す | `unserializeAllowedClasses(array &$classes)` | 追記する（`$classes[] = ...`） |
| リクエストの最後に処理する | `beforeShutdown` | シャットダウン時に呼ばれる |

## 例外の扱い

```php
public function saveEntry($eid, $revisionId)
{
    try {
        // 外部への通知など
    } catch (\Throwable $e) {
        \AcmsLogger::warning('MyPlugin: 通知に失敗しました', \Common::exceptionArray($e, ['eid' => $eid]));
    }
}
```

- 例外が本体まで届くと、`index.php` の最上位で受け止められてエラーとして記録され、デバッグモードでなければ何も表示されない画面になる。エントリーの保存は済んでいるので、「保存できたのにエラー画面になった」状態になる。
- 外部への通信には必ずタイムアウトを付ける。Hook は利用者のリクエストの中で同期して動くので、相手が応答しないと保存の操作がそのまま止まる。
