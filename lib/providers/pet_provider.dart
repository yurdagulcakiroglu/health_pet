// lib/providers/pet_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_pet/models/pet_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

final userPetsProvider = FutureProvider<List<Pet>>((ref) async {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  final snap = await FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('pets')
      .get();
  return snap.docs.map((d) => Pet.fromFirestore(d, null)).toList();
});

final selectedPetProvider = StateProvider<Pet?>((_) => null);
