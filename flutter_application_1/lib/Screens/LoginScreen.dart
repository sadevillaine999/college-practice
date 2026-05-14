import 'package:flutter/material.dart';
import 'package:flutter_application_1/Api/api_service.dart';
import 'package:flutter_application_1/Screens/ChatScreen.dart';
import 'package:flutter_application_1/Screens/Fon.dart';
import 'package:flutter_application_1/Screens/RegistrationScreen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _isLoading = false;
  
  String _emailError = '';
  String _passwordError = '';
  bool _emailValid = false;
  bool _passwordValid = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }

  void _navigateToChatScreen() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => MobileChatScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);
          return SlideTransition(position: offsetAnimation, child: child);
        },
        transitionDuration: Duration(milliseconds: 500),
      ),
    );
  }

  void _navigateToRegistrationScreen() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => RegistrationScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);
          return SlideTransition(position: offsetAnimation, child: child);
        },
        transitionDuration: Duration(milliseconds: 500),
      ),
    );
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showError('Все поля должны быть заполнены!');
      return;
    }

    if (!_isValidEmail(email)) {
      _showError('Введите корректный email');
      return;
    }

    if (password.length < 6) {
      _showError('Пароль должен быть не менее 6 символов');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ApiService.login(
        email: email,
        password: password,
      );
      
      _navigateToChatScreen();
    } catch (e) {
      String errorMessage = e.toString();
      
      if (errorMessage.contains('Incorrect email or password') || 
          errorMessage.contains('401')) {
        errorMessage = 'Неверный email или пароль';
      } else if (errorMessage.contains('Network is unreachable') ||
                 errorMessage.contains('Failed host lookup')) {
        errorMessage = 'Нет подключения к серверу';
      } else if (errorMessage.contains('timeout')) {
        errorMessage = 'Сервер не отвечает';
      } else if (errorMessage.contains('email not found') ||
                 errorMessage.contains('not registered')) {
        errorMessage = 'Пользователь с таким email не найден';
      }
      
      _showError(errorMessage.replaceAll('Exception: ', ''));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: Duration(seconds: 3),
      ),
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          height: 60,
          margin: EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            border: Border.all(
              width: 2,
              color: _emailError.isNotEmpty
                  ? Colors.red
                  : _emailValid
                      ? Colors.green
                      : Colors.white,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _emailController,
              onChanged: (value) {
                final email = value.trim();
                if (email.isEmpty) {
                  setState(() {
                    _emailError = 'Введите email';
                    _emailValid = false;
                  });
                } else if (!_isValidEmail(email)) {
                  setState(() {
                    _emailError = 'Некорректный email';
                    _emailValid = false;
                  });
                } else {
                  setState(() {
                    _emailError = '';
                    _emailValid = true;
                  });
                }
              },
              style: TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                hintText: "Введите email",
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 20),
              ),
              cursorColor: Colors.white,
            ),
          ),
        ),
        if (_emailError.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(left: 8, top: 4),
            child: Text(
              _emailError,
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          height: 60,
          margin: EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            border: Border.all(
              width: 2,
              color: _passwordError.isNotEmpty
                  ? Colors.red
                  : _passwordValid
                      ? Colors.green
                      : Colors.white,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              onChanged: (value) {
                if (value.isEmpty) {
                  setState(() {
                    _passwordError = 'Введите пароль';
                    _passwordValid = false;
                  });
                } else if (value.length < 6) {
                  setState(() {
                    _passwordError = 'Минимум 6 символов';
                    _passwordValid = false;
                  });
                } else {
                  setState(() {
                    _passwordError = '';
                    _passwordValid = true;
                  });
                }
              },
              style: TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                hintText: "Введите пароль",
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 20),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ),
              cursorColor: Colors.white,
            ),
          ),
        ),
        if (_passwordError.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(left: 8, top: 4),
            child: Text(
              _passwordError,
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  bool _isFormValid() {
    return _emailValid && _passwordValid;
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: AnimatedSwitcher(
          duration: Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return ScaleTransition(scale: animation, child: child);
          },
          child: Text(
            "TopMessenger",
            key: ValueKey('appbar'),
            style: TextStyle(
                fontSize: isSmallScreen ? 18 : 20, 
                fontWeight: FontWeight.w700, 
                color: Colors.white),
          ),
        ),
        centerTitle: true,
      ),
      body: MobileAnimatedBackground(
        child: Center(
          child: SingleChildScrollView(
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: screenWidth * (isSmallScreen ? 0.95 : 0.9),
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 15 : 20, 
                      vertical: isSmallScreen ? 20 : 30
                    ),
                    margin: EdgeInsets.all(isSmallScreen ? 10 : 20),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      border: Border.all(width: 2, color: Colors.white),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedSwitcher(
                          duration: Duration(milliseconds: 300),
                          transitionBuilder: (child, animation) {
                            return FadeTransition(opacity: animation, child: child);
                          },
                          child: Text(
                            "Авторизация",
                            key: ValueKey('title'),
                            style: TextStyle(
                                fontSize: isSmallScreen ? 24 : 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 20 : 30),
                        _buildEmailField(),
                        SizedBox(height: isSmallScreen ? 15 : 20),
                        _buildPasswordField(),
                        SizedBox(height: isSmallScreen ? 20 : 30),
                        SizedBox(
                          width: double.infinity,
                          height: isSmallScreen ? 50 : 60,
                          child: ElevatedButton(
                            onPressed: _isLoading || !_isFormValid() ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isFormValid()
                                  ? Colors.white.withOpacity(0.3)
                                  : Colors.white.withOpacity(0.1),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.white, width: 2),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                                : Text(
                                    "Войти",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: isSmallScreen ? 16 : 20,
                                        fontWeight: FontWeight.w500),
                                  ),
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 15 : 20),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            "Пароль должен содержать минимум 6 символов",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: isSmallScreen ? 11 : 12),
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 15 : 20),
                        GestureDetector(
                          onTap: _navigateToRegistrationScreen,
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Еще нет аккаунта? ",
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: isSmallScreen ? 13 : 14),
                                ),
                                AnimatedContainer(
                                  duration: Duration(milliseconds: 200),
                                  decoration: BoxDecoration(
                                    border: Border(bottom: BorderSide(
                                      color: Colors.white,
                                      width: 1,
                                    )),
                                  ),
                                  child: Text(
                                    "Создать",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isSmallScreen ? 13 : 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}