import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_pet/models/pet_model.dart';
import 'package:health_pet/providers/pet_profile_provider.dart';

class PetDetailsScreen extends ConsumerWidget {
  final String petId;

  const PetDetailsScreen({super.key, required this.petId});

  void _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    String title,
    String fieldName,
    String currentValue, {
    bool isGender = false,
  }) {
    final controller = TextEditingController(text: currentValue);
    String selectedGender = currentValue;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('$title Düzenle'),
          content: isGender
              ? DropdownButtonFormField<String>(
                  value: selectedGender,
                  items: <String>['Erkek', 'Dişi']
                      .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      })
                      .toList(),
                  onChanged: (String? newValue) {
                    selectedGender = newValue!;
                  },
                )
              : TextField(
                  controller: controller,
                  decoration: InputDecoration(hintText: "Yeni $title girin"),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () {
                final newValue = isGender ? selectedGender : controller.text;
                ref
                    .read(petProfileProvider.notifier)
                    .updateField(fieldName, newValue, petId);
                Navigator.pop(context);
              },
              child: const Text('Kaydet'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petAsync = ref.watch(petDetailsProvider(petId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hayvan Detayları'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final userId = FirebaseAuth.instance.currentUser!.uid;
              await ref
                  .read(petProfileProvider.notifier)
                  .deletePet(userId, petId);
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
      body: petAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Hata: $error')),
        data: (pet) => _buildPetDetails(context, ref, pet),
      ),
    );
  }

  Widget _buildPetDetails(BuildContext context, WidgetRef ref, Pet pet) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: CircleAvatar(
              radius: 60,
              backgroundImage: pet.profilePictureUrl != null
                  ? NetworkImage(pet.profilePictureUrl!)
                  : null,
              child: pet.profilePictureUrl == null
                  ? const Icon(Icons.pets, size: 60)
                  : null,
            ),
          ),
          const SizedBox(height: 20),

          // İsim
          _buildEditableListTile(
            context,
            ref,
            icon: Icons.adb,
            title: 'İsim',
            value: pet.name,
            fieldName: 'name',
          ),

          // Tür
          _buildEditableListTile(
            context,
            ref,
            icon: Icons.category,
            title: 'Tür',
            value: pet.type,
            fieldName: 'type',
          ),

          // Irk
          _buildEditableListTile(
            context,
            ref,
            icon: Icons.pets,
            title: 'Irk',
            value: pet.breed,
            fieldName: 'breed',
          ),

          // Doğum Tarihi
          _buildEditableListTile(
            context,
            ref,
            icon: Icons.cake,
            title: 'Doğum Tarihi',
            value: pet.birthDate,
            fieldName: 'birthDate',
          ),

          // Cinsiyet
          _buildEditableListTile(
            context,
            ref,
            icon: Icons.male,
            title: 'Cinsiyet',
            value: pet.gender,
            fieldName: 'gender',
            isGender: true,
          ),

          // Profil Fotoğrafı Güncelleme
          Center(
            child: ElevatedButton.icon(
              onPressed: () =>
                  ref.read(petProfileProvider.notifier).pickImage(),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Profil Fotoğrafını Güncelle'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableListTile(
    BuildContext context,
    WidgetRef ref, {
    required IconData icon,
    required String title,
    required String value,
    required String fieldName,
    bool isGender = false,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon),
          title: Text(title),
          subtitle: Text(value),
          trailing: IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditDialog(
              context,
              ref,
              title,
              fieldName,
              value,
              isGender: isGender,
            ),
          ),
        ),
        const Divider(),
      ],
    );
  }
}
