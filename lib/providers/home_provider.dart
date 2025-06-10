import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_pet/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

final firestoreServiceProvider = Provider((ref) => FirestoreService());

final userIdProvider = FutureProvider<String?>((ref) async {
  return FirebaseAuth.instance.currentUser?.uid;
});

final petsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final firestore = ref.watch(firestoreServiceProvider);
  final userId = await ref.watch(userIdProvider.future);
  if (userId == null) return [];
  return await firestore.getPets(userId);
});

final petRemindersProvider =
    FutureProvider<Map<String, List<Map<String, dynamic>>>>((ref) async {
      final firestore = ref.watch(firestoreServiceProvider);
      final pets = await ref.watch(petsProvider.future);
      final Map<String, List<Map<String, dynamic>>> allReminders = {};

      for (var pet in pets) {
        final reminders = await firestore.getReminders(pet['id']);
        allReminders[pet['id']] = reminders;
      }

      return allReminders;
    });
