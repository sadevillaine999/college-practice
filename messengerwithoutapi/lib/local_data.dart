class LocalData {
  static final LocalData _instance = LocalData._internal();
  factory LocalData() => _instance;
  LocalData._internal() {
    _initDefault();
  }

  Map<String, dynamic> currentUser = {
    'username': 'Гость',
    'email': 'guest@example.com',
    'bio': 'Привет!',
  };
  bool darkMode = true;
  final Map<String, List<String>> _messages = {
    'favorites': [
      '🌟 Добро пожаловать в Избранное!',
      'Здесь хранятся важные заметки и цитаты.'
    ],
    'notes': [
      '📝 Заметки – для быстрых записей.',
      'Список дел, идеи, напоминания.'
    ],
  };

  void _initDefault() {}

  void updateUserProfile({required String username, required String email, required String bio}) {
    currentUser['username'] = username;
    currentUser['email'] = email;
    currentUser['bio'] = bio;
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