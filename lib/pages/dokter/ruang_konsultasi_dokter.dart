import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart';
import '../../services/api_service.dart';
import 'package:http/http.dart' as http;
import '../../services/socket_service.dart';
import 'buat_catatan_dokter.dart';
import 'buat_resep_digital.dart';
import 'package:uuid/uuid.dart';


class RuangKonsultasiDokter extends StatefulWidget {
  final Map<String, dynamic> reservation;

  const RuangKonsultasiDokter({Key? key, required this.reservation}) : super(key: key);

  @override
  _RuangKonsultasiDokterState createState() => _RuangKonsultasiDokterState();
}

class _RuangKonsultasiDokterState extends State<RuangKonsultasiDokter> {
  final TextEditingController _messageController = TextEditingController();
  final List<Message> _messages = [];
  final ImagePicker _picker = ImagePicker();
  bool _isConnected = false;
  final Uuid uuid = Uuid();
  bool _socketInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeSocket();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadChatHistory();
    });
    if (_socketInitialized) return;
    _socketInitialized = true;
  }

  Future<void> _initializeSocket() async {
    await SocketService.initializeSocket();

    SocketService.off('receive_message');
    SocketService.off('receive_image');

    final roomId = widget.reservation['_id'];

    // 🔥 WAJIB: kalau socket sudah connect
    if (SocketService.socket!.connected) {
      SocketService.joinRoom(roomId);
      print("JOIN ROOM (immediate): $roomId");
    }

    SocketService.socket?.onConnect((_) {
      print("JOIN ROOM DOKTER: ${widget.reservation['_id']}");
      SocketService.joinRoom(widget.reservation['_id']);
    });

    SocketService.socket?.on("joined_room", (room) {
      print("BERHASIL JOIN ROOM: $room");
    });

    SocketService.on('receive_message', (data) {
      if (!mounted) return;

      final newMsg = Message.fromJson(data);

      final newId = newMsg.messageId ?? newMsg.id;

      final exists = _messages.any(
            (m) => (m.messageId ?? m.id) == newId,
      );

      if (exists) return;

      setState(() {
        _messages.add(newMsg);
      });
    });

    SocketService.on('receive_image', (data) {
      if (mounted) {
        setState(() {
          // _messages.insert(0, Message.fromJson(data));
          _messages.add(Message.fromJson(data));
        });
      }
    });

    SocketService.socket?.on("session_finished", (data) {
      if (data['reservationId'] != widget.reservation['_id']) return;
      final by = data['by'];

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text("Sesi Konsultasi Berakhir"),
          content: Text(
            by == 'doctor'
                ? "Sesi telah berakhir."
                : "Pasien telah mengakhiri sesi.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // close dialog
                Navigator.pop(context, true); // keluar chat + return ke DetailAppointment
              },
              child: const Text("OK"),
            )
          ],
        ),
      );
    });
  }

  Future<void> _loadChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/chat/${widget.reservation['_id']}'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) return;

      final data = jsonDecode(response.body);

      final List<Message> newMessages = (data['messages'] ?? [])
          .map<Message>((msg) => Message.fromJson(msg))
          .toList();

      if (!mounted) return;

      // 🔥 KUNCI: jangan overwrite kalau kosong
      if (newMessages.isNotEmpty) {
        setState(() {
          for (var msg in newMessages) {
            final exists = _messages.any((m) => m.id == msg.id);
            if (!exists) {
              // _messages.insert(0, msg);
              _messages.add(msg);
            }
          }
        });
      }

    } catch (e) {
      print('Error loading chat history: $e');
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty) return;

    final messageData = {
      'messageId': uuid.v4(),
      'reservationId': widget.reservation['_id'],
      'text': _messageController.text,
      'senderType': 'doctor',
      'timestamp': DateTime.now().toIso8601String(),
      'type' : 'text',
    };

    // // ✅ TAMBAH INI (BIAR LANGSUNG MUNCUL)
    // setState(() {
    //   _messages.add(Message.fromJson(messageData));
    // });

    // realtime
    SocketService.sendMessage(messageData);

    _messageController.clear();
  }

  void _openImage(String imagePath) {
    final fullUrl =
        '${ApiService.baseUrl.replaceAll('/api', '')}$imagePath';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenImage(imageUrl: fullUrl),
      ),
    );
  }

  Future<void> _endConsultation() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.put(
      Uri.parse('${ApiService.baseUrl}/reservasi/${widget.reservation['_id']}'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'status': 'selesai'}),
    );

    if (response.statusCode == 200) {
      // 🔥 kirim event ke socket sebelum keluar
      SocketService.sendMessage({
        'type': 'session_finished',
        'reservationId': widget.reservation['_id'],
        'by': 'doctor',
      });
      Navigator.pop(context, true);
    }
  }

  void _showActionMenu() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: EdgeInsets.symmetric(horizontal: 40),
          child: Container(
            width: 1000,
            padding: const EdgeInsets.all(40),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: SizedBox(
                  height: 200,
                  // 🔥 BUTTON RESEP
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: EdgeInsets.all(20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      side: BorderSide(
                        color: Color(0xFF109E88),
                        width: 2
                      )
                    ),
                    onPressed: () async {
                      Navigator.pop(context);
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BuatResepPage(reservation: widget.reservation),
                        ),
                      );

                      if (result != null) {
                        final message = {
                          'messageId': uuid.v4(),
                          'reservationId': widget.reservation['_id'],
                          'text': 'Resep Dokter',
                          'senderType': 'doctor',
                          'resepId': 'resep_${DateTime.now().millisecondsSinceEpoch}', // 🔥 penting
                          'timestamp': DateTime.now().toIso8601String(),
                          'type': 'resep',
                          'resep': result['resep'], // HARUS LIST
                        };

                        // // 2. realtime socket
                        SocketService.sendMessage(message);

                      }
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "BUAT RESEP",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Afacad',
                            color: Color(0xFF109E88),
                            fontSize: 24,
                            fontWeight: FontWeight.bold
                          ),
                        ),
                        SizedBox(height: 15),
                        Text(
                          "Resep digital, hanya bisa ditebus di apotek klinik",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Afacad',
                            color: Color(0xFF109E88),
                            fontSize: 18
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                ),
  
                SizedBox(width: 50),
  
                  // 🔥 BUTTON CATATAN
                Expanded(
                  child: SizedBox(
                  height: 200,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: EdgeInsets.all(20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      side: BorderSide(
                          color: Color(0xFF109E88),
                          width: 2
                      )
                    ),
                    onPressed: () async {
                      Navigator.pop(context);
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BuatCatatanPage(reservation: widget.reservation),
                        ),
                      );

                      if (result != null) {
                        final message = {
                          'messageId': uuid.v4(),
                          'reservationId': widget.reservation['_id'],
                          'text': 'Catatan Dokter',
                          'senderType': 'doctor',
                          'timestamp': result['time'],
                          'type': result['type'],
                          'diagnosis': result['diagnosis'],
                          'note': result['note'],
                        };

                        SocketService.sendMessage(message);
                        //
                        // // ✅ TAMBAH INI
                        // setState(() {
                        //   // _messages.insert(0, Message.fromJson(message));
                        //   _messages.add(
                        //       Message.fromJson(message));
                        // });
                        // await ApiService.sendCatatan(message);
                      }
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "BUAT CATATAN DOKTER",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Afacad',
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF109E88)
                          ),
                        ),
                        SizedBox(height: 15),
                        Text(
                          "Catatan ini akan tersimpan di akun pengguna serta dokter yang bersangkutan",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Afacad',
                            fontSize: 18,
                            color: Color(0xFF109E88)
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSystemCard(Message message) {
    final isResep = message.type == 'resep';

    return Container(
      margin: EdgeInsets.symmetric(vertical: 12),
      alignment: Alignment.center,
      child: Container(
        width: 350,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Color(0xFF109E88), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isResep ? "Resep Digital" : "Catatan Dokter",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF109E88),
              ),
            ),
            SizedBox(height: 8),

            Text(
              DateFormat('dd MMMM yyyy, HH:mm').format(message.time),
              style: TextStyle(color: Colors.grey),
            ),

            SizedBox(height: 12),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                  onPressed: () async {
                    if (isResep) {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BuatResepPage(
                            reservation: widget.reservation,
                            isEdit: true,
                            existingResep: message.rawData?['resep'] ?? message.rawData?['data']?['resep'],
                            messageId: message.id,
                          ),
                        ),
                      );

                      if (result != null) {
                        setState(() {
                          final index = _messages.indexWhere((m) => m.id == message.id);
                          if (index != -1) {
                            _messages[index] = Message.fromJson({
                              ...message.rawData!,
                              '_id': message.id,
                              'resep': result['resep'],
                              'timestamp': DateTime.now().toIso8601String(),
                            });
                          }
                        });
                      }

                    } else {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BuatCatatanPage(
                            reservation: widget.reservation,
                            isEdit: true,
                            existingCatatan: message.rawData,
                          ),
                        ),
                      );

                      if (result != null) {
                        setState(() {
                          final index = _messages.indexWhere((m) => m.id == message.id);

                          if (index != -1) {
                            _messages[index] = Message.fromJson({
                              ...message.rawData!,
                              '_id': message.id, // WAJIB
                              'timestamp': DateTime.now().toIso8601String(),
                              'diagnosis': result['diagnosis'],
                              'note': result['note'],
                            });
                          }
                        });
                      }
                    }
                  },
                child: Text("Selengkapnya"),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // WebSocketService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(
                color: Color(0xFF109E88),
                width: 1.0,
              ),
            ),
          ),
          child:
          Padding(
            padding: const EdgeInsets.only(top: 30.0, left: 50, right: 50),
            child: AppBar(
              automaticallyImplyLeading: false,
              leading: Center(
                child: Container(
                  width: 55,
                  height: 55,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Color(0xFF109E88),
                      width: 1,
                    ),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                    iconSize: 24,
                    icon: Icon(Icons.arrow_back, color: Color(0xFF109E88)),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Ruang Konsultasi',
                    style: TextStyle(
                      fontFamily: 'Afacad',
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF109E88),
                    ),
                  ),
                  Text(
                    'Nama Pasien : ${widget.reservation['namaPasien'] ?? 'Pasien'}',
                    style: TextStyle(
                      fontFamily: 'Afacad',
                      fontSize: 20,
                      color: Color(0xFF109E88),
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  iconSize: 30,
                  icon: Icon(Icons.check, color: Color(0xFF109E88)),
                  onPressed: _endConsultation,
                ),
              ],
              elevation: 0,
              centerTitle: true,
              backgroundColor: Colors.transparent,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              reverse: false,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                // IconButton(
                //   icon: Icon(Icons.photo_library, color: Color(0xFF109E88)),
                //   onPressed: _pickImage,
                // ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Ketik pesan...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add, color: Color(0xFF109E88)),
                  onPressed: _showActionMenu,
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Color(0xFF109E88)),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message) {
    final isMe = !message.isUser;
    final time = DateFormat('HH:mm').format(message.time);
    if (message.type == 'resep' || message.type == 'catatan') {
      return _buildSystemCard(message);
    }
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe)
            CircleAvatar(
              backgroundColor: Colors.grey[300],
              child: Icon(Icons.person, color: Colors.white, size: 18),
              radius: 16,
            ),
          SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    // color: isMe ? Color(0xFF109E88) : Colors.grey[300],
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                      bottomLeft: isMe ? Radius.circular(16) : Radius.circular(4),
                      bottomRight: isMe ? Radius.circular(4) : Radius.circular(16),
                    ),
                  ),
                  child: message.image != null
                      ? GestureDetector(
                          onTap: () {
                            _openImage(message.image!);
                          },
                          child: Image.network(
                            '${ApiService.baseUrl.replaceAll('/api', '')}${message.image}',
                            width: 200,
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                      )
                      : Text(
                    message.text,
                    style: TextStyle(
                      // color: isMe ? Colors.white : Colors.black,
                      color: Colors.black,
                      fontSize: 18
                    ),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          if (isMe)
            SizedBox(width: 8),
          if (isMe)
            CircleAvatar(
              backgroundColor: Color(0xFF109E88),
              child: Text(
                'D',
                style: TextStyle(color: Colors.white),
              ),
              radius: 16,
            ),
        ],
      ),
    );
  }
}

class Message {
  final String text;
  final String? image;
  final DateTime time;
  final bool isUser;
  final String type;
  final Map<String, dynamic>? rawData;
  final String? id;
  final String? messageId;

  Message({
    required this.text,
    this.image,
    required this.time,
    required this.isUser,
    this.type = 'text',
    this.rawData,
    this.id,
    this.messageId,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      messageId: json['messageId'],
      id: json['_id'] ?? json['id'],
      text: json['text'] ?? '',
      image: json['imageUrl'] ?? json['image'],
      time: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      isUser: json['senderType'] == 'user',
      type: (json['type'] ?? 'text').toString().toLowerCase().trim(),
      rawData: json,
    );
  }
}

class FullScreenImage extends StatelessWidget {
  final String imageUrl;

  const FullScreenImage({Key? key, required this.imageUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(imageUrl),
        ),
      ),
    );
  }
}