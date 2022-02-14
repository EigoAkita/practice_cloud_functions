import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class HomeArguments {
  final RemoteMessage message;
  final bool openedApplication;

  ///RemoteMessage概要
  ///RemoteMessageのプッシュ通知のタイトル、テキストのプロパティがnotification
  ///notificationはRemoteNotificationクラス
  ///RemoteNotificationクラスのAndroidNotification,AppleNotificationとAndroid/iOS
  ///固有のプロパティが用意されている

  HomeArguments(this.message, this.openedApplication);
}

class HomeView extends StatelessWidget {
  const HomeView({Key? key}) : super(key: key);

  Widget row(String title, String? value) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8, top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title: ',
            style: const TextStyle(color: Colors.black),
          ),
          Expanded(
              child: Text(
            value ?? 'N/A',
            style: const TextStyle(color: Colors.black),
          )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final HomeArguments args =
        ModalRoute.of(context)!.settings.arguments as HomeArguments;
    RemoteMessage message = args.message;
    RemoteNotification? notification = message.notification;

    return Scaffold(
      backgroundColor: Colors.tealAccent,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.tealAccent,
        title: const Text(
          'ホーム画面',
          style: TextStyle(
            fontSize: 18,
            color: Colors.black,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              row('Triggered application open',
                  args.openedApplication.toString()),
              row('Data', message.data['id']),

              ///notification を取得して、null じゃなかったら iOS/Android それぞれ固有のプロパティを表示
              if (notification != null) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ホーム画面',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.black,
                        ),
                      ),
                      row(
                        'Title',
                        notification.title,
                      ),
                      row(
                        'Body',
                        notification.body,
                      ),
                      if (notification.android != null) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Android Properties',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.black,
                          ),
                        ),
                        row(
                          'Priority',
                          notification.android!.priority.toString(),
                        ),
                        row(
                          'Sound',
                          notification.android!.sound,
                        ),
                        row(
                          'Visibility',
                          notification.android!.visibility.toString(),
                        ),
                      ],
                      if (notification.apple != null) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Apple Properties',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.black,
                          ),
                        ),
                        row(
                          'Subtitle',
                          notification.apple!.subtitle,
                        ),
                        row(
                          'Badge',
                          notification.apple!.badge,
                        ),
                        row(
                          'Sound',
                          notification.apple!.sound?.name,
                        ),
                      ]
                    ],
                  ),
                )
              ]
            ],
          ),
        ),
      ),
    );
  }
}
