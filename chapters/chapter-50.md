# Testing Practice Alexa Skills

Written by: Hidetaka Okamoto

## はじめに

ここからは、スキル開発時のテストについて紹介します。

Alexaのスキル開発では、まだ定石とされるテスト手法が確立されていません。
そのため、筆者が検証したもしくは実際に利用しているテスト方法について網羅的に紹介いたします。

様々なテストノウハウを活用し、より効率的かつ安定したスキル開発を目指しましょう。

## スキルのテスト方針
Alexaスキルでは様々な部分で確認したい項目がでてきます。
開発していてまず気になるのが「バックエンドの実装が問題ないか？」ということです。
これはコードに問題があるかをいち早く気づくための仕組みが必要となります。

続いて気になるのが「意図した通りにアレクサが返事をしてくれるか？」という点です。
これはAlexa Skills Kitが提供している音声認識（ASR）や自然言語処理（NLU）の動きを調べることになります。
とはいえ実際にASR / NLUの中身を見ることはできません。
そのため「作成したサンプル発話が意図した通りのインテントに辿り着いているか？」や、「スロットの値が正しく取得できるか？」などを調べることになります。

そして最後に確認する必要があるのは、「アレクサからの返答が自然な会話になっているか」というものです。
これについては今のところ定量化する方法がありませんので、Alexaシミュレーターや実機でのテストが重要となります。

## ESLintでバグを未然に防ぐ
Node.jsでスキル開発をする場合に入れておきたいのがESLintです。
ESLintはJavaScriptのコードに対して構文チェックを行うことができるツールです。


### ESLintのインストールとセットアップ
`npm i -g eslint`でインストールすることができます。
インストール後は`eslint --init`でセットアップしましょう。

```console
$ cd /PATH/TO/YOUR/ASK/PROJECT/lambda/custom
$ npm i -g eslint
$ eslint --init
? How would you like to configure ESLint? Use a popular style guide
? Which style guide do you want to follow? 
  Airbnb (https://github.com/airbnb/javascript) 
> Standard (https://github.com/standard/standard) 
  Google (https://github.com/google/eslint-config-google) 
...
```

`eslint --init`コマンドを実行することで、そのプロジェクトでのコーディング規約を対話形式で設定できます。
筆者はよくStandardを利用しますが、対話形式で細かく設定することも可能です。
[https://github.com/standard/standard](https://github.com/standard/standard)

対話形式での設定が完了すると、構文チェックに必要なツールをインストールします。

```console
Checking peerDependencies of eslint-config-standard@latest
The config that you've selected requires the following dependencies:

eslint-config-standard@latest eslint@>=5.0.0 eslint-plugin-import@>=2.13.0
  eslint-plugin-node@>=7.0.0 eslint-plugin-promise@>=4.0.0
  eslint-plugin-standard@>=4.0.0
? Would you like to install them now with npm? Yes
Installing eslint-config-standard@latest, eslint@>=5.0.0,
  eslint-plugin-import@>=2.13.0, eslint-plugin-node@>=7.0.0,
  eslint-plugin-promise@>=4.0.0, eslint-plugin-standard@>=4.0.0
npm WARN hello-world@1.0.0 No description
npm WARN hello-world@1.0.0 No repository field.

+ eslint@5.5.0
+ eslint-plugin-node@7.0.1
+ eslint-plugin-promise@4.0.0
+ eslint-config-standard@12.0.0
+ eslint-plugin-standard@4.0.0
+ eslint-plugin-import@2.14.0
added 44 packages and updated 1 package in 5.38s
Successfully created .eslintrc.yml file in /Users/develop/alexa/lambda/custom
```

`eslint [ファイル名]`で構文に問題がないか確認してみましょう。

```console
$ eslint index.js 

/Users/develop/alexa/lambda/custom/index.js
4:38  error Extra semicolon                           semi
7:12  error Missing space before function parentheses space-before-function-paren
8:73  error Extra semicolon                           semi
10:9  error Missing space before function parentheses space-before-function-paren
11:77 error Extra semicolon                           semi
17:21 error Extra semicolon                           semi
18:4  error Unexpected trailing comma                 comma-dangle
19:2  error Extra semicolon                           semi
22:12 error Missing space before function parentheses space-before-function-paren
24:9  error '&&' should be placed at the end of the line operator-linebreak
24:81 error Extra semicolon                           semi
26:9  error Missing space before function parentheses space-before-function-paren
27:38 error Extra semicolon                           semi
```

`ASK CLI`で作成されるサンプルコードは　Standard以外の規約で書かれていますので、いろいろなメッセージが表示されます。
便利なことにESLintでは`--fix`オプションをつけることで、インデントなどの軽微な規約違反を自動修正してくれます。

```console
$ eslint index.js --fix
$ git diff
diff --git a/index.js b/index.js
index f40528c..91dab24 100644
--- a/index.js
+++ b/index.js
@@ -1,96 +1,96 @@
 /* eslint-disable  func-names */
 /* eslint-disable  no-console */
 
-const Alexa = require('ask-sdk-core');
+const Alexa = require('ask-sdk-core')
 
 const LaunchRequestHandler = {
-  canHandle(handlerInput) {
-    return handlerInput.requestEnvelope.request.type === 'LaunchRequest';
+  canHandle (handlerInput) {
+    return handlerInput.requestEnvelope.request.type === 'LaunchRequest'
   },
-  handle(handlerInput) {
-    const speechText = 'Welcome to the Alexa Skills Kit, you can say hello!';
+  handle (handlerInput) {
+    const speechText = 'Welcome to the Alexa Skills Kit, you can say hello!'
 
     return handlerInput.responseBuilder
       .speak(speechText)
       .reprompt(speechText)
       .withSimpleCard('Hello World', speechText)
-      .getResponse();
-  },
-};

```

これでSyntax Errorによるスキルの動作停止などを未然に検知することができるようになりました。
またコーディング規約ができたことで、チームで開発する際にも皆が読みやすいコードを維持することができるようになります。

## Lambdaのローカルテスト
もっとも簡単かつ高速にできるテストはやはりローカルでのユニットテストです。
Node.jsではMochaやPower Assertなどを使ってテストを実行することが一般的です。
[https://mochajs.org/](https://mochajs.org/)
[https://github.com/power-assert-js/power-assert](https://github.com/power-assert-js/power-assert)


### Mocha / Power AssertでのNode.jsユニットテストのサンプル
簡単なテストの例をここに用意しました。
`describe`でテストのグループを作り、`it`にテストする内容を書きます。
1つ目のテストは1+1の結果が2というテストで、2つ目は3だというテスト内容です。

```console
$ npm i -D mocha power-assert
$ vim index.test.js

const assert = require('power-assert')
describe('初めてのテスト', () => {
    it('1+1=2', () => {
        const result = 1 + 1
        assert.equal(result, 2)
    })
    it('1+1≠3', () => {
        const result = 1 + 1
        assert.equal(result, 3)
    })
})

```
もちろん2つ目の計算は不正解ですので、実際にテストを実行すると以下のようにエラーが表示されます。

```console
$ ./node_modules/.bin/mocha index.test.js 


  初めてのテスト
    ✓ 1+1=2
    1) 1+1≠3


  1 passing (7ms)
  1 failing

  1) 初めてのテスト
       1+1≠3:

      AssertionError [ERR_ASSERTION]: 2 == 3
      + expected - actual

      -2
      +3
      
      at Decorator._callFunc (node_modules/empower-core/lib/decorator.js:110:20)
      at Decorator.concreteAssert 
        (node_modules/empower-core/lib/decorator.js:103:17)
      at Function.decoratedAssert [as equal]
        (node_modules/empower-core/lib/decorate.js:51:30)
      at Context.it (index.test.js:10:16)
```
このような形で、作成した関数が正しい値を返しているかを確認することができます。

### Handler単位でテストする

はじめにユニットテストの方法を紹介しました。
次はもう少し大きな粒度でテストしてみましょう。

ask-sdkで実装する場合、それぞれの処理は`canHandle`と`handle`のメソッドを持つオブジェクトで処理されます。
そこで今度はこのHandlerオブジェクトレベルでテストを実行してみましょう。

#### テストの準備
テストで使用するライブラリをインストールしておきましょう。

```console
$ npm i -S ask-utils
$ npm i -D mocha power-assert
```

#### サンプルのHandlerオブジェクトを用意する。
まずはテスト対象となるオブジェクトを用意します。
今回はもっとも使われることの多い`LaunchRequest`をテストします。

`ASK CLI`が作成した`/lambda/custom/`ディレクトリの中に、`handlers/LaunchRequest.js`というファイルを用意しましょう。
その中には以下のようにコードを書きます。

```js
module.exports = {
  canHandle (handlerInput) {
    return handlerInput.requestEnvelope.request.type === 'LaunchRequest'
  },
  handle (handlerInput) {
    const speechText = 'アレクサスキルへようこそ！'

    return handlerInput.responseBuilder
      .speak(speechText)
      .reprompt(speechText)
      .withSimpleCard('Hello World', speechText)
      .getResponse()
  }
}
```

スキルで使用する場合は、以下のように`index.js`で`require`して使います。

```js
const Alexa = require('ask-sdk-core')
// handlers
const LaunchRequestHandler = require('./handlers/LaunchRequest')

const skillBuilder = Alexa.SkillBuilders.custom()

exports.handler = skillBuilder
  .addRequestHandlers(
    LaunchRequestHandler
  )
  .lambda()
```

#### テストコードを用意する
続いてテスト用のファイルを用意しましょう。

mochaの場合、`mocha [ファイル名]`や`mocha tests/*/*`のように書くことでテストファイルを指定できます。

スキルで利用するコードと混ざらないように`tests`ディレクトリを作成して、その中にテストファイルをおくと良いでしょう。

#### canHandle()をテストする
ここからは実際のテスト内容を作っていきます。
`canHandle()`メソッドでは、`handlerInput.requestEnvelope.request.type`と`handlerInput.requestEnvelope.request.intent.name`の2パラメータがよく利用されています。
そのため、メソッドの引数には以下のようなオブジェクトをそれぞれ渡してやりましょう。

`canHandle()`のレスポンスは真偽値で、`true`の場合のみ`handle()`メソッドを実行します。
そのため「意図した引数でtrueを返しているか」「他のインテントでfalseを返せているか」をテストしてやりましょう。

```js
const assert = require('power-assert')
const { LaunchRequestHandler } = require('./handlers/LaunchRequest')

describe('canHandle', () => {
  it('LaunchRequestではtrueを返す', () => {
    const event = {
      requestEnvelope: {
        request: {
          type: 'LaunchRequest'
        }
      }
    }
    const result = LaunchRequestHandler.canHandle(event)
    assert.equal(result, true)
  })
  it('HelloWorldIntentではfalseを返す', () => {
    const event = {
      requestEnvelope: {
        request: {
          type: 'IntentRequest',
          intent: {
            name: 'HelloWorldIntent'
          }
        }
      }
    }
    const result = LaunchRequestHandler.canHandle(event)
    assert.equal(result, false)
  })
})
```

#### handle()をテストする
続いて実際の処理部分をテストしましょう。
`canHandle()`メソッドでは引数を自作しましたが、`responseBuilder()`以下を自前で再現するのは非常に手間です。
そこでask-utilsにテストで使えるダミーの引数を作る関数を用意しました。


```js
const { DefaultHandlerAdapter } = require('ask-sdk-core')
const assert = require('power-assert')
const { LaunchRequestHandler } = require('./index')
const { getHandlerInput, getRequestEnvelopeMock } = require('ask-utils')
const event = getRequestEnvelopeMock()

describe('LaunchRequest', () => {
  it('handle()をテストする', async () => {
    const handlerAdapter = new DefaultHandlerAdapter()
    const Input = getHandlerInput(event)
    const response = await handlerAdapter.execute(Input, LaunchRequestHandler)
    assert.equal(response.outputSpeech.ssml,
      '<speak>Welcome to the Alexa Skills Kit, you can say hello!</speak>')
    assert.equal(response.shouldEndSession, false)
  })
})
```

ちょっと複雑な書き方ですね。これはask-sdk-core本体で使用されているテストコードを参考にしています。
[https://github.com/alexa/alexa-skills-kit-sdk-for-nodejs/blob/2.0.x/ask-sdk-core/tst/dispatcher/request/handler/DefaultHandlerAdapter.spec.ts#L31-L44](https://github.com/alexa/alexa-skills-kit-sdk-for-nodejs/blob/2.0.x/ask-sdk-core/tst/dispatcher/request/handler/DefaultHandlerAdapter.spec.ts#L31-L44)

ここでは`handlerAdapter.execute`の第一引数にeventオブジェクトを、第二引数に実行させたいhandlerオブジェクトを渡します。
するとAlexa Skills Kitへ渡されるオブジェクトが返ってきますので、アサーションでチェックしていきましょう。
失敗結果は、以下のサンプルのように表示されます。この例ではスキルの返答内容が想定と異なる内容になっているのがわかります。

```console
  LaunchRequest
    1) async / awaitを利用したパターン


  0 passing (8ms)
  1 failing

  1) LaunchRequest
       async / awaitを利用したパターン:

      AssertionError [ERR_ASSERTION]: '<speak>Welcome to the Alexa Skills Kit,
        you can say hello!</speak>' == '<speak>アレクサスキルへようこそ。何が知りたいですか？</speak>'
      + expected - actual

      -<speak>Welcome to the Alexa Skills Kit, you can say hello!</speak>
      +<speak>アレクサスキルへようこそ。何が知りたいですか？</speak>
   
      at Decorator._callFunc (node_modules/empower-core/lib/decorator.js:110:20)
      at Decorator.concreteAssert
        (node_modules/empower-core/lib/decorator.js:103:17)
      at Function.decoratedAssert [as equal]
        (node_modules/empower-core/lib/decorate.js:51:30)
      at Context.it (index.test.js:13:12)
```


#### インテントや条件を変えたテストを実行する
`event`をask-utilsから取得している場合、インテントやスロット内容によってはオブジェクトの一部を変更したい場合があります。
その場合は、以下のサンプルのように該当部分だけ都度上書きするとよいでしょう。
サンプルでは、`AMAZON.HelpIntent`のリクエスト内容を作成しています。


```js
/* eslint-disable no-useless-escape */
const assert = require('power-assert')
const LaunchRequestHandler = require('../../handlers/LaunchRequest')
const { getHandlerInput, getRequestEnvelopeMock } = require('ask-utils')
const event = getRequestEnvelopeMock()

describe('LaunchRequest', () => {
  event.request.type = 'IntentRequest'
  event.request.intent = {
    name: 'AMAZON.HelpIntent'
  }
  it('canHandle test', () => {
    const param = getHandlerInput(event)
    const result = LaunchRequestHandler.canHandle(param)
    assert.equal(result, true)
  })
})
```

リクエスト内容については、Amazonのリファレンスを参考にすることをおすすめします。

カスタムスキルのJSONインタフェースのリファレンス
[https://developer.amazon.com/ja/docs/custom-skills/request-and-response-json-reference.html](https://developer.amazon.com/ja/docs/custom-skills/request-and-response-json-reference.html)

#### Lambdaのエントリポイントからテストする
最後は実際にLambdaが実行された時と同じルートでテストしてみましょう。
exportしているハンドラーそのものを読み込み、直接invokeするやり方です。
Lambdaでは3つ目の引数にcallbackを指定しますので、その中にアサーションを書くようにします。

```js
const assert = require('power-assert')
const { handler } = require('./index.js')
const { getRequestEnvelopeMock } = require('ask-utils')
const event = getRequestEnvelopeMock()

describe('LaunchRequest', () => {
  it('callbackを利用した通しテスト', (done) => {
    handler(event, {}, (error, result) => {
      assert.equal(error, null)
      assert.equal(result.response.outputSpeech.ssml,
        '<speak>Welcome to the Alexa Skills Kit, you can say hello!</speak>')
      done()
    })
  })
})

```

このレイヤのテストが通れば、Lambdaでの実装がほぼ問題ないと言えるでしょう。
スキルでエラーが発生した場合、「IAMの設定漏れ」や「そのデバイスで対応していないレスポンスが含まれている」といった外的要因に注目しやすくなります。

このテスト方法はask-sdkのテストを参考に作成しましたが、１つデメリットがあります。
それはテストがFailした際、次のようにアサーションの内容が見れないということです。

```console

  0 passing (2s)
  1 failing

  1) LaunchRequest
       callbackを利用したパターン:
     Error: Timeout of 2000ms exceeded. For async tests and hooks, ensure "done()"
      is called; if returning a Promise, ensure it resolves.
      (/Users/develop/alexa/lambda/custom/index.test.js)
```

そのため、あくまで「問題がないかを確認する」目的だけに使用することをおすすめします。

## alexa-skill-test-frameworkでのLambda結合テスト
`alexa-skill-test-framework`を利用することで、より効率的にテストを行うことができます。

### インストール
`alexa-skill-test-framework`はnpmでホストされています。
npmコマンドでインストールしましょう。
`mocha`を使用してテストを実行しますので、こちらも一緒にインストールしましょう。

```console
$ npm i -D alexa-skill-test-framework
$ npm i -g mocha
```

### 初期化
テストで利用する際は、`alexaTest.initialize()`を利用します。
`alexaTest.initialize(require('./index.js'))`のように、第一引数にLambdaのエントリポイントとなるファイルを指定しましょう。
第二引数以降は、スキルID、ユーザーID、デバイスIDの順番となります。

また、デフォルトでは`en-US`のスキルとして振る舞いますので、`setLocale()`で言語を設定しておきましょう。

```js
const alexaTest = require('alexa-skill-test-framework')
alexaTest.initialize(
  require('./index.js'),
  'amzn1.ask.skill.xxx',
  'amzn1.ask.account.VOID',
  'amzn1.ask.device.VOID'
)
alexaTest.setLocale('ja-JP')
```


### テストを書く

テストは`alexaTest.test()`メソッドに配列で定義します。
配列でテスト内容を渡してやることで、前から順に対話をテストすることができます。

```js
describe('Hello World Skill', function () {
  describe('LaunchRequest', function () {
    alexaTest.test([
      {
        request: alexaTest.getLaunchRequest(),
        says: 'アレクサスキルへようこそ。あなたのお名前は？',
        repromptsLike: 'あなたのお名前は？'
      },
      {
          request: alexaTest.getIntentRequest('HelloWorldIntent', { name: 'やまだ' }),
          says: 'こんにちは、やまださん',
          shouldEndSession: true
      }
    ])
  })
})
```

`request`にはLambdaの`event`オブジェクトを渡す必要があります。
そしてオブジェクトを作るためのヘルパーメソッドが用意されており、それを利用することで簡単に作ることができます。

```js
# LaunchRequestを呼び出したい
alexaTest.getLaunchRequest()

# HelloWorldIntentを呼び出したい
alexaTest.getIntentRequest('HelloWorldIntent')

# スロットの値をつけてテストしたい
alexaTest.getIntentRequest('HelloWorldIntent', { name: 'やまだ' }

# SessionEndRequestを呼び出したい
alexaTest.getSessionEndedRequest('Session ended')
```

その他にもダイヤログ用のヘルパーやDynamoDB向けのモックなども用意されています。
詳しくはドキュメントをご確認ください。
[https://github.com/BrianMacIntosh/alexa-skill-test-framework](https://github.com/BrianMacIntosh/alexa-skill-test-framework)

サンプルも用意されていますので、こちらを見ながら試すことをおすすめします。
[https://github.com/BrianMacIntosh/alexa-skill-test-framework/tree/master/examples](https://github.com/BrianMacIntosh/alexa-skill-test-framework/tree/master/examples)

### テストを実行する
最後に`mocha [fileName]`でテストを実行しましょう。

`alexa-skill-test-framework`では、申請時に指摘されやすい項目についてもチェックしてくれます

```console
  1) Hello World Skill
       LaunchRequest
         returns the correct responses:
     AssertionError: Request #1 (LaunchRequest): Possible Certification Problem:
      The response keeps the session open but does not contain a questionmark.
      at Object._assert (node_modules/alexa-skill-test-framework/index.js:741:9)
      at CallbackContext.assert
        (node_modules/alexa-skill-test-framework/index.js:39:17)
      at CallbackContext._questionMarkCheck
        (node_modules/alexa-skill-test-framework/index.js:64:8)
      at ctx.Promise.then.response
        (node_modules/alexa-skill-test-framework/index.js:624:17)

```

この例では`Possible Certification Problem: The response keeps the session open but does not contain a questionmark.`と指摘されました。
これは「ユーザーの入力を待つ場合、発話の中に疑問文を入れてユーザーの入力を促す必要がある」という指摘です。

指摘文章は英文で表示されますが、Google翻訳などを活用してぜひ読みといてみてください

## ask simulateを効率的に実行する
`ASK CLI`の`simulate`コマンドは非常に強力です。
NLUからLambdaの実行までという、より本番に近い形でテストすることができます。

しかしCLIで都度コマンドを入力していては、やはり煩雑さが残ります。
そこでおすすめしたいのがスクリプト化です。

筆者の場合、Node.jsでMochaを利用した形で`ask simulate`を実行させています。

### パッケージのインストール

```console
$ npm i -g ask-cli
$ npm i -d mocha power-assert

# ASK CLIのセットアップがまだの場合は、こちらも実施してください。
$ ask init
```

### テストコード

```js
const assert = require('power-assert')
const { execFile } = require('child_process')

describe('test by ask-cli', () => {
  it('should return valid response when send invocation name', (done) => {
    execFile('ask', [
      'simulate', '-s', 'amzn1.ask.skill.xxx',
      '-l', 'en-US', '-t', 'open greeter'
    ], (error, stdout, stderr) => {
      if (error) {
        assert.deepEqual(error, {})
      } else {
        const { result } = JSON.parse(stdout)
        const { invocationResponse } = result.skillExecutionInfo
        const { response } = invocationResponse.body
        assert.equal(response.card.content.indexOf('<p>'), -1)
        assert.equal(response.card.content.indexOf('undefined'), -1)
      }
      done()
    })
  })
})
```

このようにスクリプト化しておくことで、より効率的にテストを行うことができます。
また、`execFile`をネストさせることで流れの確認も行うことができます。

```js
const assert = require('power-assert')
const { execFile } = require('child_process')

const skillId = 'amzn1.ask.skill.xxx'

describe('test by ask-cli', () => {
  it('should return valid response when send invocation name', (done) => {
    execFile('ask', [
      'simulate', '-s', skillId,
      '-l', 'en-US', '-t', 'open greeter'
    ], (error, stdout, stderr) => {
      if (error) {
        assert.deepEqual(error, {})
        return
      }
      execFile('ask', [
        'simulate', '-s', skillId,
        '-l', 'en-US', '-t', 'say hello'
      ], (error, stdout, stderr) => {
        if (error) {
          assert.deepEqual(error, {})
          return
        }
        const { result } = JSON.parse(stdout)
        const { invocationResponse } = result.skillExecutionInfo
        const { response } = invocationResponse.body
        assert.equal(response.card.content.indexOf('<p>'), -1)
        assert.equal(response.card.content.indexOf('undefined'), -1)
        done()
      })
    })
  })
})
```

このテストは外部のAPIをコールする形で実行されます。
そのためテストの実行時間が長くなりがちです。
テストを実行する際は、`--timeout 20000`のようにタイムアウト時間を伸ばすオプションをつけるようにしましょう。


## 実機テストでの注意点
ここまで構文チェックやユニットテストなど、さまざまなチェックを実施しました。
そしていよいよ申請前の最終チェックが実機での動作確認です。

これまでのテストは、「スキルが問題なく動作するか」のテストでした。
しかし最後の実機テストで確認するものは「スキルが快適に利用できるか」というものです。

そして実機でのテストにあたって意識すべき点については、Amazonの音声デザインガイドが参考になります。
音声デザインガイドの中には、「設計チェックリスト」という項目があります。
ここでは以下のような項目がチェックリストとして用意されています。

- あなたのスキルでユーザーが何をできるか、明確ですか？
- ユーザーはあなたのスキルを見つけることができますか？
- 自然な会話となるように設計されていますか？
- よいデザイン方法に沿った設計をしていますか？
- ユーザーが想定外の発話をした場合でも、丁寧に対応するようになっていますか？
- ユーザーがスキルを利用するところを観察しましたか？

[https://developer.amazon.com/ja/designing-for-voice/design-checklist/](https://developer.amazon.com/ja/designing-for-voice/design-checklist/)

これらの点をおさえるためには、「日常生活の中で、発話しやすい起動Wordとサンプル発話が用意されているか？」や
「言い間違い・言い澱みした時にどう対応するか？」などのテストが必要です。

ターゲットとしているユーザーに試してもらい、フィードバックを集めることが理想的でしょう。