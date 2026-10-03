import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:musicapp/Screens/homescreen.dart';
import 'package:provider/provider.dart';
import 'package:musicapp/Screens/loginscreen.dart';
import 'package:musicapp/theme/theme_provider.dart';
import 'package:musicapp/theme/app_theme.dart';
import 'package:musicapp/providers/music_provider.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MusicProvider()),

        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],

      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,

      theme: themeProvider.lightTheme,

      darkTheme: themeProvider.darkTheme,

      themeMode: themeProvider.themeMode,

      home: const LoginScreen(),
    );
  }
}
