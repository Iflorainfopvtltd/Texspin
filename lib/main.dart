import 'package:convert2dart/services/api_service.dart';
import 'package:convert2dart/utils/shared_preferences_manager.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/app.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Global navigator key for handling notification navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Handling background message: ${message.messageId}");
  print("Background message data: ${message.data}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Set up background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  try {
    // Request notification permission
    NotificationSettings settings = await FirebaseMessaging.instance
        .requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print("Permission: ${settings.authorizationStatus}");
    
    // Handle notification when app is opened from terminated state
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print("App opened from terminated state via notification");
        print("Notification data: ${message.data}");
        // Delay navigation to ensure app is fully initialized
        Future.delayed(const Duration(milliseconds: 500), () {
          _handleNotificationClick(message);
        });
      }
    });
    
    // Handle notification when app is in background and user taps on it
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("App opened from background via notification");
      print("Notification data: ${message.data}");
      _handleNotificationClick(message);
    });
    
    // Handle foreground messages (optional - for showing in-app notifications)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Received foreground message: ${message.messageId}");
      print("Message data: ${message.data}");
      if (message.notification != null) {
        print("Notification title: ${message.notification!.title}");
        print("Notification body: ${message.notification!.body}");
      }
      // You can show a snackbar or in-app notification here
    });
    
    // Listen for token refresh
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

// Handle notification click and navigate to appropriate screen
void _handleNotificationClick(RemoteMessage message) {
  final data = message.data;
  final route = data['route'];
  final projectId = data['projectId'];
  final type = data['type'];
  
  print("Handling notification click - route: $route, projectId: $projectId, type: $type");
  
  // Navigate based on the notification data
  if (route != null && navigatorKey.currentState != null) {
    navigatorKey.currentState!.pushNamed(route);
  } else if (projectId != null && navigatorKey.currentState != null) {
    // Navigate to project detail if projectId is provided
    navigatorKey.currentState!.pushNamed('/project/$projectId');
  }
  // Add more navigation logic based on your app's routes
}

Future<void> _updateFcmTokenIfLoggedIn(String fcmToken) async {
  try {
    final token = await SharedPreferencesManager.getToken();
    
    // Only update if user is authenticated
    if (token == null || token.isEmpty) {
      print("⏳ Skipping FCM token update - user not authenticated yet");
      return;
    }
    
    final api = ApiService();
    final userRole = await SharedPreferencesManager.getUserRole();
    
    // Send FCM token based on user role
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
      // Default to admin FCM token
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
