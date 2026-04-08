// pages/dokter/ruang_konsultasi_dokter.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import 'package:http/http.dart' as http;


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

  @override
  void initState() {
    super.initState();
    // _connectWebSocket();
    _loadChatHistory();
  }

  // void _connectWebSocket() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final userData = prefs.getString('userData');
  //   final userId = userData != null ? jsonDecode(userData)['id'] : 'doctor_${DateTime.now().millisecondsSinceEpoch}';
  //
  //   WebSocketService.connect(
  //     widget.reservation['_id'],
  //     'doctor',
  //     userId,
  //   );
  //
  //   WebSocketService.setOnMessageCallback((data) {
  //     setState(() {
  //       _messages.add(Message(
  //         text: data['text'],
  //         image: data['image'],
  //         time: DateTime.parse(data['time']),
  //         isUser: data['isUser'],
  //       ));
  //     });
  //   });
  //
  //   setState(() {
  //     _isConnected = true;
  //   });
  // }

  Future<void> _loadChatHistory() async {
    try {
      // Implementasi untuk memuat riwayat chat dari database
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/chat/${widget.reservation['_id']}'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _messages.clear();
          _messages.addAll((data['messages'] as List).map((msg) => Message.fromJson(msg)).toList());
        });
      }
    } catch (e) {
      print('Error loading chat history: $e');
    }
  }

  void _sendMessage() {
    // if (_messageController.text.isEmpty) return;
    //
    // WebSocketService.sendMessage(_messageController.text);
    //
    // setState(() {
    //   _messages.add(Message(
    //     text: _messageController.text,
    //     time: DateTime.now(),
    //     isUser: false, // Dokter mengirim
    //   ));
    // });
    //
    // _messageController.clear();
  }

  Future<void> _pickImage() async {
    // try {
    //   final XFile? pickedFile = await _picker.pickImage(
    //     source: ImageSource.gallery,
    //     imageQuality: 70,
    //   );
    //
    //   if (pickedFile != null) {
    //     // Convert image to base64 and send
    //     final bytes = await pickedFile.readAsBytes();
    //     final base64Image = base64Encode(bytes);
    //
    //     WebSocketService.sendMessage('', image: base64Image);
    //
    //     setState(() {
    //       _messages.add(Message(
    //         text: '',
    //         image: base64Image,
    //         time: DateTime.now(),
    //         isUser: false,
    //       ));
    //     });
    //   }
    // } catch (e) {
    //   print('Error picking image: $e');
    // }
  }

  @override
  void dispose() {
    // WebSocketService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF109E88),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.reservation['namaPasien'] ?? 'Pasien',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              'Konsultasi Berlangsung',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(
                  _isConnected ? Icons.circle : Icons.circle_outlined,
                  color: _isConnected ? Colors.green : Colors.red,
                  size: 12,
                ),
                SizedBox(width: 4),
                Text(
                  _isConnected ? 'TERHUBUNG' : 'MENGHUBUNGKAN',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
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
                IconButton(
                  icon: Icon(Icons.photo_library, color: Color(0xFF109E88)),
                  onPressed: _pickImage,
                ),
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
    final isUser = message.isUser;
    final time = DateFormat('HH:mm').format(message.time);

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser)
            CircleAvatar(
              backgroundColor: Colors.grey[300],
              child: Icon(Icons.person, color: Colors.white, size: 18),
              radius: 16,
            ),
          SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isUser ? Colors.grey[200] : Color(0xFF109E88),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                      bottomLeft: isUser ? Radius.circular(16) : Radius.circular(4),
                      bottomRight: isUser ? Radius.circular(4) : Radius.circular(16),
                    ),
                  ),
                  child: message.image != null
                      ? Image.memory(
                    base64Decode(message.image!),
                    width: 200,
                    height: 200,
                    fit: BoxFit.cover,
                  )
                      : Text(
                    message.text,
                    style: TextStyle(
                      color: isUser ? Colors.black : Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          if (isUser)
            SizedBox(width: 8),
          if (isUser)
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

  Message({
    required this.text,
    this.image,
    required this.time,
    required this.isUser,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      text: json['text'] ?? '',
      image: json['image'],
      time: DateTime.parse(json['time']),
      isUser: json['isUser'] ?? false,
    );
  }
}