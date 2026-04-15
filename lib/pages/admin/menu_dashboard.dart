import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../navigasi/navigasi_sidebar.dart';
import '../../services/api_service.dart';
import '../../services/socket_service.dart';
import '../admin/jadwal_reservasi.dart';
import '../admin/notification_widget.dart';

class MenuDashboard extends StatefulWidget {
  const MenuDashboard({Key? key}) : super(key: key);

  @override
  _MenuDashboardState createState() => _MenuDashboardState();
}

class _MenuDashboardState extends State<MenuDashboard> {
  List notifications = [];
  final SocketService socketService = SocketService();
  int totalUsers = 0;
  int totalTransactions = 0;
  bool isLoading = true;
  List<dynamic> todayAppointments = [];


  @override
  void initState() {
    super.initState();
    _loadAll();

    socketService.connect((data) {
      final notifData = data['data'];
      final createdAt = DateTime.parse(notifData['createdAt']);
      final now = DateTime.now();

      // Filter: hanya notif yang dibuat hari ini
      if (createdAt.year == now.year &&
          createdAt.month == now.month &&
          createdAt.day == now.day) {
        setState(() {
          notifications.insert(0, notifData);
        });
      }
    });
  }

  @override
  void dispose() {
    socketService.disconnect();
    super.dispose();
  }

  Future<void> _loadAll() async {
    try {
      final notif = await ApiService.fetchNotifications();
      final users = await ApiService.getTotalUsers();
      final transactions = await ApiService.getTotalTransactions();
      final appointments = await ApiService.getTodayFilteredAppointments();

      setState(() {
        notifications = notif;
        totalUsers = users;
        totalTransactions = transactions;
        todayAppointments = appointments;
        isLoading = false;
      });
    } catch (e) {
      print("Dashboard Error: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> markAsRead() async {
    await ApiService.markAllNotificationsAsRead();
    setState(() {
      for (var notif in notifications) {
        notif['isRead'] = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationSidebar(
            currentIndex: 0,
            context: context,
          ),
          Expanded(
            child: DashboardContent(
              totalUsers: totalUsers,
              totalTransactions: totalTransactions,
              isLoading: isLoading,
              todayAppointments: todayAppointments,
              notifications: notifications,
              onMarkRead: markAsRead,
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardContent extends StatelessWidget {
  final int totalUsers;
  final int totalTransactions;
  final bool isLoading;
  final List<dynamic> todayAppointments;
  final List notifications;
  final VoidCallback onMarkRead;

  const DashboardContent({
    Key? key,
    required this.totalUsers,
    required this.totalTransactions,
    required this.isLoading,
    required this.todayAppointments,
    required this.notifications,
    required this.onMarkRead,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    int unreadCount = notifications.where((n) => n['isRead'] == false).length;
    return Column(
      children: [
        // Header dan Stats Cards yang tetap di atas saat discroll
        Container(
          padding: const EdgeInsets.only(left: 40.0, top: 16.0, right: 40.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dashboard',
                        style: TextStyle(
                          fontFamily: 'HindSiliguri',
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF109E88),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Selamat Datang, Admin!',
                        style: TextStyle(
                          fontFamily: 'Afacad',
                          fontSize: 20,
                          color: const Color(0xFF109E88),
                        ),
                      ),
                    ],
                  ),
                  // Notification Bell
                  Stack(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.25),
                            width: 1,
                          ),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.notifications,
                              color: Color(0xFF109E88)),
                          onPressed: () {
                            showDialog(
                              context: context,
                              barrierColor: Colors.transparent,
                              builder: (_) => Align(
                                alignment: Alignment.topRight,
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 80, right: 40),
                                  child: NotificationWidget(
                                    notifications: notifications,
                                    onMarkRead: onMarkRead,
                                    onSeeDetail: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => JadwalReservasi(),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      if (unreadCount > 0)
                        Positioned(
                          right: 4,
                          top: 4,
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 30),
              // Stats Row - sekarang bagian dari header yang tetap
              isLoading
                  ? Center(child: CircularProgressIndicator(color: Color(0xFF109E88)))
                  : Row(
                  children: [
                    _buildStatCard('Total Pengguna', totalUsers),
                    const SizedBox(width: 20),
                    _buildStatCard('Total Transaksi', totalTransactions),
                ],
              ),
              const SizedBox(height: 30),
              // Appointments Table Title - juga bagian dari header yang tetap
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Reservasi hari ini',
                    style: TextStyle(
                      fontFamily: 'Afacad',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF109E88),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),

        // Hanya tabel appointment yang bisa discroll
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(left: 40.0, bottom: 16.0, right: 40.0),
            child: _buildAppointmentsTable(),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, dynamic value) {
    return SizedBox(
      width: 240,
      height: 150,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: Colors.grey.shade600.withOpacity(0.5),
            width: 2,
          ),
        ),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Afacad',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF109E88),
                ),
              ),
              const SizedBox(height: 18),
              Center(
                child: value is int
                    ? Text(
                  value.toString(),
                  style: TextStyle(
                    fontFamily: 'HindSiliguri',
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF109E88),
                  ),
                )
                    : CircularProgressIndicator(color: Color(0xFF109E88)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppointmentsTable() {
    if (isLoading) {
      return Center(child: CircularProgressIndicator(color: Color(0xFF109E88)));
    }

    if (todayAppointments.isEmpty) {
      return Center(
        child: Text(
          'Tidak ada appointment hari ini',
          style: TextStyle(
            fontFamily: 'Afacad',
            fontSize: 18,
            color: const Color(0xFF109E88),
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias, // 👈 INI PENTING
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: Colors.black,
          width: 1,
        ),
      ),
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.zero,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: DataTable(
                  columnSpacing: 0,
                  horizontalMargin: 0,
                  dataRowHeight: 75,
                  dividerThickness: 1,
                  border: TableBorder(
                    borderRadius: BorderRadius.circular(10),
                    horizontalInside: BorderSide(
                      color: Colors.black,
                      width: 1,
                    ),
                    verticalInside: BorderSide(
                      color: Colors.black,
                      width: 1,
                    ),
                  ),
                  columns: [
                    _buildDataColumn('NAMA PASIEN'),
                    _buildDataColumn('NO. HANDPHONE'),
                    _buildDataColumn('TIPE'),
                    _buildDataColumn('PIC'),
                    _buildDataColumn('WAKTU'),
                    _buildDataColumn('STATUS'),
                    _buildDataColumn('PEMBAYARAN'),

                  ],
                  rows: todayAppointments.map((appointment) {
                    return _buildDataRowFromAppointment(appointment);
                  }).toList(),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  DataRow _buildDataRowFromAppointment(Map<String, dynamic> appointment) {
    final id = appointment['id'] ?? 'N/A';
    final namaPasien = appointment['namaPasien'] ?? 'N/A';
    final tipe = appointment['tipe'] ?? 'N/A';
    final pic = appointment['pic'] ?? 'N/A';
    final waktu = appointment['jamReservasi'] ?? 'N/A';
    final status = appointment['status'] ?? 'MENUNGGU' ;
    final paymentStatus = appointment['paymentStatus'] ?? 'pending';

    // Get phone number from populated user data
    final userData = appointment['userId'] is Map
        ? appointment['userId']
        : {};
    final noHandphone = userData['noHandphone'] ?? 'N/A';

    return DataRow(
      cells: [
        _buildDataCell(namaPasien),
        _buildDataCell(noHandphone),
        DataCell(
          Center(
            child: Container(
              width: 120,
              height: 30,
              decoration: BoxDecoration(
                color: _getTypeColor(tipe),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  tipe,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: 'Afacad',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
        _buildDataCell(pic),
        _buildDataCell(waktu),
        DataCell(
          Center(
            child: Container(
              width: 120,
              height: 30,
              decoration: BoxDecoration(
                color: _getStatusColor(status),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  status.toString().toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: 'Afacad',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
        DataCell(
          Center(
            child: Container(
              width: 100,
              height: 30,
              decoration: BoxDecoration(
                color: _getPaymentColor(paymentStatus),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  paymentStatus.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: 'Afacad',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),

      ],
    );
  }

  DataColumn _buildDataColumn(String label) {
    return DataColumn(
      label: Expanded(
        child: Container(
          color: Color(0xFF109E88),
          padding: EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Afacad',
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  DataCell _buildDataCell(String text) {
    return DataCell(
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'Afacad',
            fontSize: 16,
            color: const Color(0xFF109E88),
          ),
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'MEDIS':
        return const Color(0xFFFF8000);
      case 'KONSULTASI':
        return const Color(0xFF59EDAF);
      case 'NON_MEDIS':
        return const Color(0xFFF7D915);
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'BERLANGSUNG':
        return const Color(0xFFFF0000);
      case 'SELESAI':
        return const Color(0xFFADD11A);
      case 'MENUNGGU':
        return const Color(0xFF37B0FF);
      default:
        return Colors.grey;
    }
  }

  Color _getPaymentColor(String paymentStatus) {
    switch (paymentStatus.toLowerCase()) {
      case 'paid':
        return const Color(0xFF4CAF50); // Green
      case 'pending':
        return const Color(0xFFFF9800); // Orange
      default:
        return Colors.grey;
    }
  }
}