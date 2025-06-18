import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

//=== aşı kayıtları için model
class Vaccine {
  final String name;
  final DateTime date;

  Vaccine({required this.name, required this.date});

  Map<String, dynamic> toFirestore() {
    return {'name': name, 'date': Timestamp.fromDate(date)};
  }

  factory Vaccine.fromFiresote(Map<String, dynamic> map) {
    return Vaccine(
      name: map['name'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
    );
  }
}

//=== ilaç kayıtları için model
class Medication {
  final String name;
  final DateTime date;
  final bool reminder;

  Medication({required this.name, required this.date, required this.reminder});

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'date': Timestamp.fromDate(date),
      'reminder': reminder,
    };
  }

  factory Medication.fromMap(Map<String, dynamic> map) {
    return Medication(
      name: map['name'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      reminder: map['reminder'] ?? false,
    );
  }
}

//=== kilo kayıtları için model
class WeightRecord {
  final DateTime date;
  final double weight;

  WeightRecord({required this.date, required this.weight});

  factory WeightRecord.fromFirestore(dynamic data) {
    try {
      if (data == null) throw Exception('Null veri geldi');

      // Tarih dönüşümü
      final date = data['date'];
      late DateTime parsedDate;

      if (date is Timestamp) {
        parsedDate = date.toDate();
      } else if (date is String) {
        parsedDate = DateTime.parse(date);
      } else {
        throw Exception('Geçersiz tarih formatı');
      }

      // Kilo dönüşümü
      final weight = data['weight'];
      late double parsedWeight;

      if (weight is num) {
        parsedWeight = weight.toDouble();
      } else if (weight is String) {
        parsedWeight = double.tryParse(weight.replaceAll(',', '.')) ?? 0.0;
      } else {
        throw Exception('Geçersiz kilo değeri');
      }

      return WeightRecord(date: parsedDate, weight: parsedWeight);
    } catch (e) {
      debugPrint('WeightRecord dönüşüm hatası: $e');
      return WeightRecord(date: DateTime.now(), weight: 0.0);
    }
  }

  Map<String, dynamic> toFirestore() {
    return {'date': Timestamp.fromDate(date), 'weight': weight};
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeightRecord &&
          runtimeType == other.runtimeType &&
          date == other.date &&
          weight == other.weight;

  @override
  int get hashCode => date.hashCode ^ weight.hashCode;
}

//====pet modeli
class Pet {
  final String? id;
  final String name;
  final String birthDate;
  final String type;
  final String breed;
  final String gender;
  final String? profilePictureUrl;
  final String userId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<Vaccine> vaccineHistory;
  final List<Medication> medicationHistory;
  final List<WeightRecord> weightHistory;

  Pet({
    this.id,
    required this.name,
    required this.birthDate,
    required this.type,
    required this.breed,
    this.gender = 'Dişi',
    this.profilePictureUrl,
    required this.userId,
    this.createdAt,
    this.updatedAt,
    required this.vaccineHistory,
    required this.medicationHistory,
    required this.weightHistory,
  });

  factory Pet.fromFirestore(DocumentSnapshot doc, param1) {
    final data = doc.data() as Map<String, dynamic>;
    return Pet(
      id: doc.id,
      name: data['name'] ?? '',
      type: data['type'] ?? '',
      breed: data['breed'] ?? '',
      birthDate: data['birthDate'] ?? '',
      gender: data['gender'] ?? 'Dişi',
      profilePictureUrl: data['profilePictureUrl'],
      userId: data['userId'] as String? ?? '', // userId alanını ekledik
      createdAt: data['createdAt']?.toDate(),
      vaccineHistory: (data['vaccineHistory'] as List<dynamic>? ?? [])
          .map((e) => Vaccine.fromFiresote(e as Map<String, dynamic>))
          .toList(),
      medicationHistory: (data['medicationHistory'] as List<dynamic>? ?? [])
          .map((e) => Medication.fromMap(e as Map<String, dynamic>))
          .toList(),
      weightHistory: (data['weightHistory'] as List<dynamic>? ?? [])
          .map((e) => WeightRecord.fromFirestore(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'type': type,
      'breed': breed,
      'birthDate': birthDate,
      'gender': gender,
      'profilePictureUrl': profilePictureUrl,
      'userId': userId,
      'vaccineHistory': vaccineHistory.map((v) => v.toFirestore()).toList(),
      'medicationHistory': medicationHistory.map((m) => m.toMap()).toList(),
      'weightHistory': weightHistory.map((w) => w.toFirestore()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
      if (createdAt != null) 'createdAt': createdAt,
    };
  }

  Pet copyWith({
    String? id,
    String? name,
    String? birthDate,
    String? type,
    String? breed,
    String? gender,
    String? profilePictureUrl,
    String? userId,
    DateTime? createdAt,
    List<Vaccine>? vaccineHistory,
    List<Medication>? medicationHistory,
    List<WeightRecord>? weightHistory,
  }) {
    return Pet(
      id: id ?? this.id,
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      type: type ?? this.type,
      breed: breed ?? this.breed,
      gender: gender ?? this.gender,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      vaccineHistory: vaccineHistory ?? this.vaccineHistory,
      medicationHistory: medicationHistory ?? this.medicationHistory,
      weightHistory: weightHistory ?? this.weightHistory,
    );
  }

  int get age {
    try {
      final birthDateTime = DateTime.parse(birthDate);
      final now = DateTime.now();

      int age = now.year - birthDateTime.year;

      if (now.month < birthDateTime.month ||
          (now.month == birthDateTime.month && now.day < birthDateTime.day)) {
        age--;
      }
      return age;
    } catch (e) {
      return 0;
    }
  }
}
