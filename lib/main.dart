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
  final String apiKey = 'AIzaSyCTWzmz3QL6YsE-dDo5_X3Tvc7hL0NgbSQ'; 
  
  late final GenerativeModel model;
  late final ChatSession chat;
  final TextEditingController _controller = TextEditingController();
  List<Map<String, String>> messages = [];

  @override
void initState() {
  super.initState();
  
  // By putting 'models/' in front, we are using the absolute path.
  // This is the most stable way to call the model.
  model = GenerativeModel(
    model: 'gemini-2.5-flash', 
    apiKey: apiKey,
  );

  // We are going to start the chat WITHOUT system instructions first
  // just to prove the connection works.
  chat = model.startChat();
}

  void _sendMessage() async {
  final text = _controller.text;
  if (text.isEmpty) return;
  
  setState(() => messages.add({"role": "user", "text": text}));
  _controller.clear();

  try {
    // We call generateContent directly on the model.
    // This is the "Emergency Exit" for when ChatSessions fail.
    final content = [Content.text("You are Yui. Answer as her: $text")];
    final response = await model.generateContent(content);
    
    setState(() => messages.add({"role": "yui", "text": response.text ?? "..."}));
  } catch (e) {
    setState(() => messages.add({"role": "yui", "text": "Error: $e"}));
  }
}

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
                          color: isYui ? Colors.white.withAlpha(30) : Colors.pinkAccent.withAlpha(50),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.white.withAlpha(30)),
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
                  color: Colors.black.withAlpha(100),
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
}