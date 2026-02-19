import 'dart:convert';
import 'package:flutter/material.dart';
import '../../navigasi/navigasi_sidebar_terapis.dart';
import '../../services/api_service.dart';

class DetailAppointmentTerapis extends StatefulWidget {
  final Map<String, dynamic> appointmentData;

  const DetailAppointmentTerapis({Key? key, required this.appointmentData}) : super(key: key);

  @override
  _DetailAppointmentTerapisState createState() => _DetailAppointmentTerapisState();
}

class _DetailAppointmentTerapisState extends State<DetailAppointmentTerapis> {
  String status = 'MULAI TREATMENT';
  bool showInputButton = false;
  bool showResultInput = false;
  TextEditingController hasilTreatmentController = TextEditingController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    // Anda mungkin perlu mengambil status terbaru dari API di sini
  }

  void _confirmStartTreatment() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Konfirmasi"),
          content: Text("Apakah Anda yakin ingin memulai treatment?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Batal"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _updateStatus('berlangsung');
              },
              child: Text("Ya"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() {
      isLoading = true;
    });

    try {
      await ApiService.updateReservationStatus(
        reservationId: widget.appointmentData['id'],
        status: newStatus,
      );

      setState(() {
        status = newStatus == 'berlangsung' ? 'BERLANGSUNG' : 'SELESAI';
        showInputButton = newStatus == 'berlangsung';
        showResultInput = newStatus == 'berlangsung';

        if (newStatus == 'selesai') {
          showInputButton = false;
          showResultInput = false;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status berhasil diubah menjadi $newStatus')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengubah status: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _simpanHasilTreatment() async {
    if (hasilTreatmentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Harap isi hasil treatment terlebih dahulu')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await ApiService.updateReservationStatus(
        reservationId: widget.appointmentData['id'],
        status: 'selesai',
        hasilTreatment: hasilTreatmentController.text,
      );

      setState(() {
        status = 'SELESAI';
        showInputButton = false;
        showResultInput = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hasil treatment berhasil disimpan')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan hasil treatment: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

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
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.only(left: 40.0, bottom: 16.0, top: 16.0, right: 40.0),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF109E88),
                            width: 1,
                          ),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back),
                          color: const Color(0xFF109E88),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Text(
                        'Detail Appointment',
                        style: TextStyle(
                          fontFamily: 'HindSiliguri',
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF109E88),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),

                Expanded(
                  child: isLoading
                      ? Center(child: CircularProgressIndicator(color: Color(0xFF109E88)))
                      : SingleChildScrollView(
                    padding: const EdgeInsets.only(left: 40.0, bottom: 16.0, top: 16.0, right: 40.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 60.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        children: [
                                          Icon(
                                            Icons.calendar_today_outlined,
                                            color: const Color(0xFF109E88),
                                            size: 24,
                                          ),
                                          const SizedBox(width: 20),
                                          Text(
                                            widget.appointmentData['date'],
                                            style: TextStyle(
                                              fontFamily: 'Afacad',
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF109E88),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 40),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        children: [
                                          Icon(
                                            Icons.watch_later_outlined,
                                            color: const Color(0xFF109E88),
                                            size: 24,
                                          ),
                                          const SizedBox(width: 20),
                                          Text(
                                            widget.appointmentData['time'],
                                            style: TextStyle(
                                              fontFamily: 'Afacad',
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF109E88),
                                            ),
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                  SizedBox(
                                    width: 200,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: status == 'MULAI TREATMENT'
                                            ? const Color(0xFF109E88)
                                            : Colors.grey,
                                        padding: EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      onPressed: status == 'MULAI TREATMENT'
                                          ? _confirmStartTreatment
                                          : null,
                                      child: Text(
                                        status,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontFamily: 'Afacad',
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 30),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Text(
                                    'Pasien : ',
                                    style: TextStyle(
                                      fontFamily: 'Afacad',
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF109E88),
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Text(
                                    widget.appointmentData['patientName'],
                                    style: TextStyle(
                                      fontFamily: 'Afacad',
                                      fontSize: 16,
                                      color: const Color(0xFF109E88),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),


                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Text(
                                    'Treatment yang diinginkan : ',
                                    style: TextStyle(
                                      fontFamily: 'Afacad',
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF109E88),
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: Text(
                                      widget.appointmentData['treatment'],
                                      style: TextStyle(
                                        fontFamily: 'Afacad',
                                        fontSize: 16,
                                        color: const Color(0xFF109E88),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 30),

                              // Input Hasil Treatment (muncul hanya ketika status BERLANGSUNG)
                              if (showResultInput)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Hasil Treatment:',
                                      style: TextStyle(
                                        fontFamily: 'Afacad',
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF109E88),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    TextField(
                                      controller: hasilTreatmentController,
                                      maxLines: 5,
                                      decoration: InputDecoration(
                                        hintText: 'Masukkan hasil treatment...',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(
                                            color: Colors.grey.withOpacity(0.25),
                                            width: 1,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(
                                            color: const Color(0xFF109E88),
                                            width: 1,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Center(
                                      child: SizedBox(
                                        width: 200,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF109E88),
                                            padding: EdgeInsets.symmetric(vertical: 16),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                          onPressed: _simpanHasilTreatment,
                                          child: const Text(
                                            'Simpan Hasil',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontFamily: 'Afacad',
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 30),
                                  ],
                                ),

                              // Status Selesai
                              if (status == 'SELESAI')
                                Center(
                                  child: Text(
                                    'Treatment telah selesai',
                                    style: TextStyle(
                                      fontFamily: 'Afacad',
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF109E88),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    hasilTreatmentController.dispose();
    super.dispose();
  }
}