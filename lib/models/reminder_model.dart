import 'package:cloud_firestore/cloud_firestore.dart';

// Reminder Modeli - Evcil hayvanlar için hatırlatıcı verilerini temsil eder.
class Reminder {
  // === Alanlar ===
  final String id;
  final String reminderText;
  final String reminderType;
  final DateTime? reminderDateTime;
  final Duration? interval;
  final bool isEnabled;
  final String petId;
  final String petName;
  final DateTime createdAt;
  final DocumentReference? reference;

  // === Kurucu Metot ===
  Reminder({
    required this.id,
    required this.reminderText,
    required this.reminderType,
    this.reminderDateTime,
    this.interval,
    this.isEnabled = true,
    required this.petId,
    required this.petName,
    required this.createdAt,
    this.reference,
  });

  // === Firestore'dan veri alma (Deserialization) ===
  factory Reminder.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data() ?? {};

    // reminderDateTime nullable kontrolü ve dönüşümü
    final Timestamp? reminderTimestamp = data['reminderDateTime'];
    final DateTime? reminderDateTime = reminderTimestamp?.toDate();

    // interval Firestore'da saat olarak tutuluyorsa int veya double olabilir, onu kontrol edip Duration yapıyoruz
    Duration? interval;
    final intervalValue = data['interval'];
    if (intervalValue != null) {
      if (intervalValue is int) {
        interval = Duration(hours: intervalValue);
      } else if (intervalValue is double) {
        interval = Duration(hours: intervalValue.toInt());
      }
    }

    final Timestamp? createdTimestamp = data['createdAt'];
    final createdAt = createdTimestamp != null
        ? createdTimestamp.toDate()
        : DateTime.now();

    return Reminder(
      id: snapshot.id,
      reminderText: data['reminderText'] ?? '',
      reminderType: data['reminderType'] ?? '',
      reminderDateTime: reminderDateTime,
      interval: interval,
      isEnabled: data['isEnabled'] ?? true,
      petId: data['petId'] ?? '',
      petName: data['petName'] ?? '',
      createdAt: createdAt,
      reference: snapshot.reference,
    );
  }

  // === Firestore'a veri yazma (Serialization) ===
  Map<String, dynamic> toFirestore() {
    return {
      'reminderText': reminderText,
      'reminderType': reminderType,
      'reminderDateTime': reminderDateTime != null
          ? Timestamp.fromDate(reminderDateTime!)
          : null,
      'interval': interval?.inHours,
      'isEnabled': isEnabled,
      'petId': petId,
      'petName': petName,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // === Nesne kopyalama ===
  Reminder copyWith({
    String? id,
    String? reminderText,
    String? reminderType,
    DateTime? reminderDateTime,
    Duration? interval,
    bool? isEnabled,
    String? petId,
    String? petName,
    DateTime? createdAt,
    DocumentReference? reference,
  }) {
    return Reminder(
      id: id ?? this.id,
      reminderText: reminderText ?? this.reminderText,
      reminderType: reminderType ?? this.reminderType,
      reminderDateTime: reminderDateTime ?? this.reminderDateTime,
      interval: interval ?? this.interval,
      isEnabled: isEnabled ?? this.isEnabled,
      petId: petId ?? this.petId,
      petName: petName ?? this.petName,
      createdAt: createdAt ?? this.createdAt,
      reference: reference ?? this.reference,
    );
  }

  // === Debug çıktısı ===
  @override
  String toString() {
    return 'Reminder(id: $id, text: $reminderText, type: $reminderType, '
        'dateTime: $reminderDateTime, interval: $interval, '
        'enabled: $isEnabled, petId: $petId, petName: $petName)';
  }
}
