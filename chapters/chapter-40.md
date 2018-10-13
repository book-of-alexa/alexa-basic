# Deploy & Delivery

Written by: Hidetaka Okamoto

## はじめに

この章では、作成したスキルの効率的なデプロイについて紹介します。
個人で開発・運用する場合だけでなく、会社・チームで開発する際にも応用できるアイデアなどをまとめました。

## ask deployのprop / cons

ここまでは、スキルの管理・デプロイにASK CLIを利用していました。
ここでデプロイの観点から、ASK CLIのメリット・デメリットについて再度確認してみましょう。

### ASK CLIのメリット
- スキルの初期セットアップやISPなどの機能追加が簡単
- 対話モデルやスキル情報をコードで管理できる
- AWS Lambdaもまとめて管理できる

### ASK CLIのデメリット
- AWS Lambdaはus-east-1固定
- Live / Developmentどちらも同じLambdaを使用する
- IAMポリシーの設定ができない

### ASK CLIをどこまで使うべきか？
先ほどのメリット・デメリットを見ると、「AWS Lambdaの扱い」によってASK CLIの利用範囲が決まりそうです。
大まかな目安としては、「AWSのリソースをどれだけ使いこなしたいか」が１つの判断基準です。

プロトタイプや初めて個人で開発に挑戦する場合なら、比較的シンプルなAWSリソース構成となります。
その場合はASK CLIが生成するリソースだけでおおよそまかなうことが可能です。
ですのでこういったケースではASK CLIのみを利用して、シンプルかつ素早くプロダクトを用意する方が良いでしょう。

一方で複数人での開発や、比較的高頻度でスキルの更新を行いたい場合を考えてみます。
この場合、Developmentスキルでしかまだ利用できない実装が含まれるケースや、AWSリソースを組み合わせた運用となるケースが考えられます。
ASK CLIでのデプロイの場合、IAMポリシーの制約やLive / DevelopmentでAWS Lambdaを分けられないという問題がでてきます。
そのため、このようなケースではAWS Lambdaのみ別のツールを利用して管理することとなります。

## LambdaとSkillの分割管理

ASK CLIのデプロイ対象からAWS Lambdaを外すためには、２つのファイル(本書執筆時点)を手動編集する必要があります。
また、差し替えにはデプロイ済のAWS Resource Name (ARN)が必要です。事前に後述の方法などでデプロイしておきましょう。

### skill.jsonを編集する
まずはスキル情報を記載している`skill.json`から更新します。
ここではこのファイルの`.manifest.apis`部分を変更します。
`ask new`で作成したプロジェクトの場合、以下のように記述されています。

```json
{
  "manifest": {
    "publishingInformation": {...},
    "apis": {
      "custom": {
        "endpoint": {
          "sourceDir": "lambda/custom"
        }
      }
    },
...
```

これは「カスタムスキル(`custom`)のエンドポイント(`endpoint`)に`lambda/custom`のソースコードを利用します」と読むことができます。
`sourceDir`で指定したディレクトリのファイルが、`ask deploy`でAWS Lambdaへデプロイされます。

別途デプロイされたAWS Lambdaを利用する場合、ここを以下のように変更します。

```json
{
  "manifest": {
    "publishingInformation": {...},
    "apis": {
      "custom": {
        "endpoint": {
          "uri":
            "arn:aws:lambda:{REGION}:{AWS_ACCOUNT_NO}:function:{FUNCTION_NAME}"
        },
        "regions": {
          "NA": {
            "endpoint": {
              "uri":
                "arn:aws:lambda:{REGION}:{AWS_ACCOUNT_NO}:function:{FUNCTION_NAME}"
            }
          }
        }
      }
    },
...

```
こちらでは、`endpoint`にて`sourceDir`ではなく`uri`を設定します。
外部APIの場合は`uri`にHTTPSのエンドポイントを、AWS Lambdaの場合はAWS LambdaのARNを指定しましょう。
またこちらの方法では、リージョン別にエンドポイントを指定する必要があります。

デフォルトのエンドポイントは`.custom.regions.NA`配下に定義しますので、`.custom.endpoint.uri`と同じ値をいれましょう。
これでスキル情報への反映が完了しました。

### .ask/configを編集する
次にASK CLI側の設定を更新します。
ASK CLIが利用する情報は、`.ask`ディレクトリに保存されています。
`ask new`で作成・デプロイしたプロジェクトでは、以下のような内容となります。

```json
{
  "deploy_settings": {
    "default": {
      "skill_id": "amzn1.ask.skill.XXXXXXXXXXXXXXXX",
      "was_cloned": false,
      "merge": {
        "manifest": {
          "apis": {
            "custom": {
              "endpoint": {
                "uri": "{FUNCTION_NAME}"
              }
            }
          }
        }
      },
      "resources": {
        "manifest": {
          "eTag": "xxxxxxxxxxxxxx"
        },
        "interactionModel": {
          "en-US": {
            "eTag": "xxxxxxxxxxxxxx"
          }
        },
        "lambda": [
          {
            "arn":
              "arn:aws:lambda:us-east-1:{AWS_ACCOUNT_NO}:function:{FUNCTION_NAME}",
            "functionName": "{FUNCTION_NAME}",
            "awsRegion": "us-east-1",
            "alexaUsage": [
              "custom/default"
            ],
            "revisionId": "XXXXXXXXXXXXXXXXxx"
          }
        ]
      },
      "in_skill_products": []
    }
  }
}

```

`{REGION}`や`{AWS_ACCOUNT_NO}`・`{FUNCTION_NAME}`など、`{}`で囲われている値は各自のアカウントに合わせて読み替えてください。

こちらの内容に基づいて`ask deploy`が実行されます。
このままでは`custom/default`のソースがAWS Lambdaへアップロードされますので、こちらも更新しましょう。

```json
{
  "deploy_settings": {
    "default": {
      "skill_id": "amzn1.ask.skill.XXXXXXXXXXXXXXXX",
      "was_cloned": false,
      "merge": {
        "manifest": {
          "apis": {
            "custom": {
              "endpoint": {
                "uri": "arn:aws:lambda:{REGION}:{AWS_ACCOUNT_NO}:
                function:{FUNCTION_NAME}"
              }
            }
          }
        }
      },
      "resources": {
        "manifest": {
          "eTag": "xxxxxxxxxxxxx"
        },
        "interactionModel": {
          "ja-JP": {
            "eTag": "xxxxxxxxxxxxx"
          }
        }
      },
      "in_skill_products": []
    }
  }
}

```

作業内容は以下のとおりです。

- `.merge.manifest.apis.custom.endpoint.uri`をAWS LambdaのARNに変更する
- `.resources.lambda`を削除する

ここまで変更することで、`ask deploy`でAWS Lambdaをデプロイすることなくスキルを更新することができます。
すでに`ask deploy`でデプロイを実行している場合、「`.ask/config`内のリビジョンと一致しない」というエラーがでることもあります。
その場合は、`ask diff`で予定外の箇所を変更していないか確認した上で、`ask deploy --force`で上書きしましょう。

## Case1: Serverless Framework

Serverless Frameworkは、AWSに限らず様々なクラウドサービスに対してアプリケーションをデプロイできるツールです。
[https://serverless.com/framework/](https://serverless.com/framework/)

Serverless Inc.によって開発されており、DashboardやEvent Gatewayなど様々なツール・サービスもリリースされています。

### serverless.ymlサンプル

比較的シンプルなサンプルを以下に用意しました。
DynamoDBの`{YOUR_SKILL_DB_NAME}`テーブルへのアクセスが可能なLambdaを作成します。


```yml
service:
  name: YOUR_SKILL_NAME

provider:
  name: aws
  runtime: nodejs8.10
  logRetentionInDays: 30
  iamRoleStatements:
    - Effect: "Allow"
      Action:
        - "dynamodb:*"
      Resource:
        - "arn:aws:dynamodb:{REGION}:*:table/{YOUR_SKILL_DB_NAME}"

functions:
  mySkill:
    handler: mySkill.handler
    events:
      - alexaSkill
```

`events`にてスキルIDを指定することもできます。

```yml
functions:
  mySkill:
    handler: mySkill.handler
    events:
      - alexaSkill:
          appId: amzn1.ask.skill.xx-xx-xx-xx
          enabled: true
```

Serverless Frameworkのプロパティについては、ドキュメントをご確認ください。
[https://serverless.com/framework/docs/providers/aws/guide/resources/](https://serverless.com/framework/docs/providers/aws/guide/resources/)

### ES-NextまたはTypeScriptでコードを記述する
Serverless Frameworkを利用する最大のメリットは、プラグイン機構にあります。

ビルド・デプロイ前にプラグインが実行されるため、事前準備を最小限に自由な記法でソースを書くことができます。

```console
# TypeScriptで実装する場合
$ sls create -t aws-nodejs-typescript -p {PROJECT_NAME} -n {PROJECT-NAME}

# ES-Nextで実装する場合
$ sls create -t aws-nodejs-ecma-script -p {PROJECT_NAME} -n {PROJECT-NAME}
```

どちらのオプションでも、WebpackやTypeScriptといったビルドに必要なツールを含めた状態でプロジェクトが作成されます。

また、本書執筆時点のASK CLIでは未対応のログ監視もServerless Frameworkでは可能です。

```console
$ sls logs -f {YOUR_FUNCTION_NAME} -t
```

### serverless-alexa-skillsでスキル開発

Serverless Frameworkには、これだけでスキル開発が可能となるプラグインがあります。
[https://www.npmjs.com/package/serverless-alexa-skills](https://www.npmjs.com/package/serverless-alexa-skills)

```console
$ npm i -g serverless
$ serverless plugin install --name serverless-alexa-skills
```

こちらを用いた場合、`serverless.yml`の中に対話モデルなどの情報をまとめることができます。

```yml
provider:
  name: aws
  runtime: nodejs8.10
 
plugins:
  - serverless-alexa-skills
 
custom:
  alexa:
    skills:
      - id: ${env:YOUR_ALEXA_SKILL_ID}
        skillManifest:
          publishingInformation:
            locales:
              en-US:
                name: test2
          apis:
            custom: {}
          manifestVersion: '1.0'
        models:
          en-US:
            interactionModel:
              languageModel:
                invocationName: hello
                intents:
                  - name: AMAZON.CancelIntent
                    samples: []
                  - name: AMAZON.HelpIntent
                    samples: []
                  - name: AMAZON.StopIntent
                    samples: []
                  - name: HelloWorldIntent
                    samples:
                    - hello
                    - say hello
                    - hello world
```

このプラグインの使い方については、作者が自身のブログにて日本語の記事を用意されています。

Alexa Skillの開発をServerless Frameworkだけで完結するための「Serverless Alexa Skills Plugin」の紹介
[http://marcy.hatenablog.com/entry/2017/12/14/000047](http://marcy.hatenablog.com/entry/2017/12/14/000047)

### Serverless FrameworkでのCD (Continuous Delivery) 継続的デリバリー

AWSへのデプロイ時にはCloudFormationテンプレートを作成し、それをデプロイする形をとっています。
そのため、AWS上ではCloudFormationとして扱われます。
ラッパーを通して利用するため、Code Pipelineなどのビルドツールと連携させる場合は後述のSAMの方が便利でしょう。

Serverless Frameworkを利用する場合は、GitHubからCircle CIをトリガーして`sls deploy`コマンドを実行することになるでしょう。


## Case2: AWS SAM

AWS SAMはAWS CloudFormationの拡張としてAWSから提供されているプロダクトです。
サーバーレスアプリケーションに使用するサービスの定義をより簡単に書くために作られました。

Serverless Frameworkと違い、AWS SAMは公式から提供されているという点が強みです。
CloudFormationとして扱うことができるため、Code Pipeline / Code Deploy / Service Catalogなどと組み合わせて利用することができます。
また、Serverless Application Repositoryというサービスを利用することで容易にAWS上でサードパーティアプリを利用・配布できます。

一方でCLIコマンドがベータ版のため、Serverless Frameworkと比較するとすこし不便さを感じる点もあります。

### SAMテンプレート

こちらがスキル向けのLambdaを定義したテンプレートサンプルです。

```yml
AWSTemplateFormatVersion: '2010-09-09'
Transform: AWS::Serverless-2016-10-31
Description: Example Alexa skill backend
Resources:
  HelloAlexaFuncLogGroup:
    Type: AWS::Logs::LogGroup
    Properties:
      LogGroupName: !Sub /aws/lambda/${HelloAlexa}
      RetentionInDays: 14
  HelloAlexa:
    Type: AWS::Serverless::Function
    Properties:
      Handler: index.handler
      Runtime: nodejs8.10
      Environment:
        Variables:
          SKILL_NAME: 'ハローアレクサ'
      Events:
        Alexa:
          Type: AlexaSkill

Outputs:
    HelloAlexaFunction:
      Description: "Hello Alexa Lambda Function ARN"
      Value: !GetAtt HelloAlexa.Arn
```

`AWS::Serverless::Function`がAWS Lambdaについてのプロパティです。
`Properties.Events`でAWS Lambdaをトリガーするイベントを定義します。ここで`AlexaSkill`を設定しましょう。
またCloudFormationの文法が利用できるため、CloudWatch Logsのログ保有期限をカスタマイズさせています。

### AWS SAMでのCD (Continuous Delivery) 継続的デリバリー

AWS SAMは「ビルド」と「デプロイ」の2段階でソースをAWS Lambdaへデプロイします。
AWS LambdaのソースコードをアップロードするS3バケットが必要ですので、事前にAWS Lambdaと同じリージョンに用意しましょう。

```console
# ビルド
$ aws cloudformation package --template-file ./template.yml
--output-template-file template-output.yml --s3-bucket 'YOUR_S3_BUCKET_NAME'

# デプロイ
$ aws cloudformation deploy
 --template-file ./template-output.yml --stack-name {STACK_NAME}
 --capabilities CAPABILITY_IAM --region {REGION}
```

Code PipelineでCI / CDパイプラインを構築する場合、ビルドをCode Build、デプロイをCode Deployで実行するフローとなるでしょう。

## Case3: 「AWS Lambdaを使わない」という選択肢

最後に「そもそもAWS Lambdaを使用しない」という方法についても紹介します。
Alexaスキルでは、処理部分のエンドポイントにAWS LambdaだけでなくHTTPS APIも指定できます。
そのためDockerでのWeb API開発に長けているチームなどでは、AWS Lambdaを使わない方が既存のワークフローにのれる可能性があります。
なおAWS Lambdaを使用しない場合、Alexaからのリクエスト内容を検証する必要がありますのでご注意ください。  
**Alexaから送信されたリクエストを処理する**  
[https://developer.amazon.com/ja/docs/custom-skills/handle-requests-sent-by-alexa.html#request-verify](https://developer.amazon.com/ja/docs/custom-skills/handle-requests-sent-by-alexa.html#request-verify)

AWSにはDockerをホストするためのサービスとして、Elastic BeanstalkやECS、Fargate、EKSなどがあります。
また、HTTPSのエンドポイントを提供する方法についても、Certificate ManagerやCloudFrontを組み合わせることで比較的簡単に実現できます。
これらのサービスを組み合わせることによって、社内で運用しているワークフローを活かしたスキルバックエンドのデプロイが実現できるかもしれません。

## 対話モデル・スキル情報のデプロイについて

ASK CLIの初期設定時、ブラウザからAmazonへアクセスする必要があります。

```console
 ask init -p cli --no-browser --debug
-------------------- Initialize CLI --------------------
Setting up ask profile: [cli]
? Please choose one from the following AWS profiles for skill's
  Lambda function deployment.
 (Use arrow keys)

Paste the following url to your browser:
         https://www.amazon.com/ap/oa?redirect_uri=xxxxxxxxx
         
? Please enter the Authorization Code:  

```

そのため、Circle CIやCode Deployなどでのセットアップは難易度が高くなります。
PuppeteerやSeleniumなどでブラウザ操作を実行するか、セットアップ完了後のクレデンシャル情報を環境変数に持たせるかになるでしょう。

Macの場合、`~/.ask/cli_config`にクレデンシャル情報が保存されています。

```json
{
  "profiles": {
    "default": {
      "aws_profile": "default",
      "token": {
        "access_token": "xxxxxxx",
        "refresh_token": "xxxxxxxx",
        "token_type": "bearer",
        "expires_in": 3600,
        "expires_at": "2018-09-05T03:45:17.880Z"
      },
      "vendor_id": "XXXXXXXXXx"
    }
  }
}
```

`access_token` / `refresh_token` / `expires_at` / `vendor_id`の4つを環境変数に格納し、それを元にファイルを復元することが現実的かもしれません。
また、AWSのクレデンシャルについても必要となります。
こちらはServerless Frameworkを利用して以下のようにセットアップすると良いでしょう。

```console
$ npm i -g serverless
$ serverless config credentials -k ${AWS_ACCESS_KEY} -s ${AWS_SECRET_KEY} -p aws
```

