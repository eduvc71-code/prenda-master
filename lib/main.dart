import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prenda_master/core/constants/app_constants.dart';
import 'package:prenda_master/core/theme/app_theme.dart';
import 'package:prenda_master/core/router/app_router.dart';
import 'package:prenda_master/services/notification_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize timezone data for notifications
  initializeTimeZones();
  // Initialize local notifications
  initNotifications();
  // Setup workmanager for periodic tasks
  setupWorkmanager();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      routerConfig: appRouter,
    );
  }
}