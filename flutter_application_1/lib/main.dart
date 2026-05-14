import 'package:flutter/material.dart';
import 'package:flutter_application_1/Screens/LoginScreen.dart';
import 'package:flutter_application_1/Screens/RegistrationScreen.dart';
import 'package:flutter_application_1/Screens/ChatScreen.dart';

void main() {
  runApp(TopMessenger());
}

class TopMessenger extends StatefulWidget {
  const TopMessenger({super.key});

  @override
  State<TopMessenger> createState() => _TopMessengerState();
}

class _TopMessengerState extends State<TopMessenger> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegistrationScreen(),
        '/chat': (context) => MobileChatScreen(),
      },
    );
  }
}