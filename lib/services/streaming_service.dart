import 'dart:convert';
import 'package:http/http.dart' as http;

/// Datentyp für Streaming-Events
class StreamingEvent {
  final String type;
  final String? content;
  final String? fullResponse;
  final String? message;
  final String? answer;      // Neu: für strukturierte Antworten
  final String? source;      // Neu: für Quellen (später verwendbar)
  final String? documentId;  // Neu: für document_id

  StreamingEvent({
    required this.type,
    this.content,
    this.fullResponse,
    this.message,
    this.answer,
    this.source,
    this.documentId,
  });

  factory StreamingEvent.fromJson(Map<String, dynamic> json) {
    return StreamingEvent(
      type: json['type'] ?? '',
      content: json['content'],
      fullResponse: json['full_response'],
      message: json['message'],
      answer: json['answer'],
      source: json['source'],
      documentId: json['document_id'],
    );
  }
}

class StreamingService {
  /// Verarbeitet einen Streaming-Response und ruft Callbacks für Events auf
  Future<void> processStreamingResponse(
    http.StreamedResponse streamedResponse,
    Function(String content) onChunk,
    Function(String fullResponse) onComplete,
    Function(String error) onError, {
    Function(String source)? onSource, // Optional: für spätere Source-Verwendung
    Function(String documentId)? onDocumentId, // Optional: für document_id
  }) async {
    
    
    try {
      final stream = streamedResponse.stream.transform(utf8.decoder);
      String accumulatedContent = '';
      String? lastSource; // Speichere die letzte Source
      String? lastDocumentId; // Speichere die letzte document_id
      int chunkCount = 0;

      await for (String chunk in stream) {
        chunkCount++;
        
        // Einfaches SSE-Parsing: Entferne "data: " Prefix und extrahiere Content
        final lines = chunk.split('\n');
        for (String line in lines) {
          if (line.startsWith('data: ')) {
            final jsonStr = line.substring(6); // Remove 'data: '
            if (jsonStr.trim().isNotEmpty) {
              try {
                final data = json.decode(jsonStr);
                if (data is Map<String, dynamic> && data['content'] != null) {
                  final content = data['content'].toString();
                  if (content.isNotEmpty) {
                    accumulatedContent += content;
                    // Gib nur den neuen Content weiter, nicht den kompletten akkumulierten
                    onChunk(content);
                  }
                }
              } catch (e) {
                // Falls JSON-Parsing fehlschlägt, ignoriere es
              }
            }
          }
        }
      }
      
      // Am Ende die finale Response senden
      if (accumulatedContent.isNotEmpty) {
        onComplete(accumulatedContent);
      }
      
      // Falls keine Events gefunden wurden, könnte es sich um direktes JSON handeln
      if (chunkCount == 1 && accumulatedContent.isEmpty) {
        // Hier könnten wir fallback auf direktes JSON machen
      }
      
    } catch (e) {
      onError('Verbindungsfehler: $e');
    }
  }
}
