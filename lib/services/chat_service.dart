import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:health_pet/models/chat_message.dart';
import 'package:health_pet/models/pet_model.dart';

class ChatService {
  final String _deepseekToken;
  static const String _model = 'deepseek-r1:free';
  static const Duration _apiTimeout = Duration(seconds: 30);
  static const int _maxRetries = 3;
  static const int _initialRetryDelay = 2;

  ChatService({required String deepseekToken}) : _deepseekToken = deepseekToken;

  /* ---------- Dış API’ye çağrı ---------- */
  Future<ChatMessage> getAIResponse(String text, Pet? pet) async {
    final prompt = _buildPrompt(text, pet);
    final aiResponse = await _queryAIWithRetry(prompt);

    return ChatMessage(
      content: aiResponse,
      isUser: false,
      timestamp: DateTime.now(),
      selectedPetId: pet?.id,
      userId: 'assistant',
    );
  }

  Future<String> _queryAIWithRetry(String prompt) async {
    int attempt = 0;
    int delay = _initialRetryDelay;
    Exception? lastError;

    while (attempt < _maxRetries) {
      try {
        final response = await http
            .post(
              Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
              headers: _buildHeaders(),
              body: jsonEncode(_buildRequestBody(prompt)),
            )
            .timeout(_apiTimeout);

        return _handleApiResponse(response);
      } on TimeoutException {
        lastError = Exception('API request timed out');
      } on http.ClientException catch (e) {
        lastError = Exception('Network error: ${e.message}');
      } catch (e) {
        lastError = Exception('Unexpected error: ${e.toString()}');
      }
      // Başarısızsa bekle ve tekrar dene
      attempt++;
      if (attempt < _maxRetries) {
        await Future.delayed(Duration(seconds: delay));
        delay *= 2;
      }
    }
    throw lastError ?? Exception('Failed after $_maxRetries attempts');
  }

  /* ---------- Yardımcılar ---------- */
  Map<String, String> _buildHeaders() => {
    'Authorization': 'Bearer $_deepseekToken',
    'Content-Type': 'application/json',
    'HTTP-Referer': 'https://health_pet.example',
    'X-Title': 'Veteriner Asistan',
  };

  Map<String, dynamic> _buildRequestBody(String prompt) => {
    'model': "deepseek/deepseek-r1:free",
    'messages': [
      {'role': 'system', 'content': _buildSystemPrompt()},
      {'role': 'user', 'content': prompt},
    ],
    'temperature': 0.7,
    'max_tokens': 1000,
  };

  String _buildSystemPrompt() => '''
[ROL: VETERİNER YARDIMCISI]
[YANIT DİLİ: TÜRKÇE]
[LÜTFEN]
1. Kullanıcıya sıcak ve bilgilendirici bir şekilde yanıt ver.
2. Tıbbi tanı koyma, sadece öneri sun.
3. Acil durum varsa: "ACİL VETERİNER DESTEĞİ GEREKLİ" uyarısı ver.
4. Cevap yapısı:
   - Özet
   - Olası Nedenler
   - Öneriler
   - Veteriner Uyarısı (gerekiyorsa)
5. Sonunda her zaman "Başka bir sorunuz var mı?" diye sor.
''';

  String _buildPrompt(String text, Pet? pet) {
    final petInfo = pet != null
        ? '''
### Evcil Hayvan Bilgisi ###
İsim: ${pet.name}
Tür: ${pet.type}
Cins: ${pet.breed}
Yaş: ${pet.age}
Cinsiyet: ${pet.gender}
'''
        : 'Genel soru. Evcil hayvan bilgisi verilmedi.';

    return '''
$petInfo

[SORU]:
${text.trim()}

[YANIT]:
''';
  }

  String _handleApiResponse(http.Response response) {
    switch (response.statusCode) {
      case 200:
        final json = jsonDecode(response.body);
        return (json['choices'][0]['message']['content'] as String).trim();
      case 429:
        throw Exception('API rate limit exceeded');
      case 503:
        throw Exception('Service unavailable');
      default:
        throw Exception('API error: ${response.statusCode}');
    }
  }
}
