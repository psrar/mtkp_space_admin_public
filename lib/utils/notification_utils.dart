import 'dart:developer';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

const InitializationSettings _initializationSettings = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/launcher_icon'));

const NotificationDetails _platformChannelSpecifics = NotificationDetails(
    android: AndroidNotificationDetails('0', 'Важное',
        importance: Importance.max,
        priority: Priority.high,
        styleInformation: BigTextStyleInformation(''),
        ticker: 'ticker',
        playSound: true,
        enableLights: true,
        enableVibration: true));

const NotificationDetails _platformChannelSilentSpecifics = NotificationDetails(
    android: AndroidNotificationDetails('1', 'Фоновые оповещения',
        importance: Importance.min,
        priority: Priority.min,
        ticker: 'ticker',
        styleInformation: BigTextStyleInformation(''),
        channelShowBadge: false,
        playSound: false,
        enableLights: false,
        enableVibration: false));

class NotificationHandler {
  static final NotificationHandler _notificationHandler =
      NotificationHandler._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  factory NotificationHandler() => _notificationHandler;

  NotificationHandler._internal() {
    initializePlugin();
  }

  void initializePlugin() async {
    if (!kIsWeb) {
      await _flutterLocalNotificationsPlugin.initialize(_initializationSettings,
          onSelectNotification: (payload) => {});
    } else {
      log('kIsWeb, notifications disabled.');
    }
  }

  Future showNotification(String? title, String? body) async {
    await _flutterLocalNotificationsPlugin
        .show(0, title, body, _platformChannelSpecifics, payload: 'important');
  }

  Future showSilentNotification(String? title, String? body) async {
    await _flutterLocalNotificationsPlugin.show(
        1, title, body, _platformChannelSilentSpecifics,
        payload: 'silent');
  }
}
