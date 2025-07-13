class ChatMessage {
  final String text;
  final bool isUserMessage;
  final DateTime timestamp;
  final List<String>? sources;
  final List<String>? documentIds;
  final List<String>? pages;
  final bool isTyping;

  // Getter für die Abwärtskompatibilität
  String? get source => (sources?.isNotEmpty ?? false) ? sources!.first : null;

  ChatMessage({
    required this.text,
    required this.isUserMessage,
    DateTime? timestamp,
    this.sources,
    this.documentIds,
    this.pages,
    this.isTyping = false,
  }) : timestamp = timestamp ?? DateTime.now();

  // Copy constructor
  ChatMessage copyWith({
    String? text,
    bool? isUserMessage,
    DateTime? timestamp,
    List<String>? sources,
    List<String>? documentIds,
    List<String>? pages,
    bool? isTyping,
  }) {
    return ChatMessage(
      text: text ?? this.text,
      isUserMessage: isUserMessage ?? this.isUserMessage,
      timestamp: timestamp ?? this.timestamp,
      sources: sources ?? this.sources,
      documentIds: documentIds ?? this.documentIds,
      pages: pages ?? this.pages,
      isTyping: isTyping ?? this.isTyping,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isUserMessage': isUserMessage,
      'timestamp': timestamp.toIso8601String(),
      'sources': sources,
      'documentIds': documentIds,
      'pages': pages,
      'isTyping': isTyping,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    // Abwärtskompatibilität: 'source' lesen und in 'sources' umwandeln
    List<String>? sources;
    if (json.containsKey('sources')) {
      sources = json['sources'] != null
          ? List<String>.from(json['sources'] as List)
          : null;
    } else if (json.containsKey('source')) {
      final source = json['source'] as String?;
      if (source != null) {
        sources = [source];
      }
    }

    return ChatMessage(
      text: json['text'] as String,
      isUserMessage: json['isUserMessage'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
      sources: sources,
      documentIds:
          json['documentIds'] != null
              ? List<String>.from(json['documentIds'] as List)
              : null,
      pages:
          json['pages'] != null
              ? List<String>.from(json['pages'] as List)
              : null,
      isTyping: json['isTyping'] as bool? ?? false,
    );
  }
}
