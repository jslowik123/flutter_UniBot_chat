import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/chat_message.dart';
import '../widgets/chat_bubble.dart';
import '../config/app_config.dart';

class LLMInterface extends StatefulWidget {
  const LLMInterface({super.key});

  @override
  LLMInterfaceState createState() => LLMInterfaceState();
}

class LLMInterfaceState extends State<LLMInterface> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _botStarted = false;
  String _projectName = '';

  @override
  void initState() {
    super.initState();
    // Get route arguments and start bot after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args.containsKey('name')) {
        setState(() {
          _projectName = args['name'];
        });
      }
      // Start bot after getting arguments
      await startBot();
    });
  }

  Future<void> startBot() async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/start_bot'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Der Bot wurde erfolgreich gestartet!'),
                backgroundColor: Theme.of(context).colorScheme.secondary,
              ),
            );
            setState(() {
              _botStarted = true;
            });
          }
        } else {
          throw Exception('Failed to start bot: ${data['message']}');
        }
      } else {
        throw Exception('Failed to start bot: ${response.statusCode}');
      }
    } catch (e) {
      // Debug print
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Starten des Bots: $e'),
            backgroundColor: Theme.of(context).colorScheme.secondary,
          ),
        );
      }
    }
  }

  Future<void> sendMessage() async {
    if (!_botStarted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Bot wurde noch nicht gestartet!'),
          backgroundColor: Theme.of(context).colorScheme.secondary,
        ),
      );
      return;
    }

    final prompt = _controller.text.trim();
    if (prompt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Bitte gib einen Prompt ein!'),
          backgroundColor: Theme.of(context).colorScheme.secondary,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _controller.clear();
      _messages.add(ChatMessage(text: prompt, isUserMessage: true));
    });

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/send_message'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
          'Accept': 'application/json; charset=UTF-8',
        },
        body: {
          'user_input': prompt,
          'namespace': _projectName.isNotEmpty ? _projectName : 'default',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final responseText = data['response'] as String?;
        if (responseText != null) {
          setState(() {
            _messages.add(
              ChatMessage(text: responseText, isUserMessage: false),
            );
          });
        } else {
          setState(() {
            _messages.add(
              ChatMessage(
                text: "Fehler: Keine Antwort vom Server erhalten",
                isUserMessage: false,
              ),
            );
          });
        }
      } else if (response.statusCode == 422) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final errorMessage = data['message'] as String?;
        setState(() {
          _messages.add(
            ChatMessage(
              text: "Fehler: ${errorMessage ?? 'Ungültige Anfrage'}",
              isUserMessage: false,
            ),
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
      appBar: AppBar(
        title: Text(_projectName.isNotEmpty ? _projectName : 'LLM Chat'),
        elevation: 0,
      ),
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
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
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
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(width: 2),
                        ),
                      ),
                      maxLines: 1,
                      onSubmitted: (_) => sendMessage(),
                      textInputAction: TextInputAction.send,
                    ),
                  ),
                  IconButton(icon: Icon(Icons.send), onPressed: sendMessage),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
