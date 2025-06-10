import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:health_pet/providers/reminder_providers.dart';
import 'package:health_pet/screens/welcome_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
//import 'package:pet_health/screens/create_pets_profile_screen.dart';
import 'package:health_pet/screens/home_page.dart';
import 'package:health_pet/services/notification_service.dart';
//import 'package:pet_health/services/notification_service.dart';
//import 'package:timezone/data/latest.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: 'assets/.env');
  await NotificationService.init();
  await Firebase.initializeApp();
  //await NotificationHelper.initialize();
  //tz.initializeTimeZones();
  runApp(
    ProviderScope(
      // ProviderScope ile sarmalandı
      overrides: [
        notificationServiceProvider.overrideWithValue(NotificationService()),
        // Burada NotificationService sizin gerçek bildirim servisinizi temsil etmeli
      ],
      child: const PetHealth(),
    ),
  );
}

class PetHealth extends StatelessWidget {
  const PetHealth({super.key});

  // This widget is the root of your application.
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
      home: const WelcomeScreen(), // WelcomeScreen(),PetHealthHomePage()
    );
  }
}
