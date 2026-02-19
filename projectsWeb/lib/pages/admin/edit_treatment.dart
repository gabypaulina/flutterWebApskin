import 'dart:io';
import 'package:flutter/material.dart';
// import 'dart:html' as html;
import '../../navigasi/navigasi_sidebar.dart';
import '../../services/api_service.dart';

class EditTreatment extends StatefulWidget {
  final Map<String, dynamic> treatment;

  const EditTreatment({Key? key, required this.treatment}) : super(key: key);

  @override
  _EditTreatmentState createState() => _EditTreatmentState();
}

class _EditTreatmentState extends State<EditTreatment> {
  final TextEditingController _judulController = TextEditingController();
  final TextEditingController _picController = TextEditingController();
  final TextEditingController _isiController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Inisialisasi form dengan data treatment yang dipilih
    _judulController.text = widget.treatment['judul'] ?? '';
    _picController.text = widget.treatment['pic'] ?? '';
    _isiController.text = widget.treatment['isi'] ?? '';
  }

  Future<void> _updateTreatment() async {
    if (_judulController.text.isEmpty ||
        _picController.text.isEmpty ||
        _isiController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama Treatment, Dokter, dan Manfaat harus diisi!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _updateTreatmentApi(
        judul: _judulController.text,
        pic: _picController.text,
        isi: _isiController.text,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Treatment berhasil diperbarui!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      debugPrint('Error detail: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Method untuk update treatment menggunakan ApiService
  Future<void> _updateTreatmentApi({
    required String judul,
    required String pic,
    required String isi,
  }) async {
    try {
      await ApiService.updateTreatment(
        treatmentId: widget.treatment['_id'], // ID treatment yang diedit
        judul: judul,
        pic: pic,
        isi: isi,// Bisa null jika tidak ada gambar baru
      );
    } catch (e) {
      print('API Update error: $e'); // Debug
      throw Exception('Gagal memperbarui treatment: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationSidebar(
            currentIndex: 4,
            context: context,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(left: 40.0, bottom: 16.0, top: 16.0, right: 40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
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
                        'Edit Treatment',
                        style: TextStyle(
                          fontFamily: 'HindSiliguri',
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF109E88),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  Padding(
                    padding: const EdgeInsets.only(left: 60.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),

                        Text(
                          'Nama Treatment :',
                          style: TextStyle(
                            fontFamily: 'Afacad',
                            fontSize: 20,
                            color: const Color(0xFF109E88),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _judulController,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(
                                color: Color(0xFFD9D9D9),
                                width: 1.0,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(
                                color: Color(0xFFD9D9D9),
                                width: 1.0,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(
                                color: Color(0xFF109E88),
                                width: 1.5,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                        ),
                        const SizedBox(height: 20),

                        Text(
                          'Dokter :',
                          style: TextStyle(
                            fontFamily: 'Afacad',
                            fontSize: 20,
                            color: const Color(0xFF109E88),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _picController,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(
                                color: Color(0xFFD9D9D9),
                                width: 1.0,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(
                                color: Color(0xFFD9D9D9),
                                width: 1.0,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(
                                color: Color(0xFF109E88),
                                width: 1.5,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                        ),
                        const SizedBox(height: 20),

                        Text(
                          'Manfaat :',
                          style: TextStyle(
                            fontFamily: 'Afacad',
                            fontSize: 20,
                            color: const Color(0xFF109E88),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _isiController,
                          maxLines: 8,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(
                                color: Color(0xFFD9D9D9),
                                width: 1.0,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(
                                color: Color(0xFFD9D9D9),
                                width: 1.0,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(
                                color: Color(0xFF109E88),
                                width: 1.5,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 30),

                        SizedBox(
                          width: double.infinity,
                          height: 32,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF109E88),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: _isLoading ? null : _updateTreatment,
                            child: _isLoading
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(Colors.white),
                                    ),
                                )
                                : const Text(
                                'UPDATE TREATMENT',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Afacad',
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _judulController.dispose();
    _picController.dispose();
    _isiController.dispose();
    super.dispose();
  }
}