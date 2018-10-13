## 審査前にスキルを検証

作成したスキルはAmazonの審査に提出する必要があります。審査に提出する際にはアイコン設定や、スキルの説明等が正しいのかを確認する必要があります。

そこで審査の内容を検証できるコマンドが`ask validate`です。

```console
$ ask validate -l ja-JP

Call validate-skill error.
Error code: 400
{
  "message": "Unsupported locale. Please note that only en-US, en-AU, en-CA, en-GB,
    en-IN locales are currently supported. Use the developer portal to
    test any other locales."
}
```

しかし、残念ながら2018年9月時点では`ja-JP`には未対応です。
英語で実行した場合には、以下の様なJSONで結果が返ってきます。

```console
$ ask validate -l en-US

Validation created for validation id: xxx-xxx-xxx-xxx-xxx
Waiting for validation response
{
  "id": "xxx-xxx-xxx-xxx-xxx",
  "status": "SUCCESSFUL",
  "result": {
    "validations": [
      {
        "locale": "en-US",
        "title": "Example phrases cannot be empty",
        "description": "Required: Provide at least 1 example phrase",
        "status": "SUCCESSFUL",
        "importance": "REQUIRED"
      },
      {
        "locale": "en-US",
        "title": "Too many Example Phrases provided",
        "description": "Please limit your entry to a maximum
          of 3 example phrases.",
        "status": "SUCCESSFUL",
        "importance": "REQUIRED"
      },
      {
        "locale": "en-US",
        "title": "Example Phrase has duplicate phrases",
        "description": "Your example phrases must not be duplicates.
          Please provide unique entries.",
        "status": "SUCCESSFUL",
        "importance": "REQUIRED"
      },
      {
        "locale": "en-US",
        "title": "Example Phrase too short",
        "description": "Your example phrase does not meet the minimum character
          limit of 2 characters.",
        "status": "SUCCESSFUL",
        "importance": "REQUIRED"
      },
      {
        "locale": "en-US",
        "title": "Example Phrase exceeds maximum length",
        "description": "Your example phrase has exceeded the maximum character
          limit of 200 characters.",
        "status": "SUCCESSFUL",
        "importance": "REQUIRED"
      },
      {
        "locale": "en-US",
        "title": "Example Phrase contains special characters",
        "description": "Example phrases can only contain apostrophes,
          quotation marks, questions marks, periods,
          exclamation points and commas.",
        "status": "SUCCESSFUL",
        "importance": "REQUIRED"
      },
      {
        "locale": "en-US",
        "title": "Example Phrase cannot be blank",
        "description": "The first example phrase may not be left empty.",
        "status": "SUCCESSFUL",
        "importance": "REQUIRED"
      },
      {
        "locale": "en-US",
        "title": "Example phrase must start with wake word",
        "description":
          "The example phrase must start with Alexa as the wake word.",
        "status": "SUCCESSFUL",
        "importance": "REQUIRED"
      },
      {
        "locale": "en-US",
        "title": "Example phrase must contain invocation name",
        "description":
          "Your example phrase must contain the invocation name: [greeter].",
        "status": "FAILED",
        "importance": "RECOMMENDED"
      },
      {
        "locale": "en-US",
        "title": "Example phrase must match launch pattern",
        "description":
          "Your example phrase, 'Alexa open hello world' does not follow
          the right launch pattern.",
        "status": "FAILED",
        "importance": "RECOMMENDED"
      },
      {
        "locale": "en-US",
        "title": "Example Phrase too short",
        "description":
          "Your example phrase does not meet the minimum character
          limit of 2 characters.",
        "status": "SUCCESSFUL",
        "importance": "REQUIRED"
      },
      {
        "locale": "en-US",
        "title": "Example Phrase exceeds maximum length",
        "description":
          "Your example phrase has exceeded the maximum character limit
          of 200 characters.",
        "status": "SUCCESSFUL",
        "importance": "REQUIRED"
      },
      {
        "locale": "en-US",
        "title": "Example Phrase contains special characters",
        "description":
          "Example phrases can only contain apostrophes, quotation marks,
          questions marks, periods, exclamation points and commas.",
        "status": "SUCCESSFUL",
        "importance": "REQUIRED"
      },
      {
        "locale": "en-US",
        "title": "Example phrase must contain invocation name",
        "description":
          "Your example phrase must contain the invocation name: [greeter].",
        "status": "FAILED",
        "importance": "RECOMMENDED"
      },
      {
        "locale": "en-US",
        "title": "Example Phrase too short",
        "description":
          "Your example phrase does not meet the minimum character
          limit of 2 characters.",
        "status": "SUCCESSFUL",
        "importance": "REQUIRED"
      },
      {
        "locale": "en-US",
        "title": "Example Phrase exceeds maximum length",
        "description":
          "Your example phrase has exceeded the maximum character
          limit of 200 characters.",
        "status": "SUCCESSFUL",
        "importance": "REQUIRED"
      },
      {
        "locale": "en-US",
        "title": "Example Phrase contains special characters",
        "description":
          "Example phrases can only contain apostrophes, quotation marks,
          questions marks, periods, exclamation points and commas.",
        "status": "SUCCESSFUL",
        "importance": "REQUIRED"
      },
      {
        "locale": "en-US",
        "title": "Example phrase must contain invocation name",
        "description":
          "Your example phrase must contain the invocation name: [greeter].",
        "status": "FAILED",
        "importance": "RECOMMENDED"
      }
    ]
  }
}
```

`result.validations`の中を見てみると、`status=FAILED`となっている項目があります。
本書執筆時点での確認項目は次の通りです（カッコ内は筆者による概訳）。

- Too many Example Phrases provided (サンプルのフレーズが多すぎないか)
- Example Phrase has duplicate phrases (重複したサンプルのフレーズがないか)
- Example Phrase too short (サンプルのフレーズが短すぎないか)
- Example Phrase exceeds maximum length (サンプルのフレーズが長すぎないか)
- Example Phrase contains special characters (サンプルのフレーズに特殊文字が含まれていないか)
- Example Phrase cannot be blank (サンプルのフレーズが空白になっていないか)
- Example phrase must start with wake word (サンプルのフレーズが起動Wordから始まっているか)
- Example phrase must contain invocation name (サンプルのフレーズが呼び出し名を含めているか)
- Example phrase must match launch pattern(サンプルのフレーズが起動パターンにマッチするか)

次のように、すべて`status=SUCCESSFUL`になればバリデーションは完了です。

```console
$ ask validate -l en-US -s amzn1.ask.skill.xxx

Validation created for validation id: XXXXXX-XXXX-XXXX-XXXX-XXXXXX
Waiting for validation response{
  "id": "XXXXXX-XXXX-XXXX-XXXX-XXXXXX",
  "status": "SUCCESSFUL",
  "result": {
    "validations": [
      {
        "locale": "en-US",
        "title": "Example phrases cannot be empty",
        "description": "Required: Provide at least 1 example phrase",
        "status": "SUCCESSFUL",
        "importance": "REQUIRED"
      },
      {
        "locale": "en-US",
        "title": "Too many Example Phrases provided",
        "description":
          "Please limit your entry to a maximum of 3 example phrases.",
        "status": "SUCCESSFUL",
        "importance": "REQUIRED"
      },
      {
        "locale": "en-US",
        "title": "Example Phrase has duplicate phrases",
        "description": "Your example phrases must not be duplicates.
          Please provide unique entries.",
        "status": "SUCCESSFUL",
        "importance": "REQUIRED"
      },
      {
        "locale": "en-US",
        "title": "Example Phrase too short",
        "description":
          "Your example phrase does not meet the minimum character
          limit of 2 characters.",
        "status": "SUCCESSFUL",
        "importance": "REQUIRED"
      },
      {
        "locale": "en-US",
        "title": "Example Phrase exceeds maximum length",
        "description":
          "Your example phrase has exceeded the maximum character
          limit of 200 characters.",
        "status": "SUCCESSFUL",
        "importance": "REQUIRED"
      },
      {
        "locale": "en-US",
        "title": "Example Phrase contains special characters",
        "description":
          "Example phrases can only contain apostrophes, quotation marks,
          questions marks, periods, exclamation points and commas.",
        "status": "SUCCESSFUL",
        "importance": "REQUIRED"
      },
      {
        "locale": "en-US",
        "title": "Example Phrase cannot be blank",
        "description": "The first example phrase may not be left empty.",
        "status": "SUCCESSFUL",
        "importance": "REQUIRED"
      },
      {
        "locale": "en-US",
        "title": "Example phrase must start with wake word",
        "description":
          "The example phrase must start with Alexa as the wake word.",
        "status": "SUCCESSFUL",
        "importance": "REQUIRED"
      },
      {
        "locale": "en-US",
        "title": "Example phrase must contain invocation name",
        "description": "Your example phrase must contain
          the invocation name: [kyoto city guide].",
        "status": "SUCCESSFUL",
        "importance": "RECOMMENDED"
      },
      {
        "locale": "en-US",
        "title": "Example Phrase must match utterance",
        "description":
          "Your example phrase, 'Alexa, ask kyoto city guide about'
          does not contain a sample utterance that you have provided
          in your intent(s).",
        "status": "SUCCESSFUL",
        "importance": "RECOMMENDED"
      },
      {
        "locale": "en-US",
        "title": "Example Phrase too short",
        "description":
          "Your example phrase does not meet the minimum character
          limit of 2 characters.",
        "status": "SUCCESSFUL",
        "importance": "REQUIRED"
      },
      {
        "locale": "en-US",
        "title": "Example Phrase exceeds maximum length",
        "description":
          "Your example phrase has exceeded the maximum character
          limit of 200 characters.",
        "status": "SUCCESSFUL",
        "importance": "REQUIRED"
      },
      {
        "locale": "en-US",
        "title": "Example Phrase contains special characters",
        "description":
          "Example phrases can only contain apostrophes, quotation marks,
          questions marks, periods, exclamation points and commas.",
        "status": "SUCCESSFUL",
        "importance": "REQUIRED"
      },
      {
        "locale": "en-US",
        "title": "Example Phrase must match utterance",
        "description":
          "Your example phrase, 'tell me about this place'
          does not contain a sample utterance that you have provided
          in your intent(s).",
        "status": "SUCCESSFUL",
        "importance": "RECOMMENDED"
      },
      {
        "locale": "en-US",
        "title": "Example Phrase too short",
        "description":
          "Your example phrase does not meet the minimum character
          limit of 2 characters.",
        "status": "SUCCESSFUL",
        "importance": "REQUIRED"
      },
      {
        "locale": "en-US",
        "title": "Example Phrase exceeds maximum length",
        "description":
          "Your example phrase has exceeded the maximum character limit
          of 200 characters.",
        "status": "SUCCESSFUL",
        "importance": "REQUIRED"
      },
      {
        "locale": "en-US",
        "title": "Example Phrase contains special characters",
        "description":
          "Example phrases can only contain apostrophes, quotation marks,
          questions marks, periods, exclamation points and commas.",
        "status": "SUCCESSFUL",
        "importance": "REQUIRED"
      },
      {
        "locale": "en-US",
        "title": "Example Phrase must match utterance",
        "description":
          "Your example phrase, 'recommend a temple.'
          does not contain a sample utterance that you have provided
          in your intent(s).",
        "status": "SUCCESSFUL",
        "importance": "RECOMMENDED"
      }
    ]
  }
}
```

### オプション

指定できるオプションは次のとおりです。

#### --skill-id / -s

検証したいスキルのIDを指定します。未指定の場合には`.ask/config`内で指定してあるスキルIDが利用されます。

```console
$ ask validate -s amzn1.ask.skill.xxx
```

#### --locales / -l

どの言語のスキルに対して検証を行うかを指定します。検証で利用できる言語の種類は次のとおりです。

- en-US
- en-GB
- en-CA
- en-AU
- en-IN

また、環境変数で`ASK_DEFAULT_DEVICE_LOCALE`として値を設定しておくと`--locales`の指定が不要になります。

```console
$ ask validate -l en-US
```

#### --stage / -g

スキルの状態を指定します。公開中のスキルに対しては`live`を、開発中には`development`を指定します。デフォルトは`development`です。

```console
$ ask validate -g development
```

## スキルの公開申請

スキルを作成して検証を行えばAmazonに公開申請ができます。公開する前に公式の「申請チェックリスト」に従ってスキルを再度確認しておきましょう。[https://developer.amazon.com/ja/docs/devconsole/test-and-submit-your-skill.html#review-checklists](https://developer.amazon.com/ja/docs/devconsole/test-and-submit-your-skill.html#review-checklists)

公開申請もコマンドで行えます。

```console
$ ask api submit -s amzn1.ask.skill.xxx

Skill submitted successfully.
```

### オプション

指定できるオプションは次のとおりです。

#### --skill-id / -s 【必須】

公開申請したいスキルのIDを指定します。

## スキルの公開を取り下げる

公開申請を行ったスキルで問題が見つかった場合には公開の取り下げを行います。公開の取り下げもコマンドで行なえます。
ただし取り下げる場合には理由を選択する必要があります。

```console
$ ask api withdraw -s amzn1.ask.skill.xxx

? Please choose your reason for the withdrawal:
  This is a test skill and not meant for certification
> I want to add more features to the skill
  I discovered an issue with the skill
  I haven't received certification feedback yet
  I do not intend to publish the skill right away
  Other reason

? Please choose your reason for the withdrawal:  I want to add more features
to the skill Skill withdrawn successfully.
```

### オプション

指定できるオプションは次のとおりです。

#### --skill-id / -s 【必須】

公開申請したいスキルのIDを指定します。

### 注意点

また、公開申請を出した直後には次のようなエラーが発生して取り下げる事ができません。しばらく時間が経ってから再度試してください。

```console
$ ask api withdraw -s amzn1.ask.skill.xxx

? Please choose your reason for the withdrawal:  This is a test skill and not meant
  for certification
Call withdraw error.
Error code: 403
{
  "message": "The submission has not finished processing for SkillId:
    amzn1.ask.skill.xxx"
}
```