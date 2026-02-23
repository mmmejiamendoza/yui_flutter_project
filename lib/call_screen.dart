import 'package:flutter/material.dart';
import 'yui_service.dart';

class CallScreen extends StatefulWidget {
  final YuiService yui;
  const CallScreen({super.key, required this.yui});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  String _statusText = "Connecting...";
  bool _isThinking = false;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _startCall();
  }

  void _startCall() async {
    // Give the UI a moment to settle
    await Future.delayed(const Duration(milliseconds: 800));
    _sayInitialGreeting();
  }

  void _sayInitialGreeting() async {
    // Set the handler BEFORE speaking
    widget.yui.flutterTts.setCompletionHandler(() {
      if (mounted) {
        // Adding a 500ms delay helps the mic restart more reliably
        Future.delayed(const Duration(milliseconds: 500), () => _listenLoop());
      }
    });

    await widget.yui.speak("I'm here, Papa! I'm listening.");
  }

  void _listenLoop() async {
    if (!mounted) return;
    
    // 1. Clear the deck immediately
    await widget.yui.speechToText.stop();

    setState(() {
      _statusText = "Listening...";
      _isThinking = false;
    });

    // 2. Initialize with faster detection
    bool available = await widget.yui.speechToText.initialize();
    if (available) {
      widget.yui.speechToText.listen(
        onResult: (result) {
          // Update text in real-time so you see she's hearing you
          setState(() => _statusText = result.recognizedWords);

          if (result.finalResult && result.recognizedWords.isNotEmpty) {
            // 3. IMMEDIATELY stop mic once we have the sentence
            widget.yui.speechToText.stop(); 
            _processVoice(result.recognizedWords);
          }
        },
        listenFor: const Duration(seconds: 30),
        // 4. THE SPEED SECRET: 
        // We reduce this to 1 second so she responds faster after you stop speaking.
        pauseFor: const Duration(seconds: 1), 
      );
    }
  }

  void _processVoice(String text) async {
    setState(() {
      _statusText = "Thinking...";
      _isThinking = true;
    });

    // 5. Groq is fast, but we ensure the TTS doesn't block the logic
    String response = await widget.yui.getGroqResponse([{"role": "user", "text": text}]);
    
    if (mounted) {
      setState(() {
        _statusText = response;
        _isThinking = false;
      });
      
      // 6. Speak! (The CompletionHandler will jump back to _listenLoop instantly)
      await widget.yui.speak(response);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    widget.yui.speechToText.stop();
    widget.yui.flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Stack(
        // Forces all children to stay in the dead center of the screen
        alignment: Alignment.center, 
        children: [
          // 1. Pulsing Glow (Locked to center)
          Center(
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                double size = 180 + (100 * _pulseController.value);
                return Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.pinkAccent.withValues(
                      alpha: 0.15 * (1 - _pulseController.value),
                    ),
                  ),
                );
              },
            ),
          ),

          // 2. Foreground UI
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 40),
                const Text(
                  "ENCRYPTED CALL", 
                  style: TextStyle(color: Colors.white24, letterSpacing: 5, fontSize: 12),
                ),
                const Spacer(),
                
                // Avatar
                CircleAvatar(
                  radius: 80,
                  backgroundColor: Colors.pinkAccent.withValues(alpha: 0.2),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/yui.png', 
                      errorBuilder: (c, e, s) => const Icon(Icons.person, size: 80, color: Colors.white24),
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    _statusText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white, 
                      fontSize: 18, 
                      fontWeight: FontWeight.w300,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                if (_isThinking) 
                  const CircularProgressIndicator(color: Colors.pinkAccent, strokeWidth: 2),
                
                const Spacer(),
                
                // End Call Button
                Padding(
                  padding: const EdgeInsets.only(bottom: 60),
                  child: FloatingActionButton.large(
                    onPressed: () => Navigator.pop(context),
                    backgroundColor: Colors.redAccent,
                    child: const Icon(Icons.call_end, color: Colors.white, size: 40),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}