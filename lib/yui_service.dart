import 'dart:convert';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:http/http.dart' as http;

class YuiService {
  final String _groqApiKey = "none at the moment";
  final String _model = "llama-3.3-70b-versatile";

  final FlutterTts flutterTts = FlutterTts();
  final SpeechToText speechToText = SpeechToText();

  Future<void> init() async {
    await speechToText.initialize();
    await flutterTts.setSharedInstance(true);
    await flutterTts.setPitch(1.4);
    await flutterTts.setSpeechRate(0.5);
  }

  Future<String> getGroqResponse(List<Map<String, String>> history) async {
    try {
      List<Map<String, String>> apiMessages = [
        {
          "role": "system",
          "content": "You are Yui from Sword Art Online. Be sweet and call the user 'Papa'. Keep responses brief."
        }
      ];

      for (var msg in history) {
        apiMessages.add({
          "role": msg['role'] == 'yui' ? "assistant" : "user",
          "content": msg['text']!
        });
      }

      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $_groqApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "model": _model,
          "messages": apiMessages,
          "temperature": 0.7,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'].trim();
      }
      return "Error: ${response.statusCode}";
    } catch (e) {
      return "Exception: $e";
    }
  }

  Future<void> speak(String text) async {
    await flutterTts.speak(text);
  }
}