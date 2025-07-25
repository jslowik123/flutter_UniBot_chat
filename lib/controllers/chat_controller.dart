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
  List<String>? _lastSources;
  List<String>? _lastDocumentIds;
  String? _lastAnswer;

  // Getters
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  bool get botStarted => _botStarted;
  String get projectName => _projectName;
  List<String>? get lastSources => _lastSources;
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
  void addBotMessage(String text, {List<String>? sources, List<String>? documentIds, List<String>? pages}) {
    _messages.add(
      ChatMessage(
        text: text,
        isUserMessage: false,
        sources: sources,
        documentIds: documentIds,
        pages: pages,
      ),
    );
    notifyListeners();
  }

  /// Aktualisiert eine bestehende Message
  void updateMessage(
    int index,
    String text, {
    List<String>? sources,
    List<String>? documentIds,
    List<String>? pages,
  }) {
    if (index >= 0 && index < _messages.length) {
      _messages[index] = ChatMessage(
        text: text,
        isUserMessage: _messages[index].isUserMessage,
        sources: sources ?? _messages[index].sources,
        documentIds: documentIds ?? _messages[index].documentIds,
        pages: pages ?? _messages[index].pages,
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
      
      // Extrahiere 'sources' oder 'source'
      List<String>? sources;
      if (response.containsKey('sources') && response['sources'] != null) {
        sources = (response['sources'] as List<dynamic>)
            .map((e) => e.toString())
            .toList();
      } else if (response.containsKey('source') && response['source'] != null && response['source'].toString().trim().isNotEmpty) {
        sources = [response['source'].toString()];
      }

      // Extrahiere 'document_ids', 'documentIds' oder 'document_id'
      List<String>? documentIdsAsString;
      if (response.containsKey('document_ids') && response['document_ids'] != null) {
        final documentIds = response['document_ids'] as List<dynamic>?;
        documentIdsAsString = documentIds?.map((e) => e.toString()).toList();
      } else if (response.containsKey('documentIds') && response['documentIds'] != null) {
        final documentIds = response['documentIds'] as List<dynamic>?;
        documentIdsAsString = documentIds?.map((e) => e.toString()).toList();
      } else if (response.containsKey('document_id') && response['document_id'] != null && response['document_id'].toString().trim().isNotEmpty) {
        documentIdsAsString = [response['document_id'].toString()];
      }

      // Extrahiere 'pages'
      List<String>? pages;
      if (response.containsKey('pages') && response['pages'] != null) {
        pages = (response['pages'] as List<dynamic>)
            .map((e) => e.toString())
            .toList();
      }

      // Speichere die Werte für späteren Zugriff
      _lastAnswer = answer;
      _lastSources = sources;
      _lastDocumentIds = documentIdsAsString;

      // Ersetze die Typing-Nachricht durch die echte Antwort
      _messages[typingIndex] = ChatMessage(
        text: answer,
        isUserMessage: false,
        sources: sources,
        documentIds: documentIdsAsString,
        pages: pages,
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
    _lastSources = null;
    _lastDocumentIds = null;
    _lastAnswer = null;
    notifyListeners();
  }

  /// Hilfsmethode: Gibt alle temporär gespeicherten Werte zurück
  Map<String, dynamic> getTemporaryStorage() {
    return {
      'answer': _lastAnswer,
      'sources': _lastSources,
      'documentIds': _lastDocumentIds,
    };
  }

  /// Hilfsmethode: Lösche alle temporären Speicher
  void clearTemporaryStorage() {
    _lastAnswer = null;
    _lastSources = null;
    _lastDocumentIds = null;
    notifyListeners();
  }
}
