/// Übersicht: Send-Message-Prozess in der Chat-App
///
/// 1. User gibt Nachricht ein und drückt Senden (UI: LLMInterface)
/// 2. Die Methode _sendMessage() wird aufgerufen
/// 3. ChatController.sendMessage() wird aufgerufen
/// 4. ChatService.sendMessage() macht den HTTP-Request
/// 5. Antwort wird verarbeitet und als ChatMessage gespeichert
/// 6. UI zeigt die Nachrichten inkl. animierter Bot-Bubble ("tippt...") an

import '../services/chat_service.dart';
import '../models/chat_message.dart';
import 'package:flutter/material.dart';

class SendMessageProcess {
  /// Beispielhafter Ablauf (vereinfachte Logik):
  Future<void> sendMessageProcess({
    required String userInput,
    required String projectName,
    required List<ChatMessage> messages,
    required ChatService chatService,
    required VoidCallback notifyListeners,
    required void Function(ChatMessage) addUserMessage,
    required void Function(ChatMessage) updateBotMessage,
  }) async {
    // 1. User-Message hinzufügen
    addUserMessage(ChatMessage(text: userInput, isUserMessage: true));
    // 2. Bot-Bubble mit "tippt..." anzeigen
    final typingMessage = ChatMessage(text: '', isUserMessage: false, isTyping: true);
    messages.add(typingMessage);
    final typingIndex = messages.length - 1;
    notifyListeners();

    try {
      // 3. Anfrage an Backend
      final response = await chatService.sendMessage(userInput, projectName);
      final answer = response['answer'] ?? 'Keine Antwort erhalten';
      final source = response['source'];
      final documentId = response['document_id'];
      // 4. Bot-Bubble ersetzen
      messages[typingIndex] = ChatMessage(
        text: answer,
        isUserMessage: false,
        source: source,
        documentId: documentId,
      );
      notifyListeners();
    } catch (e) {
      // Fehlerfall: Bot-Bubble durch Fehlermeldung ersetzen
      messages[typingIndex] = ChatMessage(
        text: 'Fehler: $e',
        isUserMessage: false,
      );
      notifyListeners();
    }
  }
}

/// ---
///
/// **Ablauf in Stichpunkten:**
///
/// - User tippt Nachricht ein → Senden
/// - UI ruft ChatController.sendMessage()
/// - ChatController:
///   - Fügt User-Message hinzu
///   - Fügt Bot-Bubble mit isTyping: true hinzu
///   - Ruft ChatService.sendMessage() (HTTP)
///   - Antwort kommt zurück → Bot-Bubble wird ersetzt
///   - notifyListeners() triggert UI-Update
/// - ChatBubble zeigt animierte Bubble, solange isTyping == true
/// - Nach Antwort: normale Bot-Bubble mit Text und ggf. CitationCard 