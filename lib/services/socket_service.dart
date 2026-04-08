import 'package:socket_io_client/socket_io_client.dart' as IO;
import './api_service.dart';


class SocketService {
  IO.Socket? socket;

  void _createSocket() {
    if (socket != null && socket!.connected) {
      print("Socket already connected");
      return;
    }

    socket = IO.io(
      ApiService.basedUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .build(),
    );

    socket!.onConnect((_) {
      print("SOCKET CONNECTED");
    });

    socket!.onConnectError((err) {
      print("CONNECT ERROR: $err");
    });

    socket!.onError((err) {
      print("SOCKET ERROR: $err");
    });
  }

  // UNTUK ADMIN
  void connect(Function(dynamic) onNewNotification) {
    _createSocket();

    socket!.on("new_notification", (data) {
      onNewNotification(data);
    });
  }

  // UNTUK DOKTER
  void connectDoctor(
      String doctorName, Function(dynamic) onNewNotification) {

    _createSocket();
    // 🔥 JOIN ROOM DOKTER
    socket!.emit("join_doctor_room", doctorName.trim().toLowerCase());

    socket!.on("new_notification_dokter", (data) {
      print("SOCKET MASUK: $data");
      print("Doctor notif received: $data");
      onNewNotification(data);
    });
  }

  // UNTUK TERAPIS
  void connectTerapis(
      String terapisName, Function(dynamic) onNewNotification) {

    _createSocket();
    // 🔥 JOIN ROOM TERAPIS
    socket!.emit("join_terapis_room", terapisName);

    socket!.on("new_notification_terapis", (data) {
      print("SOCKET MASUK: $data");
      print("Doctor notif received: $data");
      onNewNotification(data);
    });
  }

  void disconnect() {
    socket?.disconnect();
    socket=null;
  }
}