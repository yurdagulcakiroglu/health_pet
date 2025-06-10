import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:health_pet/models/reminder_model.dart';
import 'package:health_pet/models/pet_model.dart';
import 'package:health_pet/services/notification_service.dart';

class TimeRemainingUtils {
  String getTimeRemaining(DateTime reminderDate) {
    final now = DateTime.now();
    final difference = reminderDate.difference(now);

    if (difference.isNegative) {
      return 'Geçti';
    }

    if (difference.inDays > 0) {
      return '${difference.inDays}g ${difference.inHours.remainder(24)}s kaldı';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}s ${difference.inMinutes.remainder(60)}dk kaldı';
    } else {
      return '${difference.inMinutes}dk kaldı';
    }
  }

  Color getTimeRemainingColor(DateTime reminderDate) {
    final now = DateTime.now();
    final difference = reminderDate.difference(now);

    if (difference.isNegative) {
      return Colors.red;
    }

    if (difference.inHours < 24) {
      return Colors.orange;
    }

    return Colors.green;
  }
}

//=====PROVIDERLAR====
final reminderServiceProvider = Provider<ReminderService>((ref) {
  return ReminderService(FirebaseFirestore.instance, FirebaseAuth.instance);
});

final remindersProvider = FutureProvider.autoDispose<List<Reminder>>((
  ref,
) async {
  final service = ref.watch(reminderServiceProvider);
  return service.getReminders();
});

final remindersStreamProvider = StreamProvider.autoDispose<List<Reminder>>((
  ref,
) {
  final service = ref.watch(reminderServiceProvider);
  return service.remindersStream();
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  throw UnimplementedError(); // main() içinde override edeceğiz
});

final timeRemainingUtilsProvider = Provider<TimeRemainingUtils>((ref) {
  return TimeRemainingUtils();
});

// =====SERVİCE======
class ReminderService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ReminderService(this._firestore, this._auth);

  Future<List<Pet>> getPets() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('pets')
        .get();

    return snapshot.docs
        .map(
          (doc) => Pet(
            id: doc.id,
            name: doc['name'],
            birthDate: '',
            type: '',
            breed: '',
            userId: '',
            vaccineHistory: [],
            medicationHistory: [],
            weightHistory: [],
          ),
        )
        .toList();
  }

  Future<List<Reminder>> getReminders() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final petsSnap = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('pets')
        .get();

    final reminders = <Reminder>[];

    for (final pet in petsSnap.docs) {
      final remSnap = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('pets')
          .doc(pet.id)
          .collection('reminders')
          .orderBy('createdAt', descending: true)
          .get();

      reminders.addAll(
        remSnap.docs.map((doc) => Reminder.fromFirestore(doc, null)),
      );
    }

    return reminders;
  }

  Future<void> addReminder({
    required String petId,
    required String reminderType,
    required DateTime? dateTime,
    required Duration? interval,
    required bool isEnabled,
    required WidgetRef ref,
  }) async {
    final user = _auth.currentUser;
    if (user == null || dateTime == null) return;

    final petDoc = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('pets')
        .doc(petId)
        .get();

    final petName = petDoc.data()?['name'] ?? 'Hayvan';
    final reminderText = '$petName için $reminderType zamanı';

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('pets')
        .doc(petId)
        .collection('reminders')
        .add({
          'reminderText': reminderText,
          'reminderType': reminderType,
          'reminderDateTime': Timestamp.fromDate(dateTime),
          'interval': interval?.inHours,
          'isEnabled': isEnabled,
          'createdAt': FieldValue.serverTimestamp(),
          'petId': petId,
          'petName': petName,
        });
    // ==== BURADA BİLDİRİMİ PLANLIYOR ====
    final notificationService = ref.read(notificationServiceProvider);
    await notificationService.schedule(
      id: dateTime.hashCode,
      title: 'Hatırlatma',
      body: reminderText,
      dateTime: dateTime,
    );
  }

  Future<void> deleteReminder({
    required String petId,
    required String reminderId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('pets')
        .doc(petId)
        .collection('reminders')
        .doc(reminderId)
        .delete();
  }

  Future<void> toggleReminder({
    required String petId,
    required String reminderId,
    required bool isEnabled,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('pets')
        .doc(petId)
        .collection('reminders')
        .doc(reminderId)
        .update({'isEnabled': isEnabled});
  }

  Stream<List<Reminder>> remindersStream() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _firestore
        .collectionGroup('reminders')
        .where('userId', isEqualTo: user.uid) // userId alanı
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => Reminder.fromFirestore(d, null)).toList(),
        );
  }
}
