import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'screens/admin_login_screen.dart';
import 'screens/admin_panel_screen.dart';

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KeTta Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const AdminLoginScreen(),
        '/admin': (context) => const AdminPanelScreen(),
      },
    );
  }
}
