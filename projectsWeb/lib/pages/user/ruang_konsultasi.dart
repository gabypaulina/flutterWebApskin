import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import 'package:http/http.dart' as http;
import '../../services/socket_service.dart';

class RuangKonsultasi extends StatefulWidget {
  final Map<String, dynamic> reservation;

  const RuangKonsultasi({Key? key, required this.reservation}) : super(key: key);

  @override
  _RuangKonsultasiState createState() => _RuangKonsultasiState();
}

class _RuangKonsultasiState extends State<RuangKonsultasi> {
  final TextEditingController _messageController = TextEditingController();
  final List<Message> _messages = [];
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeSocket();
    _loadChatHistory();
    _updateReservationStatus();
  }

  Future<void> _initializeSocket() async {
    await SocketService.initializeSocket();

    // Perbaiki tipe callback menjadi dynamic Function(dynamic)
    SocketService.on('receive_message', (dynamic data) {
      _handleIncomingMessage(data as Map<String, dynamic>);
    });

    SocketService.on('receive_image', (dynamic data) {
      _handleIncomingImage(data as Map<String, dynamic>);
    });

    // Join room
    SocketService.joinRoom(widget.reservation['_id']);

    // Set status connected
    // setState(() {
    //   _isConnected = SocketService.isConnected;
    // });
  }

  void _handleIncomingMessage(Map<String, dynamic> data) {
    final message = Message(
      text: data['text'] ?? '',
      image: null,
      time: DateTime.parse(data['timestamp'] ?? DateTime.now().toIso8601String()),
      isUser: data['senderType'] == 'user',
    );

    setState(() {
      _messages.insert(0, message); // Insert di awal untuk reverse list
    });
  }

  void _handleIncomingImage(Map<String, dynamic> data) {
    final message = Message(
      text: data['caption'] ?? '',
      image: data['imageUrl'],
      time: DateTime.parse(data['timestamp'] ?? DateTime.now().toIso8601String()),
      isUser: data['senderType'] == 'user',
    );

    setState(() {
      _messages.insert(0, message);
    });
  }

  Future<void> _updateReservationStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.put(
        Uri.parse('${ApiService.baseUrl}/reservasi/${widget.reservation['_id']}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'status': 'berlangsung'
        }),
      );

      if (response.statusCode == 200) {
        print('Status reservasi diperbarui menjadi berlangsung');
      }
    } catch (e) {
      print('Error updating reservation status: $e');
    }
  }

  Future<void> _loadChatHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final chatHistory = await ApiService.getChatHistory(widget.reservation['_id']);
      setState(() {
        _messages.clear();
        _messages.addAll(chatHistory.map((msg) => Message.fromJson(msg)).toList());
        _messages.sort((a, b) => b.time.compareTo(a.time)); // Urutkan terbaru di atas
      });
    } catch (e) {
      print('Error loading chat history: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty && _imageFile == null) return;

    // if (_imageFile != null) {
    //   await _sendImage();
    // } else {
    //   await _sendTextMessage();
    // }

    _messageController.clear();
    setState(() {
      _imageFile = null;
    });
  }

  Future<void> _sendTextMessage() async {
    final messageData = {
      'reservationId': widget.reservation['_id'],
      'text': _messageController.text,
      'senderType': 'user',
      'timestamp': DateTime.now().toIso8601String(),
    };

    // Kirim via socket untuk real-time
    SocketService.sendMessage(messageData);

    // Juga simpan ke database via API
    try {
      await ApiService.sendTextMessage(messageData);
    } catch (e) {
      print('Error saving message: $e');
    }
  }

  // Future<void> _sendImage() async {
  //   try {
  //     if (_imageFile == null) return;
  //
  //     final result = await ApiService.uploadImage(
  //       widget.reservation['_id'],
  //       _imageFile!,
  //     );
  //
  //     if (result['imageUrl'] != null) {
  //       // Kirim via socket untuk real-time
  //       SocketService.sendImage({
  //         'reservationId': widget.reservation['_id'],
  //         'imageUrl': result['imageUrl'],
  //         'senderType': 'user',
  //         'timestamp': DateTime.now().toIso8601String(),
  //       });
  //     } else {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Gagal mengirim gambar: ${result['error']}')),
  //       );
  //     }
  //   } catch (e) {
  //     print('Error sending image: $e');
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Gagal mengirim gambar')),
  //     );
  //   }
  // }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  @override
  void dispose() {
    SocketService.off('receive_message');
    SocketService.off('receive_image');
    SocketService.disconnect();
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
              widget.reservation['doctorInfo']?['nama'] ?? 'dr. Dokter',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              widget.reservation['doctorInfo']?['spesialis'] ?? 'Spesialis',
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
              color: SocketService.isConnected ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              SocketService.isConnected ? 'ONLINE' : 'OFFLINE',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
              padding: EdgeInsets.all(16),
              reverse: true, // Untuk chat terbaru di bawah
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),
          if (_imageFile != null)
            Container(
              padding: EdgeInsets.all(8),
              height: 150,
              child: Stack(
                children: [
                  Image.file(
                    _imageFile!,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _imageFile = null;
                        });
                      },
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.black54,
                        child: Icon(
                          Icons.close,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
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
              backgroundColor: Color(0xFF109E88),
              child: Text(
                'D',
                style: TextStyle(color: Colors.white),
              ),
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
                    color: isUser ? Color(0xFF109E88) : Colors.grey[200],
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                      bottomLeft: isUser ? Radius.circular(16) : Radius.circular(4),
                      bottomRight: isUser ? Radius.circular(4) : Radius.circular(16),
                    ),
                  ),
                  child: message.image != null
                      ? Image.network(
                    '${ApiService.baseUrl}${message.image}',
                    width: 200,
                    height: 200,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: 200,
                        height: 200,
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    },
                  )
                      : Text(
                    message.text,
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.black,
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
              backgroundColor: Colors.grey[300],
              radius: 16,
              child: Icon(Icons.person, color: Colors.white, size: 18),
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
      time: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      isUser: json['senderType'] == 'user',
    );
  }
}