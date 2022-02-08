import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

///FCM Token を取得して画面に表示する Widget
class TokenMonitor extends StatefulWidget {
  const TokenMonitor(this._builder, {Key? key}) : super(key: key);

  final Widget Function(String? token) _builder;

  @override
  State<StatefulWidget> createState() => _TokenMonitor();
}

class _TokenMonitor extends State<TokenMonitor> {
  String? _token;
  late Stream<String> _tokenStream;

  void setToken(String? token) {
    setState(() {
      _token = token;
    });
  }

  @override
  void initState() {
    ///Widget の initState で FCM Token を取得して state にセット
    super.initState();

    ///getToken メソッドで FCM トークンを取得して state にセット
    FirebaseMessaging.instance.getToken().then(setToken);

    ///onTokenRefresh メソッドは、新しい FCM トークンが生成される度に呼出
    ///アプリのインストール時の他、トークンが変更されたときにも呼び出される為、
    ///listen してトークンの変更を監視
    _tokenStream = FirebaseMessaging.instance.onTokenRefresh;
    _tokenStream.listen(setToken);
  }

  @override
  Widget build(BuildContext context) {
    return widget._builder(_token);
  }
}
