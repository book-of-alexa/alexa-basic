## スキルコンソールに反映

作成したスキルの雛形をAlexaデバイスで利用できるように、Alexa Skills Kit Developer Console（以下、スキルコンソール）にデプロイします。[https://developer.amazon.com/alexa/console/ask](https://developer.amazon.com/alexa/console/ask)

ASK CLIでデプロイを行うと、スキルの対話モデルとLambdaの両方がデプロイされます。

```console
$ ask deploy

-------------------- Create Skill Project --------------------
Profile for the deployment: [default]
Skill Id: amzn1.ask.skill.xxx
Skill deployment finished.
Model deployment finished.
Lambda deployment finished.
Lambda function(s) created:
  [Lambda ARN] arn:aws:lambda:us-east-1:xxx:function:ask-custom-alexa-book-default
Your skill is now deployed and enabled in the development stage.
Try invoking the skill by saying “Alexa, open {your_skill_invocation_name}” or simulate an invocation via the `ask simulate` command.
```

スキルコンソールを確認すると`alexa-book`というスキルが作成されています。

AWSのマネジメントコンソールからLambda Management Consoleを確認してみましょう。`ask-custom-alexa-book-default`というLambda関数が作成されています。
[https://console.aws.amazon.com/lambda/home?region=us-east-1#/functions](https://console.aws.amazon.com/lambda/home?region=us-east-1#/functions)

初回のデプロイが完了すると`.ask/config`に、スキルIDやLambdaのARNなどが上書きされます。次回以降のデプロイ時にはこれらの内容を見ながら既存のスキルに上書きされる仕組みです。

```json
 {
   "deploy_settings": {
     "default": {
+      "skill_id": "amzn1.ask.skill.xxx",
       ...省略
+      "resources": {
+        "manifest": {
+          "eTag": "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
+        },
+        "interactionModel": {
+          "ja-JP": {
+            "eTag": "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
+          }
+        },
+        "lambda": [
+          {
+            "arn": "arn:aws:lambda:us-east-1:xxx:
               function:ask-custom-alexa-book-default",
+            "functionName": "ask-custom-alexa-book-default",
+            "awsRegion": "us-east-1",
+            "alexaUsage": [
+              "custom/default"
+            ],
+            "revisionId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
+          }
+        ]
       }
     }
   }
```

ASK CLIの1.4.1では、Lambdaのリージョンを指定することができません。その為、Lambdaはバージニアにデプロイされます。東京リージョンにデプロイする場合にはServerless FrameworkやAWS SAMを利用する必要があります。

### オプション

指定できるオプションは次のとおりです。

#### --no-wait

通常はデプロイ時にスキルモデルのビルドの待機が発生しますが、この処理を非同期で行うようになります。

```console
$ ask deploy --no-wait

-------------------- Create Skill Project --------------------
Skill Id: amzn1.ask.skill.xxx
Skill deployment finished.

Model submitted. Please use the following command to track the model build status:
    ask api get-skill-status -s amzn1.ask.skill.xxx

Lambda deployment finished.
Lambda function(s) created:
  [Lambda ARN] arn:aws:lambda:us-east-1:xxx:function:ask-custom-alexa-book-default
```

#### --force

スキルコンソールからスキルのモデルを変更した場合にローカルファイルとの差分が発生します。この状態で`ask deploy`を行うと次のようなエラーが発生してデプロイが出来ません。

```console
$ ask deploy

-------------------- Update Skill Project --------------------
[Error]: The local stored [skill] eTag does not match the one on the server side.
Use "ask diff" to inspect the difference between local and remote.
Use "ask deploy --force" to deploy with the local project version regardless
of the eTag.
```

この時にローカルのファイルでスキルコンソールを上書きしたい場合に利用するのが`--force`オプションです。上書きしてしまうと元に戻すことはできなくなります。`ask deploy --force`する前には`ask diff`で差分を確認して本当に上書きして良いのか十分に確認してください。

#### --target / -t

`ask deploy`では、スキルのモデルやLambdaなど複数のリソースをデプロイします。これらを別々にデプロイする場合に利用できるのが`--target`です。指定できる値は、`all`、`lambda`、`skill`、`model`、`isp`です。デフォルトは`all`です。

```console
$ ask deploy -t model

Model deployment finished.
```

例えば、スキルモデルなどAlexaに関連するファイルは`ask deploy`でデプロイを行い、Lambdaは他の方法でデプロイを行う場合などに便利です。ただし、ターゲットを複数指定したい場合にはそれぞれでコマンドを分ける必要があります。

### 注意点

`ask deploy`は開発中のスキルにのみ実行することが可能です。例えば申請中のスキルに対して`ask deploy`を行うと次のようなエラーが発生します。

```console
$ ask deploy

-------------------- Update Skill Project --------------------
Updating skill...Call update-skill error.
Error code: 403
{
  "message": "Skill cannot be updated as it is in certification. Please withdraw
    from certification if you wish to update the skill or wait
    for the certification process to complete."
}
```

この様な場合には`ask withdraw`で申請を取り下げて開発中の状態に戻してから`ask deploy`する必要があります。

## simulateでスキルの動作確認

デプロイしたスキルはAmazon Alexaアプリから動作確認を行うこともできますが、`ask simulate`を使えばターミナルから動作確認を行うことが可能です。

デプロイしたスキルで動作確認を行ってみます。次のように入力して正しいレスポンスが返ってくれば成功です。

```console
$ ask simulate -t 'アレクサgreeterを開いて' -l ja-JP

Simulation created for simulation id: xxx
Waiting for simulation response{
"id": "xxx",
"status": "SUCCESSFUL",
"result": {
  ...
```

発話内容の`greeter`とは何でしょうか。これは、先程デプロイしたスキルの呼び出し名です。

`models/ja-JP.json`で指定されている`invocationName`が呼び出し名になります。ここに`greeter`という呼び出し名が登録されています。

```json
{
  "interactionModel": {
    "languageModel": {
      "invocationName": "greeter",
      ...省略
```

`models/~.json`の内容については公式リファレンスに記載されています。

Alexa Skills Kitのカスタム対話モデルのリファレンス | Custom Skills
[https://developer.amazon.com/ja/docs/custom-skills/custom-interaction-model-reference.html](https://developer.amazon.com/ja/docs/custom-skills/custom-interaction-model-reference.html)

### オプション

指定できるオプションは次のとおりです。

#### --text / -t

発話内容として指定したい文言をテキスト形式で指定します。上記では「アレクサgreeterを開いて」と指定しました。

#### --file / -f

`--text`で指定している発話内容を外部ファイルから指定きるのが`--file`オプションです。例えば次のように発話内容のファイルを作って指定することで外部ファイルから発話内容を読み込んでシミュレートすることが可能です。

```console
$ echo 'アレクサgreeterを開いて' > utterance.txt
$ ask simulate -f ./utterance.txt -l ja-JP
```

外部ファイルのパスは絶対パス、相対パスの両方で指定が可能です。

#### --locale / -l

どの言語のスキルに対してシミュレートを行うかを指定します。上記では日本語のスキルに対してシミュレートしたいので`ja-JP`としました。環境変数で`ASK_DEFAULT_DEVICE_LOCALE`として値を設定しておくと`--locale`の指定が不要になります。

#### --skill-id / -s

シミュレートしたいスキルのIDを指定します。未指定の場合には`.ask/config`内で指定してあるスキルIDが利用されます。

```console
ask simulate -t 'アレクサgreeterを開いて' -l ja-JP -s amzn1.ask.skill.xxx
```