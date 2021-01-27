# GoodEats API
Lambda関数として配置し、API Gatewayでエンドポイントを設定
## 用途

### Request
- ユーザーが選択した飲食店のジャンルコードとエリアコード

### Response
- 条件に適合する飲食店の情報
 > [リクルートWEBサービス（ホットペッパーグルメ）](https://webservice.recruit.co.jp/doc/hotpepper/reference.html)から取得
- 該当する飲食店のレビュー5件
 > あらかじめ[バッチ処理](https://github.com/eikoh0117/goodeats-batch)で保存しておいたものをDynamoDBから取得
