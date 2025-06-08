import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final String? selectedPetId; // Burada sadece petId var
  final String userId;

  ChatMessage({
    String? id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.selectedPetId,
    required this.userId,
  }) : id = id ?? const Uuid().v4();

  factory ChatMessage.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data()!;
    return ChatMessage.fromMap(data, snapshot.id);
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map, [String? id]) {
    return ChatMessage(
      id: id,
      content: map['content'] ?? '',
      isUser: map['isUser'] ?? false,
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      selectedPetId: map['selectedPetId'] as String?,
      userId: map['userId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'content': content,
      'isUser': isUser,
      'timestamp': Timestamp.fromDate(timestamp),
      'userId': userId,
      if (selectedPetId != null) 'selectedPetId': selectedPetId,
    };
  }

  Map<String, dynamic> toFirestore() => toMap();
}
