import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:health_pet/providers/reminder_providers.dart';
import 'package:health_pet/screens/pet_health_home_page.dart';
import 'package:health_pet/screens/welcome_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
//import 'package:pet_health/screens/create_pets_profile_screen.dart';
import 'package:health_pet/services/notification_service.dart';
import 'package:intl/date_symbol_data_file.dart';
//import 'package:pet_health/services/notification_service.dart';
//import 'package:timezone/data/latest.dart' as tz;
import 'firebase_options.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() async {
  // Flutter motorunun hazır olduğundan emin olur
  WidgetsFlutterBinding.ensureInitialized();

  // reklam servisi
  MobileAds.instance.initialize();
  // Ortam değişkenleri
  await dotenv.load(fileName: 'assets/.env');
  // Bildirim servisi
  await NotificationService.init();
  await Firebase.initializeApp();
  //await NotificationHelper.initialize();
  //tz.initializeTimeZones();

  runApp(
    ProviderScope(
      // ProviderScope ile sarmalandı
      overrides: [
        notificationServiceProvider.overrideWithValue(NotificationService()),
      ],
      child: const PetHealth(),
    ),
  );
}

class PetHealth extends StatelessWidget {
  const PetHealth({super.key});

  //bu kısım uygulamamın kökü
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pet Health App',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        canvasColor: Colors.white,
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Color(0xFFA1EF7A),
          unselectedItemColor: Colors.grey,
        ),
        //appbar tema
        appBarTheme: const AppBarTheme(
          scrolledUnderElevation: 0,
          backgroundColor: Colors.white,
        ),
      ),
      routes: {
        '/home': (context) => const PetHealthHomePage(),
        // '/welcome_screen': (context) => const WelcomeScreen()
      },
      home: const WelcomeScreen(),
    );
  }
}
