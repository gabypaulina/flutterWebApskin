import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:apskina/providers/auth_provider.dart';
import 'package:apskina/navigasi/navigasi_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_service.dart';

class HalamanProfile extends StatefulWidget {
  @override
  _HalamanProfileState createState() => _HalamanProfileState();
}

class _HalamanProfileState extends State<HalamanProfile> {
  String nama = '';
  String email = '';
  String alamat = '';
  String tanggalLahir = '';
  String noHandphone = '';
  bool isLoading = true;
  bool isEditing = false;
  Map<String, dynamic>? qnaData;
  bool hasCompletedQna = false;

  TextEditingController namaController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController alamatController = TextEditingController();
  TextEditingController tanggalLahirController = TextEditingController();
  TextEditingController noHandphoneController = TextEditingController();
  List<dynamic> skincareProducts = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadSkincareData();
    _loadQnaData();

  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');

    if (userJson != null) {
      final userData = jsonDecode(userJson) as Map<String, dynamic>;
      setState(() {
        nama = userData['nama'];
        email = userData['email'];
        alamat = userData['alamat'];
        tanggalLahir = userData['tanggalLahir'];
        noHandphone = userData['noHandphone'];
        hasCompletedQna = userData['hasCompletedQna'] ?? false;

        namaController.text = nama;
        emailController.text = email;
        alamatController.text = alamat;
        tanggalLahirController.text = tanggalLahir;
        noHandphoneController.text = noHandphone;

        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadSkincareData() async {
    try {
      final products = await ApiService.getSkincareProducts();
      setState(() {
        skincareProducts = products;
      });
    } catch (e) {
      print('Error loading skincare data: $e');
      // Bisa tambahkan snackbar untuk menampilkan error jika perlu
    }
  }

  Future<void> _loadQnaData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token != null && hasCompletedQna) {
        // Load QnA history
        final response = await ApiService.getQnaHistory();
        if (response != null && response['data'] != null) {
          setState(() {
            qnaData = response['data'];
          });
        }
      }
    } catch (e) {
      print('Error loading QnA data: $e');
    }
  }

  void _toggleEditMode() {
    setState(() {
      isEditing = !isEditing;
    });
  }

  Future<void> _saveProfile() async {
    // Validate fields
    if (namaController.text.isEmpty ||
        emailController.text.isEmpty ||
        alamatController.text.isEmpty ||
        tanggalLahirController.text.isEmpty ||
        noHandphoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Semua field harus diisi')),
      );
      return;
    }

    // Validate email format
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(emailController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Format email tidak valid')),
      );
      return;
    }

    // Validate phone number format
    if (!RegExp(r'^(\+62|0)[0-9]{9,12}$').hasMatch(noHandphoneController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Format nomor handphone tidak valid')),
      );
      return;
    }

    // Validate date format
    if (!RegExp(r'^(0[1-9]|[12][0-9]|3[01])\/(0[1-9]|1[012])\/(19|20)\d\d$')
        .hasMatch(tanggalLahirController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Format tanggal lahir harus dd/mm/yyyy')),
      );
      return;
    }

    try {
      // Show loading indicator
      setState(() {
        isLoading = true;
      });

      // Call API to update profile
      final response = await ApiService.updateProfile(
        nama: namaController.text,
        email: emailController.text,
        alamat: alamatController.text,
        tanggalLahir: tanggalLahirController.text,
        noHandphone: noHandphoneController.text,
      );

      // Update local storage
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user');

      if (userJson != null) {
        final userData = jsonDecode(userJson) as Map<String, dynamic>;
        final updatedUser = {
          ...userData,
          'nama': namaController.text,
          'email': emailController.text,
          'alamat': alamatController.text,
          'tanggalLahir': tanggalLahirController.text,
          'noHandphone': noHandphoneController.text,
        };

        await prefs.setString('user', jsonEncode(updatedUser));
      }

      // Update UI state
      setState(() {
        nama = namaController.text;
        email = emailController.text;
        alamat = alamatController.text;
        tanggalLahir = tanggalLahirController.text;
        noHandphone = noHandphoneController.text;
        isEditing = false;
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profil berhasil diperbarui')),
      );

    } catch (e) {
      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memperbarui profil: ${e.toString()}')),
      );
    }
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Konfirmasi Logout',
            style: TextStyle(
              fontFamily: 'Afacad',
              color: Color(0xFF109E88),
            ),
          ),
          content: Text(
            'Apakah Anda yakin ingin logout?',
            style: TextStyle(
              fontFamily: 'Afacad',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Batal',
                style: TextStyle(
                  fontFamily: 'Afacad',
                  color: Colors.grey,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                setState(() {
                  isLoading = true;
                });

                try {
                  // Gunakan AuthProvider untuk logout, bukan SharedPreferences langsung
                  final auth = Provider.of<AuthProvider>(context, listen: false);
                  await auth.logout();

                  // Navigate to login and clear all routes
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                        (route) => false,
                  );

                  // Show success message on login page
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Logout berhasil'),
                      ),
                    );
                  });
                } catch (e) {
                  setState(() {
                    isLoading = false;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal logout: ${e.toString()}')),
                  );
                }
              },
              child: Text(
                'Logout',
                style: TextStyle(
                  fontFamily: 'Afacad',
                  color: Colors.red,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    namaController.dispose();
    emailController.dispose();
    alamatController.dispose();
    tanggalLahirController.dispose();
    noHandphoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(100.0), // Tinggi AppBar + padding
          child: Padding(
            padding: const EdgeInsets.only(top: 30.0), // Padding di atas AppBar
            child: Expanded( // Menggunakan Expanded agar teks mengambil ruang yang tersedia
              child: Center( // Memusatkan teks di dalam Expanded
                child: Text(
                  'Profile',
                  style: TextStyle(
                    fontFamily: 'Afacad',
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    color: Color(0xFF109E88),
                  ),
                ),
              ),
            ),
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),

                // User Information Section with Icons (without Card)
                _buildProfileInfoRow(Icons.person, nama, namaController),
                const SizedBox(height: 10),
                _buildProfileInfoRow(Icons.email, email, emailController),
                const SizedBox(height: 10),
                _buildProfileInfoRow(Icons.home, alamat, alamatController),
                const SizedBox(height: 10),
                _buildProfileInfoRow(Icons.calendar_today, tanggalLahir, tanggalLahirController),
                const SizedBox(height: 10),
                _buildProfileInfoRow(Icons.phone, noHandphone, noHandphoneController),
                const SizedBox(height: 20),

                // Skin Type Data Section
                const Text(
                  'Data Tipe Kulit',
                  style: TextStyle(
                    fontSize: 20,
                    fontFamily: 'Afacad',
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF109E88),
                  ),
                ),
                const SizedBox(height: 16),
                _buildQnaResult(),
                const SizedBox(height: 20),

                // Skincare List Section - Responsive
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isSmallScreen = constraints.maxWidth < 400;

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Daftar Skincare ',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 18 : 20,
                                    fontFamily: 'Afacad',
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF109E88),
                                  ),
                                ),
                                TextSpan(
                                  text: '(optional)',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 12 : 14,
                                    fontFamily: 'Afacad',
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        OutlinedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/tambah_skincare').then((_) {
                              _loadSkincareData();
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Color(0xFF109E88)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 12 : 16,
                              vertical: isSmallScreen ? 8 : 10,
                            ),
                          ),
                          child: Text(
                            'Tambahkan',
                            style: TextStyle(
                              color: Color(0xFF109E88),
                              fontFamily: 'Afacad',
                              fontSize: isSmallScreen ? 12 : 14,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),

                _buildSkincareTable(),
                const SizedBox(height: 20),

                // Edit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : (isEditing ? _saveProfile : _toggleEditMode),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF109E88),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: isLoading
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : Text(
                      isEditing ? 'SIMPAN' : 'EDIT',
                      style: TextStyle(
                        fontFamily: 'Afacad',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Logout Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: isLoading ? null : _logout,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'LOGOUT',
                      style: TextStyle(
                        fontFamily: 'Afacad',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        bottomNavigationBar: NavigasiBar(
          currentIndex: 4, // Current page index (4 for profile)
          context: context, // Pass the context
        )
    );
  }

  Widget _buildProfileInfoRow(IconData icon, String text, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xFF109E88),
            size: 20,
          ),
          const SizedBox(width: 30),
          Expanded(
              child: isEditing
                  ? TextField(
                controller: controller,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 10, horizontal: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFFD9D9D9), // Gray border color
                      width: 1.0,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFFD9D9D9), // Gray border color
                      width: 1.0,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFF109E88), // Green border when focused
                      width: 1.5,
                    ),
                  ),
                ),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Afacad',
                  color: Color(0xFF109E88),
                ),
              )
                  : Text (
                  text,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Afacad',
                    color: Color(0xFF109E88),
                  )
              )
          ),
        ],
      ),
    );
  }

  Widget _buildSkincareTable() {
    if (skincareProducts.isEmpty) {
      return Center(
        child: Text(
          'Belum ada data skincare',
          style: TextStyle(
            fontFamily: 'Afacad',
            color: Colors.grey,
          ),
        ),
      );
    }

    // Kelompokkan produk berdasarkan jenis
    Map<String, List<dynamic>> productsByType = {};
    for (var product in skincareProducts) {
      String type = product['type'];
      if (!productsByType.containsKey(type)) {
        productsByType[type] = [];
      }
      productsByType[type]!.add(product);
    }

    // Definisikan urutan jenis skincare yang diinginkan
    const List<String> typeOrder = [
      'Toner',
      'Essence',
      'Serum',
      'Moisturizer',
      'Obat Jerawat',
      'Sunscreen'
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // Tentukan lebar kolom berdasarkan lebar layar
        final screenWidth = constraints.maxWidth;
        final jenisColumnWidth = screenWidth * 0.3; // 30% dari lebar layar
        final produkColumnWidth = screenWidth * 0.7; // 70% dari lebar layar

        // Buat list TableRow
        List<TableRow> tableRows = [
          // Header row
          TableRow(
            children: [
              _buildTableHeaderCell('JENIS', jenisColumnWidth),
              _buildTableHeaderCell('PRODUK', produkColumnWidth),
            ],
          ),
        ];

        // Tambahkan row untuk setiap jenis produk sesuai urutan yang ditentukan
        for (String type in typeOrder) {
          if (productsByType.containsKey(type)) {
            final products = productsByType[type]!;

            // Buat list untuk children row
            List<Widget> productCells = [];

            for (int i = 0; i < products.length; i++) {
              final product = products[i];
              productCells.add(
                Container(
                  width: produkColumnWidth,
                  padding: const EdgeInsets.all(14.0),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: i != products.length - 1
                          ? BorderSide(
                        color: Colors.grey.withOpacity(0.3),
                        width: 1,
                      )
                          : BorderSide.none,
                    ),
                  ),
                  child: Column(
                    children: [
                      Center(
                        child: Text(
                          product['name'],
                          style: TextStyle(
                            fontFamily: 'Afacad',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF109E88),
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Center(
                        child: Text(
                          '( ${product['ingredients'].join(', ')} )',
                          style: TextStyle(
                            fontFamily: 'Afacad',
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: const Color(0xFF109E88).withOpacity(0.8),
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            tableRows.add(
              TableRow(
                children: [
                  // Cell untuk jenis (akan memenuhi tinggi semua produk)
                  Container(
                    width: jenisColumnWidth,
                    height: products.length * 80.0, // Estimasi tinggi berdasarkan jumlah produk
                    padding: const EdgeInsets.all(14.0),
                    child: Center(
                      child: Text(
                        type,
                        style: TextStyle(
                          fontFamily: 'Afacad',
                          fontSize: 14,
                          color: const Color(0xFF109E88),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  // Cell untuk produk (multiple products dalam satu cell)
                  Container(
                    width: produkColumnWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: productCells,
                    ),
                  ),
                ],
              ),
            );
          }
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            width: screenWidth,
            child: Table(
              border: TableBorder.all(
                color: Colors.grey.withOpacity(0.25),
                width: 1,
                borderRadius: BorderRadius.circular(10),
              ),
              columnWidths: {
                0: FixedColumnWidth(jenisColumnWidth),
                1: FixedColumnWidth(produkColumnWidth),
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: tableRows,
            ),
          ),
        );
      },
    );
  }

  Widget _buildTableHeaderCell(String text, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(8.0),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'Afacad',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF109E88),
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildQnaResult() {
    if (!hasCompletedQna) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.quiz_outlined,
              size: 40,
              color: Colors.grey[400],
            ),
            SizedBox(height: 10),
            Text(
              'Belum mengisi QnA',
              style: TextStyle(
                fontFamily: 'Afacad',
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/qna');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF109E88),
              ),
              child: Text(
                'Isi QnA Sekarang',
                style: TextStyle(
                  fontFamily: 'Afacad',
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (qnaData == null) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    final responses = qnaData!['responses'] as List<dynamic>;
    final completedAt = qnaData!['completedAt'] != null
        ? DateTime.parse(qnaData!['completedAt'])
        : null;

    // Analisis hasil QnA untuk menentukan tipe kulit
    String skinType = _analyzeSkinType(responses);

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Color(0xFF109E88).withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header dengan tanggal
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Hasil Analisis Kulit',
                style: TextStyle(
                  fontFamily: 'Afacad',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF109E88),
                ),
              ),
              if (completedAt != null)
                Text(
                  DateFormat('dd/MM/yy').format(completedAt),
                  style: TextStyle(
                    fontFamily: 'Afacad',
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
          SizedBox(height: 16),

          // Tipe Kulit
          _buildSkinTypeCard(skinType),
          SizedBox(height: 16),

          // Detail Jawaban
          Text(
            'Detail Analisis:',
            style: TextStyle(
              fontFamily: 'Afacad',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF109E88),
            ),
          ),
          SizedBox(height: 10),

          // Daftar pertanyaan dan jawaban
          ...responses.take(3).map((response) => _buildQnaItem(response)).toList(),

          // Tombol lihat selengkapnya
          if (responses.length > 3)
            TextButton(
              onPressed: () {
                _showFullQnaResults(responses, skinType, completedAt);
              },
              child: Text(
                'Lihat selengkapnya →',
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

  String _analyzeSkinType(List<dynamic> responses) {
    // Logika sederhana untuk menentukan tipe kulit berdasarkan jawaban QnA
    Map<String, int> skinTypeScores = {
      'Kering': 0,
      'Berminyak': 0,
      'Kombinasi': 0,
      'Normal': 0,
      'Sensitif': 0,
    };

    for (var response in responses) {
      final answerText = response['answerText'].toString().toLowerCase();

      if (answerText.contains('kering')) skinTypeScores['Kering'] = skinTypeScores['Kering']! + 1;
      if (answerText.contains('berminyak')) skinTypeScores['Berminyak'] = skinTypeScores['Berminyak']! + 1;
      if (answerText.contains('kombinasi')) skinTypeScores['Kombinasi'] = skinTypeScores['Kombinasi']! + 1;
      if (answerText.contains('normal')) skinTypeScores['Normal'] = skinTypeScores['Normal']! + 1;
      if (answerText.contains('sensitif')) skinTypeScores['Sensitif'] = skinTypeScores['Sensitif']! + 1;
    }

    // Cari tipe kulit dengan skor tertinggi
    String dominantType = 'Normal';
    int highestScore = 0;

    skinTypeScores.forEach((type, score) {
      if (score > highestScore) {
        highestScore = score;
        dominantType = type;
      }
    });

    return dominantType;
  }

  Widget _buildSkinTypeCard(String skinType) {
    Color getColorForSkinType(String type) {
      switch (type.toLowerCase()) {
        case 'kering':
          return Colors.blue[300]!;
        case 'berminyak':
          return Colors.green[300]!;
        case 'kombinasi':
          return Colors.orange[300]!;
        case 'normal':
          return Colors.purple[300]!;
        case 'sensitif':
          return Colors.red[300]!;
        default:
          return Color(0xFF109E88);
      }
    }

    String getDescriptionForSkinType(String type) {
      switch (type.toLowerCase()) {
        case 'kering':
          return 'Kulit membutuhkan hidrasi ekstra dan pelembab intensif';
        case 'berminyak':
          return 'Kulit memproduksi minyak berlebih, perlu kontrol sebum';
        case 'kombinasi':
          return 'Area T-zone berminyak, area pipi kering atau normal';
        case 'normal':
          return 'Kulit seimbang, tidak terlalu kering atau berminyak';
        case 'sensitif':
          return 'Kulit mudah iritasi, perlu produk gentle dan hypoallergenic';
        default:
          return 'Tipe kulit terdeteksi berdasarkan hasil QnA';
      }
    }

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: getColorForSkinType(skinType).withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: getColorForSkinType(skinType).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.face_retouching_natural,
            color: getColorForSkinType(skinType),
            size: 32,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tipe Kulit:',
                  style: TextStyle(
                    fontFamily: 'Afacad',
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  skinType.toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'Afacad',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: getColorForSkinType(skinType),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  getDescriptionForSkinType(skinType),
                  style: TextStyle(
                    fontFamily: 'Afacad',
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQnaItem(Map<String, dynamic> response) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            response['questionText'],
            style: TextStyle(
              fontFamily: 'Afacad',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF109E88),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 4),
          Text(
            '→ ${response['answerText']}',
            style: TextStyle(
              fontFamily: 'Afacad',
              fontSize: 13,
              color: Colors.grey[700],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 8),
          Divider(height: 1, color: Colors.grey[300]),
        ],
      ),
    );
  }

  void _showFullQnaResults(List<dynamic> responses, String skinType, DateTime? completedAt) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Hasil Lengkap Analisis Kulit',
          style: TextStyle(
            fontFamily: 'Afacad',
            color: Color(0xFF109E88),
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (completedAt != null)
                Text(
                  'Tanggal: ${DateFormat('dd MMMM yyyy').format(completedAt)}',
                  style: TextStyle(
                    fontFamily: 'Afacad',
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              SizedBox(height: 16),
              _buildSkinTypeCard(skinType),
              SizedBox(height: 20),
              ...responses.map((response) => _buildDetailedQnaItem(response)).toList(),
            ],
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

  Widget _buildDetailedQnaItem(Map<String, dynamic> response) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tampilkan gambar pertanyaan jika ada
          if (response['questionImage'] != null)
            Column(
              children: [
                Image.network(
                  '${ApiService.basedUrl}${response['questionImage']}',
                  width: double.infinity,
                  height: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(Icons.image_not_supported, size: 40),
                ),
                SizedBox(height: 8),
              ],
            ),

          Text(
            response['questionText'],
            style: TextStyle(
              fontFamily: 'Afacad',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF109E88),
            ),
          ),
          SizedBox(height: 8),

          Text(
            response['answerText'],
            style: TextStyle(
              fontFamily: 'Afacad',
              fontSize: 13,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

}