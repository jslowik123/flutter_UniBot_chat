import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';
import '../services/streaming_service.dart';
import 'dart:convert';

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
  String _accumulatedContent = ''; // Akkumulierter Content für Parsing
  String _lastPrintedContent = ''; // Letzter geprinter Content für Debugging
  String _lastParsedContent = ''; 
  String _fullResponse = '';// Letzter geparster Content für Debugging

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

  /// Simple Chunk-Verarbeitung: Prüft Kriterien und updated Message
  void _processAccumulatedContent(int messageIndex) {
    // HIER DEINE KRITERIEN DEFINIEREN:
    //if (_accumulatedContent.contains('{ "answer" :') ) {
    print(_accumulatedContent);
    if (_accumulatedContent.contains(':')) {
      List<String> parts = _accumulatedContent.split("\"");
      //print(parts);
      _lastParsedContent = parts[3];
    } else {
      _lastParsedContent = "";
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
    
    // Content-Akkumulator zurücksetzen
    _accumulatedContent = '';
    _lastPrintedContent = '';

    try {
      final streamedResponse = await _chatService.createStreamRequest(
        userInput,
        _projectName,
      );

      await _streamingService.processStreamingResponse(
        streamedResponse,
        (content) {
          // Akkumuliere die einzelnen Chunks hier
          _accumulatedContent += content;
          
          // Prüfe ob der akkumulierte Content bereits eine Fehlermeldung enthält
          if (_isServerErrorMessage(_accumulatedContent)) {
            // Server-Fehlermeldung direkt anzeigen und Streaming stoppen
            updateMessage(botMessageIndex, _accumulatedContent, isStreaming: false);
            _lastAnswer = _accumulatedContent;
            _lastSource = null;
            _lastDocumentId = null;
            return;
          }
          
          // Normale Verarbeitung für gültige Chunks
          _processAccumulatedContent(botMessageIndex);

        },
        (fullResponse) {
          // Finale Antwort - prüfe erst auf Server-Fehler
          if (_isServerErrorMessage(fullResponse)) {
            // Server-Fehlermeldung direkt anzeigen
            updateMessage(botMessageIndex, fullResponse, isStreaming: false);
            _lastAnswer = fullResponse;
            _lastSource = null;
            _lastDocumentId = null;
            return;
          }
          
          // Normale Verarbeitung für gültige Antworten
          _accumulatedContent = fullResponse;
          _processAccumulatedContent(botMessageIndex);
          updateMessage(botMessageIndex, _lastParsedContent, isStreaming: false, source: _lastSource, documentId: _lastDocumentId);
          _lastAnswer = _lastParsedContent;
          _fullResponse = fullResponse;
          parseResponse(_fullResponse); 
          updateMessage(botMessageIndex, _lastParsedContent, isStreaming: false, source: _lastSource, documentId: _lastDocumentId);
        },
        (error) {
          // Fehler - Lösche temporäre Speicher
          _lastAnswer = null;
          _lastSource = null;
          _lastDocumentId = null;
          _accumulatedContent = '';
          _lastPrintedContent = '';
          updateMessage(botMessageIndex, 'Fehler: $error', isStreaming: false);
        },
      );

      return null; // Kein Fehler
    } catch (e) {
      updateMessage(botMessageIndex, 'Fehler: $e', isStreaming: false);
      return 'Streaming-Fehler: $e';
    } finally {
      _isLoading = false;
      _accumulatedContent = '';
      _lastPrintedContent = '';
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

  /// Prüft, ob die Response eine Server-Fehlermeldung ist
  bool _isServerErrorMessage(String response) {
    final trimmedResponse = response.trim();
    
    // Typische Server-Fehlermeldungen erkennen
    final errorPatterns = [
      'Entschuldigung, es ist ein Fehler aufgetreten',
      'Ein Fehler ist aufgetreten',
      'Internal Server Error',
      'Service Unavailable',
      'Bad Gateway',
      'Gateway Timeout',
      'Server Error',
      'Temporarily Unavailable',
      'Try again later',
      'versuchen Sie es später erneut',
    ];
    
    // Prüfe auf typische Fehlermuster
    for (String pattern in errorPatterns) {
      if (trimmedResponse.toLowerCase().contains(pattern.toLowerCase())) {
        return true;
      }
    }
    
    // Prüfe ob es eine kurze Nachricht ohne JSON-Struktur ist
    // und keine typischen JSON-Zeichen enthält
    if (trimmedResponse.length < 200 && 
        !trimmedResponse.contains('{') && 
        !trimmedResponse.contains('"answer"') &&
        !trimmedResponse.contains('"source"') &&
        !trimmedResponse.contains('"document_id"')) {
      return true;
    }
    
    return false;
  }

  void parseResponse(String response) {
    // Erst prüfen, ob es sich um eine Server-Fehlermeldung handelt
    if (_isServerErrorMessage(response)) {
      print('Server-Fehlermeldung erkannt: $response');
      _lastAnswer = response; // Zeige die Fehlermeldung direkt an
      _lastSource = null;
      _lastDocumentId = null;
      notifyListeners();
      return;
    }
    
    try {
      // Versuche JSON zu parsen
      final Map<String, dynamic> parsedData = json.decode(response);
      
      // Extrahiere die Felder
      if (parsedData.containsKey('answer')) {
        _lastAnswer = parsedData['answer']?.toString();
      }
      
      if (parsedData.containsKey('source')) {
        _lastSource = parsedData['source']?.toString();
      }
      
      if (parsedData.containsKey('document_id')) {
        _lastDocumentId = parsedData['document_id']?.toString();
      }
      
      // Benachrichtige Listener über Änderungen
      notifyListeners();
      
      print('Response parsed successfully:');
      print('Answer: $_lastAnswer');
      print('Source: $_lastSource');
      print('Document ID: $_lastDocumentId');
      
    } catch (e) {
      print('Fehler beim Parsen der Response: $e');
      print('Response content: $response');
      
      // Fallback: Versuche einfachen Text-Parsing falls JSON fehlschlägt
      _trySimpleTextParsing(response);
      
    }
  }
  
  /// Fallback-Methode für einfaches Text-Parsing
  void _trySimpleTextParsing(String response) {
    try {
      // Suche nach answer, source und document_id in der Response
      final lines = response.split('\n');
      
      for (String line in lines) {
        final trimmedLine = line.trim();
        
        if (trimmedLine.contains('"answer"')) {
          final colonIndex = trimmedLine.indexOf(':');
          if (colonIndex != -1) {
            String answerPart = trimmedLine.substring(colonIndex + 1).trim();
            // Entferne Anführungszeichen und Kommas
            answerPart = answerPart.replaceAll(RegExp(r'^"|"$|,$'), '');
            _lastAnswer = answerPart;
          }
        }
        
        if (trimmedLine.contains('"source"')) {
          final colonIndex = trimmedLine.indexOf(':');
          if (colonIndex != -1) {
            String sourcePart = trimmedLine.substring(colonIndex + 1).trim();
            sourcePart = sourcePart.replaceAll(RegExp(r'^"|"$|,$'), '');
            _lastSource = sourcePart;
          }
        }
        
        if (trimmedLine.contains('"document_id"')) {
          final colonIndex = trimmedLine.indexOf(':');
          if (colonIndex != -1) {
            String docIdPart = trimmedLine.substring(colonIndex + 1).trim();
            docIdPart = docIdPart.replaceAll(RegExp(r'^"|"$|,$'), '');
            _lastDocumentId = docIdPart;
          }
        }
      }
      
      notifyListeners();
      print('Simple text parsing completed');
      
    } catch (e) {
      print('Auch einfaches Text-Parsing fehlgeschlagen: $e');
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
    _accumulatedContent = '';
    _lastPrintedContent = '';
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
