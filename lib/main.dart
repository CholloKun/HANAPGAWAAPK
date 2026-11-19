import 'package:flutter/material.dart';
import 'services/supabase_service.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();
  runApp(const HanapGawaApp());
}

class HanapGawaApp extends StatelessWidget {
  const HanapGawaApp({super.key});

  @override
  Widget build(BuildContext context) {
    const maroonColor = Color(0xFF800000);
    const deepMaroon = Color(0xFF5A0000);

    return MaterialApp(
      title: 'Hanap Gawa — Worker & Service Booking',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: maroonColor,
          primary: maroonColor,
          secondary: deepMaroon,
          surface: const Color(0xFFFAF7F7),
        ),
        scaffoldBackgroundColor: const Color(0xFFFAF7F7),
        appBarTheme: const AppBarTheme(
          backgroundColor: maroonColor,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 2,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: maroonColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: maroonColor,
          foregroundColor: Colors.white,
        ),
      ),
      home: const LoginScreen(),
    );
  }
}
