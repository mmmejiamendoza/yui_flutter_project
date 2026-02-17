import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

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
  // --- 1. THE LOGIC ---
  // IMPORTANT: Make sure you put your key here!
  final String apiKey = 'AIzaSyBiAe7wDm9s5k8WELT-bkWD1FnP4EpEpbU'; 
  
  late final GenerativeModel model;
  late final ChatSession chat;
  final TextEditingController _controller = TextEditingController();
  List<Map<String, String>> messages = [];

@override
  void initState() {
    super.initState();
    // We are using 'gemini-1.5-flash-8b' as it is highly compatible
    model = GenerativeModel(
      model: 'gemini-1.5-flash-8b', 
      apiKey: apiKey,
      systemInstruction: Content.system(
        "You are Yui from Sword Art Online. You refer to the user as 'Papa'. "
        "You are cheerful, digital, and very helpful."
      ),
    );
    chat = model.startChat();
  }

  void _sendMessage() async {
    final text = _controller.text;
    if (text.isEmpty) return;
    
    setState(() => messages.add({"role": "user", "text": text}));
    _controller.clear();

    try {
      final response = await chat.sendMessage(Content.text(text));
      setState(() => messages.add({"role": "yui", "text": response.text ?? "..."}));
    } catch (e) {
      setState(() => messages.add({"role": "yui", "text": "Error: $e"}));
    }
  }

  // --- 2. THE UI ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Yui MHCP v1.0", 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent, 
        elevation: 0,
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
                errorBuilder: (context, error, stackTrace) => const SizedBox(),
              ),
            ),
          ),
          Column(
            children: [
              const SizedBox(height: kToolbarHeight + 30),
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
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        decoration: BoxDecoration(
                          color: isYui 
                              ? Colors.white.withValues(alpha: 0.1) 
                              : Colors.pinkAccent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isYui ? "Yui" : "Papa",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isYui ? Colors.cyanAccent : Colors.pink[200],
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              messages[i]['text']!,
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
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
} // This final bracket was the one missing!