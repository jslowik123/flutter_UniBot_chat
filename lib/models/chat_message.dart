class ChatMessage {
  final String text;
  final bool isUserMessage;
  final DateTime timestamp;
  final String? source;
  final String? documentId;
  final bool isTyping;

  ChatMessage({
    required this.text,
    required this.isUserMessage,
    DateTime? timestamp,
    this.source,
    this.documentId,
    this.isTyping = false,
  }) : timestamp = timestamp ?? DateTime.now();

  // Copy constructor
  ChatMessage copyWith({
    String? text,
    bool? isUserMessage,
    DateTime? timestamp,
    String? source,
    String? documentId,
    bool? isTyping,
  }) {
    return ChatMessage(
      text: text ?? this.text,
      isUserMessage: isUserMessage ?? this.isUserMessage,
      timestamp: timestamp ?? this.timestamp,
      source: source ?? this.source,
      documentId: documentId ?? this.documentId,
      isTyping: isTyping ?? this.isTyping,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isUserMessage': isUserMessage,
      'timestamp': timestamp.toIso8601String(),
      'source': source,
      'documentId': documentId,
      'isTyping': isTyping,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['text'] as String,
      isUserMessage: json['isUserMessage'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
      source: json['source'] as String?,
      documentId: json['documentId'] as String?,
      isTyping: json['isTyping'] as bool? ?? false,
    );
  }
}
