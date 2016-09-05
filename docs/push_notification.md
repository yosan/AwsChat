# AWSからPush通知を受け取る

1. Apple Developer Programにアプリを登録

Apple Developer Programのアプリ登録ページで、プロジェクトのBundle IDを登録する。
https://developer.apple.com/account/ios/identifier/bundle/create

「Push Notifications」をONにしておくこと。

2. 証明書の生成とダウンロード

作られたアプリをクリックすると「Push Notifications」が「Configurable」になっている。
「Edit」を押すと、「Push Notifications」の欄で「Create Certificate」が選択できる。
その後表示されるガイドにしたがって証明書を作成し、キーチェーンに取り込む。
取り込めたら、キーチェーンからその証明書を左クリックし、p12ファイルとして書き出しする。

3. AWS SNSにアプリを登録

AWS SNSのアプリの一覧から「Create platform application」を選択してアプリを登録する。
https://ap-northeast-1.console.aws.amazon.com/sns/v2/home?region=ap-northeast-1#/applications
この際、先ほど書き出したp12ファイルを選択し、書き出し時に指定したパスワードを入力する必要がある。

4. アプリの実装

AppDelegate.swiftの各デリゲート実装を参照。

APNsからtokenを受け取り、NSNotificationCenterで通知している。
LoginServiceのloginメソッドにて、AWS SNSにtokenを登録している。

5. Push通知を送ってみる

AWS SNSのWebコンソールで登録しているアプリを開き、新規に作成されているEndpointを選択してメッセージを入力し、Publishで送信する。
