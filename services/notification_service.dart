// lib/services/notification_service.dart
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();

  // 🔄 NEW channel id so Android recreates channel with correct importance
  static const String _defaultChannelId = 'default_channel_v2';
  static const String _defaultChannelName = 'General';
  static const String _defaultChannelDescription = 'General app notifications';

  static bool _initialized = false;

  // Initialize notifications (call once at app start)
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Android init
      const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS init
      const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initializationSettings =
      InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _notifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Android 13+ runtime permission
      await _notifications
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

      // iOS explicit permission
      await _notifications
          .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);

      // ✅ Create a default channel (Android 8+) with MAX importance
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        _defaultChannelId,
        _defaultChannelName,
        description: _defaultChannelDescription,
        importance: Importance.max, // <-- make it heads-up capable
        showBadge: true,
      );

      await _notifications
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      _initialized = true;
      debugPrint('✅ Local notifications initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing notifications: $e');
    }
  }

  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint('🔔 Notification tapped. Payload: ${response.payload}');
  }

  static NotificationDetails _defaultDetails() {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _defaultChannelId,
      _defaultChannelName,
      channelDescription: _defaultChannelDescription,
      importance: Importance.max,  // match channel
      priority: Priority.high,     // heads-up
      playSound: true,
      enableVibration: true,
      ticker: 'ticker',
    );

    const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    return const NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );
  }

  /// Show a local notification
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      await _notifications.show(
        id,
        title,
        body,
        _defaultDetails(),
        payload: payload,
      );
      debugPrint('🔔 Shown notification: $title');
    } catch (e) {
      debugPrint('❌ Error showing notification: $e');
    }
  }

  static Future<void> cancel(int id) async {
    try {
      await _notifications.cancel(id);
      debugPrint('Notification $id cancelled');
    } catch (e) {
      debugPrint('❌ Error cancelling notification $id: $e');
    }
  }

  static Future<void> cancelAll() async {
    try {
      await _notifications.cancelAll();
      debugPrint('All notifications cancelled');
    } catch (e) {
      debugPrint('❌ Error cancelling all notifications: $e');
    }
  }
}
