import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import 'citation_card.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment:
          message.isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        child: Column(
          crossAxisAlignment: message.isUserMessage 
              ? CrossAxisAlignment.end 
              : CrossAxisAlignment.start,
          children: [
            // Chat Bubble
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
              decoration: BoxDecoration(
                color: message.isUserMessage ? Colors.blue : Colors.grey,
                borderRadius: BorderRadius.circular(8.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      children: _parseFormattedTextForBold(message.text),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontFamily: 'Roboto',
                        height: 1.4,
                      ),
                    ),
                  ),
                  if (message.isStreaming)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'tippt...',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            
            // Citation Card - nur anzeigen wenn source oder documentId vorhanden
            if (message.source != null || message.documentId != null) ...[
              const SizedBox(height: 8),
              CitationCard(
                source: message.source,
                documentId: message.documentId,
              ),
            ],
           
          ],
        ),
      ),
    );
  }

  List<TextSpan> _parseFormattedTextForBold(String text) {
    final List<TextSpan> spans = [];
    final RegExp boldPattern = RegExp(r'\*\*(.*?)\*\*');
    final RegExp italicPattern = RegExp(r'\*(.*?)\*');

    int lastIndex = 0;
    
    // Verarbeite fetten Text
    boldPattern.allMatches(text).forEach((match) {
      // Text vor dem Match
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
        ));
      }
      
      // Fetter Text
      spans.add(TextSpan(
        text: match.group(1),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ));
      
      lastIndex = match.end;
    });
    
    // Verarbeite kursiven Text (vereinfacht)
    if (lastIndex < text.length) {
      final remainingText = text.substring(lastIndex);
      italicPattern.allMatches(remainingText).forEach((match) {
        spans.add(TextSpan(
          text: match.group(1),
          style: const TextStyle(fontStyle: FontStyle.italic),
        ));
      });
      
      // Falls kein kursiver Text, füge den Rest als normalen Text hinzu
      if (!italicPattern.hasMatch(remainingText)) {
        spans.add(TextSpan(text: remainingText));
      }
    }
    
    // Falls keine Formatierung gefunden wurde, gib den gesamten Text zurück
    if (spans.isEmpty) {
      spans.add(TextSpan(text: text));
    }
    
    return spans;
  }
}
