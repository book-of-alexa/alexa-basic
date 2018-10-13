## インストール

ASK CLIのインストールにはnpmを利用します。試した環境は下記の通りです。

```console
# 検証環境
macOS High Siera
npm 5.6.0
```

ASK CLIをインストールするにはターミナルでコマンドを実行します。

```console
$ npm install -g ask-cli
```

正しくインストールできていればバージョンを表示してみましょう。

```console
$ ask --version
1.4.1
```

ASK CLIを利用するにはAWSとAmazon開発者アカウントの認証情報が必要となります。

AWSの認証情報はLambdaの管理・デプロイに、Amazon開発者アカウントはスキルの管理や操作に利用します。

## セットアップ

それでは`ask init`で、それぞれの認証情報とASK CLIを紐付けてみましょう。

初めてAWSの認証情報を作成する場合には下記の様なメッセージが表示されます。すでに認証情報を作成済みの場合には新しいプロファイルを作成します。

```console
$ ask init
-------------------- Initialize CLI --------------------
? There is no AWS credentials file found in .aws directory, do you want to set up
  the credentials right now?(for lambda function deployment) (Use arrow keys)
> Yes. Set up the AWS credentials.
  No. Use the AWS environment variables.
  No. Skip AWS credentials association step.
  Abort the initialization process.
```

認証情報を作成しようとすると`AWS Access Key ID`と`AWS Secret Access Key`が必要となります。

AWSのIAMで必要なポリシーを設定したユーザーを作成します。最低限必要なポリシーは次の通りです。

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "iam:CreateRole",
        "iam:GetRole",
        "iam:AttachRolePolicy",
        "iam:PassRole"
      ],
      "Resource": "arn:aws:iam::*:role/ask-*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "lambda:AddPermission",
        "lambda:CreateFunction",
        "lambda:GetFunction",
        "lambda:UpdateFunctionCode",
        "lambda:ListFunctions"
      ],
      "Resource": "arn:aws:lambda:*:*:function:ask-*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:FilterLogEvents",
        "logs:getLogEvents",
        "logs:describeLogStreams"
      ],
      "Resource": "arn:aws:logs:*:*:log-group:/aws/lambda/ask-*"
    }
  ]
}
```

次にスキルを管理すためのAmazonの認証情報を紐づけます

AWSの認証情報の設定が終わるとブラウザが開きます。`Login with Amazon`を使ってAmazonの認証情報と紐づけます。

これでASK CLIからスキルの管理と、Lambdaの管理を行うことができるようになりました。

## スキルの雛形を作成する

それではASK CLIを使って新しいスキルを作成します。

スキルの作成には、`ask new`というコマンドを利用します。

オプションとして`-n {スキル名}`を追加することで、スキル名・ディレクトリ名を指定することができます。

```console
$ ask new -n alexa-book
```

このコマンドを実行すると、下記のような構成でファイルが出来上がります。

```console
alexa-book
├── .ask
│   └── config
├── lambda
│   └── custom
│       ├── index.js
│       ├── node_modules
│       ├── package-lock.json
│       └── package.json
├── models
│   └── en-US.json
└── skill.json
```

#### .ask/config

ASK CLIのための設定ファイルです。ファイルにはASK CLIで管理するためのスキルIDなどが記載されています。開発の時にこのファイルを直接触ることは殆どありません。

#### lambda/...

スキルのエンドポイントになるLambdaで利用するプログラムになります。プログラムの種類はNode.jsです。

ASK SDKはVer2になります。`lambda/custom/index.js`もVer2の形式で作成されます。

#### models/en-US.json

このファイルはインテントやサンプル発話、スロットなどスキル開発で必要な情報です。

ファイルは言語別にJSONファイルで作成します。

#### skill.json

スキルをストアに提出する為の、スキル名や説明、サンプルフレーズの情報です。

各ファイルの中身については、必要な箇所でそのつど説明します。

## スキルを日本語対応

次に先程作成したスキルの雛形を日本語化してみましょう。

### 日本語化

まずは、対話モデルの`models/en-US.json`を`models/ja-JP.json`にリネームします。

`models/~.json`は言語ごとにファイルを分けて作成します。2018年8月時点でAlexaに対応している言語は次のとおりです。

```
it-IT: イタリア語
en-US: 英語（米国）
en-CA: 英語（カナダ）
en-IN: 英語（インド）
en-AU: 英語（オーストラリア）
en-GB: 英語（英国）
de-DE: ドイツ語
fr-FR: フランス語
es-ES: スペイン語（スペイン）
es-MX: スペイン語（メキシコ）
ja-JP: 日本語
```

次に`skill.json`の`manifest/publishingInformation/locales`のキーを`en-US`から`ja-JP`に変更します。

```json
{
  "manifest": {
    "publishingInformation": {
      "locales": {
        "ja-JP": {
          ...
        }
      },
      ...
}
```

日本語対応に必要な最低限の修正はこれだけです。他の呼び出し名などは一旦そのままにしておきます。