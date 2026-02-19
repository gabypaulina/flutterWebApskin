import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../navigasi/navigasi_sidebar_dokpis.dart';
import '../../services/api_service.dart';
import 'detail_appointment.dart';
import 'package:http/http.dart' as http;

class MenuDashboardDok extends StatefulWidget {
  const MenuDashboardDok({Key? key}) : super(key: key);

  @override
  _MenuDashboardDokState createState() => _MenuDashboardDokState();
}

class _MenuDashboardDokState extends State<MenuDashboardDok> {
  String doctorName = "Dokter";
  String doctorId = "";

  @override
  void initState() {
    super.initState();
    _fetchDoctorData();
  }

  Future<void> _fetchDoctorData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      doctorName = prefs.getString('doctorName') ?? "Dokter";
      doctorId = prefs.getString('doctorId') ?? "";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationSidebarDokpis(
            currentIndex: 0,
            context: context,
          ),
          Expanded(
            child: DashboardDokContent(doctorName: doctorName, doctorId: doctorId),
          ),
        ],
      ),
    );
  }
}

class DashboardDokContent extends StatefulWidget {
  final String doctorName;
  final String doctorId;

  const DashboardDokContent({Key? key, required this.doctorName, required this.doctorId}) : super(key: key);

  @override
  _DashboardDokContentState createState() => _DashboardDokContentState();
}

class _DashboardDokContentState extends State<DashboardDokContent> {
  int totalPatients = 0;
  int totalPractices = 0;
  List<dynamic> todayAppointments = [];
  List<dynamic> allReservations = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    try {
      setState(() {
        isLoading = true;
      });

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      // DEBUG: Print doctor info
      print('=== DOCTOR INFO ===');
      print('Doctor Name: ${widget.doctorName}');
      print('Doctor ID: ${widget.doctorId}');

      // Fetch all reservations
      final reservationsResponse = await http.get(
        Uri.parse('${ApiService.baseUrl}/reservasi'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (reservationsResponse.statusCode == 200) {
        final data = jsonDecode(reservationsResponse.body);
        final allReservations = data['data'] ?? [];

        // DEBUG: Print semua reservasi untuk analisis
        print('=== ALL RESERVATIONS ===');
        print('Total reservations: ${allReservations.length}');

        for (var i = 0; i < allReservations.length; i++) {
          final reservation = allReservations[i];
          print('Reservation $i:');
          print('  ID: ${reservation['_id']}');
          print('  Tipe: ${reservation['tipe']}');
          print('  PIC: ${reservation['pic']}');
          print('  Dokter: ${reservation['dokter']}');
          print('  Nama Pasien: ${reservation['namaPasien']}');
          print('  Status: ${reservation['status']}');
          print('  Tanggal: ${reservation['tanggalReservasi']}');
          print('  ---');
        }

        // Filter reservations for this doctor - PERBAIKAN UTAMA
        // Filter reservations for this doctor - APPROACH YANG LEBIH FLEKSIBEL
        final doctorReservations = allReservations.where((reservation) {
          final pic = reservation['pic']?.toString() ?? '';
          final dokterField = reservation['dokter']?.toString() ?? '';
          final tipe = reservation['tipe']?.toString() ?? '';

          // Hanya filter reservasi MEDIS dan KONSULTASI
          if (tipe != 'MEDIS' && tipe != 'KONSULTASI') {
            return false;
          }

          // Normalisasi string untuk comparison
          final normalizedPic = pic.toLowerCase().trim();
          final normalizedDokter = dokterField.toLowerCase().trim();
          final normalizedDoctorName = widget.doctorName.toLowerCase().trim();
          final normalizedDoctorId = widget.doctorId.toLowerCase().trim();

          // Multiple matching strategies
          final matches =
          // Exact matches
          normalizedPic == normalizedDoctorName ||
              normalizedPic == normalizedDoctorId ||
              normalizedDokter == normalizedDoctorName ||
              normalizedDokter == normalizedDoctorId ||

              // Partial matches
              normalizedPic.contains(normalizedDoctorName) ||
              normalizedPic.contains(normalizedDoctorId) ||
              normalizedDokter.contains(normalizedDoctorName) ||
              normalizedDokter.contains(normalizedDoctorId) ||

              // Reverse partial matches
              normalizedDoctorName.contains(normalizedPic) ||
              normalizedDoctorName.contains(normalizedDokter);

          if (matches) {
            print('✅ MATCH FOUND:');
            print('   Reservation PIC: "$pic"');
            print('   Reservation Dokter: "$dokterField"');
            print('   Doctor Name: "${widget.doctorName}"');
            print('   Doctor ID: "${widget.doctorId}"');
          }

          return matches;
        }).toList();

        print('=== FILTERED RESERVATIONS ===');
        print('Doctor reservations count: ${doctorReservations.length}');

        // Calculate total patients (unique patients)
        final uniquePatients = {};
        int completedPractices = 0;

        for (var reservation in doctorReservations) {
          final patientName = reservation['namaPasien'];
          if (patientName != null && patientName.isNotEmpty) {
            uniquePatients[patientName] = true;
          }

          final status = reservation['status']?.toString()?.toLowerCase() ?? '';
          if (status == 'selesai') {
            completedPractices++;
          }
        }

        // Get today's appointments
        final today = _getTodayDate();
        final todayApps = doctorReservations.where((reservation) {
          final reservationDate = reservation['tanggalReservasi']?.toString() ?? '';
          final reservationStatus = reservation['status']?.toString()?.toLowerCase() ?? '';

          return reservationDate == today &&
              (reservationStatus == 'menunggu' ||
                  reservationStatus == 'dikonfirmasi' ||
                  reservationStatus == 'berlangsung');
        }).toList();

        print('Today appointments: ${todayApps.length}');
        print('Total patients: ${uniquePatients.length}');
        print('Completed practices: ${completedPractices}');

        setState(() {
          totalPatients = uniquePatients.length;
          totalPractices = completedPractices;
          todayAppointments = todayApps;
          this.allReservations = doctorReservations;
        });
      } else {
        print('Failed to fetch reservations: ${reservationsResponse.statusCode}');
        print('Response: ${reservationsResponse.body}');
      }

      setState(() {
        isLoading = false;
      });
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
    final patientList = patientHistory.values.toList();

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
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      'Histori Pasien',
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
                _buildPasienTable(patientList)
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
                fontSize: 16,
                color: const Color(0xFF109E88),
              ),
            ),
          ],
        ),
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
              // Handle notification button press
            },
          ),
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
            width: 1,
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
      childAspectRatio: 3.8,
      children: todayAppointments.map((appointment) {
        return _buildAppointmentCard(
          date: appointment['tanggalReservasi'] ?? '',
          time: appointment['jamReservasi'] ?? '',
          type: appointment['tipe'] ?? '',
          patientName: appointment['namaPasien'] ?? '',
          patientAge: 'Umur tidak tersedia', // Default since we don't have birthdate
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
      height: 90,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: Colors.grey.withOpacity(0.25),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Tanggal: $date',
                      style: TextStyle(
                        fontFamily: 'Afacad',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF109E88),
                      ),
                    ),
                  ),
                  Container(
                    width: 80,
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
                          fontSize: 16,
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
                  fontSize: 16,
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
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF109E88),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "$patientName / $patientAge",
                        style: TextStyle(
                          fontFamily: 'Afacad',
                          fontSize: 16,
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

  Widget _buildPasienTable(List<Map<String, dynamic>> patientList) {
    if (patientList.isEmpty) {
      return Center(
        child: Text(
          'Tidak ada histori pasien',
          style: TextStyle(
            fontFamily: 'Afacad',
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: Colors.grey.withOpacity(0.25),
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
                  columnSpacing: 20,
                  horizontalMargin: 20,
                  dataRowHeight: 60,
                  dividerThickness: 1,
                  border: TableBorder(
                    horizontalInside: BorderSide(
                      color: Colors.grey.withOpacity(0.25),
                      width: 1,
                    ),
                    verticalInside: BorderSide(
                      color: Colors.grey.withOpacity(0.25),
                      width: 1,
                    ),
                  ),
                  columns: [
                    _buildDataColumn('No'),
                    _buildDataColumn('Nama Pasien'),
                    _buildDataColumn('Total Pertemuan'),
                    _buildDataColumn('Aksi'),
                  ],
                  rows: patientList.asMap().entries.map((entry) {
                    final index = entry.key;
                    final patient = entry.value;

                    return _buildDataRow(
                      (index + 1).toString(),
                      patient['name'] ?? 'Unknown',
                      patient['meetingCount']?.toString() ?? '0',
                      patient,
                    );
                  }).toList(),
                ),
              ),
            );
          },
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
      case 'OFFLINE':
        return const Color(0xFFFF8000);
      case 'ONLINE':
        return const Color(0xFF59EDAF);
      case 'NON_MEDIS':
        return const Color(0xFFF7D915);
      default:
        return Colors.grey;
    }
  }
}