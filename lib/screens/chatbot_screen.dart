import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_pet/providers/chat_provider.dart';
import 'package:openai_dart/openai_dart.dart';
import 'package:health_pet/models/chat_model.dart';
import 'package:health_pet/models/pet_model.dart';
import 'package:uuid/uuid.dart';

final chatMessagesProvider = StateProvider<List<ChatMessage>>((ref) => []);
final isLoadingProvider = StateProvider<bool>((ref) => false);

class PetChatScreen extends ConsumerStatefulWidget {
  final List<Pet> userPets;

  const PetChatScreen({super.key, required this.userPets});

  @override
  ConsumerState<PetChatScreen> createState() => _PetChatScreenState();
}

class _PetChatScreenState extends ConsumerState<PetChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final _uuid = const Uuid();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final openAI = ref.read(openAIProvider);

    ref
        .read(chatMessagesProvider.notifier)
        .update(
          (state) => [
            ChatMessage(
              id: _uuid.v4(),
              content: text,
              isUser: true,
              timestamp: DateTime.now(),
            ),
            ...state,
          ],
        );

    _messageController.clear();
    ref.read(isLoadingProvider.notifier).state = true;

    try {
      final request = CreateChatCompletionRequest(
        model: ChatCompletionModel.modelId('gpt-3.5-turbo'),
        messages: [
          ChatCompletionMessage.system(
            content:
                'Sen veterinerlik ve evcil hayvanlar hakkında Türkçe konuşan yardımcı bir asistan botsun.',
          ),
          ChatCompletionMessage.user(
            content: ChatCompletionUserMessageContent.string(text),
          ),
        ],
        temperature: 0.7,
      );

      final response = await openAI.createChatCompletion(request: request);

      final botReply = response.choices.first.message.content ?? '';

      ref
          .read(chatMessagesProvider.notifier)
          .update(
            (state) => [
              ChatMessage(
                id: _uuid.v4(),
                content: botReply,
                isUser: false,
                timestamp: DateTime.now(),
              ),
              ...state,
            ],
          );
    } catch (e) {
      ref
          .read(chatMessagesProvider.notifier)
          .update(
            (state) => [
              ChatMessage(
                id: _uuid.v4(),
                content: 'Hata: ${e.toString()}',
                isUser: false,
                timestamp: DateTime.now(),
              ),
              ...state,
            ],
          );
    } finally {
      ref.read(isLoadingProvider.notifier).state = false;
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatMessagesProvider);
    final isLoading = ref.watch(isLoadingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pet Asistan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.pets),
            onPressed: _showPetSelectionDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              reverse: true,
              itemCount: messages.length,
              padding: const EdgeInsets.all(8),
              itemBuilder: (context, index) {
                final message = messages[messages.length - 1 - index];
                return _buildMessageBubble(message);
              },
            ),
          ),
          _buildInputArea(isLoading),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Align(
        alignment: message.isUser
            ? Alignment.centerRight
            : Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: message.isUser ? Colors.blue[100] : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(message.content),
        ),
      ),
    );
  }

  Widget _buildInputArea(bool isLoading) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Mesajınızı yazın...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          isLoading
              ? const CircularProgressIndicator()
              : IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: _sendMessage,
                ),
        ],
      ),
    );
  }

  void _showPetSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Evcil Hayvan Seç'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...widget.userPets.map(
              (pet) => ListTile(
                leading: CircleAvatar(
                  backgroundImage: pet.profilePictureUrl != null
                      ? NetworkImage(pet.profilePictureUrl!)
                      : const AssetImage('assets/default_pet.png')
                            as ImageProvider,
                ),
                title: Text(pet.name),
                subtitle: Text('${pet.type} • ${pet.breed}'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
