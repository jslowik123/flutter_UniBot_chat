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
    final String? date = chatbot['data']?['date'];

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300, width: 1.0),
      ),
      child: ListTile(
        onTap: () => openChatFunc(context, chatbot),
        leading: CircleAvatar(child: Icon(Icons.work, color: Colors.blue)),
        title: Text(chatbot['name']),
        subtitle: Text(
          date ?? 'Kein Datum verfügbar',
          style: TextStyle(color: Colors.grey),
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
