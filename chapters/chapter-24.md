## Essential of ask-sdk
ここからは少し踏み込んだスキル開発について学びましょう。

### ask-utilsでコードをシンプルに
`ask-sdk`をそのまま使う場合、`handlerInput`から値を取り出す処理を都度書く必要があります。

```js
const HelpIntentHandler = {
  canHandle (handlerInput) {
    return handlerInput.requestEnvelope.request.type === 'IntentRequest' &&
      handlerInput.requestEnvelope.request.intent.name === 'AMAZON.HelpIntent'
  },
  handle (handlerInput) {
  ...
  }
}
```

ESLintなどで1行あたりのコード数を制限することが多いこともあり、ヘルパー関数を都度自作する必要がありました。
そこでよく使っているヘルパー関数群を`ask-utils`という名前のライブラリにまとめました。

[https://github.com/ask-utils/ask-utils/wiki](https://github.com/ask-utils/ask-utils/wiki)

```console
# インストール
$ npm i -S ask-utils
```

`canHandle`での判定を、以下のように変えることができます。

```js
const { canHandle } = require('ask-utils')
const HelpIntentHandler = {
  canHandle (handlerInput) {
    return canHandle(handlerInput, 'IntentRequest', 'AMAZON.HelpIntent')
  },
  handle (handlerInput) {
  ...
  }
}
```

また、handlerInputの値をピンポイントで取り出す関数が多数用意されています。

```js
# intentオブジェクトを取得する
const intent = getIntent(handlerInput)

# ユーザーIDを取得する
const userId = getUserId(handlerInput)

# Echo Spotなど、ディスプレイ端末デバイスかを判定する
const hasDisplay = supportsDisplay(handlerInput)
```

本節以降のサンプルコードでは、このask-utilsを利用してコード量を削減していることがあります。
本書をお読みのあなたからのフィードバックや意見をいただき、より便利なライブラリへしていきたいと思いますのでご協力よろしくお願いします。

ask-utilsへのフィードバック： [https://github.com/ask-utils/ask-utils/issues](https://github.com/ask-utils/ask-utils/issues)


### 会話にセッション情報を持たせる
ここまでの実装では、話しかけられた内容に対してその場で返事を作るものでした。
しかし会話の流れによって意味合いが変わってくる言葉も少なくありません。

たとえば「保存しますか？」という質問に対する「はい」と、「削除しますか？」という質問に対する「はい」では挙動が全く異なります。
このようなケースでは、事前の返答を作成する時点でセッションに状態を持たせることで、文脈に応じた入力を受け付けることができます。

以下のサンプルでは、セッションに応じて`AMAZON.YesIntent`で実行するハンドラーを振り分けています。
`state`が`save`の場合は保存処理を実行するハンドラーが実行されます。
そして`state`が`delete`の場合は削除処理のハンドラーが実行されます。

```js
const {
  canHandle
} = require('ask-utils')

const SaveItemHandler = {
  canHandle (handlerInput) {
    if (canHandle(handlerInput, 'IntentRequest', 'SaveItemIntent')) return true
    if (canHandle(handlerInput, 'IntentRequest', 'AMAZON.YesIntent')) {
        const attributes = handlerInput.attributesManager.getSessionAttributes()
        return attributes.state === 'save'
    }
    return false
  },
  async handle (handlerInput) {
    // ここに保存処理を書く
    return handlerInput.responseBuilder
        .speak('データを保存しました。')
        .getResponse()
  }
}

const ConfirmHandler = {
  canHandle (handlerInput) {
    return canHandle(handlerInput, 'IntentRequest', 'ConfirmIntent')
  },
  handle (handlerInput) {
    handlerInput.attributesManager.setSessionAttributes({state: 'save'})
    return handlerInput.responseBuilder
        .speak('時間を記録しますか？')
        .reprompt('時間を記録しますか？終了する場合は、ストップと言ってください。')
        .getResponse()
  }
}

const DeleteHandler = {
  canHandle (handlerInput) {
    return canHandle(handlerInput, 'IntentRequest', 'DeleteIntent')
  },
  handle (handlerInput) {
    handlerInput.attributesManager.setSessionAttributes({state: 'delete'})
    return handlerInput.responseBuilder
        .speak(データを削除しますか？')
        .reprompt('データを削除しますか？終了する場合は、ストップと言ってください。')
        .getResponse()
  }
}

const DeleteItemHandler = {
  canHandle (handlerInput) {
    if (canHandle(handlerInput, 'IntentRequest', 'AMAZON.YesIntent')) {
        const attributes = handlerInput.attributesManager.getSessionAttributes()
        return attributes.state === 'delete'
    }
    return false
  },
  async handle (handlerInput) {
    // ここに削除処理を書く
    return handlerInput.responseBuilder
        .speak('データを削除しました。')
        .getResponse()
  }
}
```

サンプルでは、状態を保存するために利用していますが利用方法は他にも様々です。
例えばクイズゲームの正解や解説文を出題時にセッションへ保存し、正解を発表するインテントではセッションから情報を取り出すことができます。
地域情報を調べるスキルでは、駅名や町名をセッションに保存することで毎回駅名を言い直す必要がなくなります。

#### AMAZON.RepeatIntentを活用する
クイズゲームや雑学スキルなどでは、発話内容をもう一度聞きたい場合があります。
その場合に利用するのが`AMAZON.RepeatIntent`というインテントです。
このインテントを対話モデルに組み込むことで、「もう一度言って」のような発話を簡単にハンドルできます。

そして`AMAZON.RepeatIntent`のバックエンド処理では、事前にセッションへ保存された内容を発話するように実装します。

```js
const FactIntentHandler = {
  canHandle (handlerInput) {
    return canHandle(handlerInput, 'IntentRequest', 'AMAZON.FactIntent')
  },
  handle (handlerInput) {
    const content = {
      title: `福岡ソフトバンクホークスの監督`,
      content: '福岡ソフトバンクホークスの監督は工藤公康氏'
    }
    handlerInput.attributesManager.setSessionAttributes({
      repeatContent: content
    })
    return handlerInput.responseBuilder
        .speak(`${content.content}です。もう一度聞きますか？`)
        .reprompt('もう一度聞きますか？それとも終了しますか？')
        .withSimpleCard(content.title, content.content)
        .getResponse()
  }
}

const RepeatIntentHandler = {
  canHandle (handlerInput) {
    return canHandle(handlerInput, 'IntentRequest', 'AMAZON.RepeatIntent')
  },
  handle (handlerInput) {
    const { repeatContent } = handlerInput.attributesManager.getSessionAttributes()
    const reprompt = '他に聞きたいことはありますか？'
    if (!repeatContent || !repeatContent.speak) {
      return handlerInput.responseBuilder
        .speak(`すみません。コンテンツが見つかりませんでした。${reprompt}`)
        .reprompt(reprompt)
        .getResponse()
    }
    return handlerInput.responseBuilder
      .speak(`${repeatContent.content}${reprompt}`)
      .reprompt(reprompt)
      .withSimpleCard(repeatContent.title, repeatContent.content)
      .getResponse()
  }
}
```

### DynamoDBでデータの永続化
スキルによっては、会話（セッション）が終わってからも利用したい情報もあります。
そんな場合、一般的にはデータの保存・読み出しにDynamoDBを利用します。

#### DynamoDBへのアクセス方法

DynamoDBを利用する方法としては、「ask-sdkのヘルパー関数を利用する」「aws-sdkから自作する」の２つがあります。
それぞれのメリット・デメリットは以下の通りです。

##### ask-sdkを使うメリット

- aws-sdkやDynamoDBの知識なしで使える
- テーブルの作成も任せることができる
- userIDやattributesなどをよしなに保存してくれる

##### ask-sdkを使うデメリット
- attributesがMap型で保存されるので、外部から扱いにくい
- put / get以外の操作はできない
- プライマリキーのみなので原則上書き保存

##### ask-sdkが向いているケース
ask-sdkから利用する場合、「userIdからアイテムを取得する」という挙動をします。
そのため設定情報やセッションを跨いで利用したい情報の一時保存などに利用することで、実装工数を短縮することができます。

- スキルの起動回数に応じて返答をカスタマイズ
- 「続きから再生」機能の実装
- 利用地域や通知時間などのアカウント情報管理

##### aws-sdkを使うメリット・デメリット

- [メリット] DynamoDBに自由にアクセスできる
- [デメリット] aws-sdkやDynamoDBのオペレーションを覚える必要がある

##### aws-sdkが向いているケース
- webアプリなどからも参照したいデータの取り扱い
- 体重の遷移など、後で参照・集計したいデータの保存
- すでに別のサービスなどで利用しているテーブルを使いたい場合

##### ask-sdk vs aws-sdk ?
ここまでそれぞれのSDKを使ってDynamoDBにアクセスした場合のメリット・デメリットなどを紹介しました。
どちらのSDKも競合ではなく、互いを補完するように利用することができます。
たとえば、スキルの設定情報やパーソナライズについてはask-sdkからDynamoDBへアクセスします。
そしてスキルから登録したデータはaws-sdkからDynamoDBに保存して、webサービスからもデータを閲覧できるようにするということも可能です。
その場合はテーブルをそれぞれで作成する方法が無難でしょう。
またask-sdkがuserIDからgetするという性質を利用して、aws-sdkからはask-sdkでは使用しない値をプライマリキーにしてGSI(グローバルセカンダリインデックス)でクエリするという方法も考えられます。


#### ask-sdkからDynamoDBにアクセスする際のTips
ここからはask-sdkからDynamoDBにアクセスする方法について紹介します。

##### ask-sdkが利用するDynamoDB API
ソースコードを読む限りでは、以下のAPIを利用します。
IAMロールを作成する場合は、これらのAPIを実行できるようにしましょう。

- CreateTable
- PutItem
- GetItem

作成したロールをLambdaへ適応することも忘れないようにご注意ください。

##### skillBuilderをcustomからstandardに変更する
チュートリアルなどでスキルを作成した場合、skillBuilderはcustomを利用しています。
しかしDynamoDBへアクセスするヘルパー関数を利用する場合は、これをstandardに変更する必要があります。

また、Alexaオブジェクトについても`ask-sdk-core`ではなく`ask-sdk`から参照するようにしてください。

```js
- const Alexa = require('ask-sdk-core')
+ const Alexa = require('ask-sdk')

- const skillBuilder = Alexa.SkillBuilders.custom()
+ const skillBuilder = Alexa.SkillBuilders.standard()
```

##### テーブル名の登録
ask-sdk経由でアクセスするDynamoDBのテーブル名は、`withTableName()`メソッドで登録できます。
また、`withAutoCreateTable()`を組み合わせることでテーブルが存在しない場合に自動作成します。

以下のサンプルでは、`MyExampleTable`というテーブルを利用し、存在しない場合はテーブル作成も実施します。

```js
exports.handler = skillBuilder
    .addRequestHandlers(YOUR_HANDLERS...)
    .addErrorHandlers(YOUR_ERROR_HANDLER)
    .withTableName('MyExampleTable')
    .withAutoCreate(true)
    .lambda()
```

##### DynamoDBへのデータの保存
DynamoDBへのアクセスは、`handlerInput.attributesManager`を利用します。
`setPersistentAttributes()`メソッドで保存したいアイテムを登録し、`savePersistentAttributes()`でテーブルにputします。

```js
const SaveProfileHandler = {
  canHandle(handlerInput) {
    ...
  },
  async handle(handlerInput) {
    const persistentAttributes = {
        name: 'おかもと',
        age: 28
    }
    await
      handlerInput.attributesManager.setPersistentAttributes(persistentAttributes)
    await handlerInput.attributesManager.savePersistentAttributes()
    ...
  }
}
```


##### DynamoDBからのデータの取り出し

データの取り出しは`getPersistentAttributes()`を利用します。
データの更新をしたい場合は、`getPersistentAttributes()`で取り出した後に値を変更して保存するようにしましょう。

```js
const MyExampleHandler = {
  canHandle(handlerInput) {
    ...
  },
  getSpeakText(attributes) {
      const { name, age } = attributes
      if (!name && !age) return 'データが見つかりませんでした。' 
      const nameText = name ? `名前は、${name}。`: ''
      const ageText = name ? `年齢は${age}歳です。`: ''
      return `あなたの${nameText}${ageText}`
  },
  async handle(handlerInput) {
    const savedAttributes =
      await handlerInput.attributesManager.getPersistentAttributes()
    const speech = this.getSpeakText(savedAttributes || {})
    return handlerInput.responseBuilder
      .speak(speech)
      .getResponse()
  }
}
```

これでDynamoDBを利用してデータを永続化することができるようになりました。

##### ask-sdkで保存する場合の注意点
ask-sdkはAlexaアプリのAmazonアカウントごとに一意なユーザーIDをプライマリーキーとして、データを保存、取得します。
ただし、スキルを無効化するとそのユーザーIDは変化します。
そのためスキルをリセットされると、そのユーザーのデータはまた１からとなりますのでご注意下さい。

#### aws-sdkからDynamoDBにアクセスする際のTips
aws-sdkの利用方法についてはすでにさまざまな記事が存在します。
そのため本書では基本的な使い方については割愛し、スキルからアクセスする場合のTipsについてのみ紹介します。

##### プライマリキーを何にするべきか
もっとも簡単な方法は、ask-sdk同様にユーザーIDを利用することです。
ask-utilsを使用することで、比較的簡単にデータを取得できます。

```js
const AWS = require('aws-sdk')
const { getUserId } = require('ask-utils')
const dynamoDB = new AWS.DynamoDB.DocumentClient()
const TableName = 'MyExampleDB'

const SaveProfileHandler = {
  canHandle() {
    ...
  },
  async handle(handlerInput) {
    const userId = getUserId(handlerInput)
    const params = {
      TableName,
      Item: {
        id: userId,
      }
    }
    await dynamoDB.put(params).promise()
    ...
  }
}
```

しかしこの方法をとると、スキル以外からアクセスすることがすこし難しくなります。
なぜならAlexaのユーザーIDを何かしらの方法で取得する必要が出るためです。
そのため、webアプリのみ利用するユーザーが現れた場合にプライマリキーを何にするべきかという問題が発生します。

もしデータの取得にクエリを利用することを前提とすれば、プライマリキーをUUIDにする方法も考えられます。

```js
const uuidv1 = require('uuid/v1')
const moment = require('moment')
const AWS = require('aws-sdk')
const { getUserId } = require('ask-utils')
const dynamoDB = new AWS.DynamoDB.DocumentClient()
const TableName = 'MyExampleDB'

const SaveProfileHandler = {
  canHandle() {
    ...
  },
  getAppServiceUsername(handlerInput) {
    // アカウントリンク先のユーザー名などを取得する処理
  },
  async handle(handlerInput) {
    const username = this.getAppServiceUsername(handlerInput)
    const params = {
      TableName,
      Item: {
        id: uuidv1(),
        alexa_user_id: getUserId(handlerInput),
        username,
        create_time: moment().format('YYYY-MM-DDTHH:mm:ssZ')
      }
    }
    await dynamoDB.put(params).promise()
    ...
  }
}
```

もちろんプライマリキーがランダム生成された値となりますので、getItemでのデータ取得は期待できません。
しかし`alexa_user_id`や`username`を利用したGSIを作成することで、webとスキルどちらからもデータを投入することができます。
スキルのリセットでユーザーIDが変更された場合にも、アカウントリンク先の`username`からデータをクエリした後に`alexa_user_id`を更新するという方法がとれます。


### Display Interfaceに対応する
2018年7月、日本でもついに画面付きデバイスのEcho Spotが発売されました。
このほかにもFire TVやEcho Showなど、画面を持つAlexaデバイスの数は世界で増えています。

ask-sdkを使ってEcho Spotなどに任意のデータを表示させるには、`addRenderTemplateDirective()`メソッドを利用します。

また画像やテキストを表示させるためには、指定された形のオブジェクトとして渡す必要があります。
そのため`ImageHelper()`や`RichTextContentHelper()`などのヘルパーメソッドにURLや文字列を渡す実装となります。

```js
const Alexa = require('alexa-sdk')
const { supportsDisplay, canHandle } = require('ask-utils')

const ExampleHandler = {
    canHandle(handlerInput) {
        return canHandle(handlerInput, 'IntentRequest', 'ExampleIntent')
    },
    handle(handlerInput) {
        consst speechOutput = 'ピザスキルへようこそ'
        if (supportsDisplay(handlerInput)) {
        const myImage = new Alexa.ImageHelper()
            .addImageInstance('https://i.imgur.com/rpcYKDD.jpg')
            .getImage();
    
        const primaryText = new Alexa.RichTextContentHelper()
            .withPrimaryText(speechOutput)
            .getTextContent();
    
        return handlerInput.responseBuilder
            .addRenderTemplateDirective({
                type: 'BodyTemplate1',
                token: 'string',
                backButton: 'HIDDEN',
                backgroundImage: myImage,
                title: "ピザ注文スキル",
                textContent: primaryText,
            });
          　.speak(speechOutput)
          　.withSimpleCard(speechOutput)
          　.getResponse()
    }
}
```

対応しているテンプレートのリファレンスは、公式のドキュメントをご確認ください。

Displayインタフェースのリファレンス
[https://developer.amazon.com/ja/docs/custom-skills/display-interface-reference.html](https://developer.amazon.com/ja/docs/custom-skills/display-interface-reference.html)

#### Display Interfaceで追加される標準ビルトインインテント
スキルの設定でDisplay Interfaceを有効にすると、以下のインテントが自動で追加されます。

- AMAZON.PreviousIntent 
- AMAZON.NextIntent
- AMAZON.ScrollUpIntent 
- AMAZON.ScrollLeftIntent 
- AMAZON.ScrollDownIntent 
- AMAZON.ScrollRightIntent 
- AMAZON.PageUpIntent 
- AMAZON.PageDownIntent 
- AMAZON.MoreIntent 
- AMAZON.NavigateHomeIntent 
- AMAZON.NavigateSettingsIntent

このうち`AMAZON.PreviousIntent`と`AMAZON.NextIntent`以外については、特になにもする必要はありません。
というのもこれらは画面のスクロールやホーム画面に戻るためのインテントだからです。

`AMAZON.PreviousIntent`と`AMAZON.NextIntent`については、その名前の通り「戻る」または「進む」ためのインテントです。
それぞれのハンドラーを作成し、前後のコンテンツを取得できるようにしましょう。


#### Display Interface対応デバイスかどうかを判定する
Display Interfaceに対応する場合で注意すべきことは、Display Interfaceを持たないデバイスへの対応です。
Echo DotやEchoなどでスキルを利用する場合、`addRenderTemplateDirective()`メソッドを含む形でレスポンスを作成するとエラーになります。

そのため、`handlerInput`の値からDisplay Interfaceをサポートしているか否かを判別する必要があります。
デバイスがサポートしているインタフェースは、`context.System.device.supportedInterfaces`から取得できます。

```json
{
    context: {
      System: {
        device: {
          supportedInterfaces: {
            AudioPlayer: {},
            Display: {}
          }
        },
        ...

```

ask-utilsを使用した場合、以下のような形で分岐させることができます。

```js
const Alexa = require('alexa-sdk')
const { supportsDisplay, canHandle } = require('ask-utils')

const ExampleHandler = {
    canHandle(handlerInput) {
        return canHandle(handlerInput, 'IntentRequest', 'ExampleIntent')
    },
    handle(handlerInput) {
        consst speechOutput = 'ピザスキルへようこそ'
        if (supportsDisplay(handlerInput)) {
            const myImage = new Alexa.ImageHelper()
                .addImageInstance('https://i.imgur.com/rpcYKDD.jpg')
                .getImage();
    
            const primaryText = new Alexa.RichTextContentHelper()
                .withPrimaryText(speechOutput)
                .getTextContent();
    
            handlerInput.responseBuilder.addRenderTemplateDirective({
                type: 'BodyTemplate1',
                token: 'string',
                backButton: 'HIDDEN',
                backgroundImage: myImage,
                title: "ピザ注文スキル",
                textContent: primaryText,
            });
        }
        return handlerInput.responseBuilder
          　　.speak(speechOutput)
          　　.withSimpleCard(speechOutput)
          　　.getResponse()
    }
}
```

実装では次のような形となります。  
Displayオブジェクトの有無で判別しましょう。

```js
const supportsDisplay = handlerInput => {
  const { supportedInterfaces } = handlerInput.context.System.device
  if (supportedInterfaces.Display) return true
  return false
}
```
