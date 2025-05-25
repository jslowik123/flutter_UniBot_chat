import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/app_config.dart';

class ChatService {
  static const String _startBotEndpoint = '/start_bot';
  static const String _sendMessageEndpoint = '/send_message';
  static const String _sendMessageStreamEndpoint = '/send_message_stream';

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

  /// Sendet eine Nachricht ohne Streaming (Fallback)
  Future<String> sendMessage(String userInput, String projectName) async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}$_sendMessageEndpoint');
      final request =
          http.MultipartRequest('POST', uri)
            ..fields['user_input'] = userInput
            ..fields['namespace'] =
                projectName.isNotEmpty ? projectName : 'default';

      final streamedResponse = await request.send();
      final responseData = await streamedResponse.stream.bytesToString();

      if (streamedResponse.statusCode == 200) {
        final jsonResponse = json.decode(responseData);
        final responseText = jsonResponse['response'] as String?;

        if (responseText != null) {
          return responseText;
        } else {
          throw Exception(
            "Keine Antwort erhalten. Serverantwort: $jsonResponse",
          );
        }
      } else if (streamedResponse.statusCode == 422) {
        final jsonResponse = json.decode(responseData);
        final errorMessage = jsonResponse['message'] as String?;
        throw Exception("Fehler: ${errorMessage ?? 'Ungültige Anfrage'}");
      } else if (streamedResponse.statusCode == 401) {
        throw Exception("Invalid API Key, or no credits");
      } else {
        throw Exception('HTTP Error: ${streamedResponse.statusCode}');
      }
    } catch (e) {
      throw Exception('Message sending failed: $e');
    }
  }

  /// Erstellt eine Stream-Request für Server-Sent Events
  Future<http.StreamedResponse> createStreamRequest(
    String userInput,
    String projectName,
  ) async {
    final request = http.Request(
      'POST',
      Uri.parse('${AppConfig.apiBaseUrl}$_sendMessageStreamEndpoint'),
    );

    request.headers.addAll({
      'Content-Type': 'application/x-www-form-urlencoded',
    });

    request.body =
        'user_input=${Uri.encodeComponent(userInput)}&namespace=${Uri.encodeComponent(projectName.isNotEmpty ? projectName : 'default')}';

    final streamedResponse = await request.send();

    if (streamedResponse.statusCode != 200) {
      throw Exception('HTTP ${streamedResponse.statusCode}');
    }

    return streamedResponse;
  }
}
