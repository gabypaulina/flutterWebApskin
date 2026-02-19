import 'package:apskina/pages/admin/tambah_dokter.dart';
import 'package:flutter/material.dart';
import '../../navigasi/navigasi_sidebar.dart';
import '../../services/api_service.dart';

class MenuJadwal extends StatefulWidget {
  const MenuJadwal({Key? key}) : super(key: key);

  @override
  _MenuJadwalState createState() => _MenuJadwalState();
}

class _MenuJadwalState extends State<MenuJadwal> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationSidebar(
            currentIndex: 3,
            context: context,
          ),
          Expanded(
            child: JadwalContent(),
          ),
        ],
      ),
    );
  }
}

class JadwalContent extends StatefulWidget {
  const JadwalContent({Key? key}) : super(key: key);

  @override
  _JadwalContentState createState() => _JadwalContentState();
}

class _JadwalContentState extends State<JadwalContent> {
  String _selectedMonth = 'Semua Bulan';
  String _selectedYear = '2025';
  List<dynamic> _doctors = [];
  bool _isLoading = true;
  String _errorMessage = '';

  final List<String> _months = [
    'Semua Bulan',
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

  final List<String> _years = [
    '2024',
    '2025'
  ];

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final doctors = await ApiService.getDokter();

      setState(() {
        _doctors = doctors;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Gagal memuat data dokter: ${e.toString()}';
      });
      print('Error loading doctors: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header dan Button Selector (Tetap di tempat)
        Container(
          padding: const EdgeInsets.only(left: 40.0, top: 16.0, right: 40.0),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF109E88),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TambahDokter(),
                      ),
                    );
                  },
                  child: const Text(
                    'TAMBAH DOKTER',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Afacad',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),

        // Content yang bisa discroll
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(left: 40.0, bottom: 16.0, right: 40.0),
            child: _buildDoctorCards(),
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
              'Daftar Tenaga Medis',
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
            onPressed: () {
              // Handle notification button press
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDoctorCards() {
    if (_doctors.isEmpty) {
      return Center(
        child: Text(
          'Tidak ada data dokter',
          style: TextStyle(
            fontFamily: 'Afacad',
            fontSize: 18,
            color: Colors.grey,
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 0.8,
      ),
      itemCount: _doctors.length,
      itemBuilder: (context, index) {
        final doctor = _doctors[index];
        return _buildDoctorCard(doctor);
      },
    );
  }

  Widget _buildDoctorCard(Map<String, dynamic> doctor) {
    final String name = doctor['nama'] ?? 'Nama tidak tersedia';
    final String specialization = doctor['spesialis'] ?? 'Spesialis tidak tersedia';
    final String? imageUrl = doctor['foto'];
    final String doctorId = doctor['_id'] ?? '';

    return Container(
      height: 100,
      child:  Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: Colors.white,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Foto Dokter
              Container(
                width: 120,
                height: 120,
                margin: EdgeInsets.only(top: 20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Color(0xFF109E88),
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: _buildDoctorImage(imageUrl),
                ),
              ),

              SizedBox(height: 15),

              // Nama Dokter
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  name,
                  style: TextStyle(
                    fontFamily: 'Afacad',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF109E88),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              SizedBox(height: 8),

              // Spesialisasi
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  specialization,
                  style: TextStyle(
                    fontFamily: 'Afacad',
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              Spacer(),

              // Tombol Aksi
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                child: ElevatedButton(
                  onPressed: () {
                    _viewDoctorSchedule(doctor);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF109E88),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: Text(
                    'Lihat Jadwal',
                    style: TextStyle(
                      fontFamily: 'Afacad',
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        color: Colors.grey[200],
        child: Icon(
          Icons.person,
          size: 50,
          color: Colors.grey[400],
        ),
      );
    }

    // Pastikan URL lengkap (tambahkan base URL jika diperlukan)
    String fullImageUrl = imageUrl;
    if (!imageUrl.startsWith('http')) {
      fullImageUrl = '${ApiService.basedUrl}$imageUrl';
    }

    return Image.network(
      fullImageUrl,
      fit: BoxFit.contain,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            color: Color(0xFF109E88),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey[200],
          child: Icon(
            Icons.person,
            size: 50,
            color: Colors.grey[400],
          ),
        );
      },
    );
  }

  void _viewDoctorSchedule(Map<String, dynamic> doctor) {
    // Implementasi untuk melihat jadwal dokter
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Jadwal ${doctor['nama']}',
          style: TextStyle(
            fontFamily: 'Afacad',
            color: Color(0xFF109E88),
          ),
        ),
        content: Text(
          'Fitur lihat jadwal akan segera tersedia',
          style: TextStyle(
            fontFamily: 'Afacad',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Tutup',
              style: TextStyle(
                fontFamily: 'Afacad',
                color: Color(0xFF109E88),
              ),
            ),
          ),
        ],
      ),
    );
  }
}