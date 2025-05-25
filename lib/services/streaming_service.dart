import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// Datentyp für Streaming-Events
class StreamingEvent {
  final String type;
  final String? content;
  final String? fullResponse;
  final String? message;

  StreamingEvent({
    required this.type,
    this.content,
    this.fullResponse,
    this.message,
  });

  factory StreamingEvent.fromJson(Map<String, dynamic> json) {
    return StreamingEvent(
      type: json['type'] ?? '',
      content: json['content'],
      fullResponse: json['full_response'],
      message: json['message'],
    );
  }
}

class StreamingService {
  /// Verarbeitet einen Streaming-Response und ruft Callbacks für Events auf
  Future<void> processStreamingResponse(
    http.StreamedResponse streamedResponse,
    Function(String content) onChunk,
    Function(String fullResponse) onComplete,
    Function(String error) onError,
  ) async {
    try {
      final stream = streamedResponse.stream.transform(utf8.decoder);
      String accumulatedContent = '';

      await for (String chunk in stream) {
        final events = _parseServerSentEvents(chunk);

        for (StreamingEvent event in events) {
          switch (event.type) {
            case 'chunk':
              if (event.content != null) {
                accumulatedContent += event.content!;
                onChunk(accumulatedContent);
              }
              break;
            case 'complete':
              final finalResponse = event.fullResponse ?? accumulatedContent;
              onComplete(finalResponse);
              break;
            case 'error':
              onError(event.message ?? 'Unbekannter Fehler');
              break;
          }
        }
      }
    } catch (e) {
      debugPrint('Streaming error: $e');
      onError('Verbindungsfehler: $e');
    }
  }

  /// Parst Server-Sent Events aus einem Chunk
  List<StreamingEvent> _parseServerSentEvents(String chunk) {
    final List<StreamingEvent> events = [];
    final lines = chunk.split('\n');

    for (String line in lines) {
      if (line.startsWith('data: ')) {
        final jsonStr = line.substring(6); // Remove 'data: '
        if (jsonStr.trim().isEmpty) continue;

        try {
          final data = json.decode(jsonStr);
          events.add(StreamingEvent.fromJson(data));
        } catch (e) {
          debugPrint('Error parsing JSON: $e');
        }
      }
    }

    return events;
  }
}
