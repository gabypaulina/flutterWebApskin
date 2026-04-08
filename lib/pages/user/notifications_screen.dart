import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';

class NotificationsScreen extends StatefulWidget {
  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> _notifications = [];
  bool _isLoading = true;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final notifications = await ApiService.getUserNotifications();
      setState(() {
        _notifications = notifications;
        _unreadCount = notifications.where((n) => !n['isRead']).length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat notifikasi')),
      );
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      // Implement API call to mark as read
      // await ApiService.markNotificationAsRead(notificationId);

      setState(() {
        final index = _notifications.indexWhere((n) => n['_id'] == notificationId);
        if (index != -1) {
          _notifications[index]['isRead'] = true;
          _unreadCount--;
        }
      });
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifikasi'),
        backgroundColor: Color(0xFF109E88),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
          ? Center(
        child: Text(
          'Tidak ada notifikasi',
          style: TextStyle(
            fontFamily: 'Afacad',
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
      )
          : ListView.builder(
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          return _buildNotificationItem(notification);
        },
      ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    final isRead = notification['isRead'] ?? false;
    final title = notification['title'] ?? '';
    final body = notification['body'] ?? '';
    final date = _formatDate(notification['sentAt']);
    final type = notification['type'] ?? 'general';

    return ListTile(
      leading: Icon(
        type == 'advertisement' ? Icons.campaign : Icons.notifications,
        color: isRead ? Colors.grey : Color(0xFF109E88),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: 'Afacad',
          fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
          color: isRead ? Colors.grey[700] : Colors.black,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            body,
            style: TextStyle(
              fontFamily: 'Afacad',
              color: isRead ? Colors.grey[600] : Colors.grey[800],
            ),
          ),
          SizedBox(height: 4),
          Text(
            date,
            style: TextStyle(
              fontFamily: 'Afacad',
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
      trailing: !isRead
          ? Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: Color(0xFF109E88),
          shape: BoxShape.circle,
        ),
      )
          : null,
      onTap: () {
        if (!isRead) {
          _markAsRead(notification['_id']);
        }
        // Handle notification tap
      },
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';

    DateTime dateTime;
    if (date is String) {
      dateTime = DateTime.parse(date);
    } else if (date is Map && date['\$date'] != null) {
      dateTime = DateTime.parse(date['\$date']);
    } else {
      return '';
    }

    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}