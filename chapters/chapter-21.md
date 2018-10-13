## Alexa Skill backend概論
まずはAlexa Custom Skillのバックエンドについて簡単におさらいしましょう。

### バックエンドに使えるものは何か？
Alexa Custom Skillでは、以下の２種類をバックエンドに指定することができます。

- AWS Lambda
- Web API (HTTPS only)

AWS Lambdaの場合は、イベントトリガーにAlexaスキルを指定する必要があります。
外部のWeb APIを利用することもできるため、HerokuやElastic Beanstalkなどで作った自作のアプリケーションをAlexaのバックエンドにすることも可能です。
ただしWeb APIはHTTPSで接続できることが必須となりますので、必ずSSL化するようにしましょう。

### バックエンドの実装方法

AWS Lambda・Web APIどちらでもやることはシンプルです。
Alexaでは、Echoなどのデバイスで受け付けた音声を、ASR(自動音声認識)とNLU(自然言語処理)で解析します。
解析された結果は、JSON形式のデータとしてAWS LambdaまたはWeb APIに送信され、バックエンドではこれを処理する形となります。
レスポンスについても同様で、指定されたフォーマットのJSONを返してやることで、Alexaが音声に変換して各デバイスが再生するという形がとられています。

つまりはリクエスト・レスポンスの形式さえ理解すれば、webhookやWeb APIを作成するような感覚で音声アプリケーションが作成できます。

### Alexa Skills Kit SDK
とはいえリクエストの解析とレスポンスの作成を全て自力で行うことはとても大変です。
そこで私たちに用意されているのが`Alexa Skills Kit SDK`です。
SDKを利用することで、以下のサンプルのようにアプリケーションを作成することが比較的簡単となります。

```js
const Alexa = require('ask-sdk-core');

const LaunchRequestHandler = {
  canHandle(handlerInput) {
    return handlerInput.requestEnvelope.request.type === 'LaunchRequest';
  },
  handle(handlerInput) {
    const speechText = 'アレクサスキルへようこそ！';

    return handlerInput.responseBuilder
      .speak(speechText)
      .withSimpleCard('Hello World', speechText)
      .getResponse();
  },
};
```

本書を執筆している2018年9月現在、この`Alexa Skills Kit SDK`は以下の言語でリリースされています。

- Node.js: [https://github.com/alexa/alexa-skills-kit-sdk-for-nodejs](https://github.com/alexa/alexa-skills-kit-sdk-for-nodejs)
- Python: [https://github.com/alexa-labs/alexa-skills-kit-sdk-for-python](https://github.com/alexa-labs/alexa-skills-kit-sdk-for-python)
- Java: [https://github.com/alexa/alexa-skills-kit-sdk-for-java](https://github.com/alexa/alexa-skills-kit-sdk-for-java)

どの言語のSDKでも、おおよそ以下のような流れで実装する形となっております。

- １: `canHandle()`と`handle()`メソッドを持つクラス・オブジェクトを用意
- ２: `canHandle()`にて`handlerInput`の値を元に処理するインテントかを判定
- ３: `handle()`にて`handlerInput`の値を元に処理を実装
- ４：`responseBuilder`を利用してレスポンスを作成してreturnする
- ５：作成したクラス・オブジェクトを`addRequestHandlers()`で登録する

本書では、以降のコードサンプルはもっとも古くから存在するNode.js版を利用します。
コードの書き方は非常に似通ったものとなっておりますので、Python / Javaでの実装をお考えの方は各ドキュメントを元に適時読み替えながらお読みください。
