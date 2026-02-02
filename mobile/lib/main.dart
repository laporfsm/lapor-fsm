import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/router/app_router.dart'; // Add Router Import
import 'package:mobile/core/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/core/services/api_service.dart';
import 'package:mobile/core/services/notification_service.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:mobile/core/services/fcm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize Notification Services
  await NotificationService.init(); // Keep existing local notification init for now
  await FCMService.init(); // Initialize FCM

  // Restore Auth Session if exists
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');
  if (token != null) {
    apiService.setAuthToken(token);
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      // Change to .router
      title: 'Lapor FSM!',
      theme: AppTheme.lightTheme,
      routerConfig: appRouter, // Use the router
      debugShowCheckedModeBanner: false,
    );
  }
}
