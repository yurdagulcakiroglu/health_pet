import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Evcil hayvanları getir
  Future<List<Map<String, dynamic>>> getPets(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('pets')
          .where('userId', isEqualTo: userId)
          .get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Error getting pets: $e');
      return [];
    }
  }

  // Hatırlatıcıları getir
  Future<List<Map<String, dynamic>>> getReminders(String petId) async {
    try {
      final snapshot = await _firestore
          .collection('pets')
          .doc(petId)
          .collection('reminders')
          .get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Error getting reminders: $e');
      return [];
    }
  }

  // Yeni evcil hayvan ekle
  Future<void> addPet(Map<String, dynamic> petData) async {
    await _firestore.collection('pets').add(petData);
  }
}
