import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:llama_cpp_dart/llama_cpp_dart.dart';

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
  Llama? _yuiBrain; // Updated class name
  
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
    _initYuiLocal();
  }

  // FIXED: Logic to ensure the model path is handled correctly
  Future<String> _copyModelToStorage() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = "${directory.path}/yui_brain.gguf";
    final file = File(path);

    if (!await file.exists()) {
      // Copies from your assets folder to the app's internal storage
      final data = await rootBundle.load("assets/models/yui_brain.gguf");
      final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await file.writeAsBytes(bytes);
    }
    return path;
  }

  void _initYuiLocal() async {
    try {
      await _speechToText.initialize();
      await flutterTts.setSharedInstance(true); 

      final storedModelPath = await _copyModelToStorage();
      
      // --- THE FIX STARTS HERE ---
      // 1. Manually tell the library to skip native logging initialization
      // This is the "override" that stops it from looking for 'llama_log_set'
      Llama.libraryPath = null; 

      // 2. Initialize with very specific parameters
      _yuiBrain = Llama(
        storedModelPath,
        verbose: false, // Disables the logger that causes the crash
      );
      // --- THE FIX ENDS HERE ---

      setState(() => _isModelLoaded = true);
    } catch (e) {
      debugPrint("Yui Error: $e");
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

  void _sendMessage() async {
    final text = _controller.text;
    if (text.isEmpty || _yuiBrain == null) return;
    
    setState(() {
      messages.add({"role": "user", "text": text});
      _isThinking = true;
    });
    _controller.clear();

    try {
      await flutterTts.stop();

      // Formulate the Local Prompt
      final prompt = "User: $text\n\nAssistant (Yui): Always answer as Yui from SAO. Call the user 'Papa'. Be sweet and very brief.";
      
      // FIXED: Latest llama_cpp_dart generation syntax
      _yuiBrain!.setPrompt(prompt);
      String fullResponse = "";
      
      // We generate tokens until the model stops
      while (true) {
        var (token, done) = _yuiBrain!.getNext();
        fullResponse += token;
        if (done) break;
        if (fullResponse.length > 200) break; // Safety stop
      }

      setState(() {
        messages.add({"role": "yui", "text": fullResponse.trim()});
        _isThinking = false;
      });

      await flutterTts.speak(fullResponse);
    } catch (e) {
      setState(() {
        messages.add({"role": "yui", "text": "Brain Error: $e"});
        _isThinking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
        title: const Text("Yui MHCP v1.1 (Local)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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