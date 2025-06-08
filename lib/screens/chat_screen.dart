import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // yalnızca pet’leri çekmek için
import 'chat_welcome_screen.dart';
import 'package:health_pet/models/pet_model.dart';
import 'package:health_pet/models/chat_message.dart';
import 'package:health_pet/services/chat_service.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService(
    deepseekToken: dotenv.env['DEEPSEEK_TOKEN']!,
  );

  /* Bellekte tutulan geçici mesaj listesi */
  final List<ChatMessage> _messages = [];

  List<Pet> _pets = [];
  Pet? _selectedPet;
  bool _isGeneral = false;
  bool _awaitingResponse = false;
  bool _conversationEnded = false;

  /* ------------------ Init ------------------ */
  @override
  void initState() {
    super.initState();
    _loadPets();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showInitialGreeting());
  }

  Future<void> _loadPets() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('pets')
        .get();

    setState(() {
      _pets = snapshot.docs.map((doc) => Pet.fromFirestore(doc, null)).toList();
    });
  }

  /* ------------------ UI Helpers ------------------ */
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /* ------------------ Bot & User Messages ------------------ */
  void _addBotMessage(String content) {
    setState(() {
      _messages.insert(
        0,
        ChatMessage(
          content: content,
          isUser: false,
          timestamp: DateTime.now(),
          selectedPetId: _selectedPet?.id,
          userId: 'assistant',
        ),
      );
    });
    _scrollToBottom();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    /* Kullanıcı mesajını belleğe ekle */
    final userMsg = ChatMessage(
      content: text,
      isUser: true,
      timestamp: DateTime.now(),
      selectedPetId: _selectedPet?.id,
      userId: FirebaseAuth.instance.currentUser!.uid,
    );
    setState(() {
      _messages.insert(0, userMsg);
      _controller.clear();
      _awaitingResponse = true;
    });
    _scrollToBottom();

    /* Bot cevabı al */
    try {
      final reply = await _chatService.getAIResponse(
        text,
        _isGeneral ? null : _selectedPet,
      );
      setState(() {
        _messages.insert(0, reply);
        _awaitingResponse = false;
      });
      _askForMoreQuestions();
    } catch (e) {
      _addBotMessage("Üzgünüm, bir hata oluştu: ${e.toString()}");
      setState(() => _awaitingResponse = false);
    }
  }

  /* -------------- Akış Kontrolü -------------- */
  void _showInitialGreeting() {
    _addBotMessage(
      "Merhaba, ben AIngel! Size hangi konuda yardımcı olabilirim?\n\n"
      "Sorunuz dostlarınızla ilgiliyse ilgili dostunuzu seçin, "
      "genel bir soruysa 'Diğer' seçeneğini seçin.",
    );
    Future.delayed(const Duration(milliseconds: 500), _showPetSelection);
  }

  void _showPetSelection() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Lütfen bir seçenek belirleyin:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ..._pets.map(
                (pet) => ListTile(
                  leading: pet.profilePictureUrl != null
                      ? CircleAvatar(
                          backgroundImage: NetworkImage(pet.profilePictureUrl!),
                        )
                      : CircleAvatar(child: Text(pet.name[0])),
                  title: Text(pet.name),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedPet = pet;
                      _isGeneral = false;
                    });
                    _addBotMessage(
                      "${pet.name} hakkında sorularınızı yanıtlamak için buradayım. "
                      "Nasıl yardımcı olabilirim?",
                    );
                  },
                ),
              ),
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text("Diğer (Genel Soru)"),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedPet = null;
                    _isGeneral = true;
                  });
                  _addBotMessage(
                    "Veteriner asistanınız olarak genel sorularınızı yanıtlayabilirim. "
                    "Nasıl yardımcı olabilirim?",
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _askForMoreQuestions() {
    _addBotMessage(
      "Başka bir sorunuz var mı? Eğer sorunuz yoksa 'Hayır' yazabilirsiniz.",
    );
  }

  void _endConversation() {
    _addBotMessage(
      "AIngel olarak size yardımcı olabildiysem ne mutlu bana! "
      "Başka sorularınız olursa her zaman buradayım. İyi günler dilerim!",
    );
    setState(() => _conversationEnded = true);

    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ChatWelcomeScreen()),
      );
    });
  }

  void _handleUserResponse(String text) {
    final lower = text.toLowerCase();
    if (lower.contains("hayır") ||
        lower.contains("yok") ||
        lower.contains("teşekkür") ||
        lower.contains("bitir")) {
      _endConversation();
    } else {
      _sendMessage();
    }
  }

  /* ------------------ Dispose ------------------ */
  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /* ------------------ Build ------------------ */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AIngel Asistan"),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (_, i) {
                final msg = _messages[i];
                return Align(
                  alignment: msg.isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: msg.isUser ? Colors.blue[100] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: msg.isUser
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        if (_selectedPet != null && !msg.isUser)
                          Text(
                            _selectedPet!.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        Text(msg.content),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (_conversationEnded)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "Sohbet sonlandırılıyor...",
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: _awaitingResponse
                          ? "Yanıt bekleniyor..."
                          : "Mesajınızı yazın...",
                      border: const OutlineInputBorder(),
                      enabled: !_awaitingResponse && !_conversationEnded,
                    ),
                    onSubmitted: (_) => _awaitingResponse
                        ? _handleUserResponse(_controller.text)
                        : _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _awaitingResponse
                      ? () => _handleUserResponse(_controller.text)
                      : _sendMessage,
                  color: _awaitingResponse || _conversationEnded
                      ? Colors.grey
                      : Theme.of(context).primaryColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
