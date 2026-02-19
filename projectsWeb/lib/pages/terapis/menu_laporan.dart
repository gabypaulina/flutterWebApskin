import 'package:apskina/navigasi/navigasi_sidebar_terapis.dart';
import 'package:apskina/pages/terapis/hasil_treatment.dart';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class MenuLaporanTerapis extends StatefulWidget {
  const MenuLaporanTerapis({Key? key}) : super(key: key);

  @override
  _MenuLaporanTerapisState createState() => _MenuLaporanTerapisState();
}

class _MenuLaporanTerapisState extends State<MenuLaporanTerapis> {
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
            child: LaporanTerapisContent(),
          ),
        ],
      ),
    );
  }
}

class LaporanTerapisContent extends StatefulWidget {
  const LaporanTerapisContent({Key? key}) : super(key: key);

  @override
  _LaporanTerapisContentState createState() => _LaporanTerapisContentState();
}

class _LaporanTerapisContentState extends State<LaporanTerapisContent> {
  String _selectedYear = '2025';
  String _selectedMonth = 'Semua';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  final List<String> _years = ['2024', '2025'];

  final List<String> _months = [
    'Semua',
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember'
  ];

  List<Map<String, dynamic>> _allPatients = [];
  List<Map<String, dynamic>> _filteredPatients = [];

  @override
  void initState() {
    super.initState();
    _loadReservations();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadReservations() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Mengambil data reservasi dari API
      final reservations = await ApiService.getPatientHistory();

      // Filter hanya reservasi dengan PIC 'terapis' dan status 'selesai'
      final completedReservations = reservations.where((reservation) {
        return reservation['pic'] == 'terapis' &&
            reservation['status'] == 'selesai';
      }).toList();

      // Format data untuk tabel
      _allPatients = completedReservations.map((reservation) {
        return {
          'id': reservation['id'] ?? '',
          'name': reservation['patientName'] ?? '',
          'age': reservation['patientAge'] ?? '',
          'date': reservation['date'] ?? '',
          'time': reservation['time'] ?? '',
          'treatment': reservation['treatment'] ?? '',
          'reservationId': reservation['_id'] ?? '', // ID asli untuk navigasi
        };
      }).toList();

      setState(() {
        _filteredPatients = _allPatients;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading reservations: $e');
      setState(() {
        _isLoading = false;
      });

      // Fallback data jika API error
      _allPatients = [
        {
          'id': 'CT100401',
          'name': 'Michael David',
          'age': '22 tahun',
          'date': '15/03/2025',
          'time': '08:00 - 09:00',
          'treatment': 'Facial Treatment',
          'reservationId': '1'
        },
        {
          'id': 'CT100402',
          'name': 'Ronald Vaness',
          'age': '21 tahun',
          'date': '22/04/2025',
          'time': '09:00 - 10:00',
          'treatment': 'Acne Treatment',
          'reservationId': '2'
        },
        {
          'id': 'CT100403',
          'name': 'Ardianus Sebastian',
          'age': '19 tahun',
          'date': '10/05/2025',
          'time': '10:00 - 11:00',
          'treatment': 'Whitening Treatment',
          'reservationId': '3'
        },
        {
          'id': 'CT100404',
          'name': 'Jessica Sonieso',
          'age': '18 tahun',
          'date': '05/06/2025',
          'time': '11:00 - 12:00',
          'treatment': 'Relaxation Treatment',
          'reservationId': '4'
        },
        {
          'id': 'CT100405',
          'name': 'John Doe',
          'age': '35 tahun',
          'date': '18/07/2025',
          'time': '13:00 - 14:00',
          'treatment': 'Anti-Aging Treatment',
          'reservationId': '5'
        },
      ];
      _filteredPatients = _allPatients;
      _isLoading = false;
    }
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _filterPatients();
    });
  }

  void _filterPatients() {
    List<Map<String, dynamic>> filtered = _allPatients;

    // Filter berdasarkan pencarian nama
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((patient) {
        return patient['name']!
            .toLowerCase()
            .contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Filter berdasarkan tahun
    filtered = filtered.where((patient) {
      String patientYear = patient['date']!.toString().split('/')[2];
      return patientYear == _selectedYear;
    }).toList();

    // Filter berdasarkan bulan jika bukan "Semua"
    if (_selectedMonth != 'Semua') {
      int selectedMonthIndex = _months.indexOf(_selectedMonth);
      filtered = filtered.where((patient) {
        String patientMonth = patient['date']!.toString().split('/')[1];
        return int.parse(patientMonth) == selectedMonthIndex;
      }).toList();
    }

    setState(() {
      _filteredPatients = filtered;
    });
  }

  void _resetFilter() {
    setState(() {
      _searchController.clear();
      _selectedYear = '2025';
      _selectedMonth = 'Semua';
      _filteredPatients = _allPatients;
    });
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
                _buildSearchFilter(),
                const SizedBox(height: 30),
              ],
            )),
        Expanded(
          child: _isLoading
              ? Center(child: CircularProgressIndicator(color: Color(0xFF109E88)))
              : SingleChildScrollView(
            padding: const EdgeInsets.only(
                left: 40.0, bottom: 16.0, right: 40.0),
            child: Column(
              children: [
                _buildPatientsTable(),
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
              'Laporan Treatment',
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

  Widget _buildSearchFilter() {
    return Row(
      children: [
        // Search Field
        Container(
          width: 250,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFF109E88),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari nama pasien...',
                hintStyle: TextStyle(
                  color: Color(0xFF109E88),
                  fontFamily: 'Afacad',
                  fontSize: 16,
                ),
                border: InputBorder.none,
                icon: Icon(Icons.search, color: Color(0xFF109E88), size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.clear,
                      color: Color(0xFF109E88), size: 18),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
                    : null,
              ),
              style: TextStyle(
                fontFamily: 'Afacad',
                fontSize: 16,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _filterPatients();
                });
              },
            ),
          ),
        ),
        SizedBox(width: 16),
        // Tahun Filter
        Container(
          width: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFF109E88),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedYear,
                isExpanded: true,
                icon: Icon(Icons.arrow_drop_down, color: Color(0xFF109E88)),
                iconSize: 24,
                elevation: 16,
                style: TextStyle(
                  color: Color(0xFF109E88),
                  fontFamily: 'Afacad',
                  fontSize: 16,
                ),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedYear = newValue!;
                    _filterPatients();
                  });
                },
                items: _years.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        SizedBox(width: 16),
        // Bulan Filter
        Container(
          width: 130,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFF109E88),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedMonth,
                isExpanded: true,
                icon: Icon(Icons.arrow_drop_down, color: Color(0xFF109E88)),
                iconSize: 24,
                elevation: 16,
                style: TextStyle(
                  color: Color(0xFF109E88),
                  fontFamily: 'Afacad',
                  fontSize: 16,
                ),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedMonth = newValue!;
                    _filterPatients();
                  });
                },
                items: _months.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        Spacer(),
        // Tombol Reset Filter
        ElevatedButton(
          onPressed: _resetFilter,
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: Color(0xFF109E88),
                width: 1,
              ),
            ),
          ),
          child: Text(
            'Reset Filter',
            style: TextStyle(
              color: Color(0xFF109E88),
              fontFamily: 'Afacad',
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPatientsTable() {
    return Card(
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
                    _buildDataColumn('Nama Pasien'),
                    _buildDataColumn('Tanggal Reservasi'),
                    _buildDataColumn('Jam Reservasi'),
                    _buildDataColumn('Treatment'),
                    _buildDataColumn('Selengkapnya'),
                  ],
                  rows: _filteredPatients.map((patient) {
                    return _buildDataRow(
                      patient['id']!,
                      patient['name']!,
                      patient['date']!,
                      patient['time']!,
                      patient['treatment']!,
                      patient['reservationId']!,
                    );
                  }).toList(),
                ),
              ),
            );
          },
        ),
      ),
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
              fontSize: 16,
              color: const Color(0xFF109E88),
            ),
          ),
        ),
      ),
    );
  }

  DataRow _buildDataRow(String id, String name, String date,
      String time, String treatment, String reservationId) {
    return DataRow(
      cells: [
        _buildDataCell(id),
        _buildDataCell(name),
        _buildDataCell(date),
        _buildDataCell(time),
        _buildDataCell(treatment),
        DataCell(
          Center(
            child: IconButton(
              icon: Icon(
                Icons.remove_red_eye,
                color: const Color(0xFF109E88),
                size: 24,
              ),
              onPressed: () {
                // Navigasi ke halaman detail appointment non-medis
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HasilTreatment(
                      appointmentData: {
                        'id': reservationId,
                        'patientName': name,
                        'date': date,
                        'time': time,
                        'treatment': treatment,
                      },
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
}