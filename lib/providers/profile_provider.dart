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
}
