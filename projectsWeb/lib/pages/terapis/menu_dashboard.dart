import 'package:apskina/navigasi/navigasi_sidebar_terapis.dart';
import 'package:apskina/pages/terapis/detail_appointment_nonmedis.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../services/api_service.dart';

class MenuDashboardTerapis extends StatefulWidget {
  const MenuDashboardTerapis({Key? key}) : super(key: key);

  @override
  _MenuDashboardTerapisState createState() => _MenuDashboardTerapisState();
}

class _MenuDashboardTerapisState extends State<MenuDashboardTerapis> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationSidebarTerapis(
            currentIndex: 0,
            context: context,
          ),
          Expanded(
            child: DashboardTerapisContent(),
          ),
        ],
      ),
    );
  }
}

class DashboardTerapisContent extends StatefulWidget {
  const DashboardTerapisContent({Key? key}) : super(key: key);

  @override
  _DashboardTerapisContentState createState() => _DashboardTerapisContentState();
}

class _DashboardTerapisContentState extends State<DashboardTerapisContent> {
  int totalPasien = 0;
  int totalPraktek = 0;
  List<dynamic> todayAppointments = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      // Get total pasien (non-medis reservations dengan pic = terapis)
      totalPasien = await ApiService.getTotalNonMedisReservations();

      // Get today's non-medis appointments dengan pic = terapis
      todayAppointments = await ApiService.getTodayNonMedisAppointments();

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('Error loading dashboard data: $e');
      setState(() {
        isLoading = false;
      });
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
          child: isLoading
              ? Center(child: CircularProgressIndicator(color: Color(0xFF109E88)))
              : SingleChildScrollView(
            padding: const EdgeInsets.only(left: 40.0, bottom: 16.0, right: 40.0),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildStatCard('Total Pasien', totalPasien.toString()),
                    const SizedBox(width: 20),
                    _buildStatCard('Total Praktek', totalPraktek.toString()),
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
                todayAppointments.isEmpty
                    ? Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    'Tidak ada appointment hari ini',
                    style: TextStyle(
                      fontFamily: 'Afacad',
                      fontSize: 16,
                      color: const Color(0xFF109E88),
                    ),
                  ),
                )
                    : GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 3.8,
                  children: todayAppointments.map((appointment) {
                    return _buildAppointmentCard(
                      date: appointment['tanggalReservasi'],
                      time: appointment['jamReservasi'],
                      treatment: appointment['treatment'] ?? '',
                      patientName: appointment['namaPasien'],
                      context: context,
                      appointmentId: appointment['_id'], status: '',
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
              'Dashboard',
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

  Widget _buildAppointmentCard({
    required String date,
    required String time,
    required String treatment,
    required String patientName,
    required BuildContext context,
    required String appointmentId,
    required String status,

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
                  Text(
                    "Jam: $time",
                    style: TextStyle(
                      fontFamily: 'Afacad',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: const Color(0xFF109E88),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    "Treatment : ",
                    style: TextStyle(
                      fontFamily: 'Afacad',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF109E88),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      treatment,
                      style: TextStyle(
                        fontFamily: 'Afacad',
                        fontSize: 16,
                        color: const Color(0xFF109E88),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
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
                        Expanded(
                          child: Text(
                            "$patientName",
                            style: TextStyle(
                              fontFamily: 'Afacad',
                              fontSize: 16,
                              color: const Color(0xFF109E88),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (status == 'selesai')
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Color(0xFF109E88),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'SELESAI',
                        style: TextStyle(
                          fontFamily: 'Afacad',
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
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
                            builder: (context) => DetailAppointmentTerapis(
                              appointmentData: {
                                'id': appointmentId,
                                'date': date,
                                'time': time,
                                'patientName': patientName,
                                'treatment': treatment,
                                'status': status,
                              },
                            ),
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

}