import 'package:apskina/pages/dokter/hasil_konsultasi.dart';
import 'package:flutter/material.dart';
import '../../navigasi/navigasi_sidebar_dokpis.dart';
import '../../services/api_service.dart';

class MenuLaporanDok extends StatefulWidget {
  const MenuLaporanDok({Key? key}) : super(key: key);

  @override
  _MenuLaporanState createState() => _MenuLaporanState();
}

class _MenuLaporanState extends State<MenuLaporanDok> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationSidebarDokpis(
            currentIndex: 2,
            context: context,
          ),
          Expanded(
            child: LaporanDokContent(),
          ),
        ],
      ),
    );
  }
}

class LaporanDokContent extends StatefulWidget{
  const LaporanDokContent({Key? key}) : super(key: key);

  @override
  _LaporanDokContentState createState() => _LaporanDokContentState();
}

class _LaporanDokContentState extends State<LaporanDokContent> {
  List<Map<String, dynamic>> _allPatients = [];
  bool isLoading = true;
  late List<String> _years;

  String _selectedYear = DateTime.now().year.toString();
  String _selectedMonth = 'Semua';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

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

  List<Map<String, dynamic>> _filteredPatients = [];

  @override
  void initState() {
    super.initState();

    final currentYear = DateTime.now().year;

    _years = List.generate(currentYear - 2023 + 1, (index) {
      return (currentYear - index).toString();
    });

    _selectedYear = currentYear.toString();

    fetchData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
        return patient['name']!.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Filter berdasarkan tahun
    filtered = filtered.where((patient) {
      String patientYear = patient['date']!.toString().substring(0, 4);
      return patientYear == _selectedYear;
    }).toList();

    // Filter berdasarkan bulan jika bukan "Semua"
    if (_selectedMonth != 'Semua') {
      int selectedMonthIndex = _months.indexOf(_selectedMonth);
      filtered = filtered.where((patient) {
        String patientMonth = patient['date']!.toString().substring(5, 7);
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

  // Fungsi untuk memformat tanggal dari format YYYY-MM-DD ke DD/MM/YYYY
  String _formatDate(String date) {
    List<String> parts = date.split('-');
    if (parts.length == 3) {
      return '${parts[2]}/${parts[1]}/${parts[0]}';
    }
    return date;
  }

  Future<void> fetchData() async {
    try {
      final data = await ApiService.getLaporanDokter();

      setState(() {
        _allPatients = data.map<Map<String, dynamic>>((item) {
          return {
            'id': item['id'],
            'name': item['namaPasien'],
            'age': item['age']?.toString() ?? '-',
            'date': _convertDate(item['tanggalReservasi']),
            'raw': item, // simpan full data
          };
        }).toList();

        _filteredPatients = _allPatients;
        isLoading = false;
      });
    } catch (e) {
      print(e);
    }
  }

  String _convertDate(String date) {
    final parts = date.split('/');
    return "${parts[2]}-${parts[1]}-${parts[0]}"; // jadi YYYY-MM-DD
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
            )
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(left: 40.0, bottom: 16.0, right: 40.0),
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
              'Laporan Konsultasi',
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
                  icon: Icon(Icons.clear, color: Color(0xFF109E88), size: 18),
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
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }
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
                    _buildDataColumn('Umur'),
                    _buildDataColumn('Tanggal Reservasi'),
                    _buildDataColumn('Lihat Detail'),
                  ],
                  rows: _filteredPatients.map((patient) {
                    return _buildDataRow(
                      patient,
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

  DataRow _buildDataRow(
      Map<String, dynamic> patient
      ) {
    return DataRow(
      cells: [
        _buildDataCell(patient['id']),
        _buildDataCell(patient['name']),
        _buildDataCell('${patient['age']} tahun'),
        _buildDataCell(_formatDate(patient['date'])),
        DataCell(
            Center(
              child: IconButton(
                icon: Icon(
                  Icons.remove_red_eye,
                  color: const Color(0xFF109E88),
                  size: 24,
                ),
                onPressed: () {
                  // Fungsi untuk melihat detail pasien
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HasilKonsultasi(data: patient['raw']),
                    ),
                  );
                },
              ),
            )
        )
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