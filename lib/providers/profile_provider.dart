import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

final profileControllerProvider =
    StateNotifierProvider<ProfileController, ProfileState>(
      (ref) => ProfileController(),
    );

class ProfileState {
  final String email;
  final List<Map<String, dynamic>> pets;

  ProfileState({required this.email, required this.pets});

  ProfileState copyWith({String? email, List<Map<String, dynamic>>? pets}) {
    return ProfileState(email: email ?? this.email, pets: pets ?? this.pets);
  }
}

class ProfileController extends StateNotifier<ProfileState> {
  ProfileController() : super(ProfileState(email: '', pets: [])) {
    loadProfile();
    loadPets();
  }

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Future<void> loadProfile() async {
    final user = _auth.currentUser;
    if (user != null) {
      state = state.copyWith(email: user.email ?? '');
    }
  }

  Future<void> loadPets() async {
    final user = _auth.currentUser;
    if (user != null) {
      final petCollection = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('pets')
          .get();

      final pets = petCollection.docs.map((doc) {
        return {
          'id': doc.id,
          'name': doc['name'],
          'profilePictureUrl': doc['profilePictureUrl'],
        };
      }).toList();

      state = state.copyWith(pets: pets);
    }
  }

  Future<void> deletePet(String petId) async {
    try {
      // Firebase'den sil
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('pets')
          .doc(petId)
          .delete();

      // State içindeki pets listesini güncelle
      final updatedPets = state.pets
          .where((pet) => pet['id'] != petId)
          .toList();

      // Yeni state ile güncelle
      state = state.copyWith(pets: updatedPets);
    } catch (e) {
      // Hata yönetimi (opsiyonel)
      print('Pet silme hatası: $e');
    }
  }
}
