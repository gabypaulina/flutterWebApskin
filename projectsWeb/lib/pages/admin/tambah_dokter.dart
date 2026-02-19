// import 'dart:html' as html;
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../navigasi/navigasi_sidebar.dart';
import '../../services/api_service.dart';

class TambahDokter extends StatefulWidget {
  const TambahDokter({Key? key}) : super(key: key);

  @override
  _TambahDokterState createState() => _TambahDokterState();
}

class _TambahDokterState extends State<TambahDokter> {
  dynamic _selectedImage;
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _spesialisController = TextEditingController();
  final List<Map<String, dynamic>> _jadwalHari = [];
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  final List<String> _dokterList = [
    'dr. Ellen Sidowati, Sp.DVE',
    'dr. Menul Ayu U, Sp.DVE',
    'dr. Lunardi Bintanjoyo, Sp.DVE',
    'dr. Arisia Fadila, M.Ked.Klin, Sp.DVE',
    'dr. Yunita, M.Biomed',
    'dr. Agustina Tri P, Sp.DVE',
    'dr. Catherina Jessica S, Sp.DVE',
    'dr. Magdalena, M.Biomed'
  ];

  // List data spesialis
  final List<String> _spesialisList = [
    'kecantikan',
    'klinis',
    'biomedis'
  ];

  String? _selectedDokter;
  String? _selectedSpesialis;

  @override
  void initState() {
    super.initState();
    _tambahHari();
  }

  void _tambahHari() {
    setState(() {
      _jadwalHari.add({
        'hari': TextEditingController(),
        'jamPraktik': [
          {
            'jamMulai': TextEditingController(),
            'jamAkhir': TextEditingController(),
          }
        ],
      });
    });
  }

  void _tambahJamPraktik(int hariIndex) {
    setState(() {
      _jadwalHari[hariIndex]['jamPraktik'].add({
        'jamMulai': TextEditingController(),
        'jamAkhir': TextEditingController(),
      });
    });
  }

  void _hapusJamPraktik(int hariIndex, int jamIndex) {
    setState(() {
      if (_jadwalHari[hariIndex]['jamPraktik'].length > 1) {
        _jadwalHari[hariIndex]['jamPraktik'][jamIndex]['jamMulai']?.dispose();
        _jadwalHari[hariIndex]['jamPraktik'][jamIndex]['jamAkhir']?.dispose();
        _jadwalHari[hariIndex]['jamPraktik'].removeAt(jamIndex);
      }
    });
  }

  void _hapusHari(int hariIndex) {
    setState(() {
      _jadwalHari[hariIndex]['hari']?.dispose();
      for (var jam in _jadwalHari[hariIndex]['jamPraktik']) {
        jam['jamMulai']?.dispose();
        jam['jamAkhir']?.dispose();
      }
      _jadwalHari.removeAt(hariIndex);
    });
  }

  Future<void> _pickImage() async {
    // if (kIsWeb) {
    //   final html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
    //   uploadInput.accept = 'image/*';
    //   uploadInput.click();
    //
    //   uploadInput.onChange.listen((e) async {
    //     final files = uploadInput.files;
    //     if (files != null && files.isNotEmpty) {
    //       final file = files[0];
    //
    //       if (!file.type.startsWith('image/')) {
    //         ScaffoldMessenger.of(context).showSnackBar(
    //           const SnackBar(
    //             content: Text('Hanya file gambar yang diperbolehkan'),
    //             backgroundColor: Colors.red,
    //           ),
    //         );
    //         return;
    //       }
    //
    //       final reader = html.FileReader();
    //       reader.readAsArrayBuffer(file);
    //       await reader.onLoad.first;
    //
    //       final arrayBuffer = reader.result;
    //       final bytes = Uint8List.fromList(arrayBuffer as List<int>);
    //
    //       setState(() {
    //         _selectedImage = {
    //           'bytes': bytes,
    //           'filename': file.name,
    //           'type': file.type,
    //           'size': file.size
    //         };
    //       });
    //
    //       print('File selected: ${file.name}, type: ${file.type}, size: ${file.size} bytes');
    //     }
    //   });
    // } else {
    //   final pickedFile = await ImagePicker().pickImage(
    //     source: ImageSource.gallery,
    //     maxWidth: 800,
    //     maxHeight: 600,
    //     imageQuality: 85,
    //   );
    //
    //   if (pickedFile != null) {
    //     setState(() {
    //       _selectedImage = File(pickedFile.path);
    //     });
    //     print('File selected: ${pickedFile.path}');
    //   }
    // }
  }

  Future<void> _simpanDokter() async {
    // Validasi input
    if (_selectedDokter == null || _selectedDokter!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama dokter harus dipilih'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedSpesialis == null || _selectedSpesialis!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Spesialis dokter harus dipilih'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validasi jadwal
    for (var hari in _jadwalHari) {
      if (hari['hari'].text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nama hari harus diisi untuk semua jadwal'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      for (var jam in hari['jamPraktik']) {
        if (jam['jamMulai'].text.isEmpty || jam['jamAkhir'].text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Jam mulai dan jam akhir harus diisi untuk semua jadwal'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Format jadwal untuk dikirim ke API
      List<Map<String, dynamic>> jadwalPraktik = [];
      for (var hari in _jadwalHari) {
        List<Map<String, dynamic>> jamPraktikList = [];
        for (var jam in hari['jamPraktik']) {
          jamPraktikList.add({
            'jamMulai': jam['jamMulai'].text,
            'jamAkhir': jam['jamAkhir'].text,
          });
        }

        jadwalPraktik.add({
          'hari': hari['hari'].text,
          'jamPraktik': jamPraktikList,
        });
      }

      // Panggil API untuk menyimpan dokter
      final result = await ApiService.createDokter(
        nama: _selectedDokter!, // Gunakan nilai dari dropdown
        spesialis: _selectedSpesialis!, // Gunakan nilai dari dropdown
        jadwal: jadwalPraktik,
        foto: _selectedImage,
      );

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dokter berhasil ditambahkan'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Kembali dengan hasil sukses
      } else {
        throw Exception(result['message'] ?? 'Gagal menambahkan dokter');
      }
    } catch (e) {
      print('Error saving doctor: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menambahkan dokter: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

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
            child: Column(
              children: [
                // Header yang tetap di atas saat discroll
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
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Text(
                        'Tambah Jadwal Dokter',
                        style: TextStyle(
                          fontFamily: 'HindSiliguri',
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF109E88),
                        ),
                      ),
                    ],
                  ),
                ),

                // Content yang bisa discroll
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(left: 40.0, bottom: 16.0, right: 40.0, top: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Form Section dengan left padding
                        Padding(
                          padding: const EdgeInsets.only(left: 60.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      GestureDetector(
                                        onTap: _pickImage,
                                        child: Container(
                                          width: 200,
                                          height: 200,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: const Color(0xFFD9D9D9),
                                              width: 1.5,
                                            ),
                                          ),
                                          child: _selectedImage != null
                                              ? SizedBox(
                                            width: 350,
                                            height: 200,
                                            child: kIsWeb
                                                ? Image.memory(
                                              _selectedImage['bytes'] as Uint8List,
                                              fit: BoxFit.contain,
                                            )
                                                : Image.file(
                                              _selectedImage as File,
                                              fit: BoxFit.contain,
                                            ),
                                          )
                                              : Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.add_photo_alternate,
                                                size: 30,
                                                color: const Color(0xFF109E88),
                                              ),
                                              const SizedBox(height: 5),
                                              Text(
                                                'Foto Dokter',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: const Color(0xFF109E88),
                                                  fontFamily: 'Afacad',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 40),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Nama Dokter :',
                                          style: TextStyle(
                                            fontFamily: 'Afacad',
                                            fontSize: 20,
                                            color: const Color(0xFF109E88),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        SizedBox(
                                          width: 500,
                                          child: DropdownButtonFormField<String>(
                                            value: _selectedDokter,
                                            decoration: InputDecoration(
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(10),
                                                borderSide: const BorderSide(
                                                  color: Color(0xFFD9D9D9),
                                                  width: 1.0,
                                                ),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(10),
                                                borderSide: const BorderSide(
                                                  color: Color(0xFFD9D9D9),
                                                  width: 1.0,
                                                ),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(10),
                                                borderSide: const BorderSide(
                                                  color: Color(0xFF109E88),
                                                  width: 1.5,
                                                ),
                                              ),
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                              filled: true,
                                              fillColor: Colors.white,
                                            ),
                                            hint: const Text(
                                              'Pilih Nama Dokter',
                                              style: TextStyle(
                                                fontFamily: 'Afacad',
                                                color: Colors.grey,
                                              ),
                                            ),
                                            style: TextStyle(
                                              fontFamily: 'Afacad',
                                              fontSize: 16,
                                              color: const Color(0xFF109E88),
                                            ),
                                            items: _dokterList.map((String value) {
                                              return DropdownMenuItem<String>(
                                                value: value,
                                                child: Text(value),
                                              );
                                            }).toList(),
                                            onChanged: (String? newValue) {
                                              setState(() {
                                                _selectedDokter = newValue;
                                                _namaController.text = newValue ?? '';
                                              });
                                            },
                                            validator: (value) {
                                              if (value == null || value.isEmpty) {
                                                return 'Nama dokter harus dipilih';
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                        const SizedBox(height: 20),

                                        Text(
                                          'Spesialis :',
                                          style: TextStyle(
                                            fontFamily: 'Afacad',
                                            fontSize: 20,
                                            color: const Color(0xFF109E88),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        // Ganti dari TextField menjadi Dropdown
                                        SizedBox(
                                          width: 500,
                                          child: DropdownButtonFormField<String>(
                                            value: _selectedSpesialis,
                                            decoration: InputDecoration(
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(10),
                                                borderSide: const BorderSide(
                                                  color: Color(0xFFD9D9D9),
                                                  width: 1.0,
                                                ),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(10),
                                                borderSide: const BorderSide(
                                                  color: Color(0xFFD9D9D9),
                                                  width: 1.0,
                                                ),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(10),
                                                borderSide: const BorderSide(
                                                  color: Color(0xFF109E88),
                                                  width: 1.5,
                                                ),
                                              ),
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                              filled: true,
                                              fillColor: Colors.white,
                                            ),
                                            hint: const Text(
                                              'Pilih Spesialis',
                                              style: TextStyle(
                                                fontFamily: 'Afacad',
                                                color: Colors.grey,
                                              ),
                                            ),
                                            style: TextStyle(
                                              fontFamily: 'Afacad',
                                              fontSize: 16,
                                              color: const Color(0xFF109E88),
                                            ),
                                            items: _spesialisList.map((String value) {
                                              return DropdownMenuItem<String>(
                                                value: value,
                                                child: Text(
                                                  value.toUpperCase(),
                                                  style: TextStyle(
                                                    fontFamily: 'Afacad',
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                            onChanged: (String? newValue) {
                                              setState(() {
                                                _selectedSpesialis = newValue;
                                                _spesialisController.text = newValue ?? '';
                                              });
                                            },
                                            validator: (value) {
                                              if (value == null || value.isEmpty) {
                                                return 'Spesialis harus dipilih';
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Header Jadwal Praktik dengan Tombol Tambah
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'JADWAL PRAKTEK',
                                    style: TextStyle(
                                      fontFamily: 'Afacad',
                                      fontSize: 20,
                                      color: const Color(0xFF109E88),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: _tambahHari,
                                    icon: const Icon(Icons.add, size: 20),
                                    label: const Text(
                                      'TAMBAH HARI',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Afacad'
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF109E88),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // List Hari dengan Jam Praktik yang Dinamis
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _jadwalHari.length,
                                itemBuilder: (context, hariIndex) {
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 20),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFFD9D9D9),
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                'Hari ${hariIndex + 1}',
                                                style: TextStyle(
                                                  fontFamily: 'Afacad',
                                                  fontSize: 18,
                                                  color: const Color(0xFF109E88),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete, color: Colors.red),
                                              onPressed: () => _hapusHari(hariIndex),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),

                                        // Input Nama Hari
                                        Text(
                                          'Nama Hari:',
                                          style: TextStyle(
                                            fontFamily: 'Afacad',
                                            fontSize: 16,
                                            color: const Color(0xFF109E88),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        SizedBox(
                                          height: 50,
                                          child: TextField(
                                            controller: _jadwalHari[hariIndex]['hari'],
                                            decoration: InputDecoration(
                                              hintText: 'Contoh: Senin, Selasa, dll.',
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(10),
                                                borderSide: const BorderSide(
                                                  color: Color(0xFFD9D9D9),
                                                  width: 1.0,
                                                ),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(10),
                                                borderSide: const BorderSide(
                                                  color: Color(0xFFD9D9D9),
                                                  width: 1.0,
                                                ),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(10),
                                                borderSide: const BorderSide(
                                                  color: Color(0xFF109E88),
                                                  width: 1.5,
                                                ),
                                              ),
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 16),

                                        // Header Jam Praktik
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Jam Praktik:',
                                              style: TextStyle(
                                                fontFamily: 'Afacad',
                                                fontSize: 16,
                                                color: const Color(0xFF109E88),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            ElevatedButton(
                                              onPressed: () => _tambahJamPraktik(hariIndex),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF109E88),
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                              ),
                                              child: const Text(
                                                'TAMBAH JAM',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontFamily: 'Afacad',
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),

                                        // List Jam Praktik
                                        ListView.builder(
                                          shrinkWrap: true,
                                          physics: const NeverScrollableScrollPhysics(),
                                          itemCount: _jadwalHari[hariIndex]['jamPraktik'].length,
                                          itemBuilder: (context, jamIndex) {
                                            return Padding(
                                              padding: const EdgeInsets.only(bottom: 12),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      'Jam ${jamIndex + 1}:',
                                                      style: TextStyle(
                                                        fontFamily: 'Afacad',
                                                        fontSize: 14,
                                                        color: const Color(0xFF109E88),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                    child: SizedBox(
                                                      height: 45,
                                                      child: TextField(
                                                        controller: _jadwalHari[hariIndex]['jamPraktik'][jamIndex]['jamMulai'],
                                                        decoration: InputDecoration(
                                                          hintText: 'Jam Mulai (contoh: 08:00)',
                                                          border: OutlineInputBorder(
                                                            borderRadius: BorderRadius.circular(8),
                                                            borderSide: const BorderSide(
                                                              color: Color(0xFFD9D9D9),
                                                              width: 1.0,
                                                            ),
                                                          ),
                                                          enabledBorder: OutlineInputBorder(
                                                            borderRadius: BorderRadius.circular(8),
                                                            borderSide: const BorderSide(
                                                              color: Color(0xFFD9D9D9),
                                                              width: 1.0,
                                                            ),
                                                          ),
                                                          focusedBorder: OutlineInputBorder(
                                                            borderRadius: BorderRadius.circular(8),
                                                            borderSide: const BorderSide(
                                                              color: Color(0xFF109E88),
                                                              width: 1.5,
                                                            ),
                                                          ),
                                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                    child: SizedBox(
                                                      height: 45,
                                                      child: TextField(
                                                        controller: _jadwalHari[hariIndex]['jamPraktik'][jamIndex]['jamAkhir'],
                                                        decoration: InputDecoration(
                                                          hintText: 'Jam Akhir (contoh: 16:00)',
                                                          border: OutlineInputBorder(
                                                            borderRadius: BorderRadius.circular(8),
                                                            borderSide: const BorderSide(
                                                              color: Color(0xFFD9D9D9),
                                                              width: 1.0,
                                                            ),
                                                          ),
                                                          enabledBorder: OutlineInputBorder(
                                                            borderRadius: BorderRadius.circular(8),
                                                            borderSide: const BorderSide(
                                                              color: Color(0xFFD9D9D9),
                                                              width: 1.0,
                                                            ),
                                                          ),
                                                          focusedBorder: OutlineInputBorder(
                                                            borderRadius: BorderRadius.circular(8),
                                                            borderSide: const BorderSide(
                                                              color: Color(0xFF109E88),
                                                              width: 1.5,
                                                            ),
                                                          ),
                                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                                    onPressed: () => _hapusJamPraktik(hariIndex, jamIndex),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 20),

                              SizedBox(
                                width: double.infinity,
                                child: _isLoading
                                    ? const Center(child: CircularProgressIndicator())
                                    : ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF109E88),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: _simpanDokter,
                                  child: const Text(
                                    'SIMPAN JADWAL DOKTER',
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
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _namaController.dispose();
    _spesialisController.dispose();
    for (var hari in _jadwalHari) {
      hari['hari']?.dispose();
      for (var jam in hari['jamPraktik']) {
        jam['jamMulai']?.dispose();
        jam['jamAkhir']?.dispose();
      }
    }
    super.dispose();
  }
}