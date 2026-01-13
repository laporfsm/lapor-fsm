import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/router/app_router.dart'; // Add Router Import
import 'package:mobile/theme.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router( // Change to .router
      title: 'Lapor FSM!',
      theme: AppTheme.lightTheme,
      routerConfig: appRouter, // Use the router
      debugShowCheckedModeBanner: false,
    );
  }
}
