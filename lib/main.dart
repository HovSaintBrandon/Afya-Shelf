import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell.dart';
import 'screens/splash_screen.dart';
import 'config/theme.dart';

void main() {
  runApp(const AfyaShelfApp());
}

class AfyaShelfApp extends StatelessWidget {
  const AfyaShelfApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..tryAutoLogin()),
      ],
      child: MaterialApp(
        title: 'Afya Shelf',
        debugShowCheckedModeBanner: false,
        theme: AfyaTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}

class AuthCheck extends StatelessWidget {
  const AuthCheck({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return auth.isAuthenticated ? const MainShell() : const LoginScreen();
      },
    );
  }
}
