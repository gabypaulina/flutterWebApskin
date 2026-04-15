import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../navigasi/navigasi_sidebar_dokpis.dart';
import '../../services/api_service.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class HasilKonsultasi extends StatefulWidget {
  final Map<String, dynamic> data;
  final VoidCallback onBack;

  const HasilKonsultasi({
    Key? key,
    required this.data,
    required this.onBack,
  }) : super(key: key);

  @override
  _HasilKonsultasiState createState() => _HasilKonsultasiState();
}

class _HasilKonsultasiState extends State<HasilKonsultasi> {

  Future<pw.MemoryImage> _loadLogo() async {
    final bytes = await rootBundle.load('assets/images/logo.png');
    return pw.MemoryImage(bytes.buffer.asUint8List());
  }

  Future<void> _printResep() async {
    final logo = await _loadLogo();
    final pdf = pw.Document();

    // format tanggal
    String rawDate = widget.data['tanggalReservasi']; // 12/04/2024
    List<String> parts = rawDate.split('/');

    DateTime parsedDate = DateTime(
      int.parse(parts[2]),
      int.parse(parts[1]),
      int.parse(parts[0]),
    );

    String formattedDate =
    DateFormat('dd MMMM yyyy', 'id_ID').format(parsedDate);

    final resepList = List<Map<String, dynamic>>.from(
      widget.data['resep'] ?? [],
    );

    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [

                /// HEADER (judul kiri + logo kanan)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [

                    pw.Text(
                      'Resep Digital',
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(
                      width: 80,
                      height: 80,
                      child: pw.Image(logo),
                    ),

                    // /// LOGO FROM ASSETS
                    // pw.Image(
                    //   logo,
                    //   width: 80,
                    //   height: 80,
                    // ),
                  ],
                ),

                pw.SizedBox(height: 20),

                /// DOKTER
                pw.Text('Oleh : ${widget.data['pic'] ?? '-'}',
                    style: pw.TextStyle(
                        fontSize: 14
                    ),
                ),
                pw.SizedBox(height: 20),

                /// PASIEN
                pw.Text(
                    'Pasien: ${widget.data['namaPasien']}',
                  style: pw.TextStyle(
                    fontSize: 14
                  )
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                    'Umur: ${widget.data['age']} tahun',
                    style: pw.TextStyle(
                    fontSize: 14
                )
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                    'Tanggal: $formattedDate',
                    style: pw.TextStyle(
                        fontSize: 14
                    )
                ),

                pw.SizedBox(height: 20),

                /// RESEP
                pw.Text(
                  'Resep:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
                ),

                pw.SizedBox(height: 10),

                /// LIST RESEP
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey600),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(1), // No
                    1: const pw.FlexColumnWidth(6), // Nama Obat
                    2: const pw.FlexColumnWidth(3), // Dosis (kanan)
                  },
                  children: [
                    /// HEADER TABLE
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('No', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Nama Obat', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Dosis', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                      ],
                    ),

                    /// DATA ROW
                    ...List.generate(resepList.length, (index) {
                      final item = resepList[index];

                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text('${index + 1}'),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text('${item['namaObat']}'),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text('${item['dosis']}'),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.only(left: 40.0, top: 16.0, right: 40.0),
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
                          onPressed: widget.onBack
                        ),
                      ),
                      const SizedBox(width: 15),
                      Text(
                        'Hasil Konsultasi',
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
                            child: Container (
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFF109E88),
                                  width: 1,
                                ),
                              ),
                              padding: const EdgeInsets.all(50),
                              child : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Pertemuan : ',
                                        style: TextStyle(
                                          fontFamily: 'Afacad',
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF109E88),
                                        ),
                                      ),
                                      const SizedBox(width: 20),
                                      Text(
                                        '${widget.data['pertemuan']}',
                                        style: TextStyle(
                                          fontFamily: 'Afacad',
                                          fontSize: 18,
                                          color: const Color(0xFF109E88),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
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
                                            '${widget.data['namaPasien']} / ${widget.data['age']} tahun',
                                            style: TextStyle(
                                              fontFamily: 'Afacad',
                                              fontSize: 18,
                                              color: const Color(0xFF109E88),
                                            ),
                                          ),
                                        ],
                                      ),
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
                                                '${widget.data['tanggalReservasi']}',
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
                                                '${widget.data['jamReservasi']}',
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
                                    ],
                                  ),
                                  const SizedBox(height: 20),

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
                                        '${widget.data['tipe']}',
                                        style: TextStyle(
                                          fontFamily: 'Afacad',
                                          fontSize: 18,
                                          color: const Color(0xFF109E88),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),

                                  Text(
                                    'Catatan Dokter : ',
                                    style: TextStyle(
                                      fontFamily: 'Afacad',
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF109E88),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    '${widget.data['note']}',
                                    style: TextStyle(
                                      fontFamily: 'Afacad',
                                      fontSize: 18,
                                      color: const Color(0xFF109E88),
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  Text(
                                    'Resep Digital : ',
                                    style: TextStyle(
                                      fontFamily: 'Afacad',
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF109E88),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  ElevatedButton(
                                    onPressed: _printResep,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF109E88),
                                    ),
                                    child: Text(
                                      'Lihat / Unduh Resep PDF',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontFamily: 'Afacad',
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
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
}