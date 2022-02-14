import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:practice_cloud_functions/pages/home.dart';
import 'package:practice_cloud_functions/pages/information.dart';
import 'package:practice_cloud_functions/pages/message.dart';
import 'package:practice_cloud_functions/pages/offer.dart';

///プッシュ通知受信履歴一覧の Widget
class MessageList extends StatefulWidget {
  const MessageList({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _MessageList();
}

class _MessageList extends State<MessageList> {
  List<RemoteMessage> _messages = [];

  @override
  void initState() {
    ///Widget の initState で FirebaseMessaging.onMessage.listen
    super.initState();

    ///プッシュ通知を受信したら RemoteMessage オブジェクトが取得できるので配列の state に追加
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      setState(() {
        _messages = [..._messages, message];
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_messages.isEmpty) {
      return const Text('No messages received');
    }

    return ListView.builder(
        shrinkWrap: true,
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          RemoteMessage message = _messages[index];

          return ListTile(
              title: Text(
                  message.messageId ?? 'no RemoteMessage.messageId available'),
              subtitle: Text(
                  message.sentTime?.toString() ?? DateTime.now().toString()),

              ///プッシュ通知受信一覧をタップするとメッセージ詳細画面へ遷移
              onTap: () {
                switch (message.data['id']) {
                  case '1':
                    Navigator.pushNamed(
                      context,
                      '/offer',
                      arguments: OfferArguments(message, false),
                    );
                    break;
                  case '2':
                    Navigator.pushNamed(
                      context,
                      '/message',
                      arguments: MessageArguments(message, false),
                    );
                    break;
                  case '3':
                    Navigator.pushNamed(
                      context,
                      '/home',
                      arguments: HomeArguments(message, false),
                    );
                    break;
                  case '4':
                    Navigator.pushNamed(
                      context,
                      '/information',
                      arguments: InformationArguments(message, false),
                    );
                    break;
                  default:
                    Navigator.pushNamed(
                      context,
                      '/',
                    );
                }
              });
        });
  }
}
