import 'dart:convert';
import 'dart:async';
import 'dart:collection';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://91.214.78.192';
  static const String wsBaseUrl = 'ws://91.214.78.192';
  
  static String? _token;
  static String? _tokenType;
  static DateTime? _tokenExpiresAt;
  static final Map<String, dynamic> _cache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static final Duration _cacheDuration = Duration(minutes: 5);
  static final RateLimiter _rateLimiter = RateLimiter(maxRequestsPerSecond: 5);
  static final Map<String, String> _errorMessages = {
    'invalid_credentials': 'Неверный логин или пароль',
    'email_exists': 'Email уже зарегистрирован',
    'username_exists': 'Имя пользователя занято',
    'user_not_found': 'Пользователь не найден',
    'contact_already_exists': 'Контакт уже добавлен',
    'network_error': 'Нет подключения к серверу',
    'server_error': 'Ошибка сервера',
  };

  static void setToken(String token, {String? tokenType, int? expiresInSeconds}) {
    _token = token;
    _tokenType = tokenType;
    _tokenExpiresAt = expiresInSeconds != null
        ? DateTime.now().add(Duration(seconds: expiresInSeconds))
        : null;
    _clearExpiredCache();
  }

  static String? getToken() {
    return _token;
  }

  static String? getTokenType() {
    return _tokenType;
  }

  static DateTime? getTokenExpiresAt() {
    return _tokenExpiresAt;
  }

  static void clearToken() {
    _token = null;
    _tokenType = null;
    _tokenExpiresAt = null;
    _cache.clear();
    _cacheTimestamps.clear();
  }

  static Future<Map<String, String>> getHeaders() async {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
    };

    if (_token != null) {
      if (_tokenExpiresAt != null && 
          _tokenExpiresAt!.isBefore(DateTime.now().add(Duration(minutes: 5)))) {
        await _refreshToken();
      }
      headers['Authorization'] = '${_tokenType ?? 'Bearer'} $_token';
    }

    return headers;
  }

  static Future<void> preloadCommonData() async {
    if (_token == null) return;
    
    await Future.wait([
      getCurrentUserProfile(cacheOnly: false),
      getContacts(cacheOnly: false),
    ], eagerError: false);
  }

  static Future<Map<String, dynamic>> register({
    required String email,
    required String username,
    required String password,
  }) async {
    await _rateLimiter.wait();
    
    final uri = Uri.parse('$baseUrl/auth/register');
    final cacheKey = 'register_${email}_${username}';
    
    if (_isCacheValid(cacheKey)) {
      return _cache[cacheKey];
    }
    
    final resp = await _retryRequest(() async {
      return await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'username': username,
          'password': password,
        }),
      );
    });

    _logResponse('POST', uri, resp);

    if (resp.statusCode == 201) {
      final data = jsonDecode(resp.body);
      _addToCache(cacheKey, data);
      return data;
    } else {
      throw _createException(resp);
    }
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    await _rateLimiter.wait();
    
    final uri = Uri.parse('$baseUrl/auth/login');
    final cacheKey = 'login_$email';

    final Map<String, String> body = {
      'username': email,
      'password': password,
      'grant_type': 'password',
      'scope': '',
    };

    final resp = await _retryRequest(() async {
      return await http.post(
        uri,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: body,
      );
    });

    _logResponse('POST', uri, resp);

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      final token = data['access_token'];
      final tokenType = data['token_type'];
      final expiresIn = data['expires_in'];

      if (token == null) {
        throw Exception('Токен не получен');
      }
      setToken(token, tokenType: tokenType, expiresInSeconds: expiresIn is int ? expiresIn : null);
      _addToCache(cacheKey, data);
      return data;
    } else {
      throw _createException(resp);
    }
  }

  static Future<Map<String, dynamic>> getCurrentUserProfile({bool cacheOnly = false}) async {
    final uri = Uri.parse('$baseUrl/users/');
    final cacheKey = 'current_user_profile';
    
    if (_isCacheValid(cacheKey)) {
      return _cache[cacheKey];
    }
    
    if (cacheOnly) {
      throw Exception('Данные не найдены в кэше');
    }
    
    await _rateLimiter.wait();
    
    final resp = await _retryRequest(() async {
      return await http.get(uri, headers: await getHeaders());
    });

    _logResponse('GET', uri, resp);

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      Map<String, dynamic> profile = <String, dynamic>{};
      
      if (data is Map<String, dynamic>) {
        profile = data;
      } else if (data is List) {
        if (data.isNotEmpty && data.first is Map<String, dynamic>) {
          final first = data.first as Map<String, dynamic>;
          profile = first['contact'] is Map<String, dynamic> 
              ? first['contact'] as Map<String, dynamic>
              : first;
        }
      }
      
      _addToCache(cacheKey, profile);
      return profile;
    } else if (resp.statusCode == 401) {
      clearToken();
      throw Exception('Неавторизован');
    } else {
      throw _createException(resp);
    }
  }

  static Future<List<dynamic>> getContacts({bool cacheOnly = false}) async {
    final uri = Uri.parse('$baseUrl/users/');
    final cacheKey = 'contacts_list';
    
    if (_isCacheValid(cacheKey)) {
      return _cache[cacheKey];
    }
    
    if (cacheOnly) {
      throw Exception('Данные не найдены в кэше');
    }
    
    await _rateLimiter.wait();
    
    final resp = await _retryRequest(() async {
      return await http.get(uri, headers: await getHeaders());
    });

    _logResponse('GET', uri, resp);

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      _addToCache(cacheKey, data);
      return data;
    } else if (resp.statusCode == 401) {
      clearToken();
      throw Exception('Неавторизован');
    } else {
      throw _createException(resp);
    }
  }

  static Future<List<dynamic>> getMessages(int contactId, {bool cacheOnly = false}) async {
    final uri = Uri.parse('$baseUrl/dialogs/$contactId/messages');
    final cacheKey = 'messages_$contactId';
    
    if (_isCacheValid(cacheKey)) {
      return _cache[cacheKey];
    }
    
    if (cacheOnly) {
      throw Exception('Данные не найдены в кэше');
    }
    
    await _rateLimiter.wait();
    
    final resp = await _retryRequest(() async {
      return await http.get(uri, headers: await getHeaders());
    });

    _logResponse('GET', uri, resp);

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      _addToCache(cacheKey, data);
      return data;
    } else {
      throw _createException(resp);
    }
  }

  static Future<Map<String, dynamic>> addContact(String contactEmail) async {
    await _rateLimiter.wait();
    
    final uri = Uri.parse('$baseUrl/users/contacts');
    
    final resp = await _retryRequest(() async {
      return await http.post(
        uri,
        headers: await getHeaders(),
        body: jsonEncode({'contact_email': contactEmail}),
      );
    });

    _logResponse('POST', uri, resp);

    if (resp.statusCode == 201) {
      _invalidateCache('contacts_list');
      final data = jsonDecode(resp.body);
      return data;
    } else {
      throw _createException(resp);
    }
  }

  static Future<void> deleteContact(int contactId) async {
    await _rateLimiter.wait();
    
    final uri = Uri.parse('$baseUrl/users/contacts/$contactId');
    
    final resp = await _retryRequest(() async {
      return await http.delete(uri, headers: await getHeaders());
    });

    _logResponse('DELETE', uri, resp);

    if (resp.statusCode != 200 && resp.statusCode != 204) {
      throw _createException(resp);
    } else {
      _invalidateCache('contacts_list');
    }
  }

  static Future<List<dynamic>> searchUsers(String query, {bool cacheOnly = false}) async {
    final uri = Uri.parse('$baseUrl/users/search?q=$query');
    final cacheKey = 'search_$query';
    
    if (_isCacheValid(cacheKey)) {
      return _cache[cacheKey];
    }
    
    if (cacheOnly) {
      throw Exception('Данные не найдены в кэше');
    }
    
    await _rateLimiter.wait();
    
    final resp = await _retryRequest(() async {
      return await http.get(uri, headers: await getHeaders());
    });

    _logResponse('GET', uri, resp);

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      _addToCache(cacheKey, data);
      return data;
    } else {
      throw _createException(resp);
    }
  }

  static Future<Map<String, dynamic>> updateProfile({
    String? username,
    String? email,
    String? bio,
    String? status,
  }) async {
    await _rateLimiter.wait();
    
    final uri = Uri.parse('$baseUrl/users/');
    
    final Map<String, dynamic> body = {};
    if (username != null) body['username'] = username;
    if (email != null) body['email'] = email;
    if (bio != null) body['bio'] = bio;
    if (status != null) body['status'] = status;

    final resp = await _retryRequest(() async {
      return await http.put(
        uri,
        headers: await getHeaders(),
        body: jsonEncode(body),
      );
    });

    _logResponse('PUT', uri, resp);

    if (resp.statusCode == 200) {
      _invalidateCache('current_user_profile');
      final data = jsonDecode(resp.body);
      return data;
    } else {
      throw _createException(resp);
    }
  }

  static Future<Map<String, dynamic>> updateOnlineStatus(bool isOnline) async {
    await _rateLimiter.wait();
    
    final uri = Uri.parse('$baseUrl/users/online');
    
    final resp = await _retryRequest(() async {
      return await http.post(
        uri,
        headers: await getHeaders(),
        body: jsonEncode({'is_online': isOnline}),
      );
    });

    _logResponse('POST', uri, resp);

    if (resp.statusCode == 200) {
      _invalidateCache('current_user_profile');
      return jsonDecode(resp.body);
    } else {
      throw _createException(resp);
    }
  }

  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _rateLimiter.wait();
    
    final uri = Uri.parse('$baseUrl/users/password');
    
    final resp = await _retryRequest(() async {
      return await http.put(
        uri,
        headers: await getHeaders(),
        body: jsonEncode({
          'current_password': currentPassword,
          'new_password': newPassword,
        }),
      );
    });

    _logResponse('PUT', uri, resp);

    if (resp.statusCode == 200) {
      return jsonDecode(resp.body);
    } else {
      throw _createException(resp);
    }
  }

  static Future<Map<String, dynamic>> uploadAvatar(List<int> imageBytes, String fileName) async {
    await _rateLimiter.wait();
    
    final uri = Uri.parse('$baseUrl/users/avatar');
    
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = '${_tokenType ?? 'Bearer'} $_token';
    
    final multipartFile = http.MultipartFile.fromBytes(
      'avatar',
      imageBytes,
      filename: fileName,
    );
    request.files.add(multipartFile);

    final streamedResponse = await request.send();
    final resp = await http.Response.fromStream(streamedResponse);

    _logResponse('POST', uri, resp);

    if (resp.statusCode == 200) {
      _invalidateCache('current_user_profile');
      return jsonDecode(resp.body);
    } else {
      throw _createException(resp);
    }
  }

  static Future<void> logout() async {
    try {
      final uri = Uri.parse('$baseUrl/auth/logout');
      await _rateLimiter.wait();
      
      final resp = await http.post(uri, headers: await getHeaders());
      _logResponse('POST', uri, resp);
    } catch (e) {
      print('Logout error (ignored): $e');
    } finally {
      clearToken();
    }
  }

  static String getWebSocketUrl(int contactId) {
    final token = getToken();
    if (token == null) throw Exception('Токен не доступен');
    return '$wsBaseUrl/dialogs/ws/$contactId?token=$token';
  }

  static Future<bool> checkServer() async {
    try {
      final uri = Uri.parse('$baseUrl/');
      final resp = await http.get(uri);
      return resp.statusCode < 500;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> checkInternetConnection() async {
    try {
      final uri = Uri.parse('https://www.google.com');
      final resp = await http.get(uri).timeout(Duration(seconds: 3));
      return resp.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<http.Response> _retryRequest(Future<http.Response> Function() request, 
                                          {int maxRetries = 3}) async {
    for (int i = 0; i < maxRetries; i++) {
      try {
        return await request();
      } catch (e) {
        if (i == maxRetries - 1) rethrow;
        await Future.delayed(Duration(seconds: 1 << i));
      }
    }
    throw Exception('Max retries exceeded');
  }

  static void _addToCache(String key, dynamic value) {
    _cache[key] = value;
    _cacheTimestamps[key] = DateTime.now();
  }

  static bool _isCacheValid(String key) {
    if (!_cache.containsKey(key) || !_cacheTimestamps.containsKey(key)) {
      return false;
    }
    final timestamp = _cacheTimestamps[key]!;
    return DateTime.now().difference(timestamp) < _cacheDuration;
  }

  static void _invalidateCache(String key) {
    _cache.remove(key);
    _cacheTimestamps.remove(key);
  }

  static void _clearExpiredCache() {
    final now = DateTime.now();
    _cacheTimestamps.removeWhere((key, timestamp) {
      if (now.difference(timestamp) > _cacheDuration) {
        _cache.remove(key);
        return true;
      }
      return false;
    });
  }

  static Future<void> _refreshToken() async {
    print('Token refresh not implemented');
  }

  static Exception _createException(http.Response resp) {
    try {
      final error = jsonDecode(resp.body);
      final errorDetail = error['detail']?.toString() ?? '';
      
      for (final entry in _errorMessages.entries) {
        if (errorDetail.toLowerCase().contains(entry.key)) {
          return Exception(entry.value);
        }
      }
      
      if (resp.statusCode == 401) return Exception('Неавторизован');
      if (resp.statusCode == 404) return Exception('Ресурс не найден');
      if (resp.statusCode >= 500) return Exception('Ошибка сервера');
      
      return Exception(errorDetail.isNotEmpty ? errorDetail : 'Ошибка: ${resp.statusCode}');
    } catch (_) {
      return Exception('Ошибка: ${resp.statusCode}');
    }
  }

  static void _logResponse(String method, Uri uri, http.Response resp) {
    print('$method $uri -> ${resp.statusCode}');
    final body = resp.body;
    if (body.isNotEmpty) {
      try {
        final parsed = jsonDecode(body);
        print(const JsonEncoder.withIndent('  ').convert(parsed));
      } catch (_) {
        print(body);
      }
    }
  }
}

class RateLimiter {
  final int maxRequestsPerSecond;
  final Queue<DateTime> _requestTimes = Queue();
  
  RateLimiter({required this.maxRequestsPerSecond});
  
  Future<void> wait() async {
    final now = DateTime.now();
    _requestTimes.add(now);
    
    while (_requestTimes.length > maxRequestsPerSecond) {
      _requestTimes.removeFirst();
    }
    
    if (_requestTimes.length == maxRequestsPerSecond) {
      final firstRequestTime = _requestTimes.first;
      final timeDiff = now.difference(firstRequestTime);
      
      if (timeDiff < Duration(seconds: 1)) {
        final waitTime = Duration(seconds: 1) - timeDiff;
        await Future.delayed(waitTime);
      }
    }
  }
}