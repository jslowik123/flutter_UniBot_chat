import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';
import '../services/streaming_service.dart';
import 'dart:convert';
import 'dart:math';

class ChatController extends ChangeNotifier {
  final ChatService _chatService = ChatService();
  final StreamingService _streamingService = StreamingService();

  final List<ChatMessage> _messages = [
    ChatMessage(
      text: 'Stelle eine Frage oder schreibe eine Nachricht.',
      isUserMessage: false,
      isStreaming: false,
    ),
  ];

  bool _isLoading = false;
  bool _botStarted = false;
  String _projectName = '';
  String? _lastSource;
  String? _lastDocumentId;
  String? _lastAnswer; // Temporärer Speicher für answer

  // Getters
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  bool get botStarted => _botStarted;
  String get projectName => _projectName;
  String? get lastSource => _lastSource;
  String? get lastDocumentId => _lastDocumentId;
  String? get lastAnswer => _lastAnswer; // Getter für answer

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
  void addBotMessage(String text, {bool isStreaming = false, String? source, String? documentId}) {
    _messages.add(
      ChatMessage(
        text: text, 
        isUserMessage: false, 
        isStreaming: isStreaming,
        source: source,
        documentId: documentId,
      ),
    );
    notifyListeners();
  }

  /// Aktualisiert eine bestehende Message
  void updateMessage(int index, String text, {bool isStreaming = false, String? source, String? documentId}) {
    if (index >= 0 && index < _messages.length) {
      _messages[index] = ChatMessage(
        text: text,
        isUserMessage: _messages[index].isUserMessage,
        isStreaming: isStreaming,
        source: source ?? _messages[index].source,
        documentId: documentId ?? _messages[index].documentId,
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
    addBotMessage('', isStreaming: true);
    final botMessageIndex = _messages.length - 1;

    try {
      final streamedResponse = await _chatService.createStreamRequest(
        userInput,
        _projectName,
      );

      await _streamingService.processStreamingResponse(
        streamedResponse,
        (content) {
          // Chunk erhalten - Sicherheitscheck für JSON-Content
          final cleanedContent = _extractAnswerFromContent(content);
          // Speichere den aktuellen answer-Text temporär
          _lastAnswer = cleanedContent;
          updateMessage(botMessageIndex, cleanedContent, isStreaming: true, source: _lastSource, documentId: _lastDocumentId);
        },
        (fullResponse) {
          // Vollständige Antwort - Sicherheitscheck für JSON-Content
          final cleanedResponse = _extractAnswerFromContent(fullResponse);
          // Speichere die finale Antwort temporär
          _lastAnswer = cleanedResponse;
          updateMessage(botMessageIndex, cleanedResponse, isStreaming: false, source: _lastSource, documentId: _lastDocumentId);
        },
        (error) {
          // Fehler - Lösche temporäre Speicher
          _lastAnswer = null;
          _lastSource = null;
          _lastDocumentId = null;
          updateMessage(botMessageIndex, 'Fehler: $error', isStreaming: false);
        },
        onSource: (source) {
          // Source erhalten und speichern
          _lastSource = source;
          notifyListeners(); // UI über Source-Update informieren
        },
        onDocumentId: (documentId) {
          // document_id erhalten und speichern
          _lastDocumentId = documentId;
          notifyListeners(); // UI über document_id-Update informieren
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

  /// Extrahiert den Answer-Text aus Content, falls es JSON ist
  String _extractAnswerFromContent(String content) {
    // Überprüfe, ob der Content JSON-artige Strukturen enthält
    if (content.contains('{') || content.contains('"answer"') || content.contains('"source"') || content.contains('"document_id"') || content.contains('json')) {
      
      // Versuche zuerst vollständiges JSON zu parsen
      if (content.trim().startsWith('{') && content.trim().endsWith('}')) {
        try {
          final data = json.decode(content);
          if (data is Map<String, dynamic> && data.containsKey('answer')) {
            final answerText = data['answer']?.toString() ?? '';
            return answerText;
          }
        } catch (e) {
          // Ignoriere den Fehler und gehe zum robusten Text-Extraktions-Verfahren
        }
      }
      
      // Robuste Text-Extraktion für Streaming-Chunks
      String cleanedContent = content;
      
      // Schritt 1: Entferne vollständige JSON-Strukturen wenn erkennbar
      if (cleanedContent.contains('"answer"')) {
        // Extrahiere Text zwischen "answer": " und dem nächsten "
        final answerMatch = RegExp(r'"answer"\s*:\s*"([^"]*)"').firstMatch(cleanedContent);
        if (answerMatch != null) {
          cleanedContent = answerMatch.group(1) ?? '';
          return cleanedContent;
        }
      }
      
      // Schritt 2: Aggressive Bereinigung für Streaming-Chunks
      // Entferne "json" Marker am Anfang
      cleanedContent = cleanedContent.replaceAll(RegExp(r'^\s*```?\s*json\s*?\s*', caseSensitive: false), ''); // ```json```
      cleanedContent = cleanedContent.replaceAll(RegExp(r'^\s*json\s*', caseSensitive: false), ''); // "json" am Anfang
      
      // Entferne alle JSON-Syntax-Elemente
      cleanedContent = cleanedContent.replaceAll(RegExp(r'\{'), ''); // Alle {
      cleanedContent = cleanedContent.replaceAll(RegExp(r'\}'), ''); // Alle }
      cleanedContent = cleanedContent.replaceAll(RegExp(r'"answer"\s*:\s*'), ''); // "answer":
      cleanedContent = cleanedContent.replaceAll(RegExp(r'"source"\s*:\s*"[^"]*"\s*,?\s*'), ''); // "source": "..."
      cleanedContent = cleanedContent.replaceAll(RegExp(r'"document_id"\s*:\s*"[^"]*"\s*,?\s*'), ''); // "document_id": "..."
      cleanedContent = cleanedContent.replaceAll(RegExp(r',\s*"[^"]*"\s*:\s*"[^"]*"'), ''); // weitere JSON-Felder
      cleanedContent = cleanedContent.replaceAll(RegExp(r'^[",\s]+'), ''); // Anführungszeichen/Kommata am Anfang
      cleanedContent = cleanedContent.replaceAll(RegExp(r'[",\s]+$'), ''); // Anführungszeichen/Kommata am Ende
      cleanedContent = cleanedContent.replaceAll(RegExp(r'^\s*"'), ''); // Anführungszeichen am absoluten Anfang
      cleanedContent = cleanedContent.replaceAll(RegExp(r'"\s*$'), ''); // Anführungszeichen am absoluten Ende
      
      return cleanedContent;
    }
    
    // Wenn es kein JSON ist, zeige es normal an
    return content;
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
    // Begrüßungsnachricht wieder hinzufügen
    _messages.add(
      ChatMessage(
        text: 'Stelle eine Frage oder schreibe eine Nachricht.',
        isUserMessage: false,
        isStreaming: false,
      ),
    );
    // Lösche temporäre Speicher
    _lastSource = null;
    _lastDocumentId = null;
    _lastAnswer = null;
    notifyListeners();
  }

  /// Hilfsmethode: Gibt alle temporär gespeicherten Werte zurück
  Map<String, String?> getTemporaryStorage() {
    return {
      'answer': _lastAnswer,
      'source': _lastSource,
      'documentId': _lastDocumentId,
    };
  }

  /// Hilfsmethode: Lösche alle temporären Speicher
  void clearTemporaryStorage() {
    _lastAnswer = null;
    _lastSource = null;
    _lastDocumentId = null;
    notifyListeners();
  }
}
