import 'dart:html' as html;
import 'dart:math';
import 'package:apskina/pages/admin/detail_transaksi.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../../navigasi/navigasi_sidebar.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../services/api_service.dart';
import 'dart:convert';


class MenuLaporan extends StatefulWidget {
  const MenuLaporan({Key? key}) : super(key: key);

  @override
  _MenuLaporanState createState() => _MenuLaporanState();
}

class _MenuLaporanState extends State<MenuLaporan> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationSidebar(
            currentIndex: 5,
            context: context,
          ),
          Expanded(
            child: LaporanContent(),
          ),
        ],
      ),
    );
  }
}

class LaporanContent extends StatefulWidget {
  const LaporanContent({Key? key}) : super(key: key);

  @override
  _LaporanContentState createState() => _LaporanContentState();
}

class DoctorChartData {
  final String doctor;
  final int appointmentCount;
  final Color color;

  DoctorChartData(this.doctor, this.appointmentCount, this.color);
}

class _LaporanContentState extends State<LaporanContent> {
  int _selectedSection = 0;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isFilterActive = false;
  List<String> _allDoctorsFromDatabase = [];
  bool _isLoading = false;
  bool _isLoadingReservasi = false;
  bool _isLoadingPending = false;


  List<Map<String, String>> _appointmentData = [];
  List<Map<String, String>> _transaksiData = [];

  // Warna untuk chart dokter
  final List<Color> _doctorColors = [
    Color(0xFF109E88),
    Color(0xFFFF8000),
    Color(0xFF59EDAF),
    Color(0xFFF7D915),
    Color(0xFF9C27B0),
    Color(0xFF2196F3),
    Color(0xFFE91E63),
    Color(0xFF00BCD4),
    Color(0xFF8BC34A),
    Color(0xFFFFC107),
  ];

  @override
  void initState() {
    super.initState();
    _loadAllDoctors();
    _fetchReservasiLaporan();
    _fetchTransaksiPending();
  }

  String _shortDoctorName(String fullName) {
    if (fullName.contains(',')) {
      return fullName.split(',')[0].trim();
    }
    return fullName;
  }

  Future<void> _fetchReservasiLaporan() async {
    setState(() {
      _isLoadingReservasi = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('${ApiService.basedUrl}/laporan/reservasi'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List data = body['data'];

        setState(() {
          _appointmentData = data.map<Map<String, String>>((item) {
            return {
              'id': item['id'] ?? '-',
              'nama': item['nama'] ?? '-',
              'pic': item['pic'] ?? '-',
              'tanggal': item['tanggal'] ?? '-',
              'status': item['status'] ?? '-',
              'jamReservasi': item['jamReservasi'] ?? '-',
              'tipe':item['tipe'],
              'amount' : item['amount'].toString() ?? '-',
              'paidAt' : item['paidAt'] ?? '-',
              'paymentStatus' : item['paymentStatus'] ?? '-'
            };
          }).toList();

          for (var e in _appointmentData) {
            print("STATUS: ${e['status']} | PAYMENT: ${e['paymentStatus']}");
          }

          _isLoadingReservasi = false;

          print('STATUS CODE: ${response.statusCode}');
          print('BODY: ${response.body}');
        });
      }else {
        print('ERROR STATUS: ${response.statusCode}');
        setState(() {
          _isLoadingReservasi = false;
        });
      }
    } catch (e) {
      print('Error fetch reservasi: $e');
      setState(() {
        _isLoadingReservasi = false;
      });
    }
  }

  Future<void> _fetchTransaksiPending() async {
    setState(() {
      _isLoadingPending = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('${ApiService.basedUrl}/laporan/reservasi/pending'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List data = body['data'];

        setState(() {
          _transaksiData = data.map<Map<String, String>>((item) {
            return {
              'id': item['id'] ?? '-',
              'nama': item['nama'] ?? '-',
              'pic': item['pic'] ?? '-',
              'tanggal': item['tanggal'] ?? '-',
              'status': item['status'] ?? '-',
              'jamReservasi': item['jamReservasi'] ?? '-',
              'tipe':item['tipe'],
              'amount' : item['amount'].toString() ?? '-',
              'paidAt' : item['paidAt'] ?? '-',
              'paymentStatus' : item['paymentStatus'] ?? '-'
            };
          }).toList();

          _isLoadingPending = false;

          print('STATUS CODE: ${response.statusCode}');
          print('BODY: ${response.body}');
        });
      }else {
        print('ERROR STATUS: ${response.statusCode}');
        setState(() {
          _isLoadingPending = false;
        });
      }
    } catch (e) {
      print('Error fetch transaksi pending: $e');
      setState(() {
        _isLoadingPending = false;
      });
    }
  }

  // Method untuk mengambil semua dokter dari database
  Future<void> _loadAllDoctors() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/dokter'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        final List<dynamic> doctorsData = responseBody['data'] ?? [];

        // Ekstrak nama dokter dari data
        final List<String> doctorNames = doctorsData.map<String>((doctor) {
          return _shortDoctorName(doctor['nama']?.toString() ?? '');
        }).where((name) => name.isNotEmpty).toList();

        // Tambahkan 'Terapis' jika belum ada
        if (!doctorNames.contains('Terapis')) {
          doctorNames.add('Terapis');
        }

        setState(() {
          _allDoctorsFromDatabase = doctorNames;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load doctors: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading doctors: $e');
      // Fallback ke data default jika API error
      setState(() {
        _allDoctorsFromDatabase = [
          'dr. Intan',
          'dr. Cindy',
          'Terapis',
          'dr. Anton',
          'dr. Budianto',
          'dr. Diana',
          'dr. Eka',
          'dr. Fajar'
        ];
        _isLoading = false;
      });
    }
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDate: _startDate ?? DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked;
        _checkFilterStatus();
      });
    }
  }

  Future<void> _exportLaporan() async {
    try {
      final filteredData = _getFilteredAppointmentData()
        ..sort((a, b) {
          final dateA = _parseDate(a['tanggal'] ?? '');
          final dateB = _parseDate(b['tanggal'] ?? '');
          return dateA.compareTo(dateB); // ASC (lama → baru)
        });

      print('FILTERED DATA LENGTH: ${filteredData.length}');
      for (var item in filteredData) {
        print('TANGGAL: ${item['tanggal']}');
      }

      if (filteredData.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak ada data untuk di-export')),
        );
        return;
      }

      final pdf = pw.Document();
      
      final logoImage = await imageFromAssetBundle('assets/images/logo.png');

      // GRUP BERDASARKAN TANGGAL RESERVASI
      final Map<DateTime, List<Map<String, String>>> groupedData = {};

      for (var item in filteredData) {
        final rawTanggal = item['tanggal'] ?? '';
        final parsedDate = _parseDate(rawTanggal);

        final key = DateTime(parsedDate.year, parsedDate.month, parsedDate.day);

        if (!groupedData.containsKey(key)) {
          groupedData[key] = [];
        }
        groupedData[key]!.add(item);
      }

      final sortedDates = groupedData.keys.toList()
        ..sort((a, b) => a.compareTo(b));

      // Tentukan periode
      String periode;
      if (_isFilterActive && _startDate != null && _endDate != null) {
        periode = '${_formatDate(_startDate)} - ${_formatDate(_endDate)}';
      } else {
        final now = DateTime.now();
        periode = '${now.day.toString().padLeft(2, '0')} '
            '${_getMonthName(now.month)} ${now.year}';
      }

      final totalReservasi = filteredData.length;

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,

          build: (context) {
            final List<pw.Widget> widgets = [];

            // HEADER
            widgets.add(
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Image(logoImage, width: 80, height: 80),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'LAPORAN RESERVASI',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromInt(0xFF109E88),
                        ),
                      ),
                      pw.Text('Periode: $periode'),
                    ],
                  ),
                ],
              ),
            );

            widgets.add(pw.SizedBox(height: 16));

            // 🔥 INI YANG BENAR: cukup 1 loop saja
            for (var entry in groupedData.entries) {
              final tanggal = _formatDate(entry.key);
              final data = entry.value;

              widgets.add(pw.Text(
                'Tanggal: $tanggal',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromInt(0xFF109E88),
                ),
              ));

              widgets.add(
                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.black),

                    columnWidths: {
                      0: const pw.FlexColumnWidth(2.0), // ID
                      1: const pw.FlexColumnWidth(2.4), // Nama
                      2: const pw.FlexColumnWidth(2.5), // PIC (dibuat stabil & lebih lebar)
                      3: const pw.FlexColumnWidth(1.8), // Tanggal
                      4: const pw.FlexColumnWidth(2.0), // Jam
                    },

                    children: [
                      // HEADER
                      pw.TableRow(
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromInt(0xFF109E88),
                        ),
                        children: [
                          _pdfHeaderCell('ID'),
                          _pdfHeaderCell('Nama'),
                          _pdfHeaderCell('PIC'),
                          _pdfHeaderCell('Tanggal'),
                          _pdfHeaderCell('Jam'),
                        ],
                      ),

                      // DATA
                      ...data.map((e) => pw.TableRow(
                        children: [
                          _pdfCell(e['id']),
                          _pdfCell(e['nama']),

                          // 🔥 INI KUNCI UTAMA: PIC tidak akan mengubah ukuran kolom lagi
                          _pdfCell(e['pic']),

                          _pdfCell(e['tanggal']),
                          _pdfCell(e['jamReservasi']),
                        ],
                      )),
                    ],
                  )
              );

              widgets.add(pw.SizedBox(height: 10));

              // widgets.add(
              //   pw.Align(
              //     alignment: pw.Alignment.centerRight,
              //     child: pw.Text(
              //       'Total Reservasi: ${data.length}',
              //       style: pw.TextStyle(
              //         fontWeight: pw.FontWeight.bold,
              //         color: PdfColor.fromInt(0xFF109E88),
              //       ),
              //     ),
              //   ),
              // );
            }
            widgets.add(pw.SizedBox(height: 20));

            widgets.add(
              pw.Divider(color: PdfColors.grey),
            );

            widgets.add(pw.SizedBox(height: 8));

            widgets.add(
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'TOTAL RESERVASI: $totalReservasi',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromInt(0xFF109E88),
                  ),
                ),
              ),
            );

            return widgets;
          },

          footer: (context) => pw.Align( alignment: pw.Alignment.centerRight, child: pw.Text( 'Halaman ${context.pageNumber} dari ${context.pagesCount}', ), ),
        ),
      );

      final bytes = await pdf.save();

      // Platform-specific handling
      if (kIsWeb) {
        final blob = html.Blob([bytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);

        final fileName = 'Laporan_Reservasi_${DateTime.now().millisecondsSinceEpoch}.pdf';

        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..click();

        html.Url.revokeObjectUrl(url);
      } else {
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => bytes,
          name: 'Laporan_Reservasi_${DateTime.now().toString().split(' ')[0]}',
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Laporan berhasil di-download')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  pw.Widget _pdfHeaderCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Center(
        child: pw.Text(
          text,
          style: pw.TextStyle(
            color: PdfColors.white,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ),
    );
  }

  pw.Widget _pdfCell(String? text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text ?? '-',
        textAlign: pw.TextAlign.center,
        maxLines: 2, // biar nama panjang tidak merusak layout
        overflow: pw.TextOverflow.clip,
      ),
    );
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime(2030),
      initialDate: _endDate ?? (_startDate ?? DateTime.now()),
    );

    if (picked != null) {
      setState(() {
        _endDate = picked;
        _checkFilterStatus();
      });
    }
  }

  void _checkFilterStatus() {
    setState(() {
      _isFilterActive = _startDate != null && _endDate != null;
    });
  }

  void _clearFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _isFilterActive = false;
    });
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Pilih Tanggal';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  DateTime _parseDate(String dateString) {
    try {
      final parsed = DateTime.parse(dateString);
      return DateTime(parsed.year, parsed.month, parsed.day); // 🔥 buang jam & timezone
    } catch (e) {
      final parts = dateString.split('/');
      return DateTime(
        int.parse(parts[2]),
        int.parse(parts[1]),
        int.parse(parts[0]),
      );
    }
  }

  List<Map<String, String>> _getFilteredAppointmentData() {
    if (!_isFilterActive || _startDate == null || _endDate == null) return _appointmentData;

    return _appointmentData.where((appointment) {
      final appointmentDate = _parseDate(appointment['tanggal']!);
      return (appointmentDate.isAtSameMomentAs(_startDate!) ||
          appointmentDate.isAfter(_startDate!)) &&
          (appointmentDate.isAtSameMomentAs(_endDate!) ||
              appointmentDate.isBefore(_endDate!));
    }).toList();
  }

  List<Map<String, String>> _getFilteredTransaksiData() {
    if (!_isFilterActive || _startDate == null || _endDate == null) return _transaksiData;

    return _transaksiData.where((transaksi) {
      final transaksiDate = _parseDate(transaksi['tanggal']!);
      return (transaksiDate.isAtSameMomentAs(_startDate!) ||
          transaksiDate.isAfter(_startDate!)) &&
          (transaksiDate.isAtSameMomentAs(_endDate!) ||
              transaksiDate.isBefore(_endDate!));
    }).toList();
  }

  // Fungsi untuk mendapatkan data chart semua dokter dari database
  List<DoctorChartData> _getDoctorChartData() {
    final filteredData = _getFilteredAppointmentData();

    // Hitung jumlah appointment per dokter dari data yang difilter
    final doctorCounts = <String, int>{};

    for (var appointment in filteredData) {
      final doctor = _shortDoctorName(appointment['pic']!)
          .toLowerCase()
          .trim();
      doctorCounts[doctor] = (doctorCounts[doctor] ?? 0) + 1;
    }

    // Buat data chart untuk SEMUA dokter dari database
    final List<DoctorChartData> chartData = [];

    for (int i = 0; i < _allDoctorsFromDatabase.length; i++) {
      final doctor = _allDoctorsFromDatabase[i].toLowerCase().trim();
      final count = doctorCounts[doctor] ?? 0; // 0 jika tidak ada reservasi
      final color = _doctorColors[i % _doctorColors.length];
      chartData.add(DoctorChartData(doctor, count, color));
    }

    // Urutkan berdasarkan jumlah appointment (descending)
    chartData.sort((a, b) => b.appointmentCount.compareTo(a.appointmentCount));

    return chartData;
  }

  // Widget untuk menampilkan chart semua dokter
  Widget _buildDoctorChart() {
    if (_isLoading) {
      return Container(
        height: 300,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.withOpacity(0.25)),
        ),
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF109E88)),
          ),
        ),
      );
    }

    final chartData = _getDoctorChartData();

    // Hitung maxY dengan buffer 20% (minimal 1 untuk menampilkan bar)
    final maxCount = chartData.isNotEmpty
        ? chartData.map((e) => e.appointmentCount.toDouble()).reduce((a, b) => a > b ? a : b)
        : 1.0;
    final maxY = max(maxCount * 1.2, 1.0);

    return Container(
      height: 500, // Tinggi container ditambah untuk menampung lebih banyak dokter
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.5), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Semua Dokter - Jumlah Reservasi',
            style: TextStyle(
              fontFamily: 'Afacad',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF109E88),
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Menampilkan semua dokter dari database, termasuk yang tidak memiliki reservasi pada periode terpilih',
            style: TextStyle(
              fontFamily: 'Afacad',
              fontSize: 16,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
          SizedBox(height: 20),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                minY: 0,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: Colors.black87,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final doctor = chartData[groupIndex].doctor;
                      final count = chartData[groupIndex].appointmentCount;
                      return BarTooltipItem(
                        '$doctor\n',
                        TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        children: [
                          TextSpan(
                            text: count == 0
                                ? 'Tidak ada reservasi'
                                : '$count reservasi',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < chartData.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              _shortDoctorName(chartData[index].doctor),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black,
                                  fontFamily: 'Afacad',
                                  fontWeight: FontWeight.bold
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                          );
                        }
                        return Text('');
                      },
                      reservedSize: 40, // Lebih banyak ruang untuk nama dokter yang panjang
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        if (value == 0) return Text('0');
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black,
                            fontFamily: 'Afacad',
                            fontWeight: FontWeight.bold
                          ),
                        );
                      },
                      reservedSize: 40,
                    ),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.withOpacity(0.3),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey, width: 1),
                    left: BorderSide(color: Colors.grey, width: 1),
                  ),
                ),
                barGroups: chartData.asMap().entries.map((entry) {
                  final index = entry.key;
                  final data = entry.value;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: data.appointmentCount.toDouble(),
                        color: data.appointmentCount > 0
                            ? data.color
                            : data.color.withOpacity(0.3), // Warna lebih transparan untuk 0 reservasi
                        width: 14,
                        borderRadius: BorderRadius.circular(4),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxY,
                          color: Colors.grey.withOpacity(0.1),
                        ),
                      ),
                    ],
                    showingTooltipIndicators: [0],
                  );
                }).toList(),
              ),
            ),
          ),
          SizedBox(height: 12),
          // Legend dengan scroll horizontal
          Container(
            height: 80,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: chartData.map((data) {
                  final hasReservations = data.appointmentCount > 0;
                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: 4),
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: data.color.withOpacity(hasReservations ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: data.color,
                        width: hasReservations ? 1 : 0.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          color: data.color,
                        ),
                        SizedBox(width: 6),
                        Text(
                          data.doctor,
                          style: TextStyle(
                            fontSize: 13,
                            fontFamily: 'Afacad',
                            color: Colors.black,
                            fontWeight: hasReservations ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        SizedBox(width: 4),
                        Text(
                          '(${data.appointmentCount})',
                          style: TextStyle(
                            fontSize: 13,
                            fontFamily: 'Afacad',
                            color: hasReservations ? Colors.black : Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.only(left: 40.0, top: 16.0, right: 40.0),
          child: _buildHeader(),
        ),
        const SizedBox(height: 30),

        // Button Selector (APPOINTMENT/TRANSAKSI)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: _buildButtonSelector(),
        ),
        const SizedBox(height: 30),

        // Filter Periode (2 Kotak Terpisah)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: _buildFilterSection(),
        ),
        const SizedBox(height: 30),

        // Content yang bisa discroll
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(left: 40.0, bottom: 16.0, right: 40.0),
            child: _buildCurrentSection(),
          ),
        ),
      ],
    );
  }

  // ... (sisanya tetap sama - _buildHeader, _buildButtonSelector, _buildFilterSection, dll.)
  // Pastikan semua method lainnya seperti _buildHeader, _buildButtonSelector, dll. tetap ada

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Laporan',
              style: TextStyle(
                fontFamily: 'HindSiliguri',
                fontSize: 30,
                color: const Color(0xFF109E88),
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Selamat Datang, Admin!',
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
            onPressed: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildButtonSelector() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => setState(() => _selectedSection = 0),
            style: ElevatedButton.styleFrom(
              backgroundColor: _selectedSection == 0 ? Color(0xFF109E88) : Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: _selectedSection == 0 ? Colors.transparent : Color(0xFF109E88),
                  width: 1,
                ),
              ),
              elevation: 0,
            ),
            child: Text(
              'LAPORAN RESERVASI',
              style: TextStyle(
                color: _selectedSection == 0 ? Colors.white : Color(0xFF109E88),
                fontWeight: FontWeight.bold,
                fontFamily: 'Afacad',
                fontSize: 20,
              ),
            ),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: () => setState(() => _selectedSection = 1),
            style: ElevatedButton.styleFrom(
              backgroundColor: _selectedSection == 1 ? Color(0xFF109E88) : Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: _selectedSection == 1 ? Colors.transparent : Color(0xFF109E88),
                  width: 1,
                ),
              ),
              elevation: 0,
            ),
            child: Text(
              'LAPORAN PENDAPATAN',
              style: TextStyle(
                color: _selectedSection == 1 ? Colors.white : Color(0xFF109E88),
                fontFamily: 'Afacad',
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Filter Periode:',
          style: TextStyle(
            fontFamily: 'Afacad',
            fontSize: 20,
            color: Color(0xFF109E88),
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 10),
        Row(
          children: [
            // Tanggal Mulai
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _selectStartDate(context),
                icon: Icon(Icons.calendar_today, size: 18, color: Color(0xFF109E88)),
                label: Text(
                  _formatDate(_startDate),
                  style: TextStyle(
                    color: Color(0xFF109E88),
                    fontFamily: 'Afacad',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  side: BorderSide(color: Color(0xFF109E88)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            SizedBox(width: 16),
            Text(
              '-',
              style: TextStyle(
                color: Color(0xFF109E88),
                fontFamily: 'Afacad',
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 16),
            // Tanggal Akhir
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _selectEndDate(context),
                icon: Icon(Icons.calendar_today, size: 18, color: Color(0xFF109E88)),
                label: Text(
                  _formatDate(_endDate),
                  style: TextStyle(
                    color: Color(0xFF109E88),
                    fontFamily: 'Afacad',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  side: BorderSide(color: Color(0xFF109E88)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            SizedBox(width: 16),
            // Tombol hapus
            Expanded(
              child: OutlinedButton(
                onPressed: _clearFilter,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  side: BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'HAPUS FILTER',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.red,
                    fontFamily: 'Afacad',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: () {
                  _exportLaporan();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF109E88),
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'EXPORT LAPORAN',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontFamily: 'Afacad',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCurrentSection() {
    switch (_selectedSection) {
      case 0:
        return _buildAppointmentSection();
      case 1:
        return _buildTransaksiSection();
      default:
        return _buildAppointmentSection();
    }
  }

  Widget _buildAppointmentSection() {
    if (_isLoadingReservasi) {
      return Center(child: CircularProgressIndicator());
    }
    final filteredData = _getFilteredAppointmentData();
    final totalData = _appointmentData.length;
    final filteredCount = filteredData.length;

    return Column(
      children: [
        // Chart Dokter Terlaris
        _buildDoctorChart(),
        SizedBox(height: 30),

        Text(
          _isFilterActive
              ? 'Menampilkan $filteredCount dari $totalData appointment'
              : 'Total Reservasi: $totalData',
          style: TextStyle(
            fontFamily: 'Afacad',
            fontSize: 18,
            color: Color(0xFF109E88),
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        Card(
          elevation: 0,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
            side: BorderSide(
              color: Colors.black,
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
                      columnSpacing: 0,
                      horizontalMargin: 0,
                      dataRowHeight: 75,
                      dividerThickness: 1,
                      border: TableBorder(
                        horizontalInside: BorderSide(
                          color: Colors.black,
                          width: 1,
                        ),
                        verticalInside: BorderSide(
                          color: Colors.black,
                          width: 1,
                        ),
                      ),
                      columns: [
                        _buildDataColumnAppointment('ID'),
                        _buildDataColumnAppointment('NAMA PASIEN'),
                        _buildDataColumnAppointment('TIPE'),
                        _buildDataColumnAppointment('PIC'),
                        _buildDataColumnAppointment('TANGGAL RESERVASI'),
                        _buildDataColumnAppointment('STATUS')
                      ],
                      rows: filteredData.map((appointment) =>
                          _buildDataRowAppointment(
                              appointment['id']!,
                              appointment['nama']!,
                              appointment['tipe']!,
                              appointment['pic']!,
                              appointment['tanggal']!,
                              appointment['status']!
                          )
                      ).toList(),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTransaksiSection() {
    final filteredData = _getFilteredAppointmentData();
    final totalData = _appointmentData.length;
    final filteredCount = filteredData.length;

    final pending = _getFilteredTransaksiData();
    final pendingCount = pending.length;

    return Column(
      children: [
        Text(
          '$pendingCount transaksi tertunda',
          style: TextStyle(
            fontFamily: 'Afacad',
            fontSize: 16,
            color: Color(0xFF109E88),
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        Card(
          elevation: 0,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
            side: BorderSide(
              color: Colors.black,
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
                      columnSpacing: 0,
                      horizontalMargin: 0,
                      dataRowHeight: 75,
                      dividerThickness: 1,
                      border: TableBorder(
                        horizontalInside: BorderSide(
                          color: Colors.black,
                          width: 1,
                        ),
                        verticalInside: BorderSide(
                          color: Colors.black,
                          width: 1,
                        ),
                      ),
                      columns: [
                        _buildDataColumnAppointment('ID'),
                        _buildDataColumnAppointment('NAMA PASIEN'),
                        _buildDataColumnAppointment('TANGGAL'),
                        _buildDataColumnAppointment('TIPE'),
                        _buildDataColumnAppointment('PIC'),
                        _buildDataColumnAppointment('TOTAL'),
                        _buildDataColumnAppointment('DETAIL'),
                      ],
                      rows: pending.map((e) {
                        return DataRow(cells: [
                          _buildDataCell(e['id'] ?? ''),
                          _buildDataCell(e['nama'] ?? ''),
                          _buildDataCell(e['tanggal'] ?? ''),
                          _buildDataCell(e['tipe'] ?? ''),
                          _buildDataCell(e['pic'] ?? ''),
                          _buildDataCell(e['amount'] ?? ''),

                          DataCell(
                            Center(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),

                                onPressed: () async {
                                  final id = e['id'];

                                  if (id == null || id == '-' || id.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text("ID tidak valid")),
                                    );
                                    return;
                                  }

                                  try {
                                    final response = await http.put(
                                      Uri.parse('${ApiService.basedUrl}/reservasi/payment/$id'),
                                      headers: {
                                        'Content-Type': 'application/json',
                                      },
                                      body: jsonEncode({
                                        "paymentStatus": "paid",
                                      }),
                                    );

                                    if (response.statusCode == 200) {
                                      setState(() async {
                                        // 1. HAPUS dari tabel pending transaksi
                                        _transaksiData.removeWhere((item) => item['id'] == id);

                                        // 2. UPDATE di appointment (biar laporan & chart ikut berubah)
                                        final index = _appointmentData.indexWhere((item) => item['id'] == id);

                                        if (index != -1) {
                                          _appointmentData[index]['paymentStatus'] = 'paid';
                                        }

                                        // 🔥 RELOAD SEMUA DATA SEKALIGUS
                                        await _fetchReservasiLaporan();
                                        await _fetchTransaksiPending();
                                      });

                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text("Pembayaran berhasil dikonfirmasi")),
                                      );
                                    } else {
                                      print("ERROR: ${response.body}");

                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text("Gagal konfirmasi pembayaran")),
                                      );
                                    }
                                  } catch (e) {
                                    print("EXCEPTION: $e");

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text("Terjadi kesalahan server")),
                                    );
                                  }
                                },
                                child: Text(
                                  'KONFIRMASI PEMBAYARAN',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontFamily: 'Afacad',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ]);
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        SizedBox(height: 30),

        Text(
          _isFilterActive
              ? 'Menampilkan $filteredCount dari $totalData transaksi'
              : 'Total Transaksi: $totalData',
          style: TextStyle(
            fontFamily: 'Afacad',
            fontSize: 16,
            color: Color(0xFF109E88),
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        Card(
          elevation: 0,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
            side: BorderSide(
              color: Colors.black,
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
                      columnSpacing: 0,
                      horizontalMargin: 0,
                      dataRowHeight: 75,
                      dividerThickness: 1,
                      border: TableBorder(
                        horizontalInside: BorderSide(
                          color: Colors.black,
                          width: 1,
                        ),
                        verticalInside: BorderSide(
                          color: Colors.black,
                          width: 1,
                        ),
                      ),
                      columns: [
                        _buildDataColumnAppointment('ID'),
                        _buildDataColumnAppointment('NAMA PASIEN'),
                        _buildDataColumnAppointment('TANGGAL RESERVASI'),
                        _buildDataColumnAppointment('TIPE'),
                        _buildDataColumnAppointment('PIC'),
                        _buildDataColumnAppointment('TOTAL'),
                        _buildDataColumnAppointment('DETAIL'),
                      ],
                      rows: filteredData.map((transaksi) => _buildDataRow(transaksi)).toList(),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  DataRow _buildDataRow(Map<String, String> transaksi) {
    return DataRow(
      cells: [
        _buildDataCell(transaksi['id'] ?? ''),
        _buildDataCell(transaksi['nama'] ?? ''),
        _buildDataCell(transaksi['tanggal'] ?? ''),
        DataCell(
          Center(
            child: Container(
              width: 100,
              height: 30,
              decoration: BoxDecoration(
                color: _getTypeColor(transaksi['tipe'] ?? ''),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  transaksi['tipe'] ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: 'Afacad',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
        _buildDataCell(transaksi['pic'] ?? ''),
        _buildDataCell(transaksi['amount'] ?? ''),
        DataCell(
            Center(
              child: IconButton(
                icon: Icon(
                  Icons.remove_red_eye,
                  color: const Color(0xFF109E88),
                  size: 24,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetailTransaksi(data: transaksi),
                    ),
                  );
                },
              ),
            )
        )
      ],
    );
  }

  DataColumn _buildDataColumnAppointment(String label) {
    return DataColumn(
      label: Expanded(
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 8),
          color: Color(0xFF109E88),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Afacad',
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  DataRow _buildDataRowAppointment(
      String id,
      String name,
      String type,
      String pic,
      String tanggal,
      String status,
      ) {
    return DataRow(
      cells: [
        _buildDataCell(id),
        _buildDataCell(name),
        DataCell(
          Center(
            child: Container(
              width: 100,
              height: 30,
              decoration: BoxDecoration(
                color: _getTypeColor(type),
                borderRadius: BorderRadius.circular(10),
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
          ),
        ),
        _buildDataCell(pic),
        _buildDataCell(tanggal),
        DataCell(
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(10),
                ),
                child : Center(
                  child: Text(
                    status,
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
        ),
      ],
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

  // Helper: ubah nomor bulan jadi nama bulan
  String _getMonthName(int month) {
    const months = [
      '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return months[month];
  }

  // Helper: load image dari assets
  Future<pw.ImageProvider> imageFromAssetBundle(String path) async {
    final data = await rootBundle.load(path);
    return pw.MemoryImage(data.buffer.asUint8List());
  }
}