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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 30),
              // Başlık
              Text(
                'AIngel',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryDark,
                  letterSpacing: 3,
                  shadows: [
                    Shadow(
                      color: Colors.blue.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Dijital Veteriner Asistanınız',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Evcil dostunuzun sağlığıyla ilgili tüm sorularınızda yanınızda!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.4),
              ),
              const SizedBox(height: 20),

              // Maskot + hafif gölge efekti
              Expanded(
                child: Center(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 150,
                      backgroundImage: const AssetImage(
                        'assets/images/mascot.png',
                      ),
                      backgroundColor: Colors.transparent,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Başlat Butonu (degrade + gölge)
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
              const Text(
                'Bana soru sor',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 32),
            ],
          ),
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
