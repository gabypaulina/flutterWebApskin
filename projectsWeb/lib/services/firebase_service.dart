// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// class FirebaseService {
//   static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
//   static final FlutterLocalNotificationsPlugin _notificationsPlugin =
//   FlutterLocalNotificationsPlugin();
//
//   static Future<void> initialize() async {
//     // Setup local notifications
//     const AndroidInitializationSettings androidSettings =
//     AndroidInitializationSettings('@mipmap/ic_launcher');
//
//     const InitializationSettings initializationSettings =
//     InitializationSettings(android: androidSettings);
//
//     await _notificationsPlugin.initialize(
//       initializationSettings,
//       onDidReceiveNotificationResponse: (NotificationResponse response) {
//         _handleNotificationTap(response.payload);
//       },
//     );
//
//     // Request permission
//     NotificationSettings settings = await _firebaseMessaging.requestPermission(
//       alert: true,
//       badge: true,
//       sound: true,
//     );
//
//     // Get FCM token dan simpan ke server
//     await _getAndSaveFCMToken();
//
//     // Setup foreground message handler
//     FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
//
//     // Setup background message handler
//     FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
//
//     // Setup background message handler untuk ketika app terminated
//     FirebaseMessaging.instance.getInitialMessage().then(_handleBackgroundMessage);
//   }
//
//   static Future<void> _getAndSaveFCMToken() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final token = await _firebaseMessaging.getToken();
//
//       if (token != null) {
//         prefs.setString('fcm_token', token);
//         print('FCM Token: $token');
//
//         // Kirim token ke server
//         await _sendTokenToServer(token);
//       }
//     } catch (e) {
//       print('Error getting FCM token: $e');
//     }
//   }
//
//   static Future<void> _sendTokenToServer(String token) async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final userToken = prefs.getString('token');
//
//       if (userToken != null) {
//         // Implement API call to send token to server
//         print('Sending FCM token to server: $token');
//       }
//     } catch (e) {
//       print('Error sending token to server: $e');
//     }
//   }
//
//   static void _handleForegroundMessage(RemoteMessage message) {
//     _showLocalNotification(message);
//   }
//
//   static void _handleBackgroundMessage(RemoteMessage? message) {
//     if (message != null) {
//       _showLocalNotification(message);
//       _handleNotificationTap(message.data['type']);
//     }
//   }
//
//   static void _handleNotificationTap(String? payload) {
//     // Handle navigasi berdasarkan payload
//     if (payload == 'advertisement') {
//       // Navigate to notifications screen
//       print('Navigate to notifications screen');
//     }
//   }
//
//   static void _showLocalNotification(RemoteMessage message) {
//     const AndroidNotificationDetails androidPlatformChannelSpecifics =
//     AndroidNotificationDetails(
//       'high_importance_channel',
//       'High Importance Notifications',
//       channelDescription: 'This channel is used for important notifications',
//       importance: Importance.max,
//       priority: Priority.high,
//       showWhen: true,
//     );
//
//     const NotificationDetails platformChannelSpecifics =
//     NotificationDetails(android: androidPlatformChannelSpecifics);
//
//     _notificationsPlugin.show(
//       DateTime.now().millisecondsSinceEpoch ~/ 1000,
//       message.notification?.title ?? 'Notification',
//       message.notification?.body ?? 'New message',
//       platformChannelSpecifics,
//       payload: message.data['type'] ?? 'general',
//     );
//   }
//
//   static Future<String?> getFCMToken() async {
//     return await _firebaseMessaging.getToken();
//   }
// }