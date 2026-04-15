import 'package:socket_io_client/socket_io_client.dart' as IO;
import './api_service.dart';

class SocketService {
  static IO.Socket? _socket;
  static bool _isConnected = false;

  static IO.Socket? get socket => _socket;
  static bool get isConnected => _isConnected;

  static Future<void> initializeSocket() async {
    if (_socket != null && _socket!.connected) {
      print("Socket already connected");
      return;
    }

    if (_socket != null && !_socket!.connected) {
      print("Reconnecting existing socket");
      _socket!.connect();
      return;
    }
    try {
      _socket = IO.io(
        '${ApiService.basedUrl}', // Ganti dengan URL server Anda
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
      _socket!.emit('join_room', reservationId); // ✅ FIX
    }
  }

  static void sendMessage(Map<String, dynamic> messageData) {
    if (_socket != null && _isConnected) {
      _socket!.emit('send_message', messageData);
    }
  }

  // UNTUK ADMIN
  static Future<void> connectAdmin(Function(dynamic) onNewNotification) async {
    await initializeSocket();

    _socket!.off("connect");
    _socket!.off("new_notification");


    _socket!.on("connect", (_) {
      print("Socket connected");

      _socket!.emit("join_admin_room");
    });

    // 🔥 PASTIKAN LISTENER SELALU AKTIF
    _socket!.on("new_notification", (data) {
      print("NOTIF MASUK SOCKET: $data");
      onNewNotification(data);
    });

    // kalau sudah connect langsung join juga
    if (_socket!.connected) {
      _socket!.emit("join_admin_room");
    }
  }

  // UNTUK DOKTER
  static Future<void> connectDoctor(
      String doctorName,
      Function(dynamic) onNewNotification,
      ) async {
    await initializeSocket();

    final room = doctorName.trim().toLowerCase();

    _socket!.off("new_notification_dokter");

    // 👇 TARUH DI SINI
    _socket!.onAny((event, data) {
      print("EVENT MASUK: $event -> $data");
    });

    _socket!.onConnect((_) {
      print("Doctor socket connected");

      _socket!.emit("join_doctor_room", room);
      print("JOIN DOCTOR ROOM: $room");
    });

    _socket!.on("new_notification_dokter", (data) {
      print("DOCTOR NOTIF: $data");

      if (data == null) return;
      onNewNotification(data);
    });

    // kalau sudah connect
    if (_socket!.connected) {
      _socket!.emit("join_doctor_room", room);
      print("JOIN DOCTOR ROOM (already connected): $room");
    }
  }

  // UNTUK TERAPIS
  void connectTerapis(
      String terapisName, Function(dynamic) onNewNotification) {

    initializeSocket();
    // 🔥 JOIN ROOM TERAPIS
    socket!.emit("join_terapis_room", terapisName);

    socket!.on("new_notification_terapis", (data) {
      print("SOCKET MASUK: $data");
      print("Doctor notif received: $data");
      onNewNotification(data);
    });
  }

  static void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket = null;
      _isConnected = false;
    }
  }
}