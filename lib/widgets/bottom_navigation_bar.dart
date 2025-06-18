import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_pet/providers/navigation_provider.dart';
import 'package:health_pet/screens/chat_welcome_screen.dart';
//import 'package:health_pet/screens/home_screen.dart';
//import 'package:health_pet/screens/home_page.dart';
import 'package:health_pet/screens/location_screen.dart';
import 'package:health_pet/screens/pet_health_home_page.dart';
import 'package:health_pet/screens/profiles_screen.dart';
import 'package:health_pet/screens/reminder_screen.dart';
//import 'package:health_pet/screens/profiles_screen.dart';
//import 'package:health_pet/screens/reminder_screen.dart';
//import 'package:health_pet/screens/health_tips_screen.dart';
//import 'package:health_pet/screens/settings_screen.dart';

class CustomBottomNavigationBar extends ConsumerWidget {
  final String userId;
  final String petId;

  const CustomBottomNavigationBar({
    super.key,
    required this.userId,
    required this.petId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(navigationProvider);
    final navigationNotifier = ref.read(navigationProvider.notifier);

    return BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'AnaSayfa'),
        BottomNavigationBarItem(icon: Icon(Icons.pets), label: 'Profiller'),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications),
          label: 'Hatırlatıcılar',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.location_on_rounded),
          label: 'Yerler',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'AIngel'),
      ],
      currentIndex: selectedIndex,
      onTap: (index) => _navigateToPage(context, index, navigationNotifier),
    );
  }

  void _navigateToPage(
    BuildContext context,
    int index,
    NavigationNotifier notifier,
  ) {
    notifier.setIndex(index);

    final page = _getPageForIndex(index);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  Widget _getPageForIndex(int index) {
    switch (index) {
      case 0:
        return const PetHealthHomePage();
      case 1:
        return const ProfilesScreen();
      case 2:
        return const ReminderScreen(); //PetHealthHomePage(); //ReminderScreen();
      case 3:
        return const LocationScreen(); //PetHealthHomePage(); //HealthTipsScreen();
      case 4:
        return ChatWelcomeScreen(); //PetHealthHomePage(); //SettingsScreen();
      default:
        return const PetHealthHomePage();
    }
  }
}
