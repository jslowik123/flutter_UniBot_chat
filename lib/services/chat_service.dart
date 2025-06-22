import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/app_config.dart';

class ChatService {
  static const String _startBotEndpoint = '/start_bot';
  static const String _sendMessageEndpoint = '/send_message';
  bool isLoading = false;

  /// Startet den Bot auf dem Server
  Future<bool> startBot() async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}$_startBotEndpoint'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          return true;
        } else {
          throw Exception('Failed to start bot: ${data['message']}');
        }
      } else {
        throw Exception('Failed to start bot: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error starting bot: $e');
    }
  }

  /// Sendet eine Nachricht und gibt die komplette Response zurück
  Future<Map<String, dynamic>> sendMessage(
    String userInput,
    String projectName,
  ) async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}$_sendMessageEndpoint');
      final request =
          http.MultipartRequest('POST', uri)
            ..fields['user_input'] = userInput
            ..fields['namespace'] =
                projectName.isNotEmpty ? projectName : 'default';

      final streamedResponse = await request.send();
      final responseData = await streamedResponse.stream.bytesToString();

      print('--- DEBUG: HTTP-Response-Body ---');
      print(responseData);

      if (streamedResponse.statusCode == 200) {
        try {
          final jsonResponse = json.decode(responseData);
          print('--- DEBUG: Geparstes JSON ---');
          print(jsonResponse);

          // Extrahiere die Response-Felder
          final result = <String, dynamic>{};

          if (jsonResponse.containsKey('answer')) {
            result['answer'] = jsonResponse['answer']?.toString();
          }

          // Verarbeite 'sources' (plural)
          if (jsonResponse.containsKey('sources')) {
            final sourcesValue = jsonResponse['sources'];
            if (sourcesValue is List) {
              result['sources'] =
                  sourcesValue.map((s) => s.toString()).toList();
            }
          } 
          // Fallback für 'source' (singular)
          else if (jsonResponse.containsKey('source')) {
            result['sources'] = [jsonResponse['source']?.toString()];
          }

          // Verarbeite 'document_ids' (plural)
          if (jsonResponse.containsKey('document_ids')) {
            final documentIdValue = jsonResponse['document_ids'];
            if (documentIdValue is List) {
              result['document_ids'] =
                  documentIdValue.map((id) => id.toString()).toList();
            }
          } 
          // Fallback für 'document_id' (singular)
          else if (jsonResponse.containsKey('document_id')) {
            final documentIdValue = jsonResponse['document_id'];
            if (documentIdValue != null) {
              result['document_ids'] = [documentIdValue.toString()];
            }
          }

          // Fallback: Wenn 'response' ein verschachteltes JSON ist
          if (jsonResponse.containsKey('response')) {
            final responseField = jsonResponse['response'];
            if (responseField is String) {
              try {
                final innerJson = json.decode(responseField);
                if (innerJson is Map<String, dynamic>) {
                  if (innerJson.containsKey('answer')) {
                    result['answer'] = innerJson['answer']?.toString();
                  }
                  
                  // Verarbeite 'sources' im inneren JSON
                  if (innerJson.containsKey('sources')) {
                     final sourcesValue = innerJson['sources'];
                     if (sourcesValue is List) {
                       result['sources'] = sourcesValue.map((s) => s.toString()).toList();
                     }
                  } 
                  // Fallback für 'source' im inneren JSON
                  else if (innerJson.containsKey('source')) {
                    result['sources'] = [innerJson['source']?.toString()];
                  }

                  // Verarbeite 'document_ids' im inneren JSON
                  if (innerJson.containsKey('document_ids')) {
                    final documentIdValue = innerJson['document_ids'];
                     if (documentIdValue is List) {
                       result['document_ids'] = documentIdValue.map((id) => id.toString()).toList();
                     }
                  }
                   // Fallback für 'document_id' im inneren JSON
                  else if (innerJson.containsKey('document_id')) {
                    final documentIdValue = innerJson['document_id'];
                    if (documentIdValue != null) {
                      result['document_ids'] = [documentIdValue.toString()];
                    }
                  }
                }
              } catch (e) {
                // ignore, fallback bleibt
              }
            }
          }

          print('--- DEBUG: Extrahierte Felder ---');
          print('answer: ${result['answer']}');
          print('sources: ${result['sources']}');
          print('document_ids: ${result['document_ids']}');

          return result;
        } catch (e) {
          print('--- DEBUG: JSON-Parsing-Fehler ---');
          print(e);
          // Falls JSON-Parsing fehlschlägt, gib die rohe Response als answer zurück
          return {'answer': responseData};
        }
      } else if (streamedResponse.statusCode == 422) {
        final jsonResponse = json.decode(responseData);
        final errorMessage = jsonResponse['message'] as String?;
        throw Exception(
          "Fehler:  [31m${errorMessage ?? 'Ungültige Anfrage'} [0m",
        );
      } else if (streamedResponse.statusCode == 401) {
        throw Exception("Invalid API Key, or no credits");
      } else {
        throw Exception('HTTP Error: ${streamedResponse.statusCode}');
      }
    } catch (e) {
      throw Exception('Message sending failed: $e');
    }
  }
}
