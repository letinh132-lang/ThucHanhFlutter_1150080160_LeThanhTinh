import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FcmService {
  FcmService._();
  static final instance = FcmService._();
  final _messaging = FirebaseMessaging.instance;
  final _fln = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    if (Platform.isIOS) {
      await _messaging.requestPermission();
    } else {
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    final androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    final initSettings = InitializationSettings(
        android: androidInit, iOS: DarwinInitializationSettings());
    await _fln.initialize(initSettings);

    // Nhận thông báo foreground
    FirebaseMessaging.onMessage.listen((msg) async {
      final notification = msg.notification;
      if (notification == null) return;
      await _fln.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails('reviews', 'New Reviews',
              importance: Importance.high, priority: Priority.high),
          iOS: DarwinNotificationDetails(),
        ),
      );
    });

    // Subscribe topic để admin/khách nhận tin mới
    await _messaging.subscribeToTopic('new_reviews');
  }
}
