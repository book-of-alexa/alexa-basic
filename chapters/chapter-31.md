## インストール

ASK CLIのインストールにはnpmを利用します。試した環境は下記の通りです。

```console
# 検証環境
macOS Mojave
npm 6.9.0
node 10.15.3
```

ASK CLIをインストールするにはターミナルでコマンドを実行します。

```console
$ npm install -g ask-cli
```

正しくインストールできていればバージョンを表示してみましょう。

```console
$ ask --version
1.7.1
```

ASK CLIを利用するにはAWSとAmazon開発者アカウントの認証情報が必要となります。

AWSの認証情報はLambdaの管理・デプロイに、Amazon開発者アカウントはスキルの管理や操作に利用します。

## セットアップ

それでは`ask init`で、それぞれの認証情報とASK CLIを紐付けてみましょう。

初めてAWSの認証情報を作成する場合には下記の様なメッセージが表示されます。すでに認証情報を作成済みの場合には新しいプロファイルを作成します。

```console
$ ask init
This command will initialize the ASK CLI with a profile associated with your Amazon developer credentials.
------------------------- Step 1 of 2 : ASK CLI Initialization -------------------------
Switch to "Login with Amazon" page and sign-in with your Amazon developer credentials.
If your browser did not open the page, run the initialization process again with command "ask init --no-browser".
ASK Profile "default" was successfully created. The details are recorded in ask-cli config ($HOME/.ask/cli_config).
Vendor ID set as Mxxx.
```

ASK CLIとAmazonのアカウントを紐付ける際に次のようなエラーが発生して上手く紐付かない場合があります。
これはブラウザで事前にAlexa Skill Consoleにログインしておき、`ask init`をすることで解決します。

```console
Call list-vendors error.
Error code: 401
{
  "message": "You are not authorized to access this operation."
}
```

Step2でAWSの認証情報を作成します。
コマンドラインの手順に従って`AWS Access Key ID`と`AWS Secret Access Key`を設定します。

IAMで最低限必要なポリシーは次の通りです。

```json
{
    "Version": "2012-10-17",
    "Statement": {
        "Effect": "Allow",
        "Action": [
            "iam:CreateRole",
            "iam:GetRole",
            "iam:AttachRolePolicy",
            "iam:PassRole",
            "lambda:AddPermission",
            "lambda:CreateFunction",
            "lambda:GetFunction",
            "lambda:UpdateFunctionCode",
            "lambda:ListFunctions",
            "logs:FilterLogEvents",
            "logs:getLogEvents",
            "logs:describeLogStreams"
        ],
        "Resource": "*"
    }
}
```

これでASK CLIからスキルの管理と、Lambdaの管理を行うことができるようになりました。

## スキルの雛形を作成する

それではASK CLIを使って新しいスキルを作成します。

スキルの作成には、`ask new`というコマンドを利用します。
実行すると対話形式で、Lambdaの言語の種類やTemplateの種類を聞いてきます。

```console
$ ask new
? Please select the runtime Node.js V8
? List of templates you can choose Feed
? Please type in your skill name:  alexa-basic-skill
Skill "alexa-basic-skill" has been created based on the chosen template
[Warn]: Changed the property name from 'skillManifest' to 'manifest' in skill.json in order to fit the v1 Alexa Skill Management APIs accepted format.
```

このコマンドを実行すると、下記のような構成でファイルが出来上がります。

```console
alexa-book
├── .ask
│   └── config
├── lambda
│   └── custom
│       ├── node_modules
│       ├── index.js
│       ├── package-lock.json
│       ├── package.json
│       ...
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