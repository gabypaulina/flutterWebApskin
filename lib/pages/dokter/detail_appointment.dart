import 'dart:convert';
import 'package:apskina/pages/dokter/ruang_konsultasi_dokter.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../navigasi/navigasi_sidebar_dokpis.dart';
import '../../services/api_service.dart';
import 'package:http/http.dart' as http;

class DetailAppointment extends StatefulWidget {
  final Map<String, dynamic> reservation;

  const DetailAppointment({Key? key, required this.reservation}) : super(key: key);

  @override
  _DetailAppointmentState createState() => _DetailAppointmentState();
}

class _DetailAppointmentState extends State<DetailAppointment> {
  bool _isLoading = false;
  bool isConsultationStarted = false;
  bool isCompleted = false;

  List<TextEditingController> treatmentControllers = [TextEditingController()];
  TextEditingController diagnosisController = TextEditingController();
  TextEditingController noteController = TextEditingController();

  String getKeterangan(int value) {
    if (value <= 25) return 'Tidak Konsisten';
    if (value <= 50) return 'Kurang Konsisten';
    if (value <= 75) return 'Cukup Konsisten';
    return 'Sangat Konsisten';
  }

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

  Map<String, dynamic>? getAnswerByQuestionId(int questionId) {
    final qna = widget.reservation['qna'];
    if (qna == null) return null;

    final responses = qna['responses'] as List<dynamic>;

    try {
      return responses.firstWhere(
            (item) => item['questionId'] == questionId,
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> _startConsultation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await ApiService.updateReservationStatus(
          id: widget.reservation['_id'],
          status: 'berlangsung',
      );

      if (success) {
        setState(() {
          widget.reservation['status'] = 'berlangsung';
          isConsultationStarted = true;
        });

        final tipe = widget.reservation['tipe']?.toString().toLowerCase();

        if(tipe == 'konsultasi') {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RuangKonsultasiDokter(
                reservation: widget.reservation,
              ),
            ),
          );

          // 🔥 TAMBAHAN
          if (result == true) {
            setState(() {
              widget.reservation['status'] = 'selesai';
              isCompleted = true;
              isConsultationStarted = false;
            });
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memulai konsultasi')),
        );
      }
    } catch (e) {
      print('Error starting consultation: $e');
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
      final treatments = treatmentControllers
          .map((c) => c.text)
          .where((t) => t.isNotEmpty)
          .toList();

      final success = await ApiService.updateReservationStatus(
        id: widget.reservation['_id'],
        status: 'selesai',
        hasilTreatment: treatments.isNotEmpty ? treatments : null,
        diagnosis: diagnosisController.text.isNotEmpty ? diagnosisController.text: null,
        note: noteController.text.isNotEmpty ? noteController.text : null,
      );

      if (success) {
        setState(() {
          widget.reservation['status'] = 'selesai';
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
    final jenisKulit = getAnswerByQuestionId(1);
    final kondisiKulit = getAnswerByQuestionId(2);
    final sunscreen = getAnswerByQuestionId(3);
    final skincare = getAnswerByQuestionId(5);
    final makanan = getAnswerByQuestionId(6);
    final cepatSaji = getAnswerByQuestionId(7);
    final minuman = getAnswerByQuestionId(8);
    final tidur = getAnswerByQuestionId(9);
    final gangguanTidur = getAnswerByQuestionId(10);
    final avg = int.tryParse(widget.reservation['laporanRutinitasAvg']?.toString() ?? '0') ?? 0;

    print("STATUS UI: ${widget.reservation['status']}");
    return Scaffold(
      body: Row(
        children: [
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
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(left: 40.0, bottom: 16.0, top: 16.0, right: 40.0),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Form Section with left padding
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
                                            _formatTanggal(widget.reservation['tanggalReservasi'] ?? '-'),
                                            style: TextStyle(
                                              fontFamily: 'Afacad',
                                              fontSize: 18,
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
                                            widget.reservation['jamReservasi'] ?? '-',
                                            style: TextStyle(
                                              fontFamily: 'Afacad',
                                              fontSize: 18,
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
                                          style: ButtonStyle(
                                            backgroundColor: MaterialStateProperty.all(
                                              widget.reservation['status'] == 'selesai'
                                                  ? Colors.grey[800]
                                                  : Color(0xFF109E88),
                                            ),
                                            shape: MaterialStateProperty.all(
                                              RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                            ),
                                            padding: MaterialStateProperty.all(
                                              EdgeInsets.symmetric(vertical: 16),
                                            ),
                                          ),
                                          onPressed: _isLoading || widget.reservation['status'] == 'selesai'
                                              ? null
                                              : _startConsultation,
                                          child: _isLoading
                                              ? CircularProgressIndicator(color: Colors.white)
                                              : Text(
                                                  _getStatusButtonText(widget.reservation['status']),
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontFamily: 'Afacad',
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _getStatusDescription(widget.reservation['status']),
                                        style: TextStyle(
                                          fontSize: 16,
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
                                    'Pertemuan ke : ',
                                    style: TextStyle(
                                      fontFamily: 'Afacad',
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF109E88),
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Text(
                                    '${widget.reservation['pertemuan'] ?? '-'}',
                                    style: TextStyle(
                                      fontFamily: 'Afacad',
                                      fontSize: 18,
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
                                    'Pasien : ',
                                    style: TextStyle(
                                      fontFamily: 'Afacad',
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF109E88),
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Text(
                                    '${widget.reservation['namaPasien'] ?? '-'} / ${widget.reservation['age'] ?? '-'} tahun',
                                    style: TextStyle(
                                      fontFamily: 'Afacad',
                                      fontSize: 18,
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
                                    'Tipe : ',
                                    style: TextStyle(
                                      fontFamily: 'Afacad',
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF109E88),
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Text(
                                    widget.reservation['tipe'] ?? '-',
                                    style: TextStyle(
                                      fontFamily: 'Afacad',
                                      fontSize: 18,
                                      color: const Color(0xFF109E88),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 30),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Text(
                                    'Laporan Rutinitas Skincare : ',
                                    style: TextStyle(
                                      fontFamily: 'Afacad',
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF109E88),
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Text(
                                    '$avg% - ${getKeterangan(avg)}',
                                    style: TextStyle(
                                      fontFamily: 'Afacad',
                                      fontSize: 18,
                                      color: const Color(0xFF109E88),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 30),

                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                        flex: 1,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Produk Skincare Yang Digunakan : ',
                                              style: TextStyle(
                                                fontFamily: 'Afacad',
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: const Color(0xFF109E88),
                                              ),
                                            ),
                                            const SizedBox(height: 10),

                                            _buildSkincareTable(),
                                          ],
                                        ),
                                      ),

                                  const SizedBox(width: 20),

                                  Expanded(
                                    flex: 1,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Data Tipe Kulit : ',
                                          style: TextStyle(
                                            fontFamily: 'Afacad',
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF109E88),
                                          ),
                                        ),
                                        const SizedBox(height: 10),

                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(child: _buildItem("Jenis Kulit", jenisKulit)),
                                            Expanded(child: _buildItem("Kondisi Kulit", kondisiKulit)),
                                            Expanded(child: _buildItem("Kebiasaan Makan", makanan)),
                                            Expanded(child: _buildItem("Minuman", minuman)),

                                          ],
                                        ),
                                        const SizedBox(height: 20),

                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  'Penggunaan Sunscreen : ',
                                                  style: TextStyle(
                                                    fontFamily: 'Afacad',
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: const Color(0xFF109E88),
                                                  ),
                                                ),
                                                const SizedBox(height: 10),
                                                Text(
                                                  sunscreen?['answerText'] ?? '-',
                                                  style: TextStyle(
                                                    fontFamily: 'Afacad',
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: const Color(0xFF109E88),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 20),

                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  'Penggunaan Skincare : ',
                                                  style: TextStyle(
                                                    fontFamily: 'Afacad',
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: const Color(0xFF109E88),
                                                  ),
                                                ),
                                                const SizedBox(height: 10),
                                                Text(
                                                  skincare?['answerText'] ?? '-',
                                                  style: TextStyle(
                                                    fontFamily: 'Afacad',
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: const Color(0xFF109E88),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 20),

                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  'Makanan Cepat Saji : ',
                                                  style: TextStyle(
                                                    fontFamily: 'Afacad',
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: const Color(0xFF109E88),
                                                  ),
                                                ),
                                                const SizedBox(height: 10),
                                                Text(
                                                  cepatSaji?['answerText'] ?? '-',
                                                  style: TextStyle(
                                                    fontFamily: 'Afacad',
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: const Color(0xFF109E88),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 20),

                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  'Durasi Tidur : ',
                                                  style: TextStyle(
                                                    fontFamily: 'Afacad',
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: const Color(0xFF109E88),
                                                  ),
                                                ),
                                                const SizedBox(height: 10),
                                                Text(
                                                  tidur?['answerText'] ?? '-',
                                                  style: TextStyle(
                                                    fontFamily: 'Afacad',
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: const Color(0xFF109E88),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 20),

                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  'Gangguan Tidur : ',
                                                  style: TextStyle(
                                                    fontFamily: 'Afacad',
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: const Color(0xFF109E88),
                                                  ),
                                                ),
                                                const SizedBox(height: 10),
                                                Text(
                                                  gangguanTidur?['answerText'] ?? '-',
                                                  style: TextStyle(
                                                    fontFamily: 'Afacad',
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: const Color(0xFF109E88),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 20),

                                          ],
                                        )
                                      ],
                                    ),
                                  )

                                ],
                              ),
                              if (isConsultationStarted && !isCompleted) _buildConsultationForm(),

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

  Widget _buildSkincareTable() {
    List products = widget.reservation['produkSkincare'] ?? [];

    if (products.isEmpty) {
      return Text("Tidak ada data skincare");
    }

    return SizedBox(
      width: double.infinity,
      child: Table(
        border: TableBorder.all(
          color: Colors.grey.withOpacity(0.5),
          width: 2,
          borderRadius: BorderRadius.circular(10)
        ),
        columnWidths: const {
          0: FixedColumnWidth(120),
          1: FlexColumnWidth(),
        },
        children: [
          TableRow(
            children: [
            _buildTableHeaderCell('JENIS'),
            _buildTableHeaderCell('PRODUK'),
            ],
          ),
          ...products.map((product) {
            return TableRow(
              children: [
                _buildTableCell(product['productType'] ?? '-'),
                _buildProductCell(
                  product: product['name'] ?? '-',
                  ingredients: (product['productIngredients'] as List<dynamic>?)
                  ?.join(', ') ?? '-',
                ),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTableHeaderCell(String text) {
    return Padding(
        padding: const EdgeInsets.all(14.0),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'Afacad',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF109E88),
            ),
          ),
        )
    );
  }

  Widget _buildTableCell(String text) {
    return Padding(
        padding: const EdgeInsets.all(14.0),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'Afacad',
              fontSize: 16,
              color: const Color(0xFF109E88),
            ),
          ),
        )
    );
  }

  Widget _buildItem(String title, Map<String, dynamic>? data) {
    final image = data?['answerImage'] ?? 'default.png';
    final rawText = data?['answerText'] ?? '-';
    final text = rawText.contains(':')
        ? rawText.split(':')[0]
        : rawText;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Afacad',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF109E88),
            ),
          ),

          const SizedBox(height: 10),

          Flexible(
            child: Image.asset(
              'assets/images/$image',
              height: 80, // kecilin biar muat
              fit: BoxFit.contain,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            text.toUpperCase(),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis, // ⬅️ penting biar gak overflow
            maxLines: 1,
            style: TextStyle(
              fontFamily: 'Afacad',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF109E88),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCell({required String product, required String ingredients}) {
    return Padding(
      padding: const EdgeInsets.all(14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: Text(
              product,
              style: TextStyle(
                fontFamily: 'Afacad',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF109E88),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              '( $ingredients )',
              style: TextStyle(
                fontFamily: 'Afacad',
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: const Color(0xFF109E88).withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsultationForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),

        // 🔥 TREATMENT
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Treatment Yang Diambil",
              style: TextStyle(
                fontFamily: 'Afacad',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF109E88),
              ),
            ),
            IconButton(
              icon: Icon(Icons.add),
              onPressed: () {
                setState(() {
                  treatmentControllers.add(TextEditingController());
                });
              },
            )
          ],
        ),

        Column(
          children: List.generate(treatmentControllers.length, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TextField(
                controller: treatmentControllers[index],
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
            );
          }),
        ),

        const SizedBox(height: 15),

        Text("Diagnosis",
          style: TextStyle(
            fontFamily: 'Afacad',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF109E88),
          ),
        ),
        const SizedBox(height: 8),
        // 🔥 DIAGNOSIS
        TextField(
          controller: diagnosisController,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
          ),
        ),

        const SizedBox(height: 15),

        Text("Catatan Dokter",
          style: TextStyle(
            fontFamily: 'Afacad',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF109E88),
          ),
        ),
        // 🔥 CATATAN
        TextField(
          controller: noteController,
          maxLines: 4,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
          ),
        ),

        const SizedBox(height: 20),

        // 🔥 BUTTON SELESAI
        SizedBox(
          width: 200,
          child: ElevatedButton(
            style: ButtonStyle(
              // backgroundColor: MaterialStateProperty.all(
              //   widget.reservation['status'] == 'selesai'
              //       ? Colors.grey[800]
              //       : Color(0xFF109E88),
              // ),
              backgroundColor: MaterialStateProperty.all(
                  Color(0xFF109E88)
              ),
              shape: MaterialStateProperty.all(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              padding: MaterialStateProperty.all(
                EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            onPressed: _finishConsultation,
            child: Text(
              "Selesaikan Sesi",
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Afacad',
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}