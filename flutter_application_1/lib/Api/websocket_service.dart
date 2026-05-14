import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'api_service.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  Function(Map<String, dynamic>)? _onMessage;
  Function(List<dynamic>)? _onHistory;
  Function()? _onConnected;
  Function()? _onDisconnected;
  Function(String)? _onEventError;
  bool _manuallyClosed = false;

  bool get isConnected => _channel != null;

  void connect(
    int contactId, {
    required Function(Map<String, dynamic>) onMessage,
    required Function(List<dynamic>) onHistory,
    Function()? onConnected,
    Function()? onDisconnected,
    Function(String)? onEventError,
  }) {
    disconnect();
    _manuallyClosed = false;
    _onMessage = onMessage;
    _onHistory = onHistory;
    _onConnected = onConnected;
    _onDisconnected = onDisconnected;
    _onEventError = onEventError;

    try {
      final url = ApiService.getWebSocketUrl(contactId);
      print('WebSocket connecting to: $url');

      _channel = WebSocketChannel.connect(Uri.parse(url));
      _onConnected?.call();

      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDone,
      );
    } catch (e) {
      print('WebSocket connection error: $e');
      _onDisconnected?.call();
    }
  }

  void _handleMessage(dynamic message) {
    try {
      print('WebSocket received: $message');
      final data = json.decode(message as String);

      if (data['event'] == 'history') {
        _onHistory?.call(data['messages'] ?? []);
      } else if (data['event'] == 'message') {
        _onMessage?.call(data['payload'] ?? {});
      } else if (data['event'] == 'error') {
        final detail = data['detail']?.toString() ?? 'WebSocket error';
        print('WebSocket error: $detail');
        _onEventError?.call(detail);
      }
    } catch (e) {
      print('Error parsing WebSocket message: $e\nRaw message: $message');
    }
  }

  void sendMessage(String content) {
    if (_channel != null) {
      final message = json.encode({'content': content});
      print('WebSocket sending: $message');
      _channel!.sink.add(message);
    }
  }

  void _handleError(error) {
    print('WebSocket error: $error');
    if (!_manuallyClosed) {
      _onDisconnected?.call();
    }
    _cleanup();
  }

  void _handleDone() {
    print('WebSocket closed');
    if (!_manuallyClosed) {
      _onDisconnected?.call();
    }
    _cleanup();
  }

  void disconnect() {
    _manuallyClosed = true;
    _channel?.sink.close();
    _cleanup();
  }

  void _cleanup() {
    _channel = null;
    _onMessage = null;
    _onHistory = null;
    _onConnected = null;
    _onDisconnected = null;
    _onEventError = null;
  }
}