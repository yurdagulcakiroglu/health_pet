import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_pet/services/chat_service.dart';

// Ana ChatService Provider'ı
final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService(
    hfToken: dotenv.env['HUGGINGFACE_TOKEN'] ?? '',
    models: {
      'mistral': 'mistralai/Mistral-7B-Instruct-v0.1',
      'llama': 'meta-llama/Llama-2-7b-chat-hf',
      'zephyr': 'HuggingFaceH4/zephyr-7b-beta',
    },
    defaultModel: 'mistralai/Mistral-7B-Instruct-v0.1',
  );
});

// Model durumlarını takip eden provider
final modelStatusProvider = FutureProvider.family<bool, String>((
  ref,
  modelId,
) async {
  final chatService = ref.read(chatServiceProvider);
  return await chatService.checkModelStatus(modelId);
});

// Aktif model provider'ı
final activeModelProvider = StateProvider<String>((ref) {
  return 'mistralai/Mistral-7B-Instruct-v0.1';
});

// Sohbet durumu provider'ları
final chatLoadingProvider = StateProvider<bool>((ref) => false);
final chatErrorProvider = StateProvider<String?>((ref) => null);
