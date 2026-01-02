import 'package:firebase_vertexai/firebase_vertexai.dart';

class GeminiAIService {
  late final GenerativeModel _model;

  GeminiAIService() {
    // Initialize the Gemini model
    _model = FirebaseVertexAI.instance.generativeModel(
      model: 'gemini-2.0-flash-exp',
    );
  }

  /// Analyzes transcribed speech to detect if it's a help request
  /// Returns true if the text contains a help/emergency request in any language
  Future<bool> isHelpRequest(String transcribedText) async {
    try {
      // Create a prompt that asks the AI to analyze if this is a help request
      final prompt = '''
You are a multilingual emergency detection system. Analyze the following text and determine if it's a request for help, emergency, or assistance in ANY language.

The text could be in English, Hindi, Spanish, French, German, Arabic, Chinese, Japanese, Korean, Portuguese, Russian, Italian, or any other language.

Look for keywords related to:
- Help (e.g., "help", "ayuda", "aide", "hilfe", "помощь", "помощь", "帮助", "ヘルプ", "도움", "ajuda", "aiuto", "مساعدة", "मदद")
- Emergency (e.g., "emergency", "emergencia", "urgence", "notfall", "экстренная помощь", "긴급", "緊急")
- Danger (e.g., "danger", "peligro", "danger", "gefahr", "опасность", "खतरा")
- Rescue (e.g., "rescue", "rescate", "sauvetage", "rettung", "спасение", "बचाओ")
- Save me (e.g., "save me", "sálvame", "sauve-moi", "rette mich", "спаси меня", "मुझे बचाओ")

Text to analyze: "$transcribedText"

Respond with ONLY "YES" if this is a help/emergency request, or "NO" if it's not. No other text.
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      final responseText = response.text?.trim().toUpperCase() ?? '';

      // Check if the response indicates a help request
      return responseText.contains('YES');
    } catch (e) {
      print('Error analyzing text with Gemini: $e');
      // If there's an error, fall back to simple keyword detection
      return _fallbackHelpDetection(transcribedText);
    }
  }

  /// Fallback method using simple keyword matching
  bool _fallbackHelpDetection(String text) {
    final lowerText = text.toLowerCase();

    // Common help keywords in multiple languages
    final helpKeywords = [
      // English
      'help', 'emergency', 'danger', 'rescue', 'save me', 'sos',
      // Hindi
      'मदद', 'बचाओ', 'खतरा', 'आपातकाल',
      // Spanish
      'ayuda', 'socorro', 'emergencia', 'peligro', 'auxilio',
      // French
      'aide', 'secours', 'urgence', 'danger', 'au secours',
      // German
      'hilfe', 'notfall', 'gefahr', 'rettung',
      // Portuguese
      'ajuda', 'socorro', 'emergência', 'perigo',
      // Italian
      'aiuto', 'soccorso', 'emergenza', 'pericolo',
      // Russian
      'помощь', 'спасите', 'опасность',
      // Arabic
      'مساعدة', 'نجدة', 'خطر',
      // Chinese (simplified)
      '帮助', '救命', '紧急', '危险',
      // Japanese
      'ヘルプ', '助けて', '緊急', '危険',
      // Korean
      '도움', '도와주세요', '긴급', '위험',
    ];

    return helpKeywords.any((keyword) => lowerText.contains(keyword));
  }

  /// Get a conversational response for non-emergency queries (optional)
  Future<String?> getResponse(String text) async {
    try {
      final content = [Content.text(text)];
      final response = await _model.generateContent(content);
      return response.text;
    } catch (e) {
      print('Error getting Gemini response: $e');
      return null;
    }
  }
}
