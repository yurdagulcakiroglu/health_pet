import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_pet/models/pet_model.dart';
import 'package:health_pet/providers/pet_profile_provider.dart';
import 'package:health_pet/screens/weight_history_screen.dart';
import 'package:health_pet/theme/app_colors.dart';

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
              await ref.read(petProfileProvider.notifier).deletePet(petId);
              if (context.mounted) Navigator.pop(context, true);
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
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor:
                      Colors.grey[200], // Arkaplan rengi (opsiyonel)
                  backgroundImage:
                      (pet.profilePictureUrl != null &&
                          pet.profilePictureUrl!.isNotEmpty)
                      ? NetworkImage(pet.profilePictureUrl!)
                      : null,
                  child:
                      (pet.profilePictureUrl == null ||
                          pet.profilePictureUrl!.isEmpty)
                      ? Icon(
                          Icons.pets,
                          size: 50,
                          color: AppColors.secondaryDark, // İstediğiniz renk
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => ref
                        .read(petProfileProvider.notifier)
                        .updateProfilePicture(petId),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: const Color.fromARGB(152, 212, 255, 201),
                      child: Icon(
                        Icons.edit,
                        size: 18,
                        color: AppColors.secondaryDark,
                      ),
                    ),
                  ),
                ),
              ],
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

          const SizedBox(height: 20),
          // 📏 Kilo Kartı
          Card(
            color: Colors.blue.shade50,
            elevation: 2,
            child: ListTile(
              leading: const Icon(Icons.monitor_weight_outlined),
              title: const Text("Kilo Takibi"),
              subtitle: Text(
                pet.weightHistory.isNotEmpty
                    ? (() {
                        // Tarihe göre en güncel kiloyu bul
                        final latest = pet.weightHistory.reduce(
                          (a, b) => a.date.isAfter(b.date) ? a : b,
                        );
                        return "${latest.weight} kg (${latest.date.day}.${latest.date.month}.${latest.date.year})";
                      })()
                    : "Kayıtlı kilo bilgisi yok",
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WeightHistoryScreen(pet: pet),
                  ),
                );
              },
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
