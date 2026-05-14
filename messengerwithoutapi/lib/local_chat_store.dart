class LocalChatStore {
  static final LocalChatStore _instance = LocalChatStore._internal();
  factory LocalChatStore() => _instance;
  LocalChatStore._internal() {
    _initDefaultMessages();
  }

  final Map<String, List<String>> _messages = {};

  void _initDefaultMessages() {
    _messages['favorites'] = [
      '🌟 Добро пожаловать в Избранное! Здесь хранятся важные заметки.',
      'Любимые цитаты, идеи, ссылки – всё, что дорого сердцу.'
    ];
    _messages['notes'] = [
      '📌 Заметки – место для быстрых записей.',
      'Напоминания, списки дел, идеи на будущее.'
    ];
  }

  List<String> getMessages(String chatId) {
    return _messages[chatId] ?? [];
  }

  void addMessage(String chatId, String text) {
    _messages.putIfAbsent(chatId, () => []).add(text);
  }

  String? getLastMessage(String chatId) {
    final msgs = _messages[chatId];
    if (msgs == null || msgs.isEmpty) return null;
    return msgs.last;
  }
}