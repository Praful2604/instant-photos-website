import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/landing_page_screens/home_page.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

void main() async {
  usePathUrlStrategy();
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
    return MaterialApp(
      title: 'Instant Photo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A237E),
          primary: const Color(0xFF1A237E),
          secondary: const Color(0xFF00BCD4),
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme(),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF1A237E),
          ),
        ),
      ),
      home: const HomePage(),

     //  home: const SimplePageFlip(),
      debugShowCheckedModeBanner: false,
    );
  }
}
