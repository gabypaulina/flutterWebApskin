// services/socket_service.dart
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static IO.Socket? _socket;
  static bool _isConnected = false;

  static IO.Socket? get socket => _socket;
  static bool get isConnected => _isConnected;

  static Future<void> initializeSocket() async {
    try {
      _socket = IO.io(
        'http://172.20.10.2:3000/api', // Ganti dengan URL server Anda
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .enableAutoConnect()
            .build(),
      );

      _socket!.onConnect((_) {
        print('Socket connected');
        _isConnected = true;
      });

      _socket!.onDisconnect((_) {
        print('Socket disconnected');
        _isConnected = false;
      });

      _socket!.onError((error) {
        print('Socket error: $error');
        _isConnected = false;
      });

      _socket!.connect();
    } catch (e) {
      print('Error initializing socket: $e');
    }
  }

  // Ubah tipe parameter callback menjadi dynamic Function(dynamic)
  static void on(String event, dynamic Function(dynamic) callback) {
    if (_socket != null) {
      _socket!.on(event, callback);
    }
  }

  static void off(String event) {
    if (_socket != null) {
      _socket!.off(event);
    }
  }

  static void joinRoom(String reservationId) {
    if (_socket != null && _isConnected) {
      _socket!.emit('join_room', {
        'reservationId': reservationId,
      });
    }
  }

  static void sendMessage(Map<String, dynamic> messageData) {
    if (_socket != null && _isConnected) {
      _socket!.emit('send_message', messageData);
    }
  }

  static void sendImage(Map<String, dynamic> imageData) {
    if (_socket != null && _isConnected) {
      _socket!.emit('send_image', imageData);
    }
  }

  static void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket = null;
      _isConnected = false;
    }
  }
}