import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/router/app_router.dart'; // Add Router Import
import 'package:mobile/core/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/core/services/api_service.dart';
import 'package:mobile/core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Notification Service
  await NotificationService.init();
  
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
