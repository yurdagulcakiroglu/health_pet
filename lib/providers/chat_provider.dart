import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_pet/models/chat_model.dart';

final chatProvider = StateNotifierProvider<ChatNotifier, List<ChatMessage>>((
  ref,
) {
  return ChatNotifier();
});

class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  ChatNotifier() : super([]);

  void addUserMessage(String text) {
    state = [
      ...state,
      ChatMessage(text: text, isUser: true, timestamp: DateTime.now()),
    ];
  }

  void addBotResponse(String text) {
    state = [
      ...state,
      ChatMessage(text: text, isUser: false, timestamp: DateTime.now()),
    ];
  }

  void clearChat() {
    state = [];
  }
}
