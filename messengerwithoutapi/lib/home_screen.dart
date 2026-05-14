import 'package:flutter/material.dart';
import 'package:flutter_application_1/Fon.dart';
import 'package:flutter_application_1/local_data.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late bool _darkMode;

  @override
  void initState() {
    super.initState();
    _darkMode = LocalData().darkMode;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MobileAnimatedBackground(
      backgroundColor: _darkMode ? Colors.black : Colors.white,
      lineColor: _darkMode ? Colors.white : Colors.black,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            _buildChatsList(),
            _buildProfileScreen(),
            _buildSettingsScreen(),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          backgroundColor: _darkMode ? const Color(0xFF121212) : Colors.white,
          selectedItemColor: _darkMode ? Colors.blueAccent : Colors.blue,
          unselectedItemColor: _darkMode ? Colors.white70 : Colors.black54,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Чаты'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Профиль'),
            BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Настройки'),
          ],
        ),
      ),
    );
  }

  Widget _buildChatsList() {
    return Column(
      children: [
        AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text('Мои чаты', style: TextStyle(color: _darkMode ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildChatCard('favorites', '⭐ Избранное'),
                const SizedBox(height: 16),
                _buildChatCard('notes', '📝 Заметки'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChatCard(String chatId, String title) {
    final lastMessage = LocalData().getLastMessage(chatId);
    return Card(
      color: _darkMode ? Colors.white10 : Colors.grey[50],
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _darkMode ? Colors.blueAccent : Colors.blue[100],
          child: Text(title[0], style: TextStyle(color: _darkMode ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
        ),
        title: Text(title, style: TextStyle(color: _darkMode ? Colors.white : Colors.black, fontWeight: FontWeight.w500)),
        subtitle: Text(lastMessage ?? 'Нет сообщений', style: TextStyle(color: _darkMode ? Colors.white70 : Colors.black54)),
        trailing: Icon(Icons.chevron_right, color: _darkMode ? Colors.white70 : Colors.black54),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(chatId: chatId, title: title, darkMode: _darkMode)));
        },
      ),
    );
  }

  Widget _buildProfileScreen() {
    return ProfileScreen(darkMode: _darkMode, onUpdate: () => setState(() {}));
  }

  Widget _buildSettingsScreen() {
    return SettingsScreen(
      darkMode: _darkMode,
      onThemeChanged: (val) {
        setState(() {
          _darkMode = val;
          LocalData().darkMode = val;
        });
      },
    );
  }
}