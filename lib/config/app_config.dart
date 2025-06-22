enum ChatMode {
  normal,
  deepSearch,
}

class AppConfig {
  static ChatMode _chatMode = ChatMode.normal;

  static ChatMode get chatMode => _chatMode;

  static void setChatMode(ChatMode mode) {
    _chatMode = mode;
  }

  static String get apiBaseUrl {
    switch (_chatMode) {
      case ChatMode.normal:
        return "http://localhost:9000";
      case ChatMode.deepSearch:
        return "http://localhost:8000";
      default:
        return "http://localhost:9000";
    }
  }

  static const String firebaseFilesPath = 'files';
}
