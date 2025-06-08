import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

/// Uygulamada **tek** ChatMessage tanımı budur.
class ChatMessage {
  final String id;
  final String content;
  final bool isUser; // true ⇒ kullanıcı, false ⇒ bot
  final DateTime timestamp;
  final String? selectedPetId; // null ⇒ genel soru
  final String userId; // "assistant" veya Firebase uid

  ChatMessage({
    String? id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.selectedPetId,
    required this.userId,
  }) : id = id ?? const Uuid().v4();

  /* ---------- Firestore Helpers ---------- */
  factory ChatMessage.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snap,
    SnapshotOptions? _,
  ) => ChatMessage.fromMap(snap.data()!, snap.id);

  Map<String, dynamic> toFirestore() => toMap();

  /* ---------- Map Helpers ---------- */
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
}
