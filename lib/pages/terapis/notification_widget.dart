import 'package:flutter/material.dart';

class NotificationWidget extends StatelessWidget {
  final List notifications;
  final VoidCallback onMarkRead;
  final VoidCallback onSeeDetail;

  const NotificationWidget({
    Key? key,
    required this.notifications,
    required this.onMarkRead,
    required this.onSeeDetail,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    int unreadCount =
        notifications.where((n) => n['isRead'] == false).length;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 320,
        height: 350,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 8,
            )
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Notifikasi",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                  if (unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        unreadCount.toString(),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12),
                      ),
                    )
                ],
              ),
            ),

            const Divider(height: 1),

            Expanded(
              child: notifications.isEmpty
                  ? const Center(child: Text("Tidak ada notifikasi"))
                  : ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  var notif = notifications[index];

                  return ListTile(
                    title: Text(
                      notif['title'] ?? '',
                      style: TextStyle(
                        fontWeight: notif['isRead'] == true
                            ? FontWeight.normal
                            : FontWeight.bold,
                      ),
                    ),
                    subtitle:
                    Text(notif['message'] ?? ''),
                    onTap: onSeeDetail,
                  );
                },
              ),
            ),

            const Divider(height: 1),

            Row(
              mainAxisAlignment:
              MainAxisAlignment.spaceAround,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onSeeDetail();
                  },
                  child: const Text("Lihat Detail"),
                ),
                TextButton(
                  onPressed: () {
                    onMarkRead();
                    Navigator.pop(context);
                  },
                  child: const Text("Tandai Baca"),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}