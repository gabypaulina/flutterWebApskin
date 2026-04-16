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
  // String status = 'MULAI TREATMENT';
  // bool showInputButton = false;
  // bool showResultInput = false;
  bool isConsultationStarted = false;
  bool isCompleted = false;
  TextEditingController treatmentControllers = TextEditingController();
  bool _isLoading = false;

  Future<void> _startConsultation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await ApiService.updateReservationStatus(
        id: widget.appointmentData['_id'],
        status: 'berlangsung',
      );

      if (success) {
        setState(() {
          widget.appointmentData['status'] = 'berlangsung';
          isConsultationStarted = true;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memulai sesi')),
        );
      }
    } catch (e) {
      print('Error starting sesi: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _finishConsultation() async {
    setState(() => _isLoading = true);

    try {
      final treatments = treatmentControllers.text;

      final success = await ApiService.updateReservationStatus(
        id: widget.appointmentData['_id'],
        status: 'selesai',
        diagnosis: treatmentControllers.text.isNotEmpty ? treatmentControllers.text : null,
      );

      if (success) {
        setState(() {
          widget.appointmentData['status'] = 'selesai';
          isCompleted = true;
        });
      }
    } catch (e) {
      print(e);
    } finally {
      setState(() => _isLoading = false);
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
                  child: _isLoading
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
                                            widget.appointmentData['tanggalReservasi'],
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
                                            widget.appointmentData['jamReservasi'],
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
                                  Column(
                                    children: [
                                      SizedBox(
                                        width: 200,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF109E88),
                                            padding: EdgeInsets.symmetric(vertical: 16),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                          onPressed: _isLoading
                                              ? null
                                              : widget.appointmentData['status'] == 'menunggu'
                                              ? _startConsultation
                                              : widget.appointmentData['status'] == 'berlangsung'
                                              ? _finishConsultation
                                              : null,
                                          child: _isLoading
                                              ? CircularProgressIndicator(color: Colors.white)
                                              : Text(
                                            _getStatusButtonText(widget.appointmentData['status']?.toString()),
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontFamily: 'Afacad',
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _getStatusDescription(widget.appointmentData['status']?.toString()),
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontFamily: 'Afacad',
                                          color: Colors.grey,
                                        ),
                                      )
                                    ],
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
                                    '${widget.appointmentData['namaPasien']} / ${widget.appointmentData['age']} tahun',
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

                              _buildConsultationForm(),
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

  String _getStatusButtonText(String? status) {
    switch (status) {
      case 'menunggu':
        return 'MENUNGGU';
      case 'berlangsung':
        return 'SEDANG BERLANGSUNG';
      case 'selesai':
        return 'SELESAI';
      default:
        return 'MULAI';
    }
  }

  String _getStatusDescription(String? status) {
    switch (status) {
      case 'menunggu':
        return 'Klik tombol untuk memulai';
      case 'berlangsung':
        return 'Klik tombol untuk mengakhiri sesi';
      case 'selesai':
        return 'Sesi telah selesai';
      default:
        return 'Klik tombol untuk memulai';
    }
  }

  Widget _buildConsultationForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
            "Hasil Treatment",
            style: TextStyle(
              fontFamily: 'Afacad',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF109E88),
            )
        ),

        const SizedBox(height: 10),

        TextField(
          controller: treatmentControllers,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
          ),
          textAlign: TextAlign.center,
          maxLines: 6,
          style: TextStyle(
            fontFamily: 'Afacad',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF109E88),
          ),
        ),
        const SizedBox(height: 10),
        // 🔥 BUTTON SELESAI
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF109E88),
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: _finishConsultation,
            child: Text(
              'Selesaikan Sesi',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Afacad',
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        )
      ],
    );
  }
}