import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:health_pet/models/pet_model.dart';
import 'package:health_pet/providers/home_provider.dart';
import 'package:health_pet/providers/pet_profile_provider.dart';
import 'package:health_pet/screens/create_pet_profile_screen.dart';
import 'package:health_pet/widgets/bottom_navigation_bar.dart';

class PetHealthHomePage extends ConsumerWidget {
  const PetHealthHomePage({super.key});

  String _calculateTimeLeft(Timestamp? reminderTimestamp) {
    if (reminderTimestamp == null) return 'Geçersiz zaman';
    final reminderTime = reminderTimestamp.toDate();
    final now = DateTime.now();
    final difference = reminderTime.difference(now);
    if (difference.inDays > 0) {
      return '${difference.inDays} gün kaldı';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} saat kaldı';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} dakika kaldı';
    } else {
      return 'Hatırlatıcı zamanı geldi!';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final petsAsync = userId != null ? ref.watch(userPetsProvider) : null;
    final remindersAsync = ref.watch(petRemindersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Evcil Hayvanlarım'),
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),
      body: userId == null
          ? const Center(child: Text('Lütfen giriş yapınız.'))
          : petsAsync?.when(
                  data: (pets) {
                    return Column(
                      children: [
                        SizedBox(
                          height: 100,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          CreatePetProfileScreen(
                                            userId: userId,
                                          ),
                                    ),
                                  );
                                },
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                  ),
                                  child: CircleAvatar(
                                    radius: 50,
                                    backgroundColor: Color.fromARGB(
                                      199,
                                      234,
                                      248,
                                      218,
                                    ),
                                    child: Icon(
                                      Icons.add,
                                      size: 40,
                                      color: Color(0xFF78C6F7),
                                    ),
                                  ),
                                ),
                              ),
                              ...pets.map((pet) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                  ),
                                  child: CircleAvatar(
                                    radius: 50,
                                    backgroundImage:
                                        pet.profilePictureUrl?.isNotEmpty ==
                                            true
                                        ? NetworkImage(pet.profilePictureUrl!)
                                        : null,
                                    backgroundColor: const Color(0xFFDCE9FC),
                                    child:
                                        pet.profilePictureUrl?.isEmpty ?? true
                                        ? const Icon(
                                            Icons.pets,
                                            size: 40,
                                            color: Color(0xFFA1EF7A),
                                          )
                                        : null,
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        ),
                        Expanded(
                          child: remindersAsync.when(
                            data: (reminderMap) {
                              return ListView.builder(
                                itemCount: pets.length,
                                itemBuilder: (context, index) {
                                  final pet = pets[index];
                                  final reminders = reminderMap[pet.id] ?? [];

                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: reminders.isEmpty
                                        ? [
                                            Padding(
                                              padding: const EdgeInsets.all(
                                                8.0,
                                              ),
                                              child: Text(
                                                '${pet.name} için hatırlatıcı bulunmuyor.',
                                              ),
                                            ),
                                          ]
                                        : reminders.map((reminder) {
                                            final reminderTime =
                                                reminder['dateTime'];
                                            final timeLeft = _calculateTimeLeft(
                                              reminderTime,
                                            );
                                            return Card(
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 8.0,
                                                    horizontal: 16.0,
                                                  ),
                                              elevation: 4.0,
                                              child: ListTile(
                                                contentPadding:
                                                    const EdgeInsets.all(16.0),
                                                title: Text(
                                                  '${pet.name} için ${reminder['title']}',
                                                ),
                                                subtitle: Text(timeLeft),
                                              ),
                                            );
                                          }).toList(),
                                  );
                                },
                              );
                            },
                            loading: () => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            error: (e, _) =>
                                Center(child: Text('Hatırlatıcı hatası: $e')),
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Pet verisi hatası: $e')),
                ) ??
                const SizedBox(),
      bottomNavigationBar: CustomBottomNavigationBar(
        userId: userId ?? '',
        petId: '',
      ),
    );
  }
}
