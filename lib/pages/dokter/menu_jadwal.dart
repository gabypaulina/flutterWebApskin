import 'dart:async';

import 'package:flutter/material.dart';
import '../../navigasi/navigasi_sidebar_dokpis.dart';
import '../../services/api_service.dart';
import 'detail_appointment.dart';

class MenuJadwalDok extends StatefulWidget {
  const MenuJadwalDok({Key? key}) : super(key: key);

  @override
  _MenuJadwalDokState createState() => _MenuJadwalDokState();
}

class _MenuJadwalDokState extends State<MenuJadwalDok> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Expanded(
            child: JadwalDokContent(),
          ),
        ],
      ),
    );
  }
}

class JadwalDokContent extends StatefulWidget {
  const JadwalDokContent({Key? key}) : super(key: key);

  @override
  State<JadwalDokContent> createState() => _JadwalDokContentState();
}

class _JadwalDokContentState extends State<JadwalDokContent> {
  List latestTodayReservations = [];
  List todayReservations = [];
  String doctorName = "";
  bool isLoading = true;

  Timer? timer;

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
    _fetchData();

    // 🔥 AUTO REFRESH tiap 5 detik
    timer = Timer.periodic(Duration(seconds: 5), (Timer t) {
      _fetchData();
    });
  }

  @override
  void dispose() {
    timer?.cancel(); // WAJIB supaya tidak memory leak
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      final data = await ApiService.getDoctorReservations();
      print(todayReservations);

      setState(() {
        latestTodayReservations = data['latestTodayReservations'] ?? [];
        todayReservations = data['todayReservations'] ?? [];
        doctorName = data['doctorName'] ?? "Dokter";
        isLoading = false;
      });
    } catch (e) {
      print("Error fetch: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
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
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Appointment terbaru',
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
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 3.5,
                  children: latestTodayReservations.map((appointment) {
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
                ),
                const SizedBox(height: 30),
                // Appointments Table Title - juga bagian dari header yang tetap

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

                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 3.5,
                  children: todayReservations.map((appointment) {
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
                ),
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
              'Jadwal Janji Temu',
              style: TextStyle(
                fontFamily: 'HindSiliguri',
                fontSize: 30,
                color: const Color(0xFF109E88),
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Selamat Datang, Dokter!',
              style: TextStyle(
                fontFamily: 'Afacad',
                fontSize: 18,
                color: const Color(0xFF109E88),
              ),
            ),
          ],
        ),
      ],
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
          padding: const EdgeInsets.all(18), // Padding dikurangi
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Tanggal: ${_formatTanggal(date)}',
                      style: TextStyle(
                        fontFamily: 'Afacad',
                        fontSize: 18, // Font size dikurangi
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF109E88),
                      ),
                    ),
                  ),
                  Container(
                    width: 120,
                    height: 30,
                    padding: const EdgeInsets.symmetric(horizontal: 5), // Padding dikurangi
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
              const SizedBox(height: 6), // Spasi dikurangi
              Text(
                "Jam: $time",
                style: TextStyle(
                  fontFamily: 'Afacad',
                  fontWeight: FontWeight.bold,
                  fontSize: 18, // Font size dikurangi
                  color: const Color(0xFF109E88),
                ),
              ),
              const SizedBox(height: 20), // Spasi dikurangi
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        "Pasien : ",
                        style: TextStyle(
                          fontFamily: 'Afacad',
                          fontSize: 18, // Font size dikurangi
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF109E88),
                        ),
                      ),
                      const SizedBox(width: 4), // Spasi dikurangi
                      Text(
                        "$patientName / $patientAge tahun",
                        style: TextStyle(
                          fontFamily: 'Afacad',
                          fontSize: 18, // Font size dikurangi
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
                      // Navigasi ke halaman DetailAppointment
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailAppointment(reservation: appointment,),
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

  Color _getTypeColor(String type) {
    switch (type) {
      case 'MEDIS':
        return const Color(0xFFFF8000);
      case 'KONSULTASI':
        return const Color(0xFF59EDAF);
      case 'NON-MEDIS':
        return const Color(0xFFF7D915);
      default:
        return Colors.grey;
    }
  }

}