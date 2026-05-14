import 'package:flutter/material.dart';
import 'package:flutter_application_1/Fon.dart';
import 'package:flutter_application_1/local_data.dart';


class ProfileScreen extends StatefulWidget {
  final bool darkMode;
  final VoidCallback onUpdate;
  const ProfileScreen({super.key, required this.darkMode, required this.onUpdate});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final user = LocalData().currentUser;
    _usernameController.text = user['username'];
    _emailController.text = user['email'];
    _bioController.text = user['bio'];
  }

  void _saveProfile() {
    LocalData().updateUserProfile(
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      bio: _bioController.text.trim(),
    );
    widget.onUpdate();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Профиль обновлен')));
  }

  @override
  Widget build(BuildContext context) {
    return MobileAnimatedBackground(
      backgroundColor: widget.darkMode ? Colors.black : Colors.white,
      lineColor: widget.darkMode ? Colors.white : Colors.black,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text('Профиль', style: TextStyle(color: widget.darkMode ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: widget.darkMode ? Colors.blueAccent : Colors.blue,
                child: Text(LocalData().currentUser['username'][0].toUpperCase(), style: const TextStyle(fontSize: 40, color: Colors.white)),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _usernameController,
                style: TextStyle(color: widget.darkMode ? Colors.white : Colors.black),
                decoration: InputDecoration(labelText: 'Имя пользователя', labelStyle: TextStyle(color: widget.darkMode ? Colors.white70 : Colors.black54)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                style: TextStyle(color: widget.darkMode ? Colors.white : Colors.black),
                decoration: InputDecoration(labelText: 'Email', labelStyle: TextStyle(color: widget.darkMode ? Colors.white70 : Colors.black54)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _bioController,
                maxLines: 3,
                style: TextStyle(color: widget.darkMode ? Colors.white : Colors.black),
                decoration: InputDecoration(labelText: 'О себе', labelStyle: TextStyle(color: widget.darkMode ? Colors.white70 : Colors.black54)),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(backgroundColor: widget.darkMode ? Colors.blueAccent : Colors.blue, minimumSize: const Size(double.infinity, 50)),
                child: const Text('Сохранить'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}