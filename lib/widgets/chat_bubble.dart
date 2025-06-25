import 'package:flutter/material.dart';
import 'dart:convert';
import '../models/chat_message.dart';
import 'citation_card.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final String? projectName;

  const ChatBubble({super.key, required this.message, this.projectName});

  static const _noDocumentValues = [
    "no_document_used",
    "no_document_found",
    "None",
    "none",
  ];

  @override
  Widget build(BuildContext context) {
    print(message);
    print('source: ${message.source}');
    print('documentIds: ${message.documentIds}');
    return Align(
      alignment:
          message.isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        child: Column(
          crossAxisAlignment:
              message.isUserMessage
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
          children: [
            // Chat Bubble
            Container(
              padding: const EdgeInsets.symmetric(
                vertical: 10.0,
                horizontal: 16.0,
              ),
              decoration: BoxDecoration(
                color: message.isUserMessage ? Colors.blue : Colors.grey,
                borderRadius: BorderRadius.circular(8.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.isTyping) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'tippt...',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    RichText(
                      text: TextSpan(
                        children: _parseFormattedTextForBold(
                          _extractDisplayText(message.text),
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontFamily: 'Roboto',
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Citation Cards - eine für jede documentId wenn source oder documentIds vorhanden
            if (_shouldShowCitationCard(
              message.sources,
              message.documentIds,
            )) ...[
              const SizedBox(height: 8),
              ...(_buildCitationCards(message.sources, message.documentIds)),
            ],
          ],
        ),
      ),
    );
  }

  /// Prüft, ob die CitationCard angezeigt werden soll
  bool _shouldShowCitationCard(List<String>? sources, List<String>? documentIds) {
    // Liste der Werte, die bedeuten "kein Dokument"
    const noDocumentValues = _noDocumentValues;

    // Spezialfall: documentIds ist genau ["None"]
    if (documentIds != null &&
        documentIds.length == 1 &&
        documentIds.first == "None") {
      return false;
    }

    // Prüfe ob sources "kein Dokument" Werte enthalten
    bool sourcesAreNoDocument = sources == null ||
        sources.isEmpty ||
        sources.every((s) => noDocumentValues.contains(s));

    // Prüfe ob documentIds ein "kein Dokument" Wert ist
    bool documentIdIsNoDocument =
        documentIds == null ||
        documentIds.isEmpty ||
        documentIds.every((id) => noDocumentValues.contains(id));

    print('sourcesAreNoDocument: $sourcesAreNoDocument');
    print('documentIdIsNoDocument: $documentIdIsNoDocument');
    print('sources: $sources');
    print('documentIds: $documentIds');
    // CitationCard nicht anzeigen wenn beide "kein Dokument" sind
    if (sourcesAreNoDocument && documentIdIsNoDocument) {
      return false;
    }

    // CitationCard anzeigen wenn mindestens eins verfügbar ist
    return true;
  }

  /// Erstellt CitationCards für die verfügbaren documentIds
  List<Widget> _buildCitationCards(
      List<String>? sources, List<String>? documentIds) {
    List<Widget> cards = [];
    const noDocumentValues = _noDocumentValues;

    // Filtere gültige Dokument-IDs und die zugehörigen Quellen
    final validDocumentIds = <String>[];
    final validSources = <String?>[];

    if (documentIds != null && documentIds.isNotEmpty) {
      for (int i = 0; i < documentIds.length; i++) {
        final docId = documentIds[i];
        if (!noDocumentValues.contains(docId)) {
          validDocumentIds.add(docId);
          // Füge die entsprechende Quelle hinzu, falls vorhanden
          if (sources != null && i < sources.length) {
            validSources.add(sources[i]);
          } else {
            validSources.add(null);
          }
        }
      }
    }

    // Erstelle CitationCards für jedes gültige Dokument
    if (validDocumentIds.isNotEmpty) {
      for (int i = 0; i < validDocumentIds.length; i++) {
        cards.add(
          Padding(
            padding: EdgeInsets.only(bottom: cards.isNotEmpty ? 8.0 : 0),
            child: CitationCard(
              source: validSources[i],
              documentId: validDocumentIds[i],
              projectName: projectName,
            ),
          ),
        );
      }
    }
    // Fallback: Wenn es keine documentIds gibt, aber gültige Quellen
    else if (sources != null && sources.isNotEmpty) {
      final validOnlySources = sources
          .where((s) => !noDocumentValues.contains(s))
          .toList();

      for (final source in validOnlySources) {
         cards.add(
          Padding(
            padding: EdgeInsets.only(bottom: cards.isNotEmpty ? 8.0 : 0),
            child: CitationCard(
              source: source,
              documentId: null,
              projectName: projectName,
            ),
          ),
        );
      }
    }

    return cards;
  }

  /// Extrahiert den anzuzeigenden Text, falls es sich um JSON handelt
  String _extractDisplayText(String text) {
    try {
      // Prüfe ob der Text JSON ist
      final jsonData = json.decode(text);

      // Falls es ein JSON-Objekt ist, versuche das "answer" Feld zu extrahieren
      if (jsonData is Map<String, dynamic>) {
        if (jsonData.containsKey('answer')) {
          return jsonData['answer']?.toString() ?? text;
        }
        // Fallback auf 'response' falls 'answer' nicht vorhanden
        if (jsonData.containsKey('response')) {
          return jsonData['response']?.toString() ?? text;
        }
      }

      // Falls es kein erwartetes JSON-Format ist, gib den originalen Text zurück
      return text;
    } catch (e) {
      // Falls es kein JSON ist, gib den originalen Text zurück
      return text;
    }
  }

  List<TextSpan> _parseFormattedTextForBold(String text) {
    final List<TextSpan> spans = [];
    final RegExp boldPattern = RegExp(r'\*\*(.*?)\*\*');
    final RegExp italicPattern = RegExp(r'\*(.*?)\*');

    int lastIndex = 0;

    // Verarbeite fetten Text
    boldPattern.allMatches(text).forEach((match) {
      // Text vor dem Match
      if (match.start > lastIndex) {
        spans.add(TextSpan(text: text.substring(lastIndex, match.start)));
      }

      // Fetter Text
      spans.add(
        TextSpan(
          text: match.group(1),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      );

      lastIndex = match.end;
    });

    // Verarbeite kursiven Text (vereinfacht)
    if (lastIndex < text.length) {
      final remainingText = text.substring(lastIndex);
      italicPattern.allMatches(remainingText).forEach((match) {
        spans.add(
          TextSpan(
            text: match.group(1),
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
        );
      });

      // Falls kein kursiver Text, füge den Rest als normalen Text hinzu
      if (!italicPattern.hasMatch(remainingText)) {
        spans.add(TextSpan(text: remainingText));
      }
    }

    // Falls keine Formatierung gefunden wurde, gib den gesamten Text zurück
    if (spans.isEmpty) {
      spans.add(TextSpan(text: text));
    }

    return spans;
  }
}
