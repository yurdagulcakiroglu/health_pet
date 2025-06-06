import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:health_pet/models/pet_model.dart';
import 'package:health_pet/providers/pet_profile_provider.dart';
import 'package:health_pet/screens/create_pet_profile_screen.dart';
import 'package:health_pet/screens/pet_detail_screen.dart';
import 'package:health_pet/theme/bottom_navigation_bar.dart';

class PetHealthHomePage extends ConsumerWidget {
  const PetHealthHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final petsAsync = userId != null ? ref.watch(userPetsProvider) : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Evcil Hayvanlarım'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(userPetsProvider),
          ),
        ],
      ),
      body: userId == null
          ? _buildNotLoggedIn()
          : petsAsync?.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(child: Text('Hata: $error')),
                  data: (pets) => pets.isEmpty
                      ? _buildEmptyState(context)
                      : _buildPetGrid(pets),
                ) ??
                const SizedBox(),
      floatingActionButton: userId != null
          ? FloatingActionButton(
              onPressed: () => _navigateToCreatePet(context, userId),
              child: const Icon(Icons.add),
            )
          : null,
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

  Widget _buildNotLoggedIn() {
    return const Center(
      child: Text('Lütfen giriş yapın', style: TextStyle(fontSize: 18)),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.pets, size: 80, color: Colors.grey),
          const SizedBox(height: 20),
          Text(
            'Henüz evcil hayvan eklemediniz',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          const Text('Sağ alttaki + butonuna basarak ekleyebilirsiniz'),
        ],
      ),
    );
  }

  Widget _buildPetGrid(List<Pet> pets) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.9,
      ),
      itemCount: pets.length,
      itemBuilder: (context, index) => _PetCard(pet: pets[index]),
    );
  }

  void _navigateToCreatePet(BuildContext context, String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreatePetProfileScreen(userId: userId),
      ),
    );
  }
}

class _PetCard extends StatelessWidget {
  final Pet pet;

  const _PetCard({required this.pet});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Pet detay sayfasına yönlendirme
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PetDetailsScreen(petId: pet.id!),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: pet.profilePictureUrl?.isNotEmpty == true
                    ? Image.network(
                        pet.profilePictureUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholder(),
                      )
                    : _buildPlaceholder(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pet.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${pet.type} • ${pet.breed}',
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Yaş: ${_calculateAge(pet.birthDate)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(Icons.pets, size: 50, color: Colors.grey),
      ),
    );
  }

  String _calculateAge(String birthDate) {
    try {
      final birth = DateTime.parse(birthDate);
      final now = DateTime.now();
      int age = now.year - birth.year;
      if (now.month < birth.month ||
          (now.month == birth.month && now.day < birth.day)) {
        age--;
      }
      return '$age yaşında';
    } catch (e) {
      return 'Yaş hesaplanamadı';
    }
  }
}
