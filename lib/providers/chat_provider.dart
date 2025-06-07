import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openai_dart/openai_dart.dart';
import 'package:health_pet/models/chat_model.dart';
import 'package:health_pet/models/pet_model.dart';

final selectedPetProvider = StateProvider<Pet?>((ref) => null);
final chatMessagesProvider = StateProvider<List<ChatMessage>>((ref) => []);
final isLoadingProvider = StateProvider<bool>((ref) => false);

final openAIProvider = Provider<OpenAIClient>((ref) {
  final apiKey = dotenv.env['OPENAI_API_KEY']!;
  return OpenAIClient(apiKey: apiKey);
});
