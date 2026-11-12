# プラグイン（拡張アプリ）から REST API を拡張する（Ver. 3.3 以降）

Ver. 3.3.0-alpha.1 のソースで確かめた内容。プラグイン（拡張アプリ）の構成と ServiceProvider の基本は acms-plugin-development に従う。本体のソースが手元にあるときは、`Acms\Services\Facades\RestApi` と `Acms\Services\Facades\Mcp` の docblock、`extension/acms/Hook.php` の REST API の Hook のコメントを先に読む（そのバージョンで使える API と引数の形を表している）。

## どれを使うか

| したいこと | 使うもの |
|---|---|
| 独自のルートを足す | `RestApi::routes('<vendor>/v1', ...)` |
| 独自のスコープを足す | `RestApi::scopes('<vendor>', [...])` |
| エントリーなどコアのリソースの応答に項目を足す | `RestApi::extendResource()`（または Hook `extendsRestApiResource`） |
| 署名付きのリクエストなど独自の認証を使う | `RestApi::middlewareAlias()` に `authenticates: true` で登録し、ルートの `middleware` で選ぶ |
| 認証の後・呼び出しの前に共通の処理を挟む | `RestApi::middleware('after_authentication' | 'before_dispatch', ...)` |
| プラグインの設定キーを REST の設定 API に載せる | `RestApi::configSchema()`（秘密の値は `secret: true`） |
| API・MCP を使ってよいユーザーの判定を案件ごとに変える | Hook `extendsApiAccessAllowed`（トークンでのリクエストのたびに呼ばれるので重い処理を書かない。管理画面のセッションからの呼び出しでは呼ばれない） |
| 接続の通知メール（OAuth の接続・トークンの発行）の宛先や文面を変える・止める | Hook `beforeSendRestApiConnectionMail` |
| AI エージェントに独自の操作を出す | まずルートを足す（そのまま MCP のツールになる）。REST のルート 1 本に当たらない処理だけ `Mcp::tools()`（acms-mcp） |

- 登録はすべて `ServiceProvider::init()` で行う。ServiceProvider の無いユーザー拡張（`extension/acms/`）は Hook の `init()` で行う。
- 名前空間の `acms`・`mcp` は予約されている。`<vendor>` はプラグイン名など重ならない名前にする。

## ルートの形

```php
use Acms\Services\Facades\RestApi;
use Acms\Services\RestApi\Routing\RouteRegistrar;

RestApi::scopes('mysite', ['mysite:read' => '予約の読み取り']);
RestApi::routes('mysite/v1', function (RouteRegistrar $r): void {
    $r->get('/reservations', [ReservationController::class, 'index'], [
        'description' => '予約の一覧',   // 必須。openapi.json と MCP のツールの説明になる
        'scope' => 'mysite:read',
    ]);
});
```

- ハンドラは `ApiRequest` を受け取り、`ApiResponse::ok()` / `created()` / `collection()` を返す。失敗は `ApiException` を投げる（problem+json になる）。
- 主なオプション: `request`・`response`・`query`（スキーマ。openapi.json に載る）、`destructive`（削除などの上限と MCP のアクセスレベルの対象にする）、`audit`、`deprecated`、`mcp => false`（MCP のツールにしない）。
- 認証の既定は `auth`（トークン必須）。外すことはできず、差し替えるだけ。`auth.optional` は GET にだけ付けられ、トークンが無いときは公開してよいものだけを返す。
- 権限の確認はスコープだけに任せず、`permission` のオプションかハンドラの先頭で、管理画面と同じ権限を確かめる。
- Hook `extendsRestApiRoutes` でも登録できるが、引数の形が違い、そこで登録したスコープは発行画面に出ない。`RestApi::routes()` を使う。

## コアのリソースに項目を足す

- 足せるのは entries・categories・blogs・users・modules・rules・media。
- コアの項目を上書き・削除しない（違反になる）。項目名には接頭辞を付けて重ならないようにする。
- スキーマを渡すと openapi.json に読み取り専用で載る。

## 既存の拡張への影響

- 名前空間の無いグローバルの `RestApi` クラスを持つ拡張は、3.3 でファサードと衝突して致命的なエラーになる。クラス名を変える（acms-upgrade-plugin）。
