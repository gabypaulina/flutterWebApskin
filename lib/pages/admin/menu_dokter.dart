import 'package:apskina/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../navigasi/navigasi_sidebar.dart';
import 'edit_dokter.dart';
import 'tambah_dokter.dart';
import 'edit_jadwal_dokter.dart';

class MenuDokter extends StatefulWidget {
  const MenuDokter({Key? key}) : super(key: key);

  @override
  _MenuDokterState createState() => _MenuDokterState();
}

class _MenuDokterState extends State<MenuDokter> {
  List<dynamic> _dokterList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDokter();
  }

  Future<void> _loadDokter() async {
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
        final data = jsonDecode(response.body);
        setState(() {
          _dokterList = data['data'];
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load doctors');
      }
    } catch (e) {
      print('Error loading doctors: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteDokter(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.delete(
        Uri.parse('${ApiService.baseUrl}/dokter/$id'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // Refresh list after deletion
        _loadDokter();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dokter berhasil dihapus')),
        );
      } else {
        throw Exception('Failed to delete doctor');
      }
    } catch (e) {
      print('Error deleting doctor: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menghapus dokter')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationSidebar(
            currentIndex: 6,
            context: context,
          ),
          Expanded(
            child: _DokterContent(
              dokterList: _dokterList,
              isLoading: _isLoading,
              onRefresh: _loadDokter,
              onDelete: _deleteDokter,
            ),
          ),
        ],
      ),
    );
  }
}

class _DokterContent extends StatelessWidget {
  final List<dynamic> dokterList;
  final bool isLoading;
  final VoidCallback onRefresh;
  final Function(String) onDelete;

  const _DokterContent({
    Key? key,
    required this.dokterList,
    required this.isLoading,
    required this.onRefresh,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.only(left: 40.0, top: 16.0, right: 40.0),
          child: Column(
            children: [
              _buildHeader(context),
              const SizedBox(height: 30),
            ],
          ),
        ),

        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : dokterList.isEmpty
              ? Center(
            child: Text(
              'Belum ada data dokter',
              style: TextStyle(
                fontFamily: 'Afacad',
                fontSize: 18,
                color: const Color(0xFF109E88),
              ),
            ),
          )
              : SingleChildScrollView(
            padding: const EdgeInsets.only(left: 40.0, bottom: 16.0, right: 40.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GridView.builder( // Ganti dari GridView.count ke GridView.builder
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 20,
                    childAspectRatio: 350 / 200,
                  ),
                  itemCount: dokterList.length,
                  itemBuilder: (context, index) {
                    return _buildDokterCard(
                      context: context,
                      dokter: dokterList[index],
                      onDelete: onDelete,
                      onRefresh: onRefresh,
                    );
                  },
                ),
              ],
            ),
          ),
        )
      ],
    );
  }

  Widget _buildDokterCard({
    required BuildContext context,
    required dynamic dokter,
    required Function(String) onDelete,
    required VoidCallback onRefresh,
  }) {
    String imageUrl = dokter['foto'] != null
        ? '${ApiService.basedUrl}${dokter['foto']}'
        : 'assets/images/logo.png';

    return Container(
      width: 350,
      constraints: BoxConstraints(minHeight: 300), // Batasi tinggi maksimum
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.grey.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: SingleChildScrollView( // Tambahkan ScrollView jika konten terlalu panjang
        child: Column(
          mainAxisSize: MainAxisSize.min, // Pastikan column hanya mengambil space yang dibutuhkan
          children: [
            // Bagian atas dengan gambar dan info dokter
            Padding(
              padding: const EdgeInsets.all(20.0), // Kurangi padding
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Gambar Dokter
                  Container(
                    width: 150, // Perkecil ukuran gambar
                    height: 100,
                    margin: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: dokter['foto'] != null
                            ? NetworkImage(imageUrl) as ImageProvider
                            : const AssetImage('assets/images/logo.png'),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  // Informasi Dokter
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dokter['nama'] ?? 'Nama tidak tersedia',
                          style: TextStyle(
                            fontSize: 20, // Perkecil font size
                            fontFamily: 'Afacad',
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF109E88),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          dokter['spesialis'] ?? 'Spesialis tidak tersedia',
                          style: TextStyle(
                            fontFamily: 'Afacad',
                            fontSize: 16,
                            color: const Color(0xFF109E88),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Tombol aksi
                  Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18, color: Color(0xFF109E88)),
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditDokter(dokter: dokter),
                            ),
                          );
                          if (result == true) onRefresh();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 18, color: Color(0xFF109E88)),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text("Hapus Dokter"),
                                content: const Text("Apakah Anda yakin ingin menghapus dokter ini?"),
                                actions: [
                                  TextButton(
                                    child: const Text("Batal"),
                                    onPressed: () => Navigator.of(context).pop(),
                                  ),
                                  TextButton(
                                    child: const Text("Hapus", style: TextStyle(color: Colors.red)),
                                    onPressed: () {
                                      onDelete(dokter['_id']);
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // List Jadwal
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: dokter['jadwalPraktik'] != null ? dokter['jadwalPraktik'].length : 0,
                itemBuilder: (context, index) {
                  final jadwal = dokter['jadwalPraktik'][index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        // Hari
                        SizedBox(
                          width: 80,
                          child: Text(
                            jadwal['hari'] ?? '',
                            style: const TextStyle(
                              fontFamily: 'Afacad',
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF109E88),
                            ),
                          ),
                        ),
                        const SizedBox(width: 50),
                        // Waktu
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: (jadwal['jamPraktik'] as List<dynamic>?)?.map<Widget>((jam) {
                              return Text(
                                '${jam['jamMulai']} - ${jam['jamAkhir']}',
                                style: const TextStyle(
                                  fontFamily: 'Afacad',
                                  fontSize: 16,
                                  color: Color(0xFF109E88),
                                ),
                              );
                            }).toList() ?? [const Text('Tidak ada jadwal', style: TextStyle(fontSize: 16))],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Jadwal Dokter',
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
}