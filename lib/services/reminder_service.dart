/*import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:health_pet/models/reminder_model.dart';
import 'package:health_pet/services/notification_service.dart';

class ReminderService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final NotificationHelper _notificationHelper;

  ReminderService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    NotificationHelper? notificationHelper,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _notificationHelper = notificationHelper ?? NotificationHelper();

  Future<List<Reminder>> getPets() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('pets')
        .withConverter<Reminder>(
          fromFirestore: (snapshot, _) =>
              Reminder.fromFirestore(snapshot, null),
          toFirestore: (reminder, _) => reminder.toFirestore(),
        )
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<List<Reminder>> getReminders() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final petsSnapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('pets')
        .get();

    final allReminders = <Reminder>[];

    for (final petDoc in petsSnapshot.docs) {
      final remindersSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('pets')
          .doc(petDoc.id)
          .collection('reminders')
          .withConverter<Reminder>(
            fromFirestore: (snapshot, _) =>
                Reminder.fromFirestore(snapshot, null),
            toFirestore: (reminder, _) => reminder.toFirestore(),
          )
          .orderBy('createdAt', descending: true)
          .get();

      allReminders.addAll(remindersSnapshot.docs.map((doc) => doc.data()));
    }

    return allReminders;
  }

  Future<void> addReminder({
    required BuildContext context,
    required String petId,
    required String reminderType,
    required DateTime? dateTime,
    required Duration? interval,
    required bool isEnabled,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Kullanıcı giriş yapmamış');

      final petDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('pets')
          .doc(petId)
          .get();

      if (!petDoc.exists) throw Exception('Pet bulunamadı');

      final petName = petDoc['name'] ?? 'Hayvan';
      final reminderText = '$petName için $reminderType zamanı';

      final reminderRef = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('pets')
          .doc(petId)
          .collection('reminders')
          .withConverter<Reminder>(
            fromFirestore: (snapshot, _) =>
                Reminder.fromFirestore(snapshot, null),
            toFirestore: (reminder, _) => reminder.toFirestore(),
          )
          .add(
            Reminder(
              id: '',
              reminderText: reminderText,
              reminderType: reminderType,
              reminderDateTime: dateTime,
              interval: interval,
              isEnabled: isEnabled,
              petId: petId,
              petName: petName,
              createdAt: DateTime.now(),
              reference: null,
            ),
          );

      if (dateTime != null) {
        await _notificationHelper.scheduleNotification(
          id: dateTime.millisecondsSinceEpoch,
          title: reminderText,
          body: 'Hatırlatıcı: $reminderText',
          scheduledDateTime: dateTime,
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hatırlatıcı başarıyla eklendi')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Hata: ${e.toString()}')));
      rethrow;
    }
  }

  Future<void> toggleReminder({
    required String petId,
    required String reminderId,
    required bool isEnabled,
  }) async {
    await _firestore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .collection('pets')
        .doc(petId)
        .collection('reminders')
        .doc(reminderId)
        .update({'isEnabled': isEnabled});
  }

  Future<void> deleteReminder({
    required String petId,
    required String reminderId,
    required DateTime? reminderDateTime,
  }) async {
    await _firestore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .collection('pets')
        .doc(petId)
        .collection('reminders')
        .doc(reminderId)
        .delete();

    if (reminderDateTime != null) {
      await _notificationHelper.cancelNotification(
        reminderDateTime.millisecondsSinceEpoch,
      );
    }
  }
}
*/
