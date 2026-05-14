import 'package:flutter/material.dart';
import 'package:flutter_application_1/Api/api_service.dart';
import 'package:flutter_application_1/Screens/ChatScreen.dart';
import 'package:flutter_application_1/Screens/Fon.dart';
import 'package:flutter_application_1/Screens/LoginScreen.dart';


class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _emailValid = false;
  bool _usernameValid = false;
  bool _passwordValid = false;
  bool _emailChecking = false;
  String _emailError = '';
  String _usernameError = '';
  String _passwordError = '';

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

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

  void _navigateToLoginScreen() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => LoginScreen(),
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

  Future<void> _register() async {
    final email = _emailController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (email.isEmpty ||
        username.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _showError('Все поля должны быть заполнены');
      return;
    }

    if (password != confirmPassword) {
      _showError('Пароли не совпадают');
      return;
    }

    if (!_isValidEmail(email)) {
      _showError('Введите корректный email');
      return;
    }

    if (username.length < 3) {
      _showError('Логин должен быть не менее 3 символов');
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
      await ApiService.register(
        email: email,
        username: username,
        password: password,
      );

      await ApiService.login(
        email: email,
        password: password,
      );

      _navigateToChatScreen();
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.contains('email already exists') ||
          errorMessage.contains('email')) {
        errorMessage = 'Этот email уже зарегистрирован';
      } else if (errorMessage.contains('username already exists') ||
          errorMessage.contains('username')) {
        errorMessage = 'Этот логин уже занят';
      } else if (errorMessage.contains('Invalid email format')) {
        errorMessage = 'Некорректный формат email';
      } else if (errorMessage.contains('Password too short')) {
        errorMessage = 'Пароль слишком короткий';
      } else if (errorMessage.contains('Connection refused') ||
          errorMessage.contains('Network is unreachable')) {
        errorMessage = 'Нет подключения к серверу';
      } else if (errorMessage.contains('timeout')) {
        errorMessage = 'Сервер не отвежает';
      }
      
      _showError(errorMessage.replaceAll('Exception: ', ''));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email);
  }

  bool _isFormValid() {
    return _emailValid && _usernameValid && _passwordValid;
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
                    _emailError = 'Некорректный формат email';
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

  Widget _buildUsernameField() {
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
              color: _usernameError.isNotEmpty
                  ? Colors.red
                  : _usernameValid
                      ? Colors.green
                      : Colors.white,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _usernameController,
              onChanged: (value) {
                final username = value.trim();
                if (username.isEmpty) {
                  setState(() {
                    _usernameError = 'Введите логин';
                    _usernameValid = false;
                  });
                } else if (username.length < 3) {
                  setState(() {
                    _usernameError = 'Минимум 3 символа';
                    _usernameValid = false;
                  });
                } else {
                  setState(() {
                    _usernameError = '';
                    _usernameValid = true;
                  });
                }
              },
              style: TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                hintText: "Введите логин",
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 20),
              ),
              cursorColor: Colors.white,
            ),
          ),
        ),
        if (_usernameError.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(left: 8, top: 4),
            child: Text(
              _usernameError,
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
                final password = value;
                final confirmPassword = _confirmPasswordController.text;

                if (password.isEmpty) {
                  setState(() {
                    _passwordError = 'Введите пароль';
                    _passwordValid = false;
                  });
                } else if (password.length < 6) {
                  setState(() {
                    _passwordError = 'Минимум 6 символов';
                    _passwordValid = false;
                  });
                } else if (password != confirmPassword) {
                  setState(() {
                    _passwordError = 'Пароли не совпадают';
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
                hintStyle:
                    TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 20),
                suffixIcon: IconButton(
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
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

  Widget _buildConfirmPasswordField() {
    return Container(
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
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          onChanged: (value) {
            final password = _passwordController.text;
            final confirmPassword = value;

            if (confirmPassword.isEmpty) {
              setState(() {
                _passwordError = 'Подтвердите пароль';
                _passwordValid = false;
              });
            } else if (password != confirmPassword) {
              setState(() {
                _passwordError = 'Пароли не совпадают';
                _passwordValid = false;
              });
            } else if (password.length < 6) {
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
            hintText: "Подтвердите пароль",
            hintStyle:
                TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 20),
            suffixIcon: IconButton(
              onPressed: () => setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword),
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_off
                    : Icons.visibility,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ),
          cursorColor: Colors.white,
        ),
      ),
    );
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
    final screenHeight = MediaQuery.of(context).size.height;
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
                            "Регистрация",
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
                        _buildUsernameField(),
                        SizedBox(height: isSmallScreen ? 15 : 20),
                        _buildPasswordField(),
                        SizedBox(height: isSmallScreen ? 15 : 20),
                        _buildConfirmPasswordField(),
                        SizedBox(height: isSmallScreen ? 20 : 30),
                        SizedBox(
                          width: double.infinity,
                          height: isSmallScreen ? 50 : 60,
                          child: ElevatedButton(
                            onPressed: _isLoading || !_isFormValid()
                                ? null
                                : _register,
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
                                ? CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2)
                                : Text(
                                    "Зарегистрироваться",
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
                          onTap: _navigateToLoginScreen,
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Уже есть аккаунт? ",
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
                                    "Войти",
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