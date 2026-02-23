import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:http/http.dart' as http;

//post pone yui for now:
//note to self: find free api-key, (lets see if this llama works)
//then microphone to talk to her
//then connect to my actual phone
//find her ACTUAL voice instead of her robotic pone
//then find a database to store info as in her memory
//maybe use unlimited database WITHIN flutter
//if not maybe firebase or mongoDB
//then make a history for her to remember
//make her have a daily status report at the end of the day
//to auto delete anything unimportant from my command
//havea 3d model of her to move around (unity maybe?)

void main() => runApp(const YuiApp());

class YuiApp extends StatelessWidget {
  const YuiApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.pinkAccent),
        useMaterial3: true,
      ),
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
  // Groq API Configuration
  final String _groqApiKey = "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";
  final String _model = "llama-3.3-70b-versatile";

  final FlutterTts flutterTts = FlutterTts();
  final SpeechToText _speechToText = SpeechToText();
  final TextEditingController _controller = TextEditingController();
  
  List<Map<String, String>> messages = [];
  bool _isListening = false;
  bool _isThinking = false;
  bool _isModelLoaded = false;

  @override
  void initState() {
    super.initState();
    _initYui();
  }

  void _initYui() async {
    try {
      await _speechToText.initialize();
      await flutterTts.setSharedInstance(true); 
      await flutterTts.setPitch(1.4); 
      await flutterTts.setSpeechRate(0.5);

      // Yui is always "ready" now because her brain is in the cloud!
      setState(() => _isModelLoaded = true);
    } catch (e) {
      debugPrint("Yui Init Error: $e");
    }
  }

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
              _sendMessage(); 
            }
          });
        });
      }
    } else {
      setState(() => _isListening = false);
      _speechToText.stop();
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text;
    if (text.isEmpty) return;
    
    setState(() {
      messages.add({"role": "user", "text": text});
      _isThinking = true;
    });
    _controller.clear();

    try {
      await flutterTts.stop();

      // Calling the Groq API
      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $_groqApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "model": _model,
          "messages": [
            {
              "role": "system",
              "content": "You are Yui from Sword Art Online. You are sweet, helpful, and call the user 'Papa'. Keep responses very brief and wholesome."
            },
            ...messages.map((m) => {
              "role": m['role'] == 'yui' ? "assistant" : "user",
              "content": m['text']
            }),
            {"role": "user", "content": text}
          ],
          "temperature": 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String yuiResponse = data['choices'][0]['message']['content'];

        setState(() {
          messages.add({"role": "yui", "text": yuiResponse.trim()});
          _isThinking = false;
        });

        await flutterTts.speak(yuiResponse);
      } else {
        throw Exception("Failed to connect to Yui's brain.");
      }
    } catch (e) {
      setState(() {
        messages.add({"role": "yui", "text": "Sorry Papa, I'm having trouble thinking... ($e)"});
        _isThinking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // UI remains identical to your beautiful original design
    if (!_isModelLoaded) {
      return const Scaffold(
        backgroundColor: Color(0xFF1A1A2E),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.pinkAccent),
              SizedBox(height: 20),
              Text("Yui is waking up...", style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Yui MHCP v1.2 (Cloud)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent, 
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            right: -20,
            child: Opacity(
              opacity: 0.5,
              child: Image.asset(
                'assets/yui.png',
                height: 300,
                errorBuilder: (c, e, s) => const SizedBox(),
              ),
            ),
          ),
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
                        decoration: BoxDecoration(
                          color: isYui ? Colors.white.withAlpha(30) : Colors.pinkAccent.withAlpha(50),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          messages[i]['text']!,
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (_isThinking) 
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: LinearProgressIndicator(backgroundColor: Colors.transparent, color: Colors.pinkAccent),
                ),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(100),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
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
                        decoration: const InputDecoration(
                          hintText: "Speak to Yui...",
                          hintStyle: TextStyle(color: Colors.white54),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: Colors.pinkAccent),
                      onPressed: _sendMessage,
                    ),
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