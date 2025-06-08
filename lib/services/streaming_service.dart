import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

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
        
        final events = _parseServerSentEvents(chunk);

        for (StreamingEvent event in events) {
          switch (event.type) {
            case 'chunk':
              String contentToShow = '';
              
              // Priorisiere 'answer' über 'content'
              if (event.answer != null) {
                contentToShow = event.answer!;
              } else if (event.content != null) {
                contentToShow = event.content!;
              }
              
              if (contentToShow.isNotEmpty) {
                accumulatedContent += contentToShow;
                onChunk(accumulatedContent);
              }
              
              // Speichere Source für späteren Gebrauch
              if (event.source != null) {
                lastSource = event.source;
                onSource?.call(event.source!);
              }
              
              // Speichere document_id für späteren Gebrauch
              if (event.documentId != null) {
                lastDocumentId = event.documentId;
                onDocumentId?.call(event.documentId!);
              }
              break;
              
            case 'complete':
              String finalResponse = '';
              
              // Priorisiere answer/fullResponse
              if (event.answer != null) {
                finalResponse = event.answer!;
              } else if (event.fullResponse != null) {
                finalResponse = event.fullResponse!;
              } else {
                finalResponse = accumulatedContent;
              }
              
              onComplete(finalResponse);
              
              // Source-Info bei Completion verfügbar machen
              if (event.source != null || lastSource != null) {
                onSource?.call(event.source ?? lastSource!);
              }
              
              // document_id-Info bei Completion verfügbar machen
              if (event.documentId != null || lastDocumentId != null) {
                onDocumentId?.call(event.documentId ?? lastDocumentId!);
              }
              break;
              
            case 'error':
              onError(event.message ?? 'Unbekannter Fehler');
              break;
          }
        }
        
      }
      
      // Falls keine Events gefunden wurden, könnte es sich um direktes JSON handeln
      if (chunkCount == 1 && accumulatedContent.isEmpty) {
        // Hier könnten wir fallback auf direktes JSON machen
      }
      
    } catch (e) {
      onError('Verbindungsfehler: $e');
    }
  }

  /// Parst Server-Sent Events aus einem Chunk
  List<StreamingEvent> _parseServerSentEvents(String chunk) {
    final List<StreamingEvent> events = [];
    final lines = chunk.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      if (line.startsWith('data: ')) {
        final jsonStr = line.substring(6); // Remove 'data: '

        if (jsonStr.trim().isEmpty) continue;

        try {
          final data = json.decode(jsonStr);
          events.add(StreamingEvent.fromJson(data));
        } catch (e) {
          // Ignoriere JSON-Parsing Fehler
        }
      } else if (line.trim().isNotEmpty) {
        // Prüfe ob es direktes JSON ist
        try {
          final data = json.decode(line);

          // Verarbeite strukturierte Antworten mit answer/source/document_id
          if (data is Map<String, dynamic>) {
            // Wenn die Response direkt ein JSON-Objekt mit answer ist
            if (data.containsKey('answer')) {
              // Nur das answer-Feld verwenden
              final answerText = data['answer']?.toString() ?? '';
              final sourceText = data['source']?.toString();
              final docId = data['document_id']?.toString();
              
              events.add(StreamingEvent(
                type: 'chunk',
                answer: answerText,
                source: sourceText,
                documentId: docId,
              ));
              events.add(StreamingEvent(
                type: 'complete',
                answer: answerText,
                source: sourceText,
                documentId: docId,
              ));
            }
            // Fallback: Konvertiere zu SSE Format (bestehende Logik)
            else if (data['status'] == 'success' && data['response'] != null) {
              events.add(StreamingEvent(
                type: 'chunk',
                content: data['response'],
              ));
              events.add(StreamingEvent(
                type: 'complete',
                fullResponse: data['response'],
              ));
            }
            // Falls die gesamte Response als String zurückkommt (Fallback)
            else {
              // Versuche trotzdem zu parsen, falls es ein verschachtelter JSON ist
              final responseString = data.toString();
              if (responseString.contains('"answer"')) {
                // Ignoriere solche Responses - sie sind nicht korrekt formatiert
              } else {
                events.add(StreamingEvent(
                  type: 'chunk',
                  content: responseString,
                ));
                events.add(StreamingEvent(
                  type: 'complete',
                  fullResponse: responseString,
                ));
              }
            }
          }
        } catch (e) {
          // Falls JSON-Parsing fehlschlägt, behandle es als normalen Text
          if (line.contains('answer') && line.contains('{')) {
            // Versuche manuell das answer Feld zu extrahieren
            final answerMatch = RegExp(r'"answer":\s*"([^"]*)"').firstMatch(line);
            if (answerMatch != null) {
              final answerText = answerMatch.group(1) ?? '';
              events.add(StreamingEvent(
                type: 'chunk',
                answer: answerText,
              ));
              events.add(StreamingEvent(
                type: 'complete',
                answer: answerText,
              ));
            }
          }
        }
      }
    }

    return events;
  }
}
