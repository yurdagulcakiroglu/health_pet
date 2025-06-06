import 'package:cloud_firestore/cloud_firestore.dart';

class Pet {
  final String? id;
  final String name;
  final String birthDate;
  final String type;
  final String breed;
  final String gender;
  final String? profilePictureUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Pet({
    this.id,
    required this.name,
    required this.birthDate,
    required this.type,
    required this.breed,
    this.gender = 'Dişi', // Varsayılan değer
    this.profilePictureUrl,
    this.createdAt,
    this.updatedAt,
  });

  // Firestore'dan veri alırken kullanılacak factory constructor
  factory Pet.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Pet(
      id: doc.id,
      name: data['name'] ?? '',
      type: data['type'] ?? '',
      breed: data['breed'] ?? '',
      birthDate: data['birthDate'] ?? '',
      gender: data['gender'] ?? 'Dişi',
      profilePictureUrl: data['profilePictureUrl'],
      createdAt: data['createdAt']?.toDate(),
    );
  }

  // Firestore'a veri kaydederken
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'type': type,
      'breed': breed,
      'birthDate': birthDate,
      'gender': gender,
      'profilePictureUrl': profilePictureUrl,
      'updatedAt': FieldValue.serverTimestamp(),
      if (createdAt != null) 'createdAt': createdAt,
    };
  }

  // Kopyalama metodu
  Pet copyWith({
    String? id,
    String? name,
    String? type,
    String? breed,
    String? birthDate,
    String? gender,
    String? profilePictureUrl,
  }) {
    return Pet(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      breed: breed ?? this.breed,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      createdAt: createdAt, // Genellikle değiştirilmez
    );
  }
}
