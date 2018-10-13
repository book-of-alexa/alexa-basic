### Hello Alexa Skills Kit SDK

Node.js版のSDKはnpmからインストールすることができます。

```console
# もっともシンプルな使い方
$ npm i -S ask-sdk
```


#### sdk機能の部分利用

アプリケーションの実装方法によっては、SDK全ての機能を必要としない場合もあります。
その場合は、必要なモジュールだけをピックアップしてインストールすることができます。

```console
# レスポンス構築など、モデル部分のみ利用する
$ npm i -S ask-sdk-model

# コア機能のみ利用する
$ npm i -S ask-sdk-core
```

なお、`ask-sdk-core`を利用する場合、DynamoDBにアクセスするためのインタフェースを持つ`Standard Skill Builder`が利用できなくなりますので要注意です。

#### alexa-sdkとの互換性

初期からスキルを開発されている場合、`alexa-sdk`というNode.jsのSDKを使うことが少なからずありました。
現在のSDKには、このalexa-sdkと共存するためのadapterパッケージも用意されています。


```console
$ npm i -S ask-sdk-v1adapter
```

そしてLambda関数のコードを以下のように変更しましょう。

```js
- const Alexa = require('alexa-sdk');
+ const Alexa = require('ask-sdk-v1adapter');

exports.handler = function(event, context, callback) {
    const alexa = Alexa.handler(event, context, callback);
    alexa.appId = 'APP_ID'
    alexa.registerHandlers(handlers);
+    alexa.registerV2Handlers(V2IntentHandler)
    alexa.execute();
};

const handlers = {
    'HelloWorldIntent': function () {
        this.emit('こんにちは');
    },
...
}

+ const V2IntentHandler = {
+   canHandle: ({requestEnvelope}) =>
      requestEnvelope}.request.type === 'LaunchRequest',
+   handle: () => {
+     const speechText = 'ようこそ、アレクサスキルへ。こんにちは、と言ってみてください。';
+     
+     return handlerInput.responseBuilder
+         .speak(speechText)
+         .reprompt(speechText)
+         .withSimpleCard('Hello World', speechText)
+         .getResponse();
+   }
+ }
```

+マークの付いている部分のコードを追加し、-マークの部分を削除することで`ask-sdk`と`alexa-sdk`を共存させることが可能となります。