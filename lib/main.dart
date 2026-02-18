import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

void main() => runApp(const YuiApp());

class YuiApp extends StatelessWidget {
  const YuiApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.pinkAccent), useMaterial3: true),
      home: const YuiInterface(),
    );
  }
}

class YuiInterface extends StatefulWidget {
  const YuiInterface({super.key});
  @override
  State<YuiInterface> createState() => _YuiInterfaceState();
}

class _YuiInterfaceState extends State<YuiInterface> {
  final String apiKey = 'AIzaSyCTWzmz3QL6YsE-dDo5_X3Tvc7hL0NgbSQ'; 
  late final GenerativeModel model;
  late final ChatSession chat;
  
  final FlutterTts flutterTts = FlutterTts();
  final SpeechToText _speechToText = SpeechToText();
  final TextEditingController _controller = TextEditingController();
  
  List<Map<String, String>> messages = [];
  bool _isListening = false;
  bool _isThinking = false;

  @override
  void initState() {
    super.initState();
    _initYui();
  }

  void _initYui() async {
    // 1. Setup Voice
    await flutterTts.setSharedInstance(true); 
    await flutterTts.setIosAudioCategory(IosTextToSpeechAudioCategory.playback, [
      IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
    ]);
    await flutterTts.setPitch(1.4); 

    // 2. Setup Ears
    await _speechToText.initialize();

    // 3. Setup Gemini 2.5 Brain
    model = GenerativeModel(
      model: 'gemini-2.5-flash', 
      apiKey: apiKey,
      systemInstruction: Content.system(
        "You are Yui from SAO. Call user 'Papa'. No emojis. Plain text only. Very short replies."
      ),
    );
    chat = model.startChat();
    setState(() {});
  }

  // Handle Microphone logic
  void _toggleListening() async {
    if (!_isListening) {
      bool available = await _speechToText.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speechToText.listen(onResult: (result) {
          setState(() {
            _controller.text = result.recognizedWords;
            if (result.finalResult) {
              _isListening = false;
              _sendMessage(); // Auto-send when Papa stops talking
            }
          });
        });
      }
    } else {
      setState(() => _isListening = false);
      _speechToText.stop();
    }
  }

  void _sendMessage() async {
    final text = _controller.text;
    if (text.isEmpty) return;
    
    setState(() {
      messages.add({"role": "user", "text": text});
      _isThinking = true;
    });
    _controller.clear();

    try {
      await flutterTts.stop(); // Stop Yui if she was already talking
      final response = await chat.sendMessage(Content.text(text));
      final yuiReply = response.text ?? "...";

      setState(() {
        messages.add({"role": "yui", "text": yuiReply});
        _isThinking = false;
      });

      await flutterTts.speak(yuiReply);
    } catch (e) {
      setState(() {
        messages.add({"role": "yui", "text": "Error: $e"});
        _isThinking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text("Yui MHCP v1.0", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), backgroundColor: Colors.transparent, elevation: 0),
      body: Stack(
        children: [
          // Background UI
          Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF1A1A2E), Color(0xFF16213E)], begin: Alignment.topCenter, end: Alignment.bottomCenter))),
          Positioned(bottom: 100, right: -20, child: Opacity(opacity: 0.5, child: Image.asset('assets/yui.png', height: 300, errorBuilder: (c, e, s) => const SizedBox()))),
          
          Column(
            children: [
              const SizedBox(height: 100),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    bool isYui = messages[i]['role'] == 'yui';
                    return Align(
                      alignment: isYui ? Alignment.centerLeft : Alignment.centerRight,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: isYui ? Colors.white.withAlpha(30) : Colors.pinkAccent.withAlpha(50), borderRadius: BorderRadius.circular(15)),
                        child: Text(messages[i]['text']!, style: const TextStyle(color: Colors.white, fontSize: 16)),
                      ),
                    );
                  },
                ),
              ),
              if (_isThinking) const LinearProgressIndicator(backgroundColor: Colors.transparent, color: Colors.pinkAccent),
              
              // Input Area with Mic
              Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
                decoration: BoxDecoration(color: Colors.black.withAlpha(100), borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                      color: _isListening ? Colors.redAccent : Colors.pinkAccent,
                      onPressed: _toggleListening,
                    ),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(hintText: "Talk to Yui...", hintStyle: TextStyle(color: Colors.white54), border: InputBorder.none),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.send, color: Colors.pinkAccent), onPressed: _sendMessage),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}