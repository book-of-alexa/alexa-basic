## Better developing Alexa Skill
ここまでスキル開発で利用できるAWSサービスやask-sdkに関するTipsを紹介してきました。
ここからはもう一歩踏み込んだ、「より良いスキルの作り方」について考えていきましょう。

### DynamoDBで「ウェルカムメッセージ」を出し分ける

スマートスピーカーは「音声アシスタント」とよばれることもあり、アプリ・システムというよりもアシスタントとして振舞うことを期待される側面があります。
そのためスキル開発を進める中で「パーソナライズしたい」という要望が出ることは少なくありません。
スキルでもっとも簡単にできるパーソナライズが、「利用回数でメッセージを出し分けること」です。
例えばユーザーがはじめてスキルを使用する時、「そのスキルで何ができるか」や「どのように話しかければよいのか」などを教えてもらえると、より気軽にスキルを利用できます。
しかし日常的にスキルを利用する人からすると、すでに知っていることについて毎回説明されるのは煩わしいだけです。

そこでよく用いられる方法が、DynamoDBなどのデータベースに利用回数を保存し、メッセージをパーソナライズするというものです。

#### スキルの起動時、使用回数に応じた発話を出すサンプル

このサンプルでは、利用回数が0回の時は有効化のお礼と説明をAlexaが話します。
1回目以降では、3割の確率で「いつもありがとうございます」という一言を付け加えます。

```js
const {
  getRandomMessage,
  canHandle
} = require('ask-utils')
const getWelcomeMessage = (count = 0) => {
  if (count < 1) return 'スキルを登録してくれてありがとうございます。このスキルではデータの登録と確認を行うことができます。登録と確認、どちらを試しますか？'
  if (count > 0) {
    const rand = Math.floor(Math.random() * 100)
    // 3割の確率で「いつもありがとう」と付け加える
    if (rand > 69) return 'いつもありがとうございます。登録と確認。どちらにしますか？'
    return '登録と確認。どちらをしますか？'
  }
}
const LaunchRequestHandler = {
  canHandle (handlerInput) {
    return canHandle(handlerInput, 'LaunchRequest')
  },
  async handle (handlerInput) {
    const attributes =
      await handlerInput.attributesManager.getPersistentAttributes()
    const invokeCount = attributes.invokeCount || 0
    const speechText = getWelcomeMessage(invokeCount)
    const nextAttributes = {invokeCount: invokeCount + 1}
    await handlerInput.attributesManager.setPersistentAttributes(nextAttributes)
    await handlerInput.attributesManager.savePersistentAttributes()
    return handlerInput.responseBuilder
      .speak(speechText)
      .reprompt(speechText)
      .getResponse()
  }
}

```

実装を見ると、`attributesManager`を使ってデータの保存・読み取りをしているだけのシンプルな内容です。
ですがこのような実装を含めることで、まるでスキルが自分のことを理解してくれているような体験を提供することが可能となります。
サンプルでは利用回数だけですが、使用した時間やよく入力されるスロットなどのデータを上手く収集・分析することで、スキルをパーソナライズしていきましょう。

### ランダムなレスポンスで「人間らしさ」を

人間とは不思議なもので、全く同じ返事が何度も繰り返されることをとても嫌がります。
プログラムの実装をしていると、どうしてもテストや実装のしやすさから同じメッセージだけを返すようにしたくなります。
ですが、音声アプリの場合は「人間らしさ」がないとユーザーから敬遠されるケースが少なからずあります。

特に起動時や終了時のメッセージなどは毎回同じメッセージを聞くことになります。
これらのテキストをランダムに出力するようにすることで、あなたのスキルをより「人間らしく」することができます。

#### スキル終了時の返答をランダム化したサンプル

```js
const {
  getRandomMessage,
  canHandle
} = require('ask-utils')
const StopIntentHandler = {
  canHandle (handlerInput) {
   if (canHandle(handlerInput, 'IntentRequest', 'AMAZON.CancelIntent')) return true
   if (canHandle(handlerInput, 'IntentRequest', 'AMAZON.NoIntent')) return true
   if (canHandle(handlerInput, 'IntentRequest', 'AMAZON.StopIntent')) return true
   return false
  },
  handle (handlerInput) {
    const speechText = getRandomMessage([
        'では。',
        'またお使いくださいね。',
        'バイバイ。またね。',
        'いつもお疲れ様です。',
        'またいつでもお声がけくださいね。'
    ])
    return handlerInput.responseBuilder
      .speak(speechText)
      .getResponse()
  }
}

```

#### ランダム化する際のポイント
ランダムな返答を考える時に意識したいのが、「スキルのキャラ付け」です。
例えばユースケースが出勤前の忙しい時間だとすると、手短で簡潔な返答の方が好まれるでしょう。
反対に子ども向けやパーティなどで使うスキルでは、盛り上げ役やすこし気の利いた発言をするようにした方がよいでしょう。

また、まだ開発者向けプレビューのみですが、スキルの返答音声をカスタマイズする仕組みも用意されています。

- New Developer Preview: Use Amazon Polly voices in Alexa skills  
[https://aws.amazon.com/jp/blogs/machine-learning/new-developer-preview-use-amazon-polly-voices-in-alexa-skills/](https://aws.amazon.com/jp/blogs/machine-learning/new-developer-preview-use-amazon-polly-voices-in-alexa-skills/)
- 開発者プレビュー版： Amazon PollyでAlexaの音声をカスタマイズしよう  
[https://developer.amazon.com/ja/blogs/alexa/post/0e88bf72-ac90-45f1-863b-32ca8e2ae197/amazon-polly-voices-in-alexa-jp](https://developer.amazon.com/ja/blogs/alexa/post/0e88bf72-ac90-45f1-863b-32ca8e2ae197/amazon-polly-voices-in-alexa-jp)

```html
<speak>
    I want to tell you a secret. 
    <voice name="Kendra">I am not a real human.</voice>.
    Can you believe it?
</speak>
```

これらのことを踏まえると、「いま作っているスキルはユーザーとどのようなスタンスで会話をするのか」というキャラ設定を考える必要がありそうです。

### 「心を折らない」エラーハンドリング
正直なところ、エラー処理の実装はあまり気乗りしない部分です。
クラッシュしない程度の最低限な機能を実装し、残りの時間は新しい機能の開発に費やしたいと思います。
ですが意図しない動作が起きた時こそ、ユーザーに「どうすれば、やりたいことを実行できるのだろう？」という疑問に答える必要があります。

#### 保存処理に失敗した場合に固有のエラーメッセージを話すサンプル

以下のサンプルでは、データの保存処理でエラーが発生した場合のハンドリングが行われています。
まず保存処理を実行する際に、`handlerInput.attributesManager.setSessionAttributes({action: 'save'})`でアクション内容をセッションへ保存しています。
そしてエラーが起きた場合は、`ErrorHandler`の中でセッションの値を取得し、`action`が`save`の場合は保存をリトライする発話について話します。


```js
const {
  canHandle
} = require('ask-utils')
const SaveItemHandler = {
  canHandle (handlerInput) {
    return canHandle(handlerInput, 'IntentRequest', 'SaveItemIntent')
  },
  async handle (handlerInput) {
    handlerInput.attributesManager.setSessionAttributes({action: 'save'})
    const attributes =
      await handlerInput.attributesManager.getPersistentAttributes()
    const item = handlerInput.requestEnvelope.request.intent.slots.item.value
    const nextAttributes = {item}
    await handlerInput.attributesManager.setPersistentAttributes(nextAttributes)
    await handlerInput.attributesManager.savePersistentAttributes()
    return handlerInput.responseBuilder
      .speak('データを保存しました')
      .getResponse()
  }
}

const ErrorHandler = {
  canHandle () {
    return true
  },
  handle (handlerInput, error) {
    console.log(`Error handled: ${error.message}`)
    console.log(error)
    const attributes = handlerInput.attributesManager.getSessionAttributes()
    if (attributes.action) {
      if (attributes.action === 'save') {
        const action = 'データの保存は、「アレクサの原稿を追加」のように話しかけてください。'
                   
        return handlerInput.responseBuilder
          .speak(`すみません。上手く聞き取れませんでした。${action}`)
          .reprompt(action)
          .getResponse()
      }
    }
    return handlerInput.responseBuilder
      .speak(`すみません。上手く聞き取れませんでした。もう一度教えてもらえますか？`)
      .reprompt(`上手く聞き取れなくてすみません。もう一度教えてもらえますか？`))
      .getResponse()
  }
}

```


#### スロットに意図したデータが保存できない場合のハンドリング

その他の例として、スロットの扱いもあります。
例えばスロットに意図しない値が入ってきた場合、その後の処理のためにもユーザーに再入力を促すように実装します。
しかしユーザーとしては正しい発話をしているつもりだった場合、ただ再入力を促すだけの返答が繰り返されるのは非常にストレスとなります。
このケースでは、`sessionAttributes`を利用して再試行回数を記録し、複数回実行に失敗している場合はヒントや別の言い回しを提案するようにしてみましょう。

```js
const {
  canHandle,
  getSlotByName
} = require('ask-utils')
const SaveItemHandler = {
  canHandle (handlerInput) {
    return canHandle(handlerInput, 'IntentRequest', 'SaveItemIntent')
  },
  async handle (handlerInput) {
    const { request } = handlerInput.requestEnvelope
    const slot = getSlotByName(handlerInput, 'item')
    const item = slot.value || ''
    if (!item) {
        const attributes = handlerInput.attributesManager.getSessionAttributes()
        const retryCount = attributes.retryCount || 0
        handlerInput.attributesManager
          .setSessionAttributes({retryCount: retryCount + 1})
        if (retryCount > 2) {
          return handlerInput.responseBuilder
            .speak('保存するデータが見つかりませんでした。「アレクサの原稿を追加」や「明日の予定を登録」のように話しかけてみてください。')
            .reprompt('「アレクサの原稿を追加」や「明日の予定を登録」のように話しかけてみてください。終了する場合は、ストップと言ってください。')
            .getResponse()
        }
        return handlerInput.responseBuilder
          .speak('保存するデータが見つかりませんでした。もう一度言っていただけますか？')
          .reprompt('保存するデータについてもう一度教えていただけますか？')
          .getResponse()
    }
    
    const attributes =
      await handlerInput.attributesManager.getPersistentAttributes()
    const nextAttributes = {item}
    await handlerInput.attributesManager.setPersistentAttributes(nextAttributes)
    await handlerInput.attributesManager.savePersistentAttributes()
    return handlerInput.responseBuilder
      .speak('データを保存しました')
      .getResponse()
  }
}
```

### スキルの機能をどこで紹介するか？
音声アプリケーションのつらいところとして、「ユーザーに対する告知がやりづらい」というものがあります。
webやスマートフォンアプリでは、モーダルや通知アイコンなどを使用してお知らせを出すことが可能です。
しかし音声アプリの場合、会話の中にお知らせコンテンツを含める必要がでてきます。

ではAlexaで開発するスキルの場合、どの場面で紹介するのがよいでしょうか。
スキルを開発する身としては、やはりできるだけ早く新しい機能について知ってほしいと考えがちです。
そう考えた場合、スキルを起動させた直後に「XXXスキルへようこそ！ YYYという新しい機能が出たので試してね！」のようにお知らせする方法がまず思い浮かびます。

しかしこれをすると、ユーザーからの印象はかなり悪くなってしまいます。
なぜならスキルを起動させた状況とは、「何か目的があって呼び出している」場面だからです。
お店で気になるカメラの詳細を知りたくて店員さんに声をかけた場面を想像してみてください。
「何か知りたい」「何かを依頼したい」という場面で、相手が自分の話を聞かずにいきなり宣伝を始めたらあなたはどんな気持ちになりますか？

一般的に新しい機能や宣伝・レビューの依頼といった「ユーザーに対する告知」コンテンツは、「ヘルプインテント」「会話終了時」「ディスプレイへの表示」の３つが利用されます。
ヘルプインテントでは、「今月XXXという機能が追加されました。試してみますか？」のように話しかけることで、気軽に新機能を試してもらうことができるでしょう。
会話終了時には、「スキルの調子はどうですか？ レビューをぜひお願いします」や「アカウント連携すると、スマホからもデータが見れますよ」のようなお知らせを入れてみましょう。
スキル自体はすでに終了していますが、スキルに関連するアクションなどを提案することで、よりユーザーとの関わりを増やすことが期待できます。


いずれのアイデアについても、ask-utilsの`getRandomMessage()`などを利用してコンテンツをランダムに呼び出すようにすることをオススメします。
また常に宣伝するのではなく、「3回に1回程度のペースでお知らせをいれる」のようにすることで、「宣伝が多すぎる」と思われるケースを避けることができます。

#### スキル終了時に告知をいれるサンプル

```js
const {
  getRandomMessage,
  canHandle
} = require('ask-utils')
const StopIntentHandler = {
  canHandle (handlerInput) {
   if (canHandle(handlerInput, 'IntentRequest', 'AMAZON.CancelIntent')) return true
   if (canHandle(handlerInput, 'IntentRequest', 'AMAZON.NoIntent')) return true
   if (canHandle(handlerInput, 'IntentRequest', 'AMAZON.StopIntent')) return true
   return false
  },
  handle (handlerInput) {
    const prContent = getRandomMessage([
        '',
        '',
        '',
        'あ、時間のあるときに、「アレクサ、サンプルスキルで面白い話をして」と話しかけてみてください。',
        'もし旅行の予定をたてたいときがあれば、「アレクサ、サンプルスキルで旅行の予定を記録して」と話しかけると旅程が作れます。'
    ])
    const speechText = `またいつでもお声がけくださいね。${prContent}`
    return handlerInput.responseBuilder
      .speak(speechText)
      .withSimpleCard('サンプルスキル: お試しください', '「アレクサ、サンプルスキルで面白い話をして」\n「アレクサ、サンプルスキルで旅行の予定を記録して」')
      .getResponse()
  }
}

```

#### プログレッシブレスポンスで、ストレスなく待たせよう

スキルによってはAWSのDynamoDBをはじめとした外部サービスのAPIと接続する必要があります。
そして外部のAPIに接続する関係から、Alexaが返答するまでに少し時間がかかるケースも発生します。
通常のアプリケーションでは、ローディング画面を表示することでユーザーに待機していることを知らせることができます。
しかしAlexaのような音声インタフェースの場合は、ロードの状態を画面で示すことができません。
そのような場合に利用されるのが、「プログレッシブレスポンス」です。

プログレッシブレスポンスとは、スキルが完全な応答を作成するまでの間、Alexaが再生する割り込みのSSMLコンテンツです。
[https://developer.amazon.com/ja/docs/custom-skills/send-the-user-a-progressive-response.html](https://developer.amazon.com/ja/docs/custom-skills/send-the-user-a-progressive-response.html)

ask-utilsを利用することで、簡単にプログレッシブレスポンスを実装することができます。

```js
const { enqueueProgressiveResponseDirective } = require('ask-utils') 
const GetFirstEventHandler = {
  canHandle (handlerInput) {
    const request = handlerInput.requestEnvelope.request
    return request.type === 'IntentRequest' &&
      request.intent.name === 'GetFirstEventIntent'
  },
  async handle (handlerInput) {
    try {
      // プログレッシブレスポンスを利用する
      await enqueueProgressiveResponseDirective(handlerInput, 'ただいま検索中です。少々お待ちください。')
    } catch (err) {
      // プログレッシブレスポンスでトラブルが発生しても、処理を継続させる。
      console.log(err)
    }
    try {
      // 外部のAPIと接続する
      const content = await get()
      return responseBuilder
        .speak(content)
        .getResponse()
    } catch (e) {
      return responseBuilder
        .speak('すみません。データの取得に失敗しました')
        .getResponse()
    }
  }
}
```

プログレッシブレスポンスを実装することで、APIからのレスポンスを待つ間「お待ちください」のようなメッセージをAlexaに話させることができます。