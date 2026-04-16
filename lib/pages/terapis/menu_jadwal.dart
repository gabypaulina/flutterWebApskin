import 'dart:async';

import 'package:apskina/navigasi/navigasi_sidebar_terapis.dart';
import 'package:apskina/pages/terapis/detail_appointment_nonmedis.dart';
import 'package:flutter/material.dart';

import '../../services/api_service.dart';

class MenuJadwalTerapis extends StatefulWidget {
  const MenuJadwalTerapis({Key? key}) : super(key: key);

  @override
  _MenuJadwalTerapisState createState() => _MenuJadwalTerapisState();
}

class _MenuJadwalTerapisState extends State<MenuJadwalTerapis> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationSidebarTerapis(
            currentIndex: 1,
            context: context,
          ),
          Expanded(
            child: JadwalTerapisContent(),
          ),
        ],
      ),
    );
  }
}

class JadwalTerapisContent extends StatefulWidget {
  const JadwalTerapisContent({Key? key}) : super(key: key);

  @override
  State<JadwalTerapisContent> createState() => _JadwalTerapisContentState();
}

class _JadwalTerapisContentState extends State<JadwalTerapisContent> {
  List latestTodayReservations = [];
  List todayReservations = [];
  String pic = "";
  bool isLoading = true;

  Timer? timer;

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
      final data = await ApiService.getTerapisReservations();

      setState(() {
        latestTodayReservations = data['latestTodayReservations'] ?? [];
        todayReservations = data['todayReservations'] ?? [];
        pic = data['pic'] ?? "terapis";
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
                  childAspectRatio: 3.8,
                  children: latestTodayReservations.map((appointment) {
                    return _buildAppointmentCard(
                      date: appointment['tanggalReservasi'] ?? '',
                      time: appointment['jamReservasi'] ?? '',
                      treatment: appointment['treatment'] ?? '',
                      patientName: appointment['namaPasien'] ?? '',
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
                  childAspectRatio: 3.8,
                  children: todayReservations.map((appointment) {
                    return _buildAppointmentCard(
                      date: appointment['tanggalReservasi'] ?? '',
                      time: appointment['jamReservasi'] ?? '',
                      treatment: appointment['treatment'] ?? '',
                      patientName: appointment['namaPasien'] ?? '',
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
              'Jadwal Treatment',
              style: TextStyle(
                fontFamily: 'HindSiliguri',
                fontSize: 30,
                color: const Color(0xFF109E88),
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Selamat Datang, Terapis!',
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
          // child: IconButton(
          //   icon: const Icon(Icons.notifications, color: Color(0xFF109E88)),
          //   onPressed: () {
          //     // Handle notification button press
          //   },
          // ),
        ),
      ],
    );
  }

  Widget _buildAppointmentCard({
    required String date,
    required String time,
    required String treatment,
    required String patientName,
    required dynamic appointment,
    required BuildContext context, // Tambahkan parameter context
  }) {
    return SizedBox(
      height: 90, // Height tetap untuk card appointment
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
          padding: const EdgeInsets.all(12.0), // Padding dikurangi
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
                        fontSize: 16, // Font size dikurangi
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF109E88),
                      ),
                    ),
                  ),
                  Text(
                    "Jam: $time",
                    style: TextStyle(
                      fontFamily: 'Afacad',
                      fontWeight: FontWeight.bold,
                      fontSize: 16, // Font size dikurangi
                      color: const Color(0xFF109E88),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6), // Spasi dikurangi
              Row(
                children: [
                  Text(
                    "Treatment : ",
                    style: TextStyle(
                      fontFamily: 'Afacad',
                      fontSize: 16, // Font size dikurangi
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF109E88),
                    ),
                  ),
                  const SizedBox(width: 4), // Spasi dikurangi
                  Text(
                    "$treatment",
                    style: TextStyle(
                      fontFamily: 'Afacad',
                      fontSize: 16, // Font size dikurangi
                      color: const Color(0xFF109E88),
                    ),
                  ),
                ],
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
                          fontSize: 16, // Font size dikurangi
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF109E88),
                        ),
                      ),
                      const SizedBox(width: 4), // Spasi dikurangi
                      Text(
                        "$patientName",
                        style: TextStyle(
                          fontFamily: 'Afacad',
                          fontSize: 16, // Font size dikurangi
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
                          builder: (context) => DetailAppointmentTerapis(appointmentData: appointment ),
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
      case 'OFFLINE':
        return const Color(0xFFFF8000);
      case 'ONLINE':
        return const Color(0xFF59EDAF);
      case 'NON-MEDIS':
        return const Color(0xFFF7D915);
      default:
        return Colors.grey;
    }
  }

}