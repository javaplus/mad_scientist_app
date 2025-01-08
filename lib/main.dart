import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';

Brightness brighntess = Brightness.light;

// Primary color scheme for the app
ColorScheme appColorScheme = ColorScheme.fromSeed(
  brightness: brighntess,
  seedColor: Color(0x002d549d),
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Logger.level = Level.all;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mad Scientist App',
      theme: ThemeData(
        brightness: brighntess,
        textTheme: GoogleFonts.anonymousProTextTheme(),
        colorScheme: appColorScheme,
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: appColorScheme.primary,
          foregroundColor: appColorScheme.onPrimary,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: appColorScheme.primary,
            foregroundColor: appColorScheme.onPrimary,
            padding: const EdgeInsets.all(12),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(2),
              ),
            ),
          ),
        ),
      ),
      home: HomeScreen(),
    );
  }
}
