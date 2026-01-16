import 'package:Texspin/services/api_service.dart';
import 'package:Texspin/utils/shared_preferences_manager.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/app.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Handling background message: ${message.messageId}");
  print("Background message data: ${message.data}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  try {
    NotificationSettings settings = await FirebaseMessaging.instance
        .requestPermission(alert: true, badge: true, sound: true);
    print("Permission: ${settings.authorizationStatus}");

    FirebaseMessaging.instance.getInitialMessage().then((
      RemoteMessage? message,
    ) {
      if (message != null) {
        print("App opened from terminated state via notification");
        print("Notification data: ${message.data}");

        Future.delayed(const Duration(milliseconds: 500), () {
          _handleNotificationClick(message);
        });
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("App opened from background via notification");
      print("Notification data: ${message.data}");
      _handleNotificationClick(message);
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Received foreground message: ${message.messageId}");
      print("Message data: ${message.data}");
      if (message.notification != null) {
        print("Notification title: ${message.notification!.title}");
        print("Notification body: ${message.notification!.body}");
      }
    });

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      print("FCM Token Refreshed: $newToken");
      SharedPreferencesManager.saveFcmToken(newToken);
      _updateFcmTokenIfLoggedIn(newToken);
    });
  } catch (e) {
    print("Firebase Messaging error (continuing without it): $e");
  }
  runApp(const MyApp());
}

void _handleNotificationClick(RemoteMessage message) {
  final data = message.data;
  final route = data['route'];
  final projectId = data['projectId'];
  final type = data['type'];

  print(
    "Handling notification click - route: $route, projectId: $projectId, type: $type",
  );

  if (route != null && navigatorKey.currentState != null) {
    navigatorKey.currentState!.pushNamed(route);
  } else if (projectId != null && navigatorKey.currentState != null) {
    navigatorKey.currentState!.pushNamed('/project/$projectId');
  }
}

Future<void> _updateFcmTokenIfLoggedIn(String fcmToken) async {
  try {
    final token = await SharedPreferencesManager.getToken();

    if (token == null || token.isEmpty) {
      print("⏳ Skipping FCM token update - user not authenticated yet");
      return;
    }

    final api = ApiService();
    final userRole = await SharedPreferencesManager.getUserRole();

    if (userRole == 'staff') {
      await api.updateStaffFcmToken(fcmToken);
      print("🎉 Staff FCM token updated successfully");
    } else if (userRole == 'manager') {
      await api.updateManagerFcmToken(fcmToken);
      print("🎉 Manager    token updated successfully");
    } else if (userRole == 'worker') {
      await api.updateWorkerFcmToken(fcmToken);
      print("🎉 Worker FCM token updated successfully");
    } else {
      await api.updateFcmToken(fcmToken);
      print("🎉 Admin FCM token updated successfully");
    }
  } catch (e) {
    print("Error updating FCM token: $e");
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Texspin',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      home: const App(),
    );
  }
}
