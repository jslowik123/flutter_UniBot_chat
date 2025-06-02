import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';
import '../services/streaming_service.dart';

class ChatController extends ChangeNotifier {
  final ChatService _chatService = ChatService();
  final StreamingService _streamingService = StreamingService();

  final List<ChatMessage> _messages = [
    ChatMessage(
      text: 'Stelle eine Frage oder schreibe eine Nachricht...',
      isUserMessage: false,
      isStreaming: false,
    ),
  ];

  bool _isLoading = false;
  bool _botStarted = false;
  String _projectName = '';

  // Getters
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  bool get botStarted => _botStarted;
  String get projectName => _projectName;

  // Setters
  void setProjectName(String name) {
    _projectName = name;
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
  void addBotMessage(String text, {bool isStreaming = false}) {
    _messages.add(
      ChatMessage(text: text, isUserMessage: false, isStreaming: isStreaming),
    );
    notifyListeners();
  }

  /// Aktualisiert eine bestehende Message
  void updateMessage(int index, String text, {bool isStreaming = false}) {
    if (index >= 0 && index < _messages.length) {
      _messages[index] = ChatMessage(
        text: text,
        isUserMessage: _messages[index].isUserMessage,
        isStreaming: isStreaming,
      );
      notifyListeners();
    }
  }

  /// Sendet eine Nachricht mit Streaming
  Future<String?> sendStreamingMessage(String userInput) async {
    if (!_botStarted) {
      return 'Bot wurde noch nicht gestartet!';
    }

    if (userInput.trim().isEmpty) {
      return 'Bitte gib einen Prompt ein!';
    }

    // User-Message hinzufügen
    _isLoading = true;
    addUserMessage(userInput);

    // Leere Bot-Message für Streaming hinzufügen
    final botMessageIndex = _messages.length;
    addBotMessage('', isStreaming: true);

    try {
      final streamedResponse = await _chatService.createStreamRequest(
        userInput,
        _projectName,
      );

      await _streamingService.processStreamingResponse(
        streamedResponse,
        (content) {
          // Chunk erhalten
          updateMessage(botMessageIndex, content, isStreaming: true);
        },
        (fullResponse) {
          // Vollständige Antwort
          updateMessage(botMessageIndex, fullResponse, isStreaming: false);
        },
        (error) {
          // Fehler
          updateMessage(botMessageIndex, 'Fehler: $error', isStreaming: false);
        },
      );

      return null; // Kein Fehler
    } catch (e) {
      updateMessage(botMessageIndex, 'Fehler: $e', isStreaming: false);
      return 'Streaming-Fehler: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sendet eine Nachricht ohne Streaming (Fallback)
  Future<String?> sendRegularMessage(String userInput) async {
    if (!_botStarted) {
      return 'Bot wurde noch nicht gestartet!';
    }

    if (userInput.trim().isEmpty) {
      return 'Bitte gib einen Prompt ein!';
    }

    _isLoading = true;
    addUserMessage(userInput);
    notifyListeners();

    try {
      final response = await _chatService.sendMessage(userInput, _projectName);
      addBotMessage(response);
      return null; // Kein Fehler
    } catch (e) {
      addBotMessage('Fehler: $e');
      return 'Nachrichtenfehler: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Löscht alle Nachrichten
  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }
}
