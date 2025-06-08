import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_pet/models/chat_message.dart';
import 'package:health_pet/models/pet_model.dart';
import 'package:health_pet/services/chat_service.dart';

/// ChatService provider
final chatServiceProvider = Provider<ChatService>((ref) {
  final token = dotenv.env['DEEPSEEK_TOKEN'];
  if (token == null || token.isEmpty) {
    throw Exception('DEEPSEEK_TOKEN .env dosyasında tanımlı değil');
  }
  return ChatService(deepseekToken: token);
});

/// Chat state notifier
class ChatNotifier extends StateNotifier<ChatState> {
  final Ref ref;

  ChatNotifier(this.ref) : super(ChatState.initial());

  /// Send message and get response
  Future<void> sendMessage(String text) async {
    state = state.copyWith(status: ChatStatus.loading, error: null);

    try {
      final response = await ref
          .read(chatServiceProvider)
          .getAIResponse(text, state.selectedPet);

      state = state.copyWith(
        messages: [response, ...state.messages],
        status: ChatStatus.idle,
        awaitingResponse: true,
      );
    } catch (e) {
      state = state.copyWith(status: ChatStatus.error, error: e.toString());
    }
  }

  /// Select pet for conversation
  void selectPet(Pet? pet) {
    state = state.copyWith(
      selectedPet: pet,
      isGeneral: pet == null,
      showPetSelection: false,
    );

    // Add welcome message for selected pet
    final welcomeMessage = ChatMessage(
      content: pet != null
          ? "Merhaba! ${pet.name} hakkında sorularınızı yanıtlamak için buradayım."
          : "Merhaba! Veteriner asistanınız olarak genel sorularınızı yanıtlayabilirim.",
      isUser: false,
      timestamp: DateTime.now(),
      selectedPetId: pet?.id, // Burada selectedPetId kullanıyoruz
      userId: 'assistant',
    );

    state = state.copyWith(messages: [welcomeMessage, ...state.messages]);
  }

  /// End conversation and return to welcome screen
  void endConversation() {
    final goodbyeMessage = ChatMessage(
      content:
          "Görüşmeyi sonlandırıyorum. Başka sorularınız olursa her zaman buradayım!",
      isUser: false,
      timestamp: DateTime.now(),
      userId: 'assistant',
      selectedPetId: state.selectedPet?.id, // Nullable olarak ekledik
    );

    state = state.copyWith(
      messages: [goodbyeMessage, ...state.messages],
      conversationEnded: true,
    );
  }

  /// Show pet selection dialog
  void showPetSelection(List<Pet> pets) {
    state = state.copyWith(showPetSelection: true, availablePets: pets);
  }

  /// Add user message to chat
  void addUserMessage(String text) {
    final userMessage = ChatMessage(
      content: text,
      isUser: true,
      timestamp: DateTime.now(),
      selectedPetId: state.selectedPet?.id, // Burada selectedPetId kullanıyoruz
      userId: 'user',
    );

    state = state.copyWith(messages: [userMessage, ...state.messages]);
  }
}

/// Chat state
class ChatState {
  final List<ChatMessage> messages;
  final ChatStatus status;
  final String? error;
  final bool awaitingResponse;
  final bool conversationEnded;
  final bool showPetSelection;
  final List<Pet> availablePets;
  final Pet? selectedPet;
  final bool isGeneral;

  const ChatState({
    required this.messages,
    required this.status,
    this.error,
    required this.awaitingResponse,
    required this.conversationEnded,
    required this.showPetSelection,
    required this.availablePets,
    this.selectedPet,
    required this.isGeneral,
  });

  factory ChatState.initial() {
    return ChatState(
      messages: [],
      status: ChatStatus.idle,
      awaitingResponse: false,
      conversationEnded: false,
      showPetSelection: false,
      availablePets: [],
      isGeneral: false,
    );
  }

  ChatState copyWith({
    List<ChatMessage>? messages,
    ChatStatus? status,
    String? error,
    bool? awaitingResponse,
    bool? conversationEnded,
    bool? showPetSelection,
    List<Pet>? availablePets,
    Pet? selectedPet,
    bool? isGeneral,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      status: status ?? this.status,
      error: error ?? this.error,
      awaitingResponse: awaitingResponse ?? this.awaitingResponse,
      conversationEnded: conversationEnded ?? this.conversationEnded,
      showPetSelection: showPetSelection ?? this.showPetSelection,
      availablePets: availablePets ?? this.availablePets,
      selectedPet: selectedPet ?? this.selectedPet,
      isGeneral: isGeneral ?? this.isGeneral,
    );
  }
}

enum ChatStatus { idle, loading, error }

/// Chat state provider
final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(ref);
});
