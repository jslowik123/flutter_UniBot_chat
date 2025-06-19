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
  Future<Map<String, dynamic>> sendMessage(String userInput, String projectName) async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}$_sendMessageEndpoint');
      final request = http.MultipartRequest('POST', uri)
        ..fields['user_input'] = userInput
        ..fields['namespace'] = projectName.isNotEmpty ? projectName : 'default';

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
          
          if (jsonResponse.containsKey('source')) {
            result['source'] = jsonResponse['source']?.toString();
          }
          
          if (jsonResponse.containsKey('document_id')) {
            result['document_id'] = jsonResponse['document_id']?.toString();
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
                  if (innerJson.containsKey('source')) {
                    result['source'] = innerJson['source']?.toString();
                  }
                  if (innerJson.containsKey('document_id')) {
                    result['document_id'] = innerJson['document_id']?.toString();
                  }
                }
              } catch (e) {
                // ignore, fallback bleibt
              }
            }
          }
          
          print('--- DEBUG: Extrahierte Felder ---');
          print('answer: ${result['answer']}');
          print('source: ${result['source']}');
          print('document_id: ${result['document_id']}');

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
        throw Exception("Fehler: [31m${errorMessage ?? 'Ungültige Anfrage'}[0m");
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
