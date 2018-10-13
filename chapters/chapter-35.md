## LambdaのLogを確認

ASK CLIで作ったスキルはLambdaを通してCloudWatchにログとして出力されます。このログをCLIから確認することが可能です。それが`ask lambda log`です。

```console
$ ask lambda log --function ask-custom-alexa-book-default

|=============== Display Logs ===============|
|==== Function Name: ask-custom-alexa-book-default ====|

START RequestId: xxx-xxx-xxx-xxx-xxx Version: $LATEST
END RequestId: xxx-xxx-xxx-xxx-xxx
REPORT RequestId: xxx-xxx-xxx-xxx-xxx	Duration: 75.04 ms	Billed Duration: 100 ms
  Memory Size: 128 MB	Max Memory Used: 49 MB
```

### オプション

指定できるオプションは次のとおりです。

#### --function / -f 【必須】

ログを表示したいLambda関数名を指定します。

#### --start-time --end-time

ログを表示したい日付の範囲を`--start-time`と`--end-time`で指定します。どちらか片方だけでもかまいません。また、各日付は時間も含めて指定することができます。

```console
$ ask lambda log --function ask-custom-alexa-book-default
  --start-time '2018-10-08 10:00' --end-time '2018-10-08 12:00'
```

#### --limit

`--limit`はログを表示する件数を指定できます。値は数値で指定します。

```console
$ ask lambda log --function ask-custom-alexa-book-default --limit 10
```

#### --raw

通常ログはCLIで見やすい様に色が付いて表示されますが、`--raw`を指定すると装飾無しのログとして表示されます。

### 注意点

現時点では、`ask lambda log`には`tail -f`のようなログを監視して表示を待つような指定をすることはできません。