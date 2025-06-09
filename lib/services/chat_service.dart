import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:health_pet/models/chat_message.dart';
import 'package:health_pet/models/pet_model.dart';

class ChatService {
  final String _deepseekToken;
  static const String _model = 'deepseek-r1:free';
  static const Duration _apiTimeout = Duration(seconds: 30);
  static const int _maxRetries = 5; // Artırıldı
  static const int _initialRetryDelay = 5; // Artırıldı
  final Map<String, String> _responseCache = {}; // Önbellek eklendi

  ChatService({required String deepseekToken}) : _deepseekToken = deepseekToken;

  /* ---------- Dış API'ye çağrı ---------- */
  Future<ChatMessage> getAIResponse(String text, Pet? pet) async {
    try {
      final cacheKey = _generateCacheKey(text, pet);
      if (_responseCache.containsKey(cacheKey)) {
        return ChatMessage(
          content: _responseCache[cacheKey]!,
          isUser: false,
          timestamp: DateTime.now(),
          selectedPetId: pet?.id,
          userId: 'assistant',
        );
      }

      final prompt = _buildPrompt(text, pet);
      final aiResponse = await _queryAIWithRetry(prompt);

      // Yanıtı önbelleğe al
      _responseCache[cacheKey] = aiResponse;

      return ChatMessage(
        content: aiResponse,
        isUser: false,
        timestamp: DateTime.now(),
        selectedPetId: pet?.id,
        userId: 'assistant',
      );
    } catch (e) {
      // API hatası durumunda fallback yanıt
      return _getFallbackResponse(
        text,
        pet,
        e is Exception ? e : Exception(e.toString()),
      );
    }
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
        lastError = Exception(
          'API yanıt vermedi, lütfen daha sonra tekrar deneyin',
        );
      } on http.ClientException {
        lastError = Exception(
          'Ağ hatası: Lütfen internet bağlantınızı kontrol edin',
        );
      } catch (e) {
        lastError = Exception('Beklenmeyen hata: ${e.toString()}');
      }

      attempt++;
      if (attempt < _maxRetries) {
        // Üstel geri çekilme (exponential backoff)
        await Future.delayed(Duration(seconds: delay));
        delay *= 2;
      }
    }
    throw lastError ?? Exception('$_maxRetries deneme sonrası başarısız oldu');
  }

  /* ---------- Yardımcı Metotlar ---------- */
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
5. Kullanıcıyı bilgilendirici ve destekleyici ol.
6. Sorulara net ve anlaşılır cevaplar ver.
''';

  String _buildPrompt(String text, Pet? pet) {
    final petInfo =
        pet !=
            null //Ağırlık: ${pet.weight ?? 'Bilinmiyor'} kg
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
        throw Exception(
          'API kotası doldu. Lütfen 10 saniye sonra tekrar deneyin.',
        );
      case 503:
        throw Exception(
          'Servis şu anda kullanılamıyor. Lütfen daha sonra deneyin.',
        );
      default:
        throw Exception(
          'API hatası (${response.statusCode}): ${response.body}',
        );
    }
  }

  String _generateCacheKey(String text, Pet? pet) {
    return '${text.trim()}_${pet?.id ?? 'general'}';
  }

  ChatMessage _getFallbackResponse(String text, Pet? pet, Exception error) {
    // Sık sorulan sorular için fallback yanıtlar
    final lowerText = text.toLowerCase();

    if (lowerText.contains('kedi') && lowerText.contains('beslenme')) {
      return ChatMessage(
        content: '''
Kediniz için genel beslenme önerileri:
1. Yaşına uygun kaliteli kedi maması kullanın
2. Temiz su her zaman erişilebilir olsun
3. Ödül mamalarını abartmayın
4. Veterinerinizin önerdiği beslenme programını uygulayın

Not: API geçici olarak kullanılamıyor. Detaylı bilgi için lütfen daha sonra tekrar deneyin.
''',
        isUser: false,
        timestamp: DateTime.now(),
        selectedPetId: pet?.id,
        userId: 'assistant',
      );
    }

    // Genel fallback yanıt
    return ChatMessage(
      content:
          '''
Üzgünüm, şu anda veteriner asistanına ulaşamıyorum. (Hata: ${error.toString()})

Lütfen daha sonra tekrar deneyin veya acil durumlarda doğrudan bir veteriner kliniği ile iletişime geçin.
''',
      isUser: false,
      timestamp: DateTime.now(),
      selectedPetId: pet?.id,
      userId: 'assistant',
    );
  }
}
