class ChatMessage {
  final String text;
  final bool isUserMessage;
  final bool isStreaming;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUserMessage,
    this.isStreaming = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  // Copy constructor for updating streaming messages
  ChatMessage copyWith({
    String? text,
    bool? isUserMessage,
    bool? isStreaming,
    DateTime? timestamp,
  }) {
    return ChatMessage(
      text: text ?? this.text,
      isUserMessage: isUserMessage ?? this.isUserMessage,
      isStreaming: isStreaming ?? this.isStreaming,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  // Convert to/from JSON if needed for persistence
  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isUserMessage': isUserMessage,
      'isStreaming': isStreaming,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['text'] as String,
      isUserMessage: json['isUserMessage'] as bool,
      isStreaming: json['isStreaming'] as bool? ?? false,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}
