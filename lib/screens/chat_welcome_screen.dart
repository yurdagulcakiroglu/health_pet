import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart';
import '../theme/app_colors.dart';
import '../widgets/bottom_navigation_bar.dart';
import '../providers/pet_profile_provider.dart';

class ChatWelcomeScreen extends ConsumerWidget {
  const ChatWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final petsAsync = userId != null ? ref.watch(userPetsProvider) : null;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            // Uygulama ismi
            Text(
              'AIngel',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDark,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Dijital Veteriner Asistanınız',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // Maskot tam merkezde ve büyük şekilde
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Center(
                  child: CircleAvatar(
                    radius: 100,
                    backgroundImage: const AssetImage(
                      'assets/images/mascot.png',
                    ),
                    backgroundColor: Colors.transparent,
                  ),
                ),
              ),
            ),

            // Butonlar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ChatScreen()),
                      );
                    },
                    child: const Text('Hadi başlayalım'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ChatScreen()),
                      );
                    },
                    child: const Text(
                      'Bana soru sor',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar:
          petsAsync?.when(
            data: (pets) => CustomBottomNavigationBar(
              userId: userId ?? '',
              petId: pets.isNotEmpty ? pets.first.id ?? '' : '',
            ),
            loading: () =>
                const CustomBottomNavigationBar(userId: '', petId: ''),
            error: (_, __) =>
                const CustomBottomNavigationBar(userId: '', petId: ''),
          ) ??
          const CustomBottomNavigationBar(userId: '', petId: ''),
    );
  }
}
