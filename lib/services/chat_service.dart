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

          // NEU: Extrahiere ggf. aus structured_response
          Map<String, dynamic> responseMap = jsonResponse;
          if (jsonResponse.containsKey('structured_response') && jsonResponse['structured_response'] is Map) {
            responseMap = jsonResponse['structured_response'] as Map<String, dynamic>;
          }

          // Answer (immer String, auch wenn leer)
          result['answer'] = responseMap['answer']?.toString() ?? '';

          // Sources (immer Liste, auch wenn leer)
          if (responseMap.containsKey('sources') && responseMap['sources'] is List) {
            result['sources'] = (responseMap['sources'] as List).map((s) => s.toString()).toList();
          } else if (responseMap.containsKey('source') && responseMap['source'] != null && responseMap['source'].toString().isNotEmpty) {
            result['sources'] = [responseMap['source'].toString()];
          } else {
            result['sources'] = [];
          }

          // Document IDs (immer Liste, auch wenn leer)
          if (responseMap.containsKey('document_ids') && responseMap['document_ids'] is List) {
            result['document_ids'] = (responseMap['document_ids'] as List).map((id) => id.toString()).toList();
          } else if (responseMap.containsKey('document_id') && responseMap['document_id'] != null && responseMap['document_id'].toString().isNotEmpty) {
            result['document_ids'] = [responseMap['document_id'].toString()];
          } else {
            result['document_ids'] = [];
          }

          // Page Numbers (immer Liste, auch wenn leer)
          if (responseMap.containsKey('pages') && responseMap['pages'] is List) {
            result['pages'] = (responseMap['pages'] as List).map((page) => page.toString()).toList();
          } else if (responseMap.containsKey('pages') && responseMap['pages'] != null && responseMap['pages'].toString().isNotEmpty) {
            result['pages'] = [responseMap['pages'].toString()];
          } else {
            result['pages'] = [];
          }

          // Fallback: Wenn 'response' ein verschachteltes JSON ist
          if (jsonResponse.containsKey('response')) {
            final responseField = jsonResponse['response'];
            if (responseField is String) {
              try {
                final innerJson = json.decode(responseField);
                if (innerJson is Map<String, dynamic>) {
                  // Answer (überschreibt nur, wenn vorhanden)
                  if (innerJson.containsKey('answer')) {
                    result['answer'] = innerJson['answer']?.toString() ?? result['answer'];
                  }
                  // Sources (immer Liste)
                  if (innerJson.containsKey('sources') && innerJson['sources'] is List) {
                    result['sources'] = (innerJson['sources'] as List).map((s) => s.toString()).toList();
                  } else if (innerJson.containsKey('source') && innerJson['source'] != null && innerJson['source'].toString().isNotEmpty) {
                    result['sources'] = [innerJson['source'].toString()];
                  }
                  // Document IDs (immer Liste)
                  if (innerJson.containsKey('document_ids') && innerJson['document_ids'] is List) {
                    result['document_ids'] = (innerJson['document_ids'] as List).map((id) => id.toString()).toList();
                  } else if (innerJson.containsKey('document_id') && innerJson['document_id'] != null && innerJson['document_id'].toString().isNotEmpty) {
                    result['document_ids'] = [innerJson['document_id'].toString()];
                  }
                  // Page Numbers (immer Liste)
                  if (innerJson.containsKey('pages') && innerJson['pages'] is List) {
                    result['pages'] = (innerJson['pages'] as List).map((page) => page.toString()).toList();
                  } else if (innerJson.containsKey('page_number') && innerJson['page_number'] != null && innerJson['page_number'].toString().isNotEmpty) {
                    result['pages'] = [innerJson['page_number'].toString()];
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
          print('pages: ${result['pages']}');

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
