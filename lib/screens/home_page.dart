import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:health_pet/providers/pet_profile_provider.dart';
import 'package:health_pet/screens/create_pet_profile_screen.dart';
import 'package:health_pet/theme/bottom_navigation_bar.dart';

class PetHealthHomePage extends ConsumerStatefulWidget {
  const PetHealthHomePage({super.key});

  @override
  ConsumerState<PetHealthHomePage> createState() => _PetHealthHomePageState();
}

class _PetHealthHomePageState extends ConsumerState<PetHealthHomePage> {
  late Future<List<Map<String, dynamic>>> _petsFuture;

  @override
  void initState() {
    super.initState();
    _loadPets();
  }

  Future<void> _loadPets() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      setState(() {
        _petsFuture = ref.read(petProfileProvider.notifier).getUserPets(userId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Evcil Hayvanlarım'),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadPets),
        ],
      ),
      body: userId == null
          ? _buildNotLoggedIn()
          : FutureBuilder<List<Map<String, dynamic>>>(
              future: _petsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Hata: ${snapshot.error}'));
                }
                final pets = snapshot.data ?? [];
                return pets.isEmpty ? _buildEmptyState() : _buildPetGrid(pets);
              },
            ),
      floatingActionButton: userId != null
          ? FloatingActionButton(
              onPressed: () => _navigateToCreatePet(context, userId),
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: const CustomBottomNavigationBar(
        userId: '',
        petId: '',
      ),
    );
  }

  Widget _buildNotLoggedIn() {
    return const Center(
      child: Text('Lütfen giriş yapın', style: TextStyle(fontSize: 18)),
    );
  }

  Widget _buildEmptyState() {
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

  Widget _buildPetGrid(List<Map<String, dynamic>> pets) {
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
    ).then((_) => _loadPets());
  }
}

class _PetCard extends StatelessWidget {
  final Map<String, dynamic> pet;

  const _PetCard({required this.pet});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: pet['profilePictureUrl']?.isNotEmpty == true
                  ? Image.network(
                      pet['profilePictureUrl'],
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
                  pet['name'] ?? 'İsimsiz',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${pet['type'] ?? '-'} • ${pet['breed'] ?? '-'}',
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Yaş: ${_calculateAge(pet['birthDate'])}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
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

  String _calculateAge(String? birthDate) {
    if (birthDate == null || birthDate.isEmpty) return 'Bilinmiyor';
    try {
      final birth = DateTime.parse(birthDate);
      final age = DateTime.now().difference(birth).inDays ~/ 365;
      return '$age';
    } catch (e) {
      return '?';
    }
  }
}
