import 'package:flutter/material.dart';

class ChatbotTile extends StatelessWidget {
  final Map<String, dynamic> chatbot;
  final Function openChatFunc;

  const ChatbotTile({
    super.key,
    required this.chatbot,
    required this.openChatFunc,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String? date = chatbot['data']?['date'];

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        onTap: () => openChatFunc(context, chatbot),
        leading: CircleAvatar(child: Icon(Icons.work)),
        title: Text(chatbot['name'], style: theme.textTheme.headlineSmall),
        subtitle: Text(
          date ?? 'Kein Datum verfügbar',
          style: theme.textTheme.bodyMedium,
        ),
        trailing: IconButton(
          icon: Icon(Icons.chat_bubble),
          onPressed: () => openChatFunc(context, chatbot),
          tooltip: 'Chat öffnen',
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 8.0,
        ),
      ),
    );
  }
}
