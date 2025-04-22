import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/chat_message.dart';
import '../widgets/chat_bubble.dart'; 

class LLMInterface extends StatefulWidget {
  const LLMInterface({super.key});

  @override
  LLMInterfaceState createState() => LLMInterfaceState();
}

class LLMInterfaceState extends State<LLMInterface> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  final String _baseUrl = 'http://localhost:8000';
  bool _botStarted = false;

  @override
  void initState() {
    super.initState();
    startBot();
  }

  Future<void> startBot() async {
    try {
      final response = await http.post(Uri.parse('$_baseUrl/start_bot'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Der Bot wurde erfolgreich gestartet!'),
            ),
          );
          setState(() {
            _botStarted = true;
          });
        } else {
          throw Exception('Failed to start bot');
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Starten des Bots: $e')),
      );
    }
  }

  Future<void> sendMessage() async {
    if (!_botStarted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bot wurde noch nicht gestartet!')),
      );
      return;
    }

    final prompt = _controller.text.trim();
    if (prompt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte gib einen Prompt ein!')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _messages.add(ChatMessage(text: prompt, isUserMessage: true));
    });

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/send_message'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_input': prompt}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _controller.clear();
          _messages.add(
            ChatMessage(text: data['response'], isUserMessage: false),
          );
        });
      } else if (response.statusCode == 401) {
        setState(() {
          _messages.add(
            ChatMessage(
              text: "Invalid API Key, or no credits",
              isUserMessage: false,
            ),
          );
        });
      } else {
        setState(() {
          _messages.add(
            ChatMessage(
              text: 'Fehler: ${response.statusCode}',
              isUserMessage: false,
            ),
          );
        });
      }
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(text: 'Fehler: $e', isUserMessage: false));
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('LLM Chat'), elevation: 4),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return ChatBubble(message: _messages[index]);
                },
              ),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: CircularProgressIndicator(),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Schreibe eine Nachricht...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      maxLines: 1,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: sendMessage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
