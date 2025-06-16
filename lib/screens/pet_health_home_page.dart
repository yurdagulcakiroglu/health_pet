import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:health_pet/screens/create_pet_profile_screen.dart';
import 'package:health_pet/screens/chat_welcome_screen.dart';
import 'package:health_pet/screens/pet_detail_screen.dart';
import 'package:health_pet/widgets/bottom_navigation_bar.dart';
import 'package:animate_do/animate_do.dart';

class PetHealthHomePage extends StatefulWidget {
  const PetHealthHomePage({super.key});

  @override
  State<PetHealthHomePage> createState() => _PetHealthHomePageState();
}

class _PetHealthHomePageState extends State<PetHealthHomePage> {
  String? _userId;
  List<Map<String, dynamic>> _pets = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser?.uid;
    _fetchPets();
  }

  Future<void> _fetchPets() async {
    if (_userId == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .collection('pets')
        .get();

    setState(() {
      _pets = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      _loading = false;
    });
  }

  // Hatırlatıcıları pets altındaki reminders koleksiyonundan çekiyoruz
  Future<List<Map<String, dynamic>>> _getReminders(String petId) async {
    if (_userId == null) return [];

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .collection('pets')
        .doc(petId)
        .collection('reminders')
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  String _calculateTimeLeft(Timestamp? reminderTimestamp) {
    if (reminderTimestamp == null) return 'Geçersiz zaman';
    final now = DateTime.now();
    final difference = reminderTimestamp.toDate().difference(now);
    if (difference.inDays > 0) return '${difference.inDays} gün kaldı';
    if (difference.inHours > 0) return '${difference.inHours} saat kaldı';
    if (difference.inMinutes > 0) return '${difference.inMinutes} dakika kaldı';
    return 'Hatırlatıcı zamanı geldi!';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Evcil Hayvanlarım'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Evcil hayvan avatar listesi
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                GestureDetector(
                  onTap: () async {
                    if (_userId != null) {
                      final newPet = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              CreatePetProfileScreen(userId: _userId!),
                        ),
                      );
                      if (newPet != null && mounted) {
                        _fetchPets(); // Yeni pet eklendiyse listeyi güncelle
                      }
                    }
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Color.fromARGB(199, 234, 248, 218),
                      child: Icon(
                        Icons.add,
                        size: 40,
                        color: Color(0xFF78C6F7),
                      ),
                    ),
                  ),
                ),
                ..._pets.map((pet) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PetDetailsScreen(petId: pet['id']),
                          ),
                        );
                      },
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage:
                            (pet['profilePictureUrl'] == null ||
                                pet['profilePictureUrl'].isEmpty)
                            ? null
                            : NetworkImage(pet['profilePictureUrl']),
                        backgroundColor: const Color(0xFFDCE9FC),
                        child:
                            (pet['profilePictureUrl'] == null ||
                                pet['profilePictureUrl'].isEmpty)
                            ? const Icon(
                                Icons.pets,
                                size: 40,
                                color: Color(0xFFA1EF7A),
                              )
                            : null,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Hatırlatıcılar ve AI kartı
          Expanded(
            child: ListView(
              children: [
                ..._pets.map((pet) {
                  return FutureBuilder<List<Map<String, dynamic>>>(
                    future: _getReminders(pet['id']),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text('Hata: ${snapshot.error}'),
                        );
                      }

                      final reminders = snapshot.data ?? [];

                      if (reminders.isEmpty) {
                        return const SizedBox.shrink(); // Hiç hatırlatıcı yoksa gizle
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 4,
                            ),
                            child: Text(
                              '${pet['name']} için Hatırlatıcılar',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          ...reminders.map((reminder) {
                            final reminderTime =
                                reminder['reminderDateTime'] as Timestamp?;
                            final timeLeft = _calculateTimeLeft(reminderTime);
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                vertical: 6.0,
                                horizontal: 16.0,
                              ),
                              elevation: 4,
                              child: ListTile(
                                leading: const Icon(
                                  Icons.alarm,
                                  color: Colors.teal,
                                ),
                                title: Text(
                                  '${reminder['reminderType']}',
                                  // Eğer petName de gerekiyorsa buraya eklenebilir ama zaten pet bazında listeleniyor
                                ),
                                subtitle: Text('Hatırlatıcı: $timeLeft'),
                              ),
                            );
                          }).toList(),
                        ],
                      );
                    },
                  );
                }),

                const SizedBox(height: 10),

                // AIngel kartı
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ZoomIn(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ChatWelcomeScreen(),
                          ),
                        );
                      },
                      child: Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF8DECB4), Color(0xFF78C6F7)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                '🤖 AIngel - Yapay Zekâ Asistanınız!',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Evcil dostlarınızın sağlığını AIngel ile kolayca yönetin. Hemen tıklayın!',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNavigationBar(
        userId: '',
        petId: '',
      ),
    );
  }
}
