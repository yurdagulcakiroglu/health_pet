import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:health_pet/models/chat_message.dart';
import 'package:health_pet/models/pet_model.dart';

class ChatService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final String _hfToken;
  final Map<String, String> _models;
  final String _defaultModel;

  ChatService({
    required String hfToken,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    Map<String, String>? models,
    String defaultModel = 'mistralai/Mistral-7B-Instruct-v0.1',
  }) : _hfToken = hfToken,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _models =
           models ??
           {
             'mistral': 'mistralai/Mistral-7B-Instruct-v0.1',
             'llama': 'meta-llama/Llama-2-7b-chat-hf',
             'zephyr': 'HuggingFaceH4/zephyr-7b-beta',
           },
       _defaultModel = defaultModel;

  Stream<List<ChatMessage>> messages({String? userId}) {
    final uid = userId ?? _auth.currentUser?.uid;
    if (uid == null) {
      // Kullanıcı yoksa boş liste döndür
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('chatMessages')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (d) => ChatMessage.fromFirestore(d, null),
              ) // parametre düzeltildi
              .toList()
              .reversed
              .toList(),
        );
  }

  Future<void> sendUser(String text, Pet? pet) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Kullanıcı mesajını kaydet
      final userMsg = ChatMessage(
        content: text,
        isUser: true,
        timestamp: DateTime.now(),
        selectedPetId: pet?.id, // sadece pet id gönderiliyor
        userId: user.uid,
      );

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('chatMessages')
          .add(userMsg.toFirestore());

      // Model seçimi ve prompt oluşturma
      final selectedModel = _selectModelBasedOnContent(text, pet);
      final prompt = _buildPrompt(text, pet, selectedModel);

      // API çağrısı
      final reply = await _queryModelWithRetry(
        prompt: prompt,
        model: selectedModel,
        maxRetries: 2,
      );

      // Bot yanıtını kaydet
      final botMsg = ChatMessage(
        content: reply,
        isUser: false,
        timestamp: DateTime.now(),
        selectedPetId: pet?.id, // sadece pet id gönderiliyor
        userId: 'bot_${user.uid}',
      );

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('chatMessages')
          .add(botMsg.toFirestore());
    } catch (e) {
      debugPrint('Message sending error: $e');
      rethrow;
    }
  }

  Future<String> _queryModelWithRetry({
    required String prompt,
    required String model,
    int maxRetries = 3,
    int initialDelay = 2,
  }) async {
    int attempt = 0;
    int delay = initialDelay;
    String lastError = '';

    while (attempt < maxRetries) {
      try {
        final response = await http
            .post(
              Uri.parse('https://api-inference.huggingface.co/models/$model'),
              headers: {
                'Authorization': 'Bearer $_hfToken',
                'Content-Type': 'application/json',
              },
              body: jsonEncode({'inputs': prompt}),
            )
            .timeout(const Duration(seconds: 30));

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          if (responseData is List && responseData.isNotEmpty) {
            final result = (responseData.first['generated_text'] as String)
                .replaceFirst(prompt, '')
                .trim();
            if (result.isNotEmpty) return result;
            throw Exception('Empty response from model');
          }
          throw Exception('Invalid response format');
        } else if (response.statusCode == 503) {
          final retryAfter =
              int.tryParse(response.headers['retry-after'] ?? '$delay') ??
              delay;
          lastError = 'Model is loading, retrying in $retryAfter seconds';
          await Future.delayed(Duration(seconds: retryAfter));
          delay *= 2;
          attempt++;
        } else {
          lastError = 'API Error: ${response.statusCode} - ${response.body}';
          throw Exception(lastError);
        }
      } on TimeoutException {
        lastError = 'Request timeout (attempt ${attempt + 1}/$maxRetries)';
        if (++attempt >= maxRetries) throw Exception(lastError);
      } catch (e) {
        lastError = e.toString();
        rethrow;
      }
    }
    throw Exception('Max retries reached. Last error: $lastError');
  }

  String _selectModelBasedOnContent(String text, Pet? pet) {
    final lowerText = text.toLowerCase();

    if (lowerText.contains('beslenme') ||
        lowerText.contains('diyet') ||
        lowerText.contains('mama')) {
      return _models['zephyr'] ?? _defaultModel;
    }

    if (lowerText.contains('hastalık') ||
        lowerText.contains('tedavi') ||
        lowerText.contains('ilaç')) {
      return _models['llama'] ?? _defaultModel;
    }

    return _defaultModel;
  }

  String _buildPrompt(String text, Pet? pet, String model) {
    final petInfo = pet != null
        ? """
### Pet Profile ###
Name: ${pet.name}
Type: ${pet.type}
Breed: ${pet.breed}
Age: ${pet.age} years
Gender: ${pet.gender}
"""
        : "\nGeneral question: Not specific to any pet";

    return """
[ROLE: VETERINARY ASSISTANT]
[MODEL: ${model.split('/').last}]
[INSTRUCTIONS]
1. Respond in Turkish with a friendly tone
2. Provide general information, no medical diagnoses
3. For emergencies, state "ACİL VETERİNER DESTEĞİ GEREKLİ"
4. Structure response as:
   - Summary
   - Possible Causes
   - Recommendations
   - Veterinary Warning

$petInfo

[USER QUESTION]
${text.trim()}

[RESPONSE]:
Merhaba! ${pet != null ? '${pet.name} için ' : ''}sorunuzu yanıtlıyorum:
""";
  }

  Future<bool> checkModelStatus(String model) async {
    try {
      final response = await http
          .head(
            Uri.parse('https://api-inference.huggingface.co/models/$model'),
            headers: {'Authorization': 'Bearer $_hfToken'},
          )
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Model status check failed: $e');
      return false;
    }
  }
}
