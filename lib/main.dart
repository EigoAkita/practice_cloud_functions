import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:practice_cloud_functions/pages/home.dart';
import 'package:practice_cloud_functions/pages/information.dart';
import 'package:practice_cloud_functions/pages/message.dart';
import 'package:practice_cloud_functions/pages/offer.dart';
import 'package:practice_cloud_functions/permissions.dart';
import 'package:practice_cloud_functions/token_monitor.dart';
import 'package:simple_logger/simple_logger.dart';
import 'message_list.dart';

final logger = SimpleLogger();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  ///アプリがフォアグラウンドの時以外にこの handler からアプリを起動された時の為にここでも
  ///await Firebase.initializeApp()
  await Firebase.initializeApp();
}

///Android特有のチャンネル
///別名カテゴリとも呼ばれていて一つのアプリで複数の通知カテゴリを持てたり、
///カテゴリごとにプッシュ通知を分けたりできる
///現状はHigh Importance Notificationという一つのカテゴリ
///High Importance Notificationの文言はアプリ情報/通知から見ることができる
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel', // id
  'High Importance Notifications', // title
  importance: Importance.high,
  enableVibration: true,
  playSound: true,
);

///Android ではアプリがフォアグラウンド状態で
///画面上部にプッシュ通知メッセージを表示することができない為、
///ローカル通知で擬似的に通知メッセージを表示

///グローバルにローカル通知を表示する
///FlutterLocalNotificationsPlugin クラスを宣言してオブジェクトを生成
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  ///WidgetsFlutterBinding.ensureInitialized() で Flutter Engine を使う準備
  WidgetsFlutterBinding.ensureInitialized();

  ///Firebase を初期化
  await Firebase.initializeApp();

  ///プッシュ通知をバックグラウンドやタスクを落としたターミネイト状態で受信した時の
  ///handler FirebaseMessaging.onBackgroundMessage
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  ///iOS 固有のフォアグラウンドのプッシュ通知受信時アクションを設定
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  runApp(
    const MessagingExampleApp(),
  );
}

class MessagingExampleApp extends StatelessWidget {
  const MessagingExampleApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Messaging Example App',
      theme: ThemeData.dark(),
      routes: {
        '/': (context) => const Application(),
        '/offer': (context) => const OfferView(),
        '/message': (context) => const MessageView(),
        '/home': (context) => const HomeView(),
        '/information': (context) => const InformationView(),
      },
    );
  }
}

int _messageCount = 0;

String constructFCMPayload(String token) {
  _messageCount++;
  return jsonEncode({
    'token': token,
    'data': {
      'via': 'FlutterFire Cloud Messaging!!!',
      'count': _messageCount.toString(),
    },
    'notification': {
      'title': 'Hello FlutterFire!',
      'body': 'This notification (#$_messageCount) was created via FCM!',
    },
  });
}

class Application extends StatefulWidget {
  const Application({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _Application();
}

class _Application extends State<Application> {
  late String _token;

  @override
  void initState() {
    super.initState();

    ///アプリのタスクを落としてる状態でプッシュ通知からアプリを起動した時のアクションを実装
    ///通知メッセージからアプリを起動したら Navigator.pushNamed で自動で画面遷移
    FirebaseMessaging.instance.getInitialMessage().then(
      (RemoteMessage? message) {
        switch (message!.data['id']) {
          case '1':
            Navigator.pushNamed(context, '/offer',
                arguments: OfferArguments(message, true));
            break;
          case '2':
            Navigator.pushNamed(context, '/message',
                arguments: MessageArguments(message, true));
            break;
          case '3':
            Navigator.pushNamed(context, '/home',
                arguments: HomeArguments(message, true));
            break;
          case '4':
            Navigator.pushNamed(context, '/information',
                arguments: InformationArguments(message, true));
            break;
          default:
            break;
        }
      },
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      ///FirebaseMessaging.onMessage.listen で取得したプッシュ通知のメッセージオブジェクト
      ///RemoteNotification とそのプロパティである AndroidNotification が null
      ///じゃなかったら flutterLocalNotificationsPlugin.show でローカル通知を表示
      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                channel.id,
                channel.name,
                icon: 'launch_background',
              ),
            ));
      }
    });

    ///FirebaseMessaging.onMessageOpenedApp.listen
    ///でバックグラウンド状態でプッシュ通知メッセージからアプリを起動した場合に
    ///メッセージ詳細画面へ遷移する実装
    ///通知メッセージからアプリを起動したら Navigator.pushNamed で自動で画面遷移
    FirebaseMessaging.onMessageOpenedApp.listen(
      (RemoteMessage message) {
        switch (message.data['id']) {
          case '1':
            Navigator.pushNamed(context, '/offer',
                arguments: OfferArguments(message, true));
            break;
          case '2':
            Navigator.pushNamed(context, '/message',
                arguments: MessageArguments(message, true));
            break;
          case '3':
            Navigator.pushNamed(context, '/home',
                arguments: HomeArguments(message, true));
            break;
          case '4':
            Navigator.pushNamed(context, '/information',
                arguments: InformationArguments(message, true));
            break;
          default:
            break;
        }
      },
    );
  }

  Future<void> sendPushMessage() async {
    if (_token.isEmpty) {
      return;
    }

    try {
      logger.info('メッセージ送信');
      await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: constructFCMPayload(_token),
      );
    } catch (e) {
      logger.info(e.toString());
    }
  }

  void onActionSelected(String value) async {
    switch (value) {
      case 'subscribe':
        {
          await FirebaseMessaging.instance.subscribeToTopic('fcm_test');
        }
        break;
      case 'unsubscribe':
        {
          await FirebaseMessaging.instance.unsubscribeFromTopic('fcm_test');
        }
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cloud Messaging"),
        actions: <Widget>[
          PopupMenuButton(
            onSelected: onActionSelected,
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem(
                  value: "subscribe",
                  child: Text("Subscribe to topic"),
                ),
                const PopupMenuItem(
                  value: "unsubscribe",
                  child: Text("Unsubscribe to topic"),
                ),
                const PopupMenuItem(
                  value: "get_apns_token",
                  child: Text("Get APNs token (Apple only)"),
                ),
              ];
            },
          ),
        ],
      ),
      floatingActionButton: Builder(
        builder: (context) => FloatingActionButton(
          onPressed: () => sendPushMessage(),
          child: const Icon(Icons.send),
          backgroundColor: Colors.white,
        ),
      ),
      body: SingleChildScrollView(
        child: Column(children: [
          const MetaCard("Permissions", Permissions()),
          MetaCard("FCM Token", TokenMonitor((token) {
            _token = token!;
            logger.info(token);
            return token.isEmpty
                ? const CircularProgressIndicator()
                : Text(token, style: const TextStyle(fontSize: 12));
          })),
          const MetaCard(
            "Message Stream",
            MessageList(),
          ),
        ]),
      ),
    );
  }
}

class MetaCard extends StatelessWidget {
  final String _title;
  final Widget _children;

  const MetaCard(this._title, this._children, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(left: 8, right: 8, top: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: Text(
                  _title,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              _children,
            ],
          ),
        ),
      ),
    );
  }
}
