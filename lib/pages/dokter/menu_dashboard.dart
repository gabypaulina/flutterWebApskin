import 'dart:convert';
import 'package:apskina/services/socket_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../navigasi/navigasi_sidebar_dokpis.dart';
import '../../services/api_service.dart';
import 'detail_appointment.dart';
import 'package:http/http.dart' as http;
import '../dokter/notification_widget.dart';

class MenuDashboardDok extends StatefulWidget {
  const MenuDashboardDok({Key? key}) : super(key: key);

  @override
  _MenuDashboardDokState createState() => _MenuDashboardDokState();
}

class _MenuDashboardDokState extends State<MenuDashboardDok> {
  List notifications = [];
  String doctorId = "";
  String doctorName = "";
  bool isLoading = true;
  List<dynamic> todayAppointments = [];

  @override
  void initState() {
    super.initState();
    _initializeDashboard();
  }

  Future<void> _initializeDashboard() async {
    final prefs = await SharedPreferences.getInstance();
    doctorId = prefs.getString('doctorId') ?? "";
    doctorName = prefs.getString('doctorName') ?? "";

    SocketService.connectDoctor(
      doctorName,
          (data) {
        final notifData = data['data'];
        if (notifData == null) return;

        setState(() {
          final id = notifData['_id'] ?? notifData['createdAt'];

          if (!notifications.any((n) =>
          (n['_id'] ?? n['createdAt']) == id)) {
            notifications.insert(0, notifData);
          }
        });
      },
    );

    await _loadAll();
  }

  @override
  void dispose() {
    SocketService.socket?.off("new_notification_dokter");
    super.dispose();
  }

  Future<void> _loadAll() async {
    try{
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      print("TOKEN DASHBOARD: $token");

      final notifdok = await ApiService.fetchNotifDokter(token!);
      // final appointments = await ApiService.getTodayAppointments();

      setState(() {
        notifications = [
          ...notifdok,
          ...notifications,
        ];
        doctorName = prefs.getString('doctorName') ?? "Dokter";
        doctorId = prefs.getString('doctorId') ?? "";
        // todayAppointments = appointments;
        isLoading = false;
      });
    }catch (e) {
      print("Dashboard Error: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> markAsRead() async {
    await ApiService.markAllNotificationsDoctorAsRead();
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
          Expanded(
            child: DashboardDokContent(
              key: ValueKey(doctorName),
                doctorName: doctorName,
                doctorId: doctorId,
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

class DashboardDokContent extends StatefulWidget {
  final String doctorName;
  final String doctorId;
  final bool isLoading;
  final List<dynamic> todayAppointments;
  final List notifications;
  final VoidCallback onMarkRead;

  const DashboardDokContent({
    Key? key,
    required this.doctorName,
    required this.doctorId,
    required this.isLoading,
    required this.todayAppointments,
    required this.notifications,
    required this.onMarkRead,
  }) : super(key: key);

  @override
  _DashboardDokContentState createState() => _DashboardDokContentState();
}

class _DashboardDokContentState extends State<DashboardDokContent> {
  int totalPatients = 0;
  int totalPractices = 0;
  List<dynamic> todayAppointments = [];
  List<dynamic> allReservations = [];
  bool isLoading = true;
  String doctorName = "";

  String _formatTanggal(String dateStr) {
    try {
      final parts = dateStr.split('/');
      if (parts.length != 3) return dateStr;

      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);

      const months = [
        "Januari",
        "Februari",
        "Maret",
        "April",
        "Mei",
        "Juni",
        "Juli",
        "Agustus",
        "September",
        "Oktober",
        "November",
        "Desember"
      ];

      return "$day ${months[month - 1]} $year";
    } catch (e) {
      return dateStr;
    }
  }

  @override
  void initState() {
    super.initState();
    doctorName = widget.doctorName ?? "";
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    String normalize(String s) {
      return s
          .toLowerCase()
          .replaceAll('.', '')
          .replaceAll(' ', '')
          .trim();
    }

    try {
      setState(() {
        isLoading = true;
      });

      final reservationsResponse =
      await ApiService.getDoctorReservations();

      final todayApps = reservationsResponse['todayReservations'] ?? [];
      final allReservations = reservationsResponse['allReservations'] ?? [];

      final doctor = normalize(widget.doctorName);

      final completedReservations = allReservations.where((res) {
        final status = (res['status'] ?? '')
            .toString()
            .toLowerCase()
            .trim();

        final pic = normalize(res['pic'] ?? '');

        final isDone = status.contains('selesai'); // 🔥 lebih aman

        return isDone && pic == doctor;
      }).toList();

      print("WIDGET DOCTOR NAME: ${widget.doctorName}");
      print("NORMALIZED DOCTOR: ${normalize(widget.doctorName)}");

      final uniquePatients = <String>{};

      for (var res in allReservations) {
        final key = res['userId']?.toString() ?? res['namaPasien'];
        uniquePatients.add(key);
      }

      setState(() {
        todayAppointments = todayApps;
        totalPatients = uniquePatients.length;
        totalPractices = completedReservations.length;
        isLoading = false;
      });

      print("ALL: ${allReservations.length}");
      print("SELESAI: ${completedReservations.length}");
      print("UNIQUE PASIEN: ${uniquePatients.length}");
      print(reservationsResponse.keys);

    } catch (e) {
      print('Error fetching dashboard data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  String _getTodayDate() {
    final now = DateTime.now();
    final day = now.day.toString().padLeft(2, '0');
    final month = now.month.toString().padLeft(2, '0');
    final year = now.year.toString();
    return '$day/$month/$year';
  }

// Group reservations by patient and count meetings
  Map<String, Map<String, dynamic>> _getPatientHistory() {
    final patientMap = <String, Map<String, dynamic>>{};

    for (var reservation in allReservations) {
      final patientName = reservation['namaPasien'] ?? 'Unknown Patient';
      final patientId = reservation['userId']?.toString() ?? patientName;

      if (!patientMap.containsKey(patientId)) {
        patientMap[patientId] = {
          'name': patientName,
          'meetingCount': 0,
          'reservations': [],
          'latestReservation': null
        };
      }

      patientMap[patientId]!['meetingCount'] = (patientMap[patientId]!['meetingCount'] as int) + 1;
      patientMap[patientId]!['reservations'].add(reservation);

      // Update latest reservation
      final currentLatest = patientMap[patientId]!['latestReservation'];
      if (currentLatest == null) {
        patientMap[patientId]!['latestReservation'] = reservation;
      } else {
        // Compare dates to find the latest
        try {
          final currentDate = _parseDate(currentLatest['tanggalReservasi']);
          final newDate = _parseDate(reservation['tanggalReservasi']);
          if (newDate.isAfter(currentDate)) {
            patientMap[patientId]!['latestReservation'] = reservation;
          }
        } catch (e) {
          print('Error parsing date: $e');
        }
      }
    }

    return patientMap;
  }

// Helper method to parse date from "dd/mm/yyyy" format
  DateTime _parseDate(String dateStr) {
    try {
      final parts = dateStr.split('/');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
    } catch (e) {
      print('Error parsing date $dateStr: $e');
    }
    return DateTime(2000); // Default old date if parsing fails
  }

  @override
  Widget build(BuildContext context) {
    final patientHistory = _getPatientHistory();

    return Column(
      children: [
        Container(
            padding: const EdgeInsets.only(left: 40.0, top: 16.0, right: 40.0),
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 30),
              ],
            )
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(left: 40.0, bottom: 16.0, right: 40.0),
            child: isLoading
                ? Center(child: CircularProgressIndicator(color: Color(0xFF109E88)))
                : Column(
              children: [
                Row(
                  children: [
                    _buildStatCard('Total Pasien', totalPatients.toString()),
                    const SizedBox(width: 20),
                    _buildStatCard('Total Praktek', totalPractices.toString()),
                  ],
                ),
                const SizedBox(height: 30),
                // Appointments Table Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Appointment hari ini',
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
                _buildTodayAppointments(),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard',
              style: TextStyle(
                fontFamily: 'HindSiliguri',
                fontSize: 30,
                color: const Color(0xFF109E88),
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Selamat Datang, ${widget.doctorName}!',
              style: TextStyle(
                fontFamily: 'Afacad',
                fontSize: 18,
                color: const Color(0xFF109E88),
              ),
            ),
          ],
        ),
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
                icon: const Icon(Icons.notifications, color: Color(0xFF109E88)),
                onPressed: () {
                  showDialog(
                    context: context,
                    barrierColor: Colors.transparent,
                    builder: (_) => Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding:
                        const EdgeInsets.only(top: 80, right: 40),
                        child: NotificationWidget(
                          notifications: widget.notifications,
                          onMarkRead: widget.onMarkRead,
                          onSeeDetail: () {
                            // Bisa arahkan ke halaman appointment dokter
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            if (widget.notifications
                .where((n) => n['isRead'] == false)
                .isNotEmpty)
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
                    widget.notifications
                        .where((n) => n['isRead'] == false)
                        .length
                        .toString(),
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
    );
  }

  Widget _buildStatCard(String title, String value) {
    return SizedBox(
      width: 240,
      height: 150,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: Colors.grey.withOpacity(0.25),
            width: 3,
          ),
        ),
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
                child: Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'HindSiliguri',
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF109E88),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodayAppointments() {
    if (todayAppointments.isEmpty) {
      return Center(
        child: Text(
          'Tidak ada appointment hari ini',
          style: TextStyle(
            fontFamily: 'Afacad',
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 3.5,
      children: todayAppointments.map((appointment) {
        return _buildAppointmentCard(
          date: appointment['tanggalReservasi'] ?? '',
          time: appointment['jamReservasi'] ?? '',
          type: appointment['tipe'] ?? '',
          patientName: appointment['namaPasien'] ?? '',
          patientAge: appointment['age'] != null
              ? appointment['age'].toString()
              : '-',
          context: context,
          appointment: appointment,
        );
      }).toList(),
    );
  }

  Widget _buildAppointmentCard({
    required String date,
    required String time,
    required String type,
    required String patientName,
    required String patientAge,
    required BuildContext context,
    required dynamic appointment,
  }) {
    return SizedBox(
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: Colors.grey.withOpacity(0.25),
            width: 3,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Tanggal: ${_formatTanggal(date)}',
                      style: TextStyle(
                        fontFamily: 'Afacad',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF109E88),
                      ),
                    ),
                  ),
                  Container(
                    width: 120,
                    height: 30,
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      color: _getTypeColor(type),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        type,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontFamily: 'Afacad',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                "Jam: $time",
                style: TextStyle(
                  fontFamily: 'Afacad',
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: const Color(0xFF109E88),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        "Pasien : ",
                        style: TextStyle(
                          fontFamily: 'Afacad',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF109E88),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "$patientName / $patientAge tahun",
                        style: TextStyle(
                          fontFamily: 'Afacad',
                          fontSize: 18,
                          color: const Color(0xFF109E88),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.remove_red_eye,
                      color: const Color(0xFF109E88),
                      size: 24,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailAppointment(reservation: appointment),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  DataRow _buildDataRow(
      String no,
      String name,
      String totalPertemuan,
      dynamic patientData,
      ) {
    return DataRow(
      cells: [
        _buildDataCell(no),
        _buildDataCell(name),
        _buildDataCell(totalPertemuan),
        DataCell(
          Center(
            child: IconButton(
              icon: Icon(
                Icons.remove_red_eye,
                color: const Color(0xFF109E88),
                size: 24,
              ),
              onPressed: () {
                _viewPatientDetails(patientData);
              },
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
          padding: EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Afacad',
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: const Color(0xFF109E88),
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

  void _viewPatientDetails(dynamic patientData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Detail Pasien - ${patientData['name']}',
          style: TextStyle(
            fontFamily: 'Afacad',
            color: Color(0xFF109E88),
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Nama: ${patientData['name']}', style: TextStyle(fontFamily: 'Afacad')),
              Text('Total Pertemuan: ${patientData['meetingCount']}', style: TextStyle(fontFamily: 'Afacad')),
              SizedBox(height: 16),
              Text('Riwayat Reservasi:', style: TextStyle(fontFamily: 'Afacad', fontWeight: FontWeight.bold)),
              ...(patientData['reservations'] as List<dynamic>?)?.take(5).map((reservation) =>
                  Text('• ${reservation['tanggalReservasi']} - ${reservation['tipe']}',
                      style: TextStyle(fontFamily: 'Afacad', fontSize: 14))
              ).toList() ?? [],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Tutup',
              style: TextStyle(
                fontFamily: 'Afacad',
                color: Color(0xFF109E88),
              ),
            ),
          ),
        ],
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
}