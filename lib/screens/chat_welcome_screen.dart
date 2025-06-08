// lib/screens/welcome_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'chat_screen.dart';
import '../providers/pet_provider.dart';
import '../models/pet_model.dart';

class ChatWelcomeScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext ctx, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Veteriner Asistan')),
      body: ref
          .watch(userPetsProvider)
          .when(
            data: (pets) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Bir hayvan seçin ya da "Genel Soru" ile devam edin.',
                    ),
                    ...pets.map(
                      (p) => ElevatedButton(
                        child: Text(p.name),
                        onPressed: () {
                          ref.read(selectedPetProvider.notifier).state = p;
                          Navigator.push(
                            ctx,
                            MaterialPageRoute(
                              builder: (_) => const ChatScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    ElevatedButton(
                      child: const Text('Genel Soru'),
                      onPressed: () {
                        ref.read(selectedPetProvider.notifier).state = null;
                        Navigator.push(
                          ctx,
                          MaterialPageRoute(builder: (_) => const ChatScreen()),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Hata: $e')),
          ),
    );
  }
}
