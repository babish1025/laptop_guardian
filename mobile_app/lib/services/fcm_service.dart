import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';

/// Top-level background message handler required by Firebase Messaging
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  if (kDebugMode) {
    print('FCM Background message: ${message.messageId} - ${message.notification?.title}');
  }
}

class FcmService {
  final ApiService _api;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  bool _initialized = false;
  String? _fcmToken;
  String? _statusMessage = 'Not initialized';

  FcmService(this._api);

  String? get fcmToken => _fcmToken;
  String get statusMessage => _statusMessage ?? 'Inactive';
  bool get isReady => _initialized && _fcmToken != null;

  /// Initialize Firebase, local notification channel, and FCM listeners.
  /// Gracefully catches errors if google-services.json is missing or Firebase is unreachable.
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // 1. Initialize Firebase Core
      await Firebase.initializeApp();

      // 2. Setup background handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // 3. Setup Android notification channel for foreground alerts
      const androidChannel = AndroidNotificationChannel(
        'laptop_guardian_alerts',
        'Laptop Guardian Alerts',
        description: 'Instant alerts for laptop status changes, power events, and security.',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(androidChannel);
      }

      // Initialize local notifications plugin
      const initSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      );
      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) {
          if (kDebugMode) {
            print('Local notification tapped: ${response.payload}');
          }
        },
      );

      // 4. Request notification permissions (Android 13+)
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        _statusMessage = 'Notification permission denied by user';
        if (kDebugMode) print(_statusMessage);
        return;
      }

      // 5. Retrieve device token
      _fcmToken = await messaging.getToken();
      if (_fcmToken != null) {
        _statusMessage = 'FCM Active';
        if (kDebugMode) print('FCM Token: $_fcmToken');
        // Register token with backend
        await registerTokenWithBackend(_fcmToken!);
      }

      // 6. Listen for token refreshes
      messaging.onTokenRefresh.listen((newToken) async {
        _fcmToken = newToken;
        await registerTokenWithBackend(newToken);
      });

      // 7. Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final notification = message.notification;
        final android = message.notification?.android;

        if (notification != null && android != null) {
          _localNotifications.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                androidChannel.id,
                androidChannel.name,
                channelDescription: androidChannel.description,
                importance: Importance.max,
                priority: Priority.high,
                icon: '@mipmap/ic_launcher',
              ),
            ),
            payload: message.data['device_id']?.toString(),
          );
        }
      });

      // 8. Handle notification tap when app opened from background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        if (kDebugMode) {
          print('Notification caused app to open: ${message.data}');
        }
      });

      _initialized = true;
    } catch (e) {
      _statusMessage = 'Firebase not initialized (polling fallback active): $e';
      if (kDebugMode) print(_statusMessage);
    }
  }

  /// Register FCM push token with backend API
  Future<bool> registerTokenWithBackend(String token, {String? deviceId}) async {
    try {
      final res = await _api.post(
        '/api/devices/fcm-token',
        body: {
          'token': token,
          'platform': 'android',
          if (deviceId != null) 'device_id': deviceId,
        },
      );
      return res['success'] == true;
    } catch (e) {
      if (kDebugMode) print('Failed to send FCM token to backend: $e');
      return false;
    }
  }

  /// Sync token after user logs in
  Future<void> syncAfterLogin() async {
    if (_fcmToken != null) {
      await registerTokenWithBackend(_fcmToken!);
    }
  }
}
