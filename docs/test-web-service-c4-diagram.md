c4 diagramの練習用

geminiに教えてもらった

```
レベル,名前,地図での例え,誰に見せる図？,何を描く？
Level 1,System Context(システムコンテキスト),世界地図,経営者・非エンジニア全ステークホルダー,システム全体と、ユーザーや外部システムとの関係。技術用語は使いません。
Level 2,Container(コンテナ),市町村地図,アーキテクト・開発リーダーインフラ担当,Webサーバー、DB、スマホアプリなど「個別にデプロイ・実行される単位」。一番よく使われます。
Level 3,Component(コンポーネント),詳細な街路図,開発者,1つのコンテナ（例：APIサーバー）の中身。「Controller」「Service」「Repository」などの構成要素。
Level 4,Code(コード),建物の設計図,開発者,クラス図やER図。細かすぎるため、手書きすることは稀で、ツールで自動生成するのが一般的です。
```

- アーキテクチャ

中〜大規模なECサイト（オンラインショップ）

<details><summary>詳細</summary>

サービス概要：ECサイト（オンラインストア）
ユーザーが商品の閲覧、カートへの追加、購入（決済）、そして注文完了メールを受け取るまでの機能を備えたWebサービスです。

1. エッジ・配信層 (CDN / LB)
「商品画像の高速表示」

役割: ユーザーはきれいな商品写真やバナー画像を大量に見ます。これらをWebサーバーがいちいち配信すると負荷が高すぎるため、CDNにキャッシュさせて、世界中どこからでも爆速で表示させます。

WAF: クレジットカード情報を扱うため、攻撃（SQLインジェクションなど）をここでブロックします。

2. アプリケーション層 (API / Web)
「買い物かごとレジ機能」

Web Server (BFF): スマホアプリやPCブラウザからのリクエストを受け付け、画面を表示するためのHTMLやJSONを返します。

API Server: 「在庫はあるか？」「クーポンの期限は切れていないか？」「合計金額はいくらか？」といった計算（ビジネスロジック）を行います。セール時などアクセスが集中したときは、ここの台数を自動で増やします（オートスケール）。

3. データ層 (Cache / DB)
「商品カタログとカートの中身」

Cache (Redis): **「カートの中身」や「ログイン中のユーザー情報」**をここに置きます。DBにいちいち問い合わせると遅いので、メモリ上で高速に出し入れします。

DB Replica (参照用): **「商品一覧の表示」**に使います。見るだけの人は圧倒的に多いので、参照専用のDBを複数用意して負荷を分散します。

DB Primary (書込用): **「購入確定（在庫を減らす）」**という絶対に間違ってはいけない処理だけは、親玉であるPrimary DBで行います。

4. 非同期・バッチ層 (Worker / Queue)
「注文完了メールと発送手配」

ユーザーが「購入」ボタンを押した瞬間、システムは「購入完了画面」を即座に出したいと考えます。

しかし裏側では、「メールを送る」「倉庫に出荷指示データを送る」「ポイントを付与する」など、時間がかかる仕事が残っています。

そこで、「とりあえず購入は受付済み」というメモをQueueに入れ、ユーザーにはすぐ「完了」を表示します。

裏で待機しているWorkerが、Queueからメモを取り出し、「メール送信」や「外部物流システムへの連携」をゆっくり確実に実行します。

</details>

```mermaid
graph TD
    %% 定義: クラスとスタイル
    classDef user fill:#d9c,stroke:#333,stroke-width:2px;
    classDef edge fill:#cce5ff,stroke:#333,stroke-width:2px;
    classDef compute fill:#d5e8d4,stroke:#82b366,stroke-width:2px;
    classDef data fill:#fff2cc,stroke:#d6b656,stroke-width:2px;
    classDef async fill:#e1d5e7,stroke:#9673a6,stroke-width:2px;

    %% クライアント層
    subgraph ClientLayer ["クライアント環境"]
        User((ユーザー / Browser / App)):::user
    end

    %% エッジ・配信層
    subgraph EdgeLayer ["エッジ / 配信層 (Public)"]
        CDN[CDN / DNS]:::edge
        WAF[WAF / Security]:::edge
        LB[Load Balancer]:::edge
    end

    %% アプリケーション層
    subgraph AppLayer ["アプリケーション層 (Private)"]
        WebServer[Web Server / Frontend]:::compute
        APIServer[API Server / Backend]:::compute
        Worker[Batch / Async Worker]:::async
    end

    %% データ層
    subgraph DataLayer ["データ永続化層 (Private)"]
        Cache[(Redis / Cache)]:::data
        DB_Primary[(RDBMS Primary)]:::data
        DB_Replica[(RDBMS Replica)]:::data
        ObjStorage[Object Storage]:::data
        MsgQueue>Message Queue]:::async
    end

    %% 接続関係
    User -->|HTTPS| CDN
    CDN --> WAF
    WAF --> LB

    LB -->|Static Assets| ObjStorage
    LB -->|Traffic| WebServer

    WebServer -->|API Call| APIServer

    APIServer -->|Read/Write| Cache
    APIServer -->|Write| DB_Primary
    APIServer -->|Read| DB_Replica

    %% 非同期処理の流れ
    APIServer -.->|非同期タスク登録| MsgQueue
    MsgQueue -->|Job Consume| Worker
    Worker -->|Batch Write| DB_Primary

    %% DBレプリケーション
    DB_Primary -.->|Replication| DB_Replica

    %% レイアウト調整用の不可視リンク
    Cache ~~~ DB_Primary
```

- level1

```mermaid
C4Context
    title System Context Diagram for EC Platform

    %% --- user ---
    Person(guest, "ゲスト利用者", "会員登録せずに商品を閲覧・検索する")
    Person(member, "会員ユーザー", "購入履歴を持ち、決済・お気に入り機能を利用する")

    %% --- system ---
    System(ec_platform, "ECプラットフォーム", "商品販売、在庫管理、受注処理を行う中核システム")

    %% --- staff ---
    Enterprise_Boundary(b1, "運営企業") {
        Person(merchandiser, "MD / 商品担当", "商品マスタ登録、価格設定、キャンペーン管理")
        Person(support, "カスタマーサポート", "注文キャンセル、返金対応、問い合わせ対応")
        Person(warehouse, "倉庫・物流スタッフ", "ピッキングリスト出力、出荷ステータス更新")
    }

    %% --- external service ---
    System_Ext(payment, "決済ゲートウェイ", "Stripe / PayPal")
    System_Ext(logistics, "配送業者システム", "ヤマト運輸 / 佐川急便")
    System_Ext(marketing, "MAツール / CRM", "Salesforce / SendGrid")

    %% --- relationship ---
    Rel(guest, ec_platform, "商品検索・閲覧", "HTTPS")
    Rel(member, ec_platform, "購入・決済・マイページ", "HTTPS")

    %% --- staff relationship ---
    Rel(merchandiser, ec_platform, "CMSで商品管理", "HTTPS / Admin UI")
    Rel(support, ec_platform, "管理画面で顧客対応", "HTTPS / Admin UI")
    Rel(warehouse, ec_platform, "出荷指示確認・実績登録", "Handy Terminal / HTTPS")

    %% external relationship ---
    Rel(ec_platform, payment, "決済処理", "API")
    Rel(ec_platform, logistics, "配送伝票発行・追跡番号取得", "API / CSV")
    Rel(ec_platform, marketing, "カゴ落ちメール・販促配信", "API")
```

- level2

```mermaid
C4Container
    title Container Diagram for Web Service System

    %% ステークホルダー
    Person(user, "一般ユーザー", "ブラウザやスマホアプリから利用")

    %% システム境界
    System_Boundary(c1, "Web Service System") {
        %% フロントエンド
        Container(spa, "SPA / Web App", "ブラウザ上で動作するフロントエンド")
        Container(mobile, "Mobile App", "ネイティブアプリケーション")

        %% エントリポイント
        Container(api_gw, "API Gateway / BFF", "ルーティング、認証、レート制限")

        %% バックエンド
        Container(backend_api, "Backend API", "ビジネスロジックを提供するコアAPI")
        Container(worker, "Async Worker", "非同期ジョブ、バッチ処理を実行")

        %% データストア
        ContainerDb(db, "Primary Database", "ユーザー情報、トランザクションデータの保存")
        ContainerDb(cache, "Cache", "Redis", "セッション、頻出データのキャッシュ")
        ContainerDb(obj_store, "Object Storage", "画像、静的ファイル、ログ")
    }

    %% 外部システム
    System_Ext(payment_system, "決済ゲートウェイ", "Stripe")
    System_Ext(mail_system, "メール配信サービス", "SendGrid")

    %% 関係定義
    Rel(user, spa, "利用する", "HTTPS")
    Rel(user, mobile, "利用する", "HTTPS")

    Rel(spa, api_gw, "APIコール", "JSON/HTTPS")
    Rel(mobile, api_gw, "APIコール", "JSON/HTTPS")

    Rel(api_gw, backend_api, "リクエスト転送", "gRPC / REST")

    Rel(backend_api, db, "Read/Write", "SQL")
    Rel(backend_api, cache, "Read/Write", "RESP")
    Rel(backend_api, obj_store, "Upload/Download", "HTTPS")

    Rel(backend_api, worker, "ジョブ登録", "Message Queue")
    Rel(worker, db, "Batch Write", "SQL")

    Rel(backend_api, payment_system, "決済実行", "API")
    Rel(worker, mail_system, "メール送信", "API")
```


- level2 商品購入フローのダイナミック図

```mermaid
C4Dynamic
    title Dynamic Diagram: 商品購入処理 (同期処理 + 非同期処理)

    %% --- 登場要素 (Level 2 コンテナ図 + 高解像度ステークホルダー) ---
    Person(member, "会員ユーザー", "ログイン済みの購入者")

    Container_Boundary(c1, "ECプラットフォーム") {
        Container(spa, "SPA / フロントエンド", "React", "ブラウザ上のカート画面")
        Container(api_gw, "API Gateway", "Nginx", "認証・ルーティング")
        Container(backend, "Backend API", "Go", "注文・決済ビジネスロジック")
        ContainerDb(db, "Primary DB", "PostgreSQL", "在庫・注文データ")
        Container(worker, "Async Worker", "Python", "メール・連携処理")
        ContainerDb(redis, "Message Queue", "Redis", "非同期タスクキュー")
    }

    System_Ext(payment, "決済ゲートウェイ", "Stripe API")
    System_Ext(mail, "メール配信サービス", "SendGrid API")

    %% --- 処理フロー (indexを利用して順序を明示) ---

    %% 1. フロントエンドからバックエンドへ
    Rel(member, spa, "1. 「購入する」ボタンをクリック")
    Rel(spa, api_gw, "2. 注文確定リクエスト (POST /orders)", "JSON/HTTPS")
    Rel(api_gw, backend, "3. リクエスト転送 (Auth済)", "gRPC")

    %% 2. 同期処理 (ビジネスロジック・決済・DB)
    Rel(backend, db, "4. トランザクション開始・在庫引当", "SQL")
    Rel(backend, payment, "5. クレジットカード決済実行", "HTTPS")
    Rel(payment, backend, "6. 決済成功応答", "JSON")
    Rel(backend, db, "7. 注文データ確定 (Commit)", "SQL")

    %% 3. 非同期タスク登録 (ここが境界線)
    Rel(backend, redis, "8. 「注文完了メール送信」タスクを登録", "RESP")

    %% 4. レスポンス返却 (ユーザーを待たせない)
    Rel(backend, api_gw, "9. 処理成功レスポンス", "JSON")
    Rel(api_gw, spa, "10. レスポンス転送", "JSON")
    Rel(spa, member, "11. 完了画面 (Thank Youページ) 表示")

    %% 5. 裏側の処理 (ワーカー)
    Rel(redis, worker, "12. タスク取得 (Consume)", "RESP")
    Rel(worker, db, "13. 注文詳細・会員情報の取得", "SQL")
    Rel(worker, mail, "14. 注文確定メール送信指示", "HTTPS API")
```
