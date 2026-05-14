import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_application_1/Api/api_service.dart';
import 'package:flutter_application_1/Api/websocket_service.dart';
import 'package:flutter_application_1/Screens/LoginScreen.dart';
import 'package:flutter_application_1/Screens/Fon.dart';

class MobileChatScreen extends StatefulWidget {
  const MobileChatScreen({super.key});

  @override
  State<MobileChatScreen> createState() => _MobileChatScreenState();
}

class _MobileChatScreenState extends State<MobileChatScreen> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  bool _showProfileMenu = false;
  bool _showAddContactMenu = false;
  bool _showSearchMenu = false;
  bool _showChangePasswordMenu = false;
  bool _showStatusMenu = false;
  
  List<dynamic> _contacts = [];
  Map<String, dynamic>? _currentUser;
  
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _addContactController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  bool _isLoadingContacts = true;
  bool _isLoadingSearch = false;
  bool _isUpdatingProfile = false;
  bool _isChangingPassword = false;
  bool _isUploadingAvatar = false;
  
  bool _notificationsEnabled = true;
  bool _darkMode = true;
  bool _showOnlineStatus = true;
  String _status = "Доступен";
  File? _selectedAvatar;
  final List<String> _statusOptions = ["Доступен", "Не беспокоить", "Офлайн", "Встреча", "В отпуске"];
  final List<String> _statusIcons = ["🟢", "🔴", "⚫", "👥", "🏝️"];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCurrentUser();
    _loadContacts();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updateOnlineStatus(true);
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _updateOnlineStatus(false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _updateOnlineStatus(bool isOnline) async {
    try {
      await ApiService.updateOnlineStatus(isOnline);
    } catch (e) {
      print('Error updating online status: $e');
    }
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await ApiService.getCurrentUserProfile();
      if (mounted) {
        setState(() {
          _currentUser = user;
          _usernameController.text = user['username'] ?? '';
          _emailController.text = user['email'] ?? '';
          _bioController.text = user['bio'] ?? '';
          _status = user['status'] ?? 'Доступен';
        });
      }
    } catch (e) {
      if (mounted) {
        _handleAuthException(e);
      }
    }
  }

  Future<void> _loadContacts() async {
    if (mounted) {
      setState(() { _isLoadingContacts = true; });
    }

    try {
      final contacts = await ApiService.getContacts();
      if (mounted) {
        setState(() { _contacts = contacts; });
      }
    } catch (e) {
      if (mounted) {
        _handleAuthException(e);
        _showSnackbar('Ошибка загрузки контактов', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() { _isLoadingContacts = false; });
      }
    }
  }

  Future<void> _addContact() async {
    final email = _addContactController.text.trim();
    if (email.isEmpty) {
      _showSnackbar('Введите email', isError: true);
      return;
    }
    final currentEmail = (_currentUser?['email'] ?? '').toString().toLowerCase();
    if (currentEmail.isNotEmpty && email.toLowerCase() == currentEmail) {
      _showSnackbar('Вы не можете добавить себя в контакты', isError: true);
      return;
    }

    try {
      await ApiService.addContact(email);
      _showSnackbar('Контакт добавлен');
      _addContactController.clear();
      _loadContacts();
      if (mounted) {
        setState(() { _showAddContactMenu = false; });
      }
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('self') || msg.contains('yourself')) {
        _showSnackbar('Вы не можете добавить себя в контакты', isError: true);
      } else if (msg.contains('404') || msg.contains('not found')) {
        _showSnackbar('Пользователь с таким email не найден', isError: true);
      } else {
        _handleAuthException(e);
        _showSnackbar('Ошибка добавления', isError: true);
      }
    }
  }

  Future<void> _searchUsers() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    if (mounted) {
      setState(() { _isLoadingSearch = true; });
    }

    try {
      final results = await ApiService.searchUsers(query);
      if (mounted) {
        _showSearchResults(results);
      }
    } catch (e) {
      if (mounted) {
        _handleAuthException(e);
        _showSnackbar('Ошибка поиска', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() { _isLoadingSearch = false; });
      }
    }
  }

  Future<void> _updateProfile() async {
    if (_bioController.text.length > 256) {
      _showSnackbar('О себе не должно превышать 256 символов', isError: true);
      return;
    }

    if (mounted) {
      setState(() { _isUpdatingProfile = true; });
    }

    try {
      await ApiService.updateProfile(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        bio: _bioController.text.trim(),
        status: _status,
      );
      _showSnackbar('Профиль обновлен');
      _loadCurrentUser();
    } catch (e) {
      _showSnackbar('Ошибка обновления', isError: true);
    } finally {
      if (mounted) {
        setState(() { 
          _isUpdatingProfile = false;
          _showProfileMenu = false;
        });
      }
    }
  }

  Future<void> _changePassword() async {
    final currentPassword = _currentPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      _showSnackbar('Все поля должны быть заполнены', isError: true);
      return;
    }

    if (newPassword.length < 6) {
      _showSnackbar('Новый пароль должен содержать минимум 6 символов', isError: true);
      return;
    }

    if (newPassword != confirmPassword) {
      _showSnackbar('Пароли не совпадают', isError: true);
      return;
    }

    if (mounted) {
      setState(() { _isChangingPassword = true; });
    }

    try {
      await ApiService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      _showSnackbar('Пароль успешно изменен');
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      if (mounted) {
        setState(() { _showChangePasswordMenu = false; });
      }
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('current password') || msg.contains('неверный')) {
        _showSnackbar('Текущий пароль неверен', isError: true);
      } else {
        _showSnackbar('Ошибка изменения пароля', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() { _isChangingPassword = false; });
      }
    }
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      if (mounted) {
        setState(() {
          _selectedAvatar = File(pickedFile.path);
        });
      }
      await _uploadAvatar();
    }
  }

  Future<void> _uploadAvatar() async {
    if (_selectedAvatar == null) return;

    if (mounted) {
      setState(() { _isUploadingAvatar = true; });
    }

    try {
      final imageBytes = await _selectedAvatar!.readAsBytes();
      await ApiService.uploadAvatar(imageBytes, _selectedAvatar!.path.split('/').last);
      _showSnackbar('Аватар обновлен');
      _loadCurrentUser();
    } catch (e) {
      _showSnackbar('Ошибка загрузки аватара', isError: true);
    } finally {
      if (mounted) {
        setState(() { 
          _isUploadingAvatar = false;
          _selectedAvatar = null;
        });
      }
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? Icons.error : Icons.info, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError 
            ? Colors.red.withOpacity(0.9)
            : (_darkMode ? Colors.green.withOpacity(0.9) : Colors.blue.withOpacity(0.9)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showNotification(String title, String body) {
    if (!_notificationsEnabled) return;
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _darkMode ? Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.notifications_active, color: _darkMode ? Colors.blueAccent : Colors.blue),
            SizedBox(width: 12),
            Text(title, style: TextStyle(
              color: _darkMode ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            )),
          ],
        ),
        content: Text(body, style: TextStyle(
          color: _darkMode ? Colors.white70 : Colors.black87,
          fontSize: 16,
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(
              color: _darkMode ? Colors.blueAccent : Colors.blue,
            )),
          ),
        ],
      ),
    );
  }

  void _handleAuthException(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('401') || msg.contains('403') || msg.contains('validate credentials')) {
      ApiService.logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
      _showSnackbar('Сессия истекла, войдите снова', isError: true);
    }
  }

  void _closeAllMenus() {
    if (!mounted) return;
    setState(() {
      _showProfileMenu = false;
      _showAddContactMenu = false;
      _showSearchMenu = false;
      _showChangePasswordMenu = false;
      _showStatusMenu = false;
    });
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) {
        _closeAllMenus();
        if (mounted) {
          setState(() { _selectedIndex = index; });
        }
      },
      backgroundColor: _darkMode ? Color(0xFF121212) : Colors.white,
      selectedItemColor: _darkMode ? Colors.blueAccent : Colors.blue,
      unselectedItemColor: _darkMode ? Colors.white70 : Colors.black54,
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
      elevation: 8,
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.chat_bubble_outline),
          activeIcon: Icon(Icons.chat_bubble),
          label: 'Чаты',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.contacts_outlined),
          activeIcon: Icon(Icons.contacts),
          label: 'Контакты',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings_outlined),
          activeIcon: Icon(Icons.settings),
          label: 'Настройки',
        ),
      ],
    );
  }

  Widget _buildProfileMenu() {
    return AnimatedPositioned(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      left: 0,
      right: 0,
      top: _showProfileMenu ? 0 : MediaQuery.of(context).size.height,
      bottom: 0,
      child: GestureDetector(
        onTap: () => setState(() { _showProfileMenu = false; }),
        child: Container(
          color: Colors.black.withOpacity(0.5),
          child: Center(
            child: SingleChildScrollView(
              child: Container(
                width: 400,
                padding: EdgeInsets.all(20),
                margin: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _darkMode ? Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Редактировать профиль', style: TextStyle(
                          color: _darkMode ? Colors.white : Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        )),
                        IconButton(
                          icon: Icon(Icons.close, color: _darkMode ? Colors.white70 : Colors.black54),
                          onPressed: () => setState(() { _showProfileMenu = false; }),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: _darkMode ? Colors.white24 : Colors.grey[200],
                          backgroundImage: _selectedAvatar != null 
                              ? FileImage(_selectedAvatar!)
                              : (_currentUser?['avatar_url'] != null 
                                  ? NetworkImage(_currentUser!['avatar_url']) 
                                  : null) as ImageProvider?,
                          child: _selectedAvatar == null && _currentUser?['avatar_url'] == null
                              ? Icon(Icons.person, size: 50, color: _darkMode ? Colors.white70 : Colors.black54)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickAvatar,
                            child: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _darkMode ? Colors.blueAccent : Colors.blue,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: _isUploadingAvatar
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Icon(Icons.edit, size: 20, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 20),
                    TextField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: 'Имя пользователя',
                        labelStyle: TextStyle(color: _darkMode ? Colors.white70 : Colors.black54),
                        filled: true,
                        fillColor: _darkMode ? Colors.white10 : Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: Icon(Icons.person, color: _darkMode ? Colors.white70 : Colors.black54),
                      ),
                      style: TextStyle(color: _darkMode ? Colors.white : Colors.black),
                    ),
                    SizedBox(height: 15),
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: TextStyle(color: _darkMode ? Colors.white70 : Colors.black54),
                        filled: true,
                        fillColor: _darkMode ? Colors.white10 : Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: Icon(Icons.email, color: _darkMode ? Colors.white70 : Colors.black54),
                      ),
                      style: TextStyle(color: _darkMode ? Colors.white : Colors.black),
                    ),
                    SizedBox(height: 15),
                    TextField(
                      controller: _bioController,
                      maxLines: 3,
                      maxLength: 256,
                      decoration: InputDecoration(
                        labelText: 'О себе',
                        labelStyle: TextStyle(color: _darkMode ? Colors.white70 : Colors.black54),
                        filled: true,
                        fillColor: _darkMode ? Colors.white10 : Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: Icon(Icons.info, color: _darkMode ? Colors.white70 : Colors.black54),
                        counterText: '${_bioController.text.length}/256',
                        counterStyle: TextStyle(
                          color: _bioController.text.length > 256 ? Colors.red : (_darkMode ? Colors.white70 : Colors.black54),
                        ),
                      ),
                      style: TextStyle(color: _darkMode ? Colors.white : Colors.black),
                      onChanged: (value) => setState(() {}),
                    ),
                    SizedBox(height: 15),
                    GestureDetector(
                      onTap: () => setState(() { _showStatusMenu = true; }),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: _darkMode ? Colors.white10 : Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.flag, color: _darkMode ? Colors.white70 : Colors.black54),
                            SizedBox(width: 12),
                            Text('Статус', style: TextStyle(
                              color: _darkMode ? Colors.white70 : Colors.black54,
                            )),
                            Spacer(),
                            Text(_status, style: TextStyle(
                              color: _darkMode ? Colors.white : Colors.black,
                              fontWeight: FontWeight.w500,
                            )),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_drop_down, color: _darkMode ? Colors.white70 : Colors.black54),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isUpdatingProfile ? null : _updateProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _darkMode ? Colors.blueAccent : Colors.blue,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isUpdatingProfile 
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text('Сохранить изменения'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusMenu() {
    return AnimatedPositioned(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      left: 0,
      right: 0,
      top: _showStatusMenu ? 0 : MediaQuery.of(context).size.height,
      bottom: 0,
      child: GestureDetector(
        onTap: () => setState(() { _showStatusMenu = false; }),
        child: Container(
          color: Colors.black.withOpacity(0.5),
          child: Center(
            child: Container(
              width: 300,
              padding: EdgeInsets.all(20),
              margin: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _darkMode ? Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Выберите статус', style: TextStyle(
                    color: _darkMode ? Colors.white : Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  )),
                  SizedBox(height: 20),
                  ..._statusOptions.asMap().entries.map((entry) {
                    final index = entry.key;
                    final status = entry.value;
                    return ListTile(
                      leading: Text(_statusIcons[index], style: TextStyle(fontSize: 20)),
                      title: Text(status, style: TextStyle(
                        color: _darkMode ? Colors.white : Colors.black,
                      )),
                      trailing: _status == status 
                          ? Icon(Icons.check, color: _darkMode ? Colors.blueAccent : Colors.blue)
                          : null,
                      onTap: () {
                        setState(() {
                          _status = status;
                          _showStatusMenu = false;
                        });
                        _updateProfile();
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChangePasswordMenu() {
    return AnimatedPositioned(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      left: 0,
      right: 0,
      top: _showChangePasswordMenu ? 0 : MediaQuery.of(context).size.height,
      bottom: 0,
      child: GestureDetector(
        onTap: () => setState(() { _showChangePasswordMenu = false; }),
        child: Container(
          color: Colors.black.withOpacity(0.5),
          child: Center(
            child: SingleChildScrollView(
              child: Container(
                width: 400,
                padding: EdgeInsets.all(20),
                margin: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _darkMode ? Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Изменить пароль', style: TextStyle(
                          color: _darkMode ? Colors.white : Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        )),
                        IconButton(
                          icon: Icon(Icons.close, color: _darkMode ? Colors.white70 : Colors.black54),
                          onPressed: () => setState(() { _showChangePasswordMenu = false; }),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    TextField(
                      controller: _currentPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Текущий пароль',
                        labelStyle: TextStyle(color: _darkMode ? Colors.white70 : Colors.black54),
                        filled: true,
                        fillColor: _darkMode ? Colors.white10 : Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: Icon(Icons.lock, color: _darkMode ? Colors.white70 : Colors.black54),
                      ),
                      style: TextStyle(color: _darkMode ? Colors.white : Colors.black),
                    ),
                    SizedBox(height: 15),
                    TextField(
                      controller: _newPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Новый пароль',
                        labelStyle: TextStyle(color: _darkMode ? Colors.white70 : Colors.black54),
                        filled: true,
                        fillColor: _darkMode ? Colors.white10 : Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: Icon(Icons.lock_outline, color: _darkMode ? Colors.white70 : Colors.black54),
                      ),
                      style: TextStyle(color: _darkMode ? Colors.white : Colors.black),
                    ),
                    SizedBox(height: 15),
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Подтвердите пароль',
                        labelStyle: TextStyle(color: _darkMode ? Colors.white70 : Colors.black54),
                        filled: true,
                        fillColor: _darkMode ? Colors.white10 : Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: Icon(Icons.lock_reset, color: _darkMode ? Colors.white70 : Colors.black54),
                      ),
                      style: TextStyle(color: _darkMode ? Colors.white : Colors.black),
                    ),
                    SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isChangingPassword ? null : _changePassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _darkMode ? Colors.blueAccent : Colors.blue,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isChangingPassword 
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text('Изменить пароль'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddContactMenu() {
    return AnimatedPositioned(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      left: 0,
      right: 0,
      top: _showAddContactMenu ? 0 : MediaQuery.of(context).size.height,
      bottom: 0,
      child: GestureDetector(
        onTap: () => setState(() { _showAddContactMenu = false; }),
        child: Container(
          color: Colors.black.withOpacity(0.5),
          child: Center(
            child: Container(
              width: 300,
              padding: EdgeInsets.all(20),
              margin: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _darkMode ? Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Добавить контакт', style: TextStyle(
                    color: _darkMode ? Colors.white : Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  )),
                  SizedBox(height: 20),
                  TextField(
                    controller: _addContactController,
                    decoration: InputDecoration(
                      labelText: 'Email пользователя',
                      labelStyle: TextStyle(color: _darkMode ? Colors.white70 : Colors.black54),
                      filled: true,
                      fillColor: _darkMode ? Colors.white10 : Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: Icon(Icons.email, color: _darkMode ? Colors.white70 : Colors.black54),
                    ),
                    style: TextStyle(color: _darkMode ? Colors.white : Colors.black),
                  ),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _addContact,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _darkMode ? Colors.blueAccent : Colors.blue,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text('Добавить'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showSearchResults(List<dynamic> results) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: _darkMode ? Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          width: double.maxFinite,
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Результаты поиска',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _darkMode ? Colors.white : Colors.black,
                ),
              ),
              SizedBox(height: 16),
              Container(
                height: 300,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final user = results[index];
                    return Container(
                      margin: EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: _darkMode ? Colors.white10 : Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _darkMode ? Colors.blueAccent : Colors.blue[100],
                          child: Text(
                            (user['username']?[0] ?? 'U').toUpperCase(),
                            style: TextStyle(
                              color: _darkMode ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          user['username'] ?? '',
                          style: TextStyle(
                            color: _darkMode ? Colors.white : Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          user['email'] ?? '',
                          style: TextStyle(
                            color: _darkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.person_add, 
                            color: _darkMode ? Colors.blueAccent : Colors.blue),
                          onPressed: () async {
                            try {
                              await ApiService.addContact(user['email']);
                              _showSnackbar('Контакт добавлен');
                              _loadContacts();
                              Navigator.pop(context);
                            } catch (e) {
                              _showSnackbar('Ошибка добавления', isError: true);
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _darkMode ? Colors.blueAccent : Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('Закрыть'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchMenu() {
    return AnimatedPositioned(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      left: 0,
      right: 0,
      top: _showSearchMenu ? 0 : MediaQuery.of(context).size.height,
      bottom: 0,
      child: Container(
        color: _darkMode ? Color(0xFF121212) : Colors.white,
        child: Column(
          children: [
            AppBar(
              backgroundColor: _darkMode ? Color(0xFF1E1E1E) : Colors.white,
              elevation: 0,
              title: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Поиск пользователей...',
                  hintStyle: TextStyle(color: _darkMode ? Colors.white70 : Colors.black54),
                  border: InputBorder.none,
                  suffixIcon: IconButton(
                    icon: Icon(Icons.search, color: _darkMode ? Colors.white70 : Colors.black54),
                    onPressed: _searchUsers,
                  ),
                ),
                style: TextStyle(color: _darkMode ? Colors.white : Colors.black),
                onSubmitted: (_) => _searchUsers(),
              ),
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: _darkMode ? Colors.white : Colors.black),
                onPressed: () => setState(() { _showSearchMenu = false; }),
              ),
              actions: [
                if (_isLoadingSearch)
                  Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: CircularProgressIndicator(color: _darkMode ? Colors.white : Colors.black),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatsScreen() {
    return MobileAnimatedBackground(
      backgroundColor: _darkMode ? Colors.black : Colors.white,
      lineColor: _darkMode ? Colors.white : Colors.black,
      child: Column(
        children: [
          AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text('Мои чаты', style: TextStyle(
              color: _darkMode ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            )),
            actions: [
              IconButton(
                onPressed: () => setState(() { _showSearchMenu = true; }),
                icon: Icon(Icons.search, color: _darkMode ? Colors.white : Colors.black),
              ),
            ],
          ),
          Expanded(
            child: _isLoadingContacts
                ? Center(child: CircularProgressIndicator(color: _darkMode ? Colors.white : Colors.black))
                : _contacts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 80,
                              color: _darkMode ? Colors.white70 : Colors.black54,
                            ),
                            SizedBox(height: 20),
                            Text(
                              'Контакты отсутствуют',
                              style: TextStyle(
                                color: _darkMode ? Colors.white70 : Colors.black54,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Добавьте контакты для общения',
                              style: TextStyle(
                                color: _darkMode ? Colors.white60 : Colors.black38,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _contacts.length,
                        itemBuilder: (context, index) {
                          final contact = _contacts[index];
                          final contactUser = contact['contact'] ?? contact;
                          final lastMessage = contact['last_message'] ?? '';
                          
                          return Container(
                            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: Card(
                              color: _darkMode ? Colors.white10 : Colors.grey[50],
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _darkMode ? Colors.blueAccent : Colors.blue[100],
                                  child: Text(
                                    (contactUser['username']?[0] ?? 'U').toUpperCase(),
                                    style: TextStyle(
                                      color: _darkMode ? Colors.white : Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Text(
                                      contactUser['username'] ?? '',
                                      style: TextStyle(
                                        color: _darkMode ? Colors.white : Colors.black,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'онлайн',
                                      style: TextStyle(
                                        color: _darkMode ? Colors.greenAccent : Colors.green,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Text(
                                  lastMessage.isNotEmpty ? lastMessage : 'Нет сообщений',
                                  style: TextStyle(
                                    color: _darkMode ? Colors.white70 : Colors.black54,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: Icon(
                                  Icons.chevron_right,
                                  color: _darkMode ? Colors.white70 : Colors.black54,
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => _ChatDetailScreen(
                                        contact: contact,
                                        currentUser: _currentUser,
                                        darkMode: _darkMode,
                                        onNotification: (message) {
                                          if (_notificationsEnabled) {
                                            _showNotification(
                                              contactUser['username'] ?? 'Новое сообщение',
                                              message,
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactsScreen() {
    return MobileAnimatedBackground(
      backgroundColor: _darkMode ? Colors.black : Colors.white,
      lineColor: _darkMode ? Colors.white : Colors.black,
      child: Column(
        children: [
          AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text('Контакты', style: TextStyle(
              color: _darkMode ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            )),
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: _darkMode ? Colors.white : Colors.black),
              onPressed: () => setState(() { _selectedIndex = 0; }),
            ),
            actions: [
              IconButton(
                onPressed: () => setState(() { _showAddContactMenu = true; }),
                icon: Icon(Icons.person_add, color: _darkMode ? Colors.white : Colors.black),
              ),
            ],
          ),
          Expanded(
            child: _isLoadingContacts
                ? Center(child: CircularProgressIndicator(color: _darkMode ? Colors.white : Colors.black))
                : _contacts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 80,
                              color: _darkMode ? Colors.white70 : Colors.black54,
                            ),
                            SizedBox(height: 20),
                            Text(
                              'Контакты отсутствуют',
                              style: TextStyle(
                                color: _darkMode ? Colors.white70 : Colors.black54,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: () => setState(() { _showAddContactMenu = true; }),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _darkMode ? Colors.blueAccent : Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                              child: Text('Добавить контакт'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _contacts.length,
                        itemBuilder: (context, index) {
                          final contact = _contacts[index];
                          final contactUser = contact['contact'] ?? contact;
                          
                          return Container(
                            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: Card(
                              color: _darkMode ? Colors.white10 : Colors.grey[50],
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _darkMode ? Colors.blueAccent : Colors.blue[100],
                                  child: Text(
                                    (contactUser['username']?[0] ?? 'U').toUpperCase(),
                                    style: TextStyle(
                                      color: _darkMode ? Colors.white : Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  contactUser['username'] ?? '',
                                  style: TextStyle(
                                    color: _darkMode ? Colors.white : Colors.black,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      contactUser['email'] ?? '',
                                      style: TextStyle(
                                        color: _darkMode ? Colors.white70 : Colors.black54,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            color: Colors.green,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'онлайн',
                                          style: TextStyle(
                                            color: _darkMode ? Colors.greenAccent : Colors.green,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsScreen() {
    return MobileAnimatedBackground(
      backgroundColor: _darkMode ? Colors.black : Colors.white,
      lineColor: _darkMode ? Colors.white : Colors.black,
      child: Column(
        children: [
          AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text('Настройки', style: TextStyle(
              color: _darkMode ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            )),
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: _darkMode ? Colors.white : Colors.black),
              onPressed: () => setState(() { _selectedIndex = 0; }),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(16),
              children: [
                Card(
                  color: _darkMode ? Colors.white10 : Colors.grey[50],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: Text('Уведомления', style: TextStyle(
                            color: _darkMode ? Colors.white : Colors.black,
                          )),
                          subtitle: Text('Показывать уведомления о новых сообщениях',
                            style: TextStyle(color: _darkMode ? Colors.white70 : Colors.black54)),
                          value: _notificationsEnabled,
                          onChanged: (value) => setState(() { _notificationsEnabled = value; }),
                          activeColor: _darkMode ? Colors.blueAccent : Colors.blue,
                        ),
                        SwitchListTile(
                          title: Text('Темная тема', style: TextStyle(
                            color: _darkMode ? Colors.white : Colors.black,
                          )),
                          subtitle: Text('Использовать темную тему интерфейса',
                            style: TextStyle(color: _darkMode ? Colors.white70 : Colors.black54)),
                          value: _darkMode,
                          onChanged: (value) => setState(() { _darkMode = value; }),
                          activeColor: _darkMode ? Colors.blueAccent : Colors.blue,
                        ),
                        SwitchListTile(
                          title: Text('Показывать статус онлайн', style: TextStyle(
                            color: _darkMode ? Colors.white : Colors.black,
                          )),
                          subtitle: Text('Отображать ваш онлайн статус другим пользователям',
                            style: TextStyle(color: _darkMode ? Colors.white70 : Colors.black54)),
                          value: _showOnlineStatus,
                          onChanged: (value) => setState(() { _showOnlineStatus = value; }),
                          activeColor: _darkMode ? Colors.blueAccent : Colors.blue,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Card(
                  color: _darkMode ? Colors.white10 : Colors.grey[50],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        title: Text('Мой профиль', style: TextStyle(
                          color: _darkMode ? Colors.white : Colors.black,
                        )),
                        leading: Icon(Icons.person, 
                          color: _darkMode ? Colors.blueAccent : Colors.blue),
                        trailing: Icon(Icons.chevron_right, 
                          color: _darkMode ? Colors.white70 : Colors.black54),
                        onTap: () => setState(() { _showProfileMenu = true; }),
                      ),
                      ListTile(
                        title: Text('Изменить пароль', style: TextStyle(
                          color: _darkMode ? Colors.white : Colors.black,
                        )),
                        leading: Icon(Icons.lock, 
                          color: _darkMode ? Colors.blueAccent : Colors.blue),
                        trailing: Icon(Icons.chevron_right, 
                          color: _darkMode ? Colors.white70 : Colors.black54),
                        onTap: () => setState(() { _showChangePasswordMenu = true; }),
                      ),
                      ListTile(
                        title: Text('О приложении', style: TextStyle(
                          color: _darkMode ? Colors.white : Colors.black,
                        )),
                        leading: Icon(Icons.info, 
                          color: _darkMode ? Colors.blueAccent : Colors.blue),
                        trailing: Icon(Icons.chevron_right, 
                          color: _darkMode ? Colors.white70 : Colors.black54),
                        onTap: () => showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: _darkMode ? Color(0xFF1E1E1E) : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            title: Row(
                              children: [
                                Icon(Icons.chat, 
                                  color: _darkMode ? Colors.blueAccent : Colors.blue),
                                SizedBox(width: 12),
                                Text('TopMessenger v2.0', style: TextStyle(
                                  color: _darkMode ? Colors.white : Colors.black,
                                  fontWeight: FontWeight.bold,
                                )),
                              ],
                            ),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Веб-мессенджер для общения в реальном времени.',
                                  style: TextStyle(
                                    color: _darkMode ? Colors.white70 : Colors.black87,
                                  )),
                                SizedBox(height: 10),
                                Text('Разработано с использованием:',
                                  style: TextStyle(
                                    color: _darkMode ? Colors.white : Colors.black,
                                    fontWeight: FontWeight.w500,
                                  )),
                                SizedBox(height: 5),
                                Text('• Flutter для мобильного интерфейса',
                                  style: TextStyle(color: _darkMode ? Colors.white70 : Colors.black54)),
                                Text('• Django для серверной части',
                                  style: TextStyle(color: _darkMode ? Colors.white70 : Colors.black54)),
                                Text('• WebSocket для живого чата',
                                  style: TextStyle(color: _darkMode ? Colors.white70 : Colors.black54)),
                                SizedBox(height: 15),
                                Text('© 2026 TopMessenger. Все права защищены.',
                                  style: TextStyle(
                                    color: _darkMode ? Colors.white60 : Colors.black38,
                                    fontSize: 12,
                                  )),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('Закрыть', style: TextStyle(
                                  color: _darkMode ? Colors.blueAccent : Colors.blue,
                                )),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 30),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: ElevatedButton(
                    onPressed: () async {
                      await ApiService.logout();
                      if (mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => LoginScreen()),
                          (route) => false,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('Выйти из аккаунта'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _selectedIndex,
            children: [
              _buildChatsScreen(),
              _buildContactsScreen(),
              _buildSettingsScreen(),
            ],
          ),
          if (_showProfileMenu) _buildProfileMenu(),
          if (_showAddContactMenu) _buildAddContactMenu(),
          if (_showSearchMenu) _buildSearchMenu(),
          if (_showChangePasswordMenu) _buildChangePasswordMenu(),
          if (_showStatusMenu) _buildStatusMenu(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }
}

class _ChatDetailScreen extends StatefulWidget {
  final Map<String, dynamic> contact;
  final Map<String, dynamic>? currentUser;
  final bool darkMode;
  final Function(String)? onNotification;

  const _ChatDetailScreen({
    required this.contact,
    required this.currentUser,
    required this.darkMode,
    this.onNotification,
  });

  @override
  State<_ChatDetailScreen> createState() => __ChatDetailScreenState();
}

class __ChatDetailScreenState extends State<_ChatDetailScreen> {
  final WebSocketService _wsService = WebSocketService();
  Timer? _reconnectTimer;
  List<dynamic> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  bool _isLoading = true;
  bool _wsConnected = false;
  String? _wsError;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
  }

  @override
  void dispose() {
    _reconnectTimer?.cancel();
    _wsService.disconnect();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  int? get _contactId {
    final contact = widget.contact['contact'] ?? widget.contact;
    final id = contact?['id'];
    if (id is int) return id;
    if (id is num) return id.toInt();
    return null;
  }

  void _connectWebSocket() {
    _reconnectTimer?.cancel();
    final contactId = _contactId;
    if (contactId == null) {
      _showSnackbar('Не удалось определить диалог', isError: true);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    _wsService.connect(
      contactId,
      onMessage: (msg) {
        if (!mounted) return;
        setState(() {
          _messages.add(msg);
          _isLoading = false;
        });
        _scrollToBottom();
        if (widget.onNotification != null) {
          widget.onNotification!(msg['content'] ?? 'Новое сообщение');
        }
      },
      onHistory: (history) {
        if (!mounted) return;
        setState(() {
          _messages = history;
          _isLoading = false;
        });
        _scrollToBottom();
      },
      onConnected: () {
        if (!mounted) return;
        setState(() {
          _wsConnected = true;
          _wsError = null;
        });
      },
      onDisconnected: () {
        if (!mounted) return;
        setState(() => _wsConnected = false);
        _scheduleReconnect();
      },
      onEventError: (detail) {
        if (!mounted) return;
        setState(() => _wsError = detail);
        _showSnackbar('Ошибка соединения. Попробуем переподключиться.', isError: true);
        _scheduleReconnect();
      },
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      _connectWebSocket();
    });
  }

  void _showSnackbar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? Icons.error : Icons.info, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError 
            ? Colors.red.withOpacity(0.9)
            : (widget.darkMode ? Colors.green.withOpacity(0.9) : Colors.blue.withOpacity(0.9)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _handleAuthException(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('401') || msg.contains('403') || msg.contains('validate credentials')) {
      ApiService.logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
      _showSnackbar('Сессия истекла, войдите снова', isError: true);
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    if (!_wsService.isConnected) {
      _showSnackbar('Нет соединения, пробуем переподключиться...', isError: true);
      _connectWebSocket();
      return;
    }

    _wsService.sendMessage(text);
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final contactUser = widget.contact['contact'] ?? widget.contact;
    
    return MobileAnimatedBackground(
      backgroundColor: widget.darkMode ? Colors.black : Colors.white,
      lineColor: widget.darkMode ? Colors.white : Colors.black,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back, color: widget.darkMode ? Colors.white : Colors.black),
          ),
          title: Row(
            children: [
              CircleAvatar(
                backgroundColor: widget.darkMode ? Colors.white24 : Colors.grey[200],
                child: Text(
                  (contactUser['username']?[0] ?? 'U').toUpperCase(),
                  style: TextStyle(
                    color: widget.darkMode ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contactUser['username'] ?? '',
                      style: TextStyle(
                        color: widget.darkMode ? Colors.white : Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _wsConnected ? Colors.greenAccent : Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 4),
                        Text(
                          _wsConnected ? 'онлайн' : 'офлайн',
                          style: TextStyle(
                            color: _wsConnected ? Colors.greenAccent : Colors.redAccent,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: widget.darkMode ? Colors.white : Colors.black))
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        final isMe = message['sender_id'] == widget.currentUser?['id'];
                        final bubbleColor = isMe
                            ? (widget.darkMode ? Color(0xFF2563EB) : Color(0xFF2196F3))
                            : (widget.darkMode ? Colors.white10 : Colors.grey[200]);
                        final textColor = isMe
                            ? Colors.white
                            : (widget.darkMode ? Colors.white : Colors.black);
                        
                        return AnimatedContainer(
                          duration: Duration(milliseconds: 200),
                          child: Align(
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: bubbleColor,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.75,
                              ),
                              child: Text(
                                message['content'] ?? '',
                                style: TextStyle(color: textColor, height: 1.3),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: widget.darkMode ? Colors.white10 : Colors.grey[50],
                border: Border(
                  top: BorderSide(color: widget.darkMode ? Colors.white24 : Colors.black12),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: TextStyle(color: widget.darkMode ? Colors.white : Colors.black),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: widget.darkMode ? Colors.white10 : Colors.white,
                        hintText: 'Сообщение...',
                        hintStyle: TextStyle(color: widget.darkMode ? Colors.white60 : Colors.black38),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: _messageController.text.trim().isNotEmpty
                          ? (widget.darkMode ? Colors.blueAccent : Colors.blue)
                          : (widget.darkMode ? Colors.white10 : Colors.grey[300]),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: _messageController.text.trim().isNotEmpty ? _sendMessage : null,
                      icon: Icon(Icons.send, 
                        color: _messageController.text.trim().isNotEmpty 
                            ? Colors.white 
                            : (widget.darkMode ? Colors.white30 : Colors.black38)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}