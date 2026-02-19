import 'package:flutter/material.dart';
import '../../navigasi/navigasi_sidebar_dokpis.dart';
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
          NavigationSidebarDokpis(
            currentIndex: 1,
            context: context,
          ),
          Expanded(
            child: JadwalDokContent(),
          ),
        ],
      ),
    );
  }
}

class JadwalDokContent extends StatelessWidget {
  const JadwalDokContent({Key? key}) : super(key: key);

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
                  children: [
                    _buildAppointmentCard(
                      date: "24 Agustus 2025",
                      time: "11.00",
                      type: "OFFLINE",
                      patientName: "Gaby Paulina",
                      patientAge: "22 tahun",
                      context: context,
                    ),
                  ],
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
                  children: [
                    _buildAppointmentCard(
                      date: "10 April 2025",
                      time: "11.15",
                      type: "ONLINE",
                      patientName: "Michael David",
                      patientAge: "22 tahun",
                      context: context,
                    ),
                    _buildAppointmentCard(
                      date: "10 April 2025",
                      time: "14.00",
                      type: "OFFLINE",
                      patientName: "Jessica Sonieso",
                      patientAge: "18 tahun",
                      context: context,
                    ),
                    // Appointment ketiga akan otomatis berada di baris berikutnya
                    _buildAppointmentCard(
                      date: "10 April 2025",
                      time: "16.30",
                      type: "ONLINE",
                      patientName: "John Doe",
                      patientAge: "35 tahun",
                      context: context,
                    ),
                  ],
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

  Widget _buildAppointmentCard({
    required String date,
    required String time,
    required String type,
    required String patientName,
    required String patientAge,
    required BuildContext context
  }) {
    return SizedBox(
      height: 80, // Height tetap untuk card appointment
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
                  Container(
                    width: 80,
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
                          fontSize: 16,
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
                  fontSize: 16, // Font size dikurangi
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
                          fontSize: 16, // Font size dikurangi
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF109E88),
                        ),
                      ),
                      const SizedBox(width: 4), // Spasi dikurangi
                      Text(
                        "$patientName / $patientAge",
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
                          builder: (context) => DetailAppointment(reservation: {},),
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