// import 'dart:html' as html;
import 'dart:math';
import 'package:apskina/pages/admin/detail_transaksi.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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

  // Data contoh
  final List<Map<String, String>> _appointmentData = [
    {
      'id': 'CT100401',
      'nama': 'Michael David',
      'tipe': 'OFFLINE',
      'pic': 'dr. Intan',
      'status': 'SELESAI',
      'tanggal': '10/04/2025'
    },
    {
      'id': 'CT100402',
      'nama': 'Ronald Vaness',
      'tipe': 'ONLINE',
      'pic': 'dr. Intan',
      'status': 'SELESAI',
      'tanggal': '15/04/2025'
    },
    {
      'id': 'CT100403',
      'nama': 'Ardianus Sebastian',
      'tipe': 'ONLINE',
      'pic': 'dr. Cindy',
      'status': 'SELESAI',
      'tanggal': '20/04/2025'
    },
    {
      'id': 'CT100404',
      'nama': 'Michael Susanto',
      'tipe': 'NON-MEDIS',
      'pic': 'Terapis',
      'status': 'SELESAI',
      'tanggal': '25/04/2025'
    },
    {
      'id': 'CT100405',
      'nama': 'Susan',
      'tipe': 'OFFLINE',
      'pic': 'dr. Cindy',
      'status': 'SELESAI',
      'tanggal': '30/04/2025'
    },
    {
      'id': 'CT100406',
      'nama': 'John Doe',
      'tipe': 'OFFLINE',
      'pic': 'dr. Intan',
      'status': 'SELESAI',
      'tanggal': '05/05/2025'
    },
    {
      'id': 'CT100407',
      'nama': 'Jane Smith',
      'tipe': 'ONLINE',
      'pic': 'dr. Intan',
      'status': 'SELESAI',
      'tanggal': '10/05/2025'
    },
  ];

  final List<Map<String, String>> _transaksiData = [
    {
      'id': 'CT100401',
      'tanggal': '10/04/2025',
      'nama': 'Michael David',
      'tipe': 'OFFLINE',
      'pic': 'dr. Intan',
      'total': '345.000',
    },
    {
      'id': 'CT100402',
      'tanggal': '15/04/2025',
      'nama': 'Ronald Vaness',
      'tipe': 'ONLINE',
      'pic': 'dr. Intan',
      'total': '540.000',
    },
    {
      'id': 'CT100403',
      'tanggal': '20/04/2025',
      'nama': 'Ardianus Sebastian',
      'tipe': 'ONLINE',
      'pic': 'dr. Cindy',
      'total': '420.000',
    },
  ];

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
          return doctor['nama']?.toString() ?? '';
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
      final filteredData = _getFilteredAppointmentData();

      if (filteredData.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak ada data untuk di-export')),
        );
        return;
      }

      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              children: [
                pw.Text(
                  'LAPORAN RESERVASI KLINIK APSKINA',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromInt(0xFF109E88),
                  ),
                ),

                if (_isFilterActive && _startDate != null && _endDate != null)
                  pw.Text(
                    'Periode: ${_formatDate(_startDate)} - ${_formatDate(_endDate)}',
                    style: const pw.TextStyle(fontSize: 12),
                  ),

                pw.SizedBox(height: 20),

                pw.TableHelper.fromTextArray(
                  context: context,
                  headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                  headerDecoration: pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFF109E88),
                  ),
                  data: <List<dynamic>>[
                    ['ID', 'Nama Pasien', 'Tipe', 'PIC', 'Status', 'Tanggal'],
                    for (var appointment in filteredData)
                      [
                        appointment['id'] ?? '',
                        appointment['nama'] ?? '',
                        appointment['tipe'] ?? '',
                        appointment['pic'] ?? '',
                        appointment['status'] ?? '',
                        appointment['tanggal'] ?? '',
                      ],
                  ],
                ),
              ],
            );
          },
        ),
      );

      final bytes = await pdf.save();

      // Platform-specific handling
      // if (kIsWeb) {
      //   // Untuk Web
      //   final blob = html.Blob([bytes], 'application/pdf');
      //   final url = html.Url.createObjectUrlFromBlob(blob);
      //
      //   final fileName = 'Laporan_Reservasi_${DateTime.now().millisecondsSinceEpoch}.pdf';
      //
      //   final anchor = html.AnchorElement(href: url)
      //     ..setAttribute('download', fileName)
      //     ..click();
      //
      //   html.Url.revokeObjectUrl(url);
      // } else {
      //   // Untuk Mobile/Desktop
      //   await Printing.layoutPdf(
      //     onLayout: (PdfPageFormat format) async => bytes,
      //     name: 'Laporan_Reservasi_${DateTime.now().toString().split(' ')[0]}',
      //   );
      // }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Laporan berhasil di-download')),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
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

  void _applyFilter() {
    if (_startDate != null && _endDate != null) {
      setState(() {
        _isFilterActive = true;
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Pilih Tanggal';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  DateTime _parseDate(String dateString) {
    final parts = dateString.split('/');
    return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
  }

  List<Map<String, String>> _getFilteredAppointmentData() {
    if (!_isFilterActive || _startDate == null || _endDate == null) return _appointmentData;

    return _appointmentData.where((appointment) {
      final appointmentDate = _parseDate(appointment['tanggal']!);
      return appointmentDate.isAfter(_startDate!.subtract(Duration(days: 1))) &&
          appointmentDate.isBefore(_endDate!.add(Duration(days: 1)));
    }).toList();
  }

  List<Map<String, String>> _getFilteredTransaksiData() {
    if (!_isFilterActive || _startDate == null || _endDate == null) return _transaksiData;

    return _transaksiData.where((transaksi) {
      final transaksiDate = _parseDate(transaksi['tanggal']!);
      return transaksiDate.isAfter(_startDate!.subtract(Duration(days: 1))) &&
          transaksiDate.isBefore(_endDate!.add(Duration(days: 1)));
    }).toList();
  }

  // Fungsi untuk mendapatkan data chart semua dokter dari database
  List<DoctorChartData> _getDoctorChartData() {
    final filteredData = _getFilteredAppointmentData();

    // Hitung jumlah appointment per dokter dari data yang difilter
    final doctorCounts = <String, int>{};

    for (var appointment in filteredData) {
      final doctor = appointment['pic']!;
      doctorCounts[doctor] = (doctorCounts[doctor] ?? 0) + 1;
    }

    // Buat data chart untuk SEMUA dokter dari database
    final List<DoctorChartData> chartData = [];

    for (int i = 0; i < _allDoctorsFromDatabase.length; i++) {
      final doctor = _allDoctorsFromDatabase[i];
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
        border: Border.all(color: Colors.grey.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Semua Dokter - Jumlah Reservasi',
            style: TextStyle(
              fontFamily: 'Afacad',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF109E88),
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Menampilkan semua dokter dari database, termasuk yang tidak memiliki reservasi pada periode terpilih',
            style: TextStyle(
              fontFamily: 'Afacad',
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
          SizedBox(height: 16),
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
                          fontSize: 14,
                        ),
                        children: [
                          TextSpan(
                            text: count == 0
                                ? 'Tidak ada reservasi'
                                : '$count reservasi',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
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
                            child: RotatedBox(
                              quarterTurns: 1,
                              child: Text(
                                chartData[index].doctor,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.black,
                                  fontFamily: 'Afacad',
                                  fontWeight: chartData[index].appointmentCount > 0
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          );
                        }
                        return Text('');
                      },
                      reservedSize: 80, // Lebih banyak ruang untuk nama dokter yang panjang
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
                            fontSize: 12,
                            color: Colors.black,
                            fontFamily: 'Afacad',
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
                            fontSize: 11,
                            fontFamily: 'Afacad',
                            color: Colors.black,
                            fontWeight: hasReservations ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        SizedBox(width: 4),
                        Text(
                          '(${data.appointmentCount})',
                          style: TextStyle(
                            fontSize: 11,
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
                fontSize: 16,
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
                fontSize: 16,
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
            fontSize: 16,
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
            fontSize: 16,
            color: Color(0xFF109E88),
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        Card(
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
                      columnSpacing: 0,
                      horizontalMargin: 0,
                      dataRowHeight: 75,
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
                        _buildDataColumnAppointment('ID'),
                        _buildDataColumnAppointment('Nama Pasien'),
                        _buildDataColumnAppointment('Tipe'),
                        _buildDataColumnAppointment('PIC'),
                        _buildDataColumnAppointment('Status'),
                        _buildDataColumnAppointment('Tanggal')
                      ],
                      rows: filteredData.map((appointment) =>
                          _buildDataRowAppointment(
                              appointment['id']!,
                              appointment['nama']!,
                              appointment['tipe']!,
                              appointment['pic']!,
                              appointment['status']!,
                              appointment['tanggal']!
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
    final filteredData = _getFilteredTransaksiData();
    final totalData = _transaksiData.length;
    final filteredCount = filteredData.length;

    return Column(
      children: [
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
                      columnSpacing: 0,
                      horizontalMargin: 0,
                      dataRowHeight: 75,
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
                        _buildDataColumn('ID'),
                        _buildDataColumn('Tanggal'),
                        _buildDataColumn('Nama Pasien'),
                        _buildDataColumn('Tipe'),
                        _buildDataColumn('PIC'),
                        _buildDataColumn('Total'),
                        _buildDataColumn('Aksi'),
                      ],
                      rows: filteredData.map((transaksi) =>
                          _buildDataRow(
                            transaksi['id']!,
                            transaksi['tanggal']!,
                            transaksi['nama']!,
                            transaksi['tipe']!,
                            transaksi['pic']!,
                            transaksi['total']!,
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
              fontSize: 20,
              color: const Color(0xFF109E88),
            ),
          ),
        ),
      ),
    );
  }

  DataRow _buildDataRow(
      String id,
      String tanggal,
      String name,
      String type,
      String pic,
      String total,
      ) {
    return DataRow(
      cells: [
        _buildDataCell(id),
        _buildDataCell(tanggal),
        _buildDataCell(name),
        DataCell(
          Center(
            child: Container(
              width: 150,
              height: 45,
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
        _buildDataCell(total),
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
                      builder: (context) => DetailTransaksi(),
                    ),
                  );
                },
              ),
            )
        )
      ],
    );
  }

  void _showDetailTransaksi(String id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Detail Transaksi $id'),
          content: Text('Detail informasi untuk transaksi $id akan ditampilkan di sini.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  DataColumn _buildDataColumnAppointment(String label) {
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
              fontSize: 20,
              color: const Color(0xFF109E88),
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
      String status,
      String tanggal,
      ) {
    return DataRow(
      cells: [
        _buildDataCell(id),
        _buildDataCell(name),
        DataCell(
          Center(
            child: Container(
              width: 150,
              height: 45,
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
        DataCell(
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 150,
                height: 45,
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
        _buildDataCell(tanggal)
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