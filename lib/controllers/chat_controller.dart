import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';

class ChatController extends ChangeNotifier {
  final ChatService _chatService = ChatService();

  final List<ChatMessage> _messages = [
    ChatMessage(
      text: 'Stelle eine Frage oder schreibe eine Nachricht.',
      isUserMessage: false,
    ),
  ];

  bool _isLoading = false;
  bool _botStarted = false;
  String _projectName = '';
  String? _lastSource;
  List<String>? _lastDocumentIds;
  String? _lastAnswer;

  // Getters
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  bool get botStarted => _botStarted;
  String get projectName => _projectName;
  String? get lastSource => _lastSource;
  List<String>? get lastDocumentIds => _lastDocumentIds;
  String? get lastAnswer => _lastAnswer;

  // Setters
  void setProjectName(String name) {
    _projectName = name;
    notifyListeners();
  }

  void setIsLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Startet den Bot
  Future<String?> startBot() async {
    try {
      final success = await _chatService.startBot();
      if (success) {
        _botStarted = true;
        notifyListeners();
        return null; // Kein Fehler
      } else {
        return 'Bot konnte nicht gestartet werden';
      }
    } catch (e) {
      return 'Fehler beim Starten des Bots: $e';
    }
  }

  /// Fügt eine User-Message hinzu
  void addUserMessage(String text) {
    _messages.add(ChatMessage(text: text, isUserMessage: true));
    notifyListeners();
  }

  /// Fügt eine Bot-Message hinzu
  void addBotMessage(String text, {String? source, List<String>? documentIds}) {
    _messages.add(
      ChatMessage(
        text: text,
        isUserMessage: false,
        source: source,
        documentIds: documentIds,
      ),
    );
    notifyListeners();
  }

  /// Aktualisiert eine bestehende Message
  void updateMessage(
    int index,
    String text, {
    String? source,
    List<String>? documentIds,
  }) {
    if (index >= 0 && index < _messages.length) {
      _messages[index] = ChatMessage(
        text: text,
        isUserMessage: _messages[index].isUserMessage,
        source: source ?? _messages[index].source,
        documentIds: documentIds ?? _messages[index].documentIds,
      );
      notifyListeners();
    }
  }

  /// Sendet eine Nachricht
  Future<String?> sendMessage(String userInput) async {
    if (!_botStarted) {
      return 'Bot wurde noch nicht gestartet!';
    }

    if (userInput.trim().isEmpty) {
      return 'Bitte gib einen Prompt ein!';
    }

    _isLoading = true;
    addUserMessage(userInput);
    // Füge eine Bot-Nachricht mit isTyping: true hinzu
    _messages.add(ChatMessage(text: '', isUserMessage: false, isTyping: true));
    final typingIndex = _messages.length - 1;
    notifyListeners();

    try {
      final response = await _chatService.sendMessage(userInput, _projectName);

      // Extrahiere die Felder aus der Response
      final answer = response['answer'] ?? 'Keine Antwort erhalten';
      final source = response['source'];
      final documentIds = response['document_ids'] as List<String>?;

      // Speichere die Werte für späteren Zugriff
      _lastAnswer = answer;
      _lastSource = source;
      _lastDocumentIds = documentIds;

      // Ersetze die Typing-Nachricht durch die echte Antwort
      _messages[typingIndex] = ChatMessage(
        text: answer,
        isUserMessage: false,
        source: source,
        documentIds: documentIds,
      );
      notifyListeners();
      return null; // Kein Fehler
    } catch (e) {
      // Ersetze die Typing-Nachricht durch die Fehlermeldung
      _messages[typingIndex] = ChatMessage(
        text: 'Fehler: $e',
        isUserMessage: false,
      );
      notifyListeners();
      return 'Nachrichtenfehler: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Löscht alle Nachrichten
  void clearMessages() {
    _messages.clear();
    // Begrüßungsnachricht wieder hinzufügen
    _messages.add(
      ChatMessage(
        text: 'Stelle eine Frage oder schreibe eine Nachricht.',
        isUserMessage: false,
      ),
    );
    // Lösche temporäre Speicher
    _lastSource = null;
    _lastDocumentIds = null;
    _lastAnswer = null;
    notifyListeners();
  }

  /// Hilfsmethode: Gibt alle temporär gespeicherten Werte zurück
  Map<String, dynamic> getTemporaryStorage() {
    return {
      'answer': _lastAnswer,
      'source': _lastSource,
      'documentIds': _lastDocumentIds,
    };
  }

  /// Hilfsmethode: Lösche alle temporären Speicher
  void clearTemporaryStorage() {
    _lastAnswer = null;
    _lastSource = null;
    _lastDocumentIds = null;
    notifyListeners();
  }
}
