import 'package:flutter/material.dart';
import '../controllers/chat_controller.dart';
import '../widgets/chat_bubble.dart';

class LLMInterface extends StatefulWidget {
  const LLMInterface({super.key});

  @override
  LLMInterfaceState createState() => LLMInterfaceState();
}

class LLMInterfaceState extends State<LLMInterface> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatController _chatController = ChatController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initializeChat();
    });

    // Listen to chat controller changes
    _chatController.addListener(() {
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _chatController.dispose();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    // Get project name from route arguments
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args.containsKey('name')) {
      _chatController.setProjectName(args['name']);
    }

    // Start bot
    setState(() {
      _chatController.setIsLoading(true);
    });
    final error = await _chatController.startBot();
    if (!mounted) return;
    setState(() {
      _chatController.setIsLoading(false);
    });
    if (error != null && mounted) {
      _showSnackBar(error, isError: true);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.secondary,
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();

    final error = await _chatController.sendMessage(text);
    if (!mounted) return;

    if (error != null && mounted) {
      _showSnackBar(error, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _chatController.projectName.isNotEmpty
              ? _chatController.projectName
              : 'LLM Chat',
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _chatController.clearMessages();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: AnimatedBuilder(
                animation: _chatController,
                builder: (context, child) {
                  return ListView.builder(
                    controller: _scrollController,
                    itemCount: _chatController.messages.length,
                    itemBuilder: (context, index) {
                      return ChatBubble(
                        message: _chatController.messages[index],
                        projectName: _chatController.projectName,
                      );
                    },
                  );
                },
              ),
            ),
            AnimatedBuilder(
              animation: _chatController,
              builder: (context, child) {
                if (_chatController.isLoading) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Bot tippt...',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      enabled: !_chatController.isLoading,
                      decoration: InputDecoration(
                        hintText: 'Schreibe eine Nachricht...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(width: 2),
                        ),
                        suffixIcon: Icon(Icons.lightbulb_outline, color: Theme.of(context).colorScheme.secondary,),
                      ),
                      maxLines: 1,
                      onSubmitted: (_) => _sendMessage(),
                      textInputAction: TextInputAction.send,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _chatController.isLoading ? null : _sendMessage,
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
