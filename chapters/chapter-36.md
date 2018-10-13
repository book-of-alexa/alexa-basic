## インテント履歴

Alexaに対してユーザーがどの様な発話をして、どのインテントが呼び出されたのかを履歴で見ることができます。

ただし、インテント履歴に保存されるデータには制限があります。例えばロケールごとに1日最低10人のユニークユーザーの利用が必要です。また、全ての発話が保存されるわけではありません。発話されるデータはプライバシー基準に基づいて選択されたデータのみです。

しかし、インテント履歴を見ればユーザーがどの様な発話をしているかの傾向を見ることができます。スキルをどの様に改善すれば良いのかの指標にもなります。定期的に確認してスキル開発の改善に役立ててください。

### 結果

ASK CLIでインテント履歴を取得するには`ask api intent-requests-history`に履歴を取得したいスキルIDを`-s`で指定します。

```console
$ ask api intent-requests-history -s amzn1.ask.skill.xxx

{
  "_links": {
    "next": {
      "href": "/v1/skills/amzn1.ask.skill.xxx/history/intentRequests&nextToken=xxx"
    },
    "self": {
      "href": "/v1/skills/amzn1.ask.skill.xxx/history/intentRequests"
    }
  },
  "isTruncated": true,
  "items": [
    {
      "intent": {
        "confidence": {
          "bin": "HIGH"
        },
        "name": "SearchIntent",
        "slots": {
          "keyword": {
            "name": "keyword"
          }
        }
      },
      "interactionType": "MODAL",
      "locale": "ja-JP",
      "stage": "live",
      "utteranceText": "〇〇について調べて"
    }
  ],
  ...省略
  "nextToken": "xxx",
  "skillId": "amzn1.ask.skill.xxx",
  "startIndex": 0,
  "totalCount": 10
}
```

#### items

複数件のインテント履歴が格納されています。ユーザーが発話した内容は`items.utteranceText`です。その発話によって呼び出されたインテント名は`items.intent.name`です。

またインテント履歴は既にリリースされているスキルと開発中の両方で取得できます。`items.stage`が`live`になっているものが、リリース済みの履歴で`development`が開発中の履歴になります。

#### nextToken

インテント履歴の結果はデフォルトで10件づつ取得できます。表示件数を超える履歴がある場合には続きのデータを取得する必要があります。その際に利用するトークンが`nextToken`です。

その他の項目については公式ドキュメントを確認してください。[https://developer.amazon.com/ja/docs/smapi/intent-request-history.html](https://developer.amazon.com/ja/docs/smapi/intent-request-history.html)

### オプション

指定できるオプションは次のとおりです。

#### --skill-id / -s 【必須】

インテント履歴を表示したいスキルのIDを指定します。

#### --filters

インテント履歴を取得する時の条件を指定できます。例えば、リリース済みの履歴を取得する場合には`items.stage`を`live`だけに絞り込みます。

```console
$ ask api intent-requests-history -s amzn1.ask.skill.xxx
  --filters "Name=stage,Values=live"
```

複数の条件を組み合わせることも可能です。例えばリリース済みでインテント名を`SearchIntent`のみに絞り込みたいときには`;`で区切って指定します。

```console
$ ask api intent-requests-history -s amzn1.ask.skill.xxx
  --filters "Name=stage,Values=live;Name=intent.name,Values=SearchIntent"
```

#### --max-results

1度に取得するインテント履歴の数です。デフォルトは10件です。最大250件まで取得できます。

```console
$ ask api intent-requests-history -s amzn1.ask.skill.xxx --max-results 1
```

####  --sort-field --sort-direction

取得するインテント履歴の並び順を指定できます。例えばインテント名で昇順の履歴を取得したい場合には次のとおりです。

```console
$ ask api intent-requests-history -s amzn1.ask.skill.xxx
  --sort-field intent.name --sort-direction asc
```

並び順のデフォルトが`desc`となっているので注意してください。

#### --next-token

取得したインテント履歴の結果の数が多い場合には複数に分かれる場合があります。その際に利用するオプションです。`--next-token`に指定する値は、前回の検索で取得した結果の`nextToken`です。

```console
$ ask api intent-requests-history -s amzn1.ask.skill.xxx --next-token [取得した結果のnextToken]
```
