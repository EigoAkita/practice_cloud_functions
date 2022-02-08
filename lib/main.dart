import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:practice_cloud_functions/permissions.dart';
import 'package:practice_cloud_functions/token_monitor.dart';

import 'message.dart';
import 'message_list.dart';

final logger = Logger();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel', // id
  'High Importance Notifications', // title
  importance: Importance.high,
  enableVibration: true,
  playSound: true,
);

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

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
        '/message': (context) => const MessageView(),
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
    FirebaseMessaging.instance.getInitialMessage().then(
      (RemoteMessage? message) {
        if (message != null) {
          Navigator.pushNamed(context, '/message',
              arguments: MessageArguments(message, true));
        }
      },
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

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

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      Navigator.pushNamed(context, '/message',
          arguments: MessageArguments(message, true));
    });
  }

  Future<void> sendPushMessage() async {
    if (_token.isEmpty) {
      return;
    }

    try {
      await http.post(
        Uri.parse('https://api.rnfirebase.io/messaging/send'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: constructFCMPayload(_token),
      );
    } catch (e) {
      logger.i(e.toString());
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
