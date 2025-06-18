import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:health_pet/providers/profile_provider.dart';
import 'package:health_pet/screens/pet_detail_screen.dart';
import 'package:health_pet/widgets/bottom_navigation_bar.dart';

class ProfilesScreen extends ConsumerStatefulWidget {
  const ProfilesScreen({super.key});

  @override
  ConsumerState<ProfilesScreen> createState() => _ProfilesScreenState();
}

class _ProfilesScreenState extends ConsumerState<ProfilesScreen> {
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmNewPasswordController =
      TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Profil ekranı her açıldığında pet listesi yeniden yüklensin
    ref.read(profileControllerProvider.notifier).loadPets();
  }

  Future<void> _updatePassword() async {
    if (_formKey.currentState!.validate()) {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        try {
          String email = user.email ?? '';
          AuthCredential credential = EmailAuthProvider.credential(
            email: email,
            password: _oldPasswordController.text,
          );

          await user.reauthenticateWithCredential(credential);
          await user.updatePassword(_newPasswordController.text);
          if (mounted) Navigator.of(context).pop();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Şifre başarıyla güncellendi')),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Şifre güncelleme hatası: $e')),
          );
        }
      }
    }
  }

  void _showUpdatePasswordDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Şifre Güncelle'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _oldPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Eski Şifre'),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Eski şifre boş olamaz'
                      : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Yeni Şifre'),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Yeni şifre boş olamaz'
                      : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _confirmNewPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Yeni Şifre (Tekrar)',
                  ),
                  validator: (value) => value != _newPasswordController.text
                      ? 'Şifreler uyuşmuyor'
                      : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: _updatePassword,
              child: const Text('Güncelle'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              title: const Text('E-posta'),
              subtitle: Text(profileState.email),
              tileColor: Colors.grey.shade100,
            ),
            const Divider(),
            ListTile(
              title: const Text('Şifre'),
              subtitle: const Text('******'),
              trailing: const Icon(Icons.edit),
              onTap: _showUpdatePasswordDialog,
            ),
            const SizedBox(height: 20),
            const Text(
              'Evcil Hayvanlarım',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF78C6F7),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                itemCount: profileState.pets.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemBuilder: (context, index) {
                  final pet = profileState.pets[index];
                  return GestureDetector(
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              PetDetailsScreen(petId: pet['id']),
                        ),
                      );
                      if (result == true) {
                        ref.read(profileControllerProvider.notifier).loadPets();
                      }
                    },
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: const Color(0xFFDCE9FC),
                          backgroundImage:
                              (pet['profilePictureUrl'] != null &&
                                  pet['profilePictureUrl'] != '')
                              ? NetworkImage(pet['profilePictureUrl'])
                              : null,
                          child:
                              (pet['profilePictureUrl'] == null ||
                                  pet['profilePictureUrl'] == '')
                              ? const Icon(
                                  Icons.pets,
                                  size: 40,
                                  color: Color(0xFFA1EF7A),
                                )
                              : null,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          pet['name'] ?? 'İsimsiz',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavigationBar(
        userId: '',
        petId: '',
      ),
    );
  }
}
