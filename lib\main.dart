import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // This file was created by flutterfire configure
import 'providers/auth_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/main_navigation.dart'; // 🛠️ Imported the missing master ribbon navigation shell!

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AuthProvider(),
      child: MaterialApp(
        title: 'TaskFlow',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          primaryColor: const Color(0xFF7C3AED),
          scaffoldBackgroundColor: const Color(0xFF020617),
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    // 🚀 Fixed! If authenticated, route straight to MainNavigation shell instead of standalone Dashboard.
    if (authProvider.user != null) {
      return const MainNavigation();
    } else {
      return const AuthScreen();
    }
  }
}