import 'package:flutter/material.dart';
import 'package:flutter_application_1/Fon.dart';


class SettingsScreen extends StatelessWidget {
  final bool darkMode;
  final Function(bool) onThemeChanged;
  const SettingsScreen({super.key, required this.darkMode, required this.onThemeChanged});

  @override
  Widget build(BuildContext context) {
    return MobileAnimatedBackground(
      backgroundColor: darkMode ? Colors.black : Colors.white,
      lineColor: darkMode ? Colors.white : Colors.black,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text('Настройки', style: TextStyle(color: darkMode ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
        ),
        body: ListView(
          children: [
            SwitchListTile(
              title: Text('Темная тема', style: TextStyle(color: darkMode ? Colors.white : Colors.black)),
              value: darkMode,
              onChanged: (val) => onThemeChanged(val),
              activeColor: darkMode ? Colors.blueAccent : Colors.blue,
            ),
            ListTile(
              title: Text('О приложении', style: TextStyle(color: darkMode ? Colors.white : Colors.black)),
              leading: Icon(Icons.info, color: darkMode ? Colors.blueAccent : Colors.blue),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('TopMessenger Lite'),
                    content: const Text('Локальная версия. Только Избранное и Заметки. Без интернета.'),
                    actions: [TextButton(onPressed: () => Navigator.pop(_), child: const Text('OK'))],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}