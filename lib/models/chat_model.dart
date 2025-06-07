import 'package:health_pet/models/pet_model.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final Pet? selectedPet;

  ChatMessage({
    String? id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.selectedPet,
  }) : id = id ?? const Uuid().v4();

  factory ChatMessage.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data()!;
    return ChatMessage(
      id: snapshot.id,
      content: data['content'] ?? '',
      isUser: data['isUser'] ?? false,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      selectedPet: data['pet'] != null
          ? Pet.fromFirestore(
              data['pet'],
              null, // Pet için ayrı bir DocumentSnapshot yoksa
            )
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'content': content,
      'isUser': isUser,
      'timestamp': Timestamp.fromDate(timestamp),
      if (selectedPet != null) 'pet': selectedPet!.toFirestore(),
    };
  }

  ChatMessage copyWith({
    String? id,
    String? content,
    bool? isUser,
    DateTime? timestamp,
    Pet? selectedPet,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      selectedPet: selectedPet ?? this.selectedPet,
    );
  }

  @override
  String toString() {
    return 'ChatMessage(id: $id, content: $content, isUser: $isUser, timestamp: $timestamp, pet: ${selectedPet?.name})';
  }
}
