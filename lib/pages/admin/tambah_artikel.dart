import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
// import 'dart:html' as html;
import '../../navigasi/navigasi_sidebar.dart';
import '../../services/api_service.dart';

class TambahArtikel extends StatefulWidget {
  const TambahArtikel({Key? key}) : super(key: key);

  @override
  _TambahArtikelState createState() => _TambahArtikelState();
}

class _TambahArtikelState extends State<TambahArtikel> {
  dynamic _selectedImage; // Changed to dynamic to handle both web and mobile
  final TextEditingController _judulController = TextEditingController();
  final TextEditingController _sumberController = TextEditingController();
  final TextEditingController _isiController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  // Di fungsi _pickImage(), pastikan hanya menerima file gambar
  Future<void> _pickImage() async {
    // if (kIsWeb) {
    //   final html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
    //   uploadInput.accept = 'image/*'; // Hanya terima gambar
    //   uploadInput.click();
    //
    //   uploadInput.onChange.listen((e) async {
    //     final files = uploadInput.files;
    //     if (files != null && files.isNotEmpty) {
    //       final file = files[0];
    //
    //       // Validasi tipe file di frontend juga
    //       if (!file.type.startsWith('image/')) {
    //         ScaffoldMessenger.of(context).showSnackBar(
    //           SnackBar(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationSidebar(
            currentIndex: 1,
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
                        'Tambah Artikel',
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

                  // Form Section with left padding
                  Padding(
                    padding: const EdgeInsets.only(left: 60.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image upload with preview (same as IklanContent)
                        Text(
                          'Upload Gambar :',
                          style: TextStyle(
                            fontFamily: 'Afacad',
                            fontSize: 20,
                            color: const Color(0xFF109E88),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            width: 150,
                            height: 100,
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
                                    width: 150,
                                    height: 100,
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
                                        'Upload',
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
                        const SizedBox(height: 20),

                        // Rest of your form fields...
                        Text(
                          'Judul Artikel :',
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
                                color: Color(0xFFD9D9D9), // Gray border color
                                width: 1.0,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(
                                color: Color(0xFFD9D9D9), // Gray border color
                                width: 1.0,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(
                                color: Color(0xFF109E88), // Green border when focused
                                width: 1.5,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                        ),
                        const SizedBox(height: 20),

                        Text(
                          'Sumber Artikel :',
                          style: TextStyle(
                            fontFamily: 'Afacad',
                            fontSize: 20,
                            color: const Color(0xFF109E88),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _sumberController,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(
                                color: Color(0xFFD9D9D9), // Gray border color
                                width: 1.0,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(
                                color: Color(0xFFD9D9D9), // Gray border color
                                width: 1.0,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(
                                color: Color(0xFF109E88), // Green border when focused
                                width: 1.5,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                        ),
                        const SizedBox(height: 20),

                        Text(
                          'Isi Artikel :',
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
                                color: Color(0xFFD9D9D9), // Gray border color
                                width: 1.0,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(
                                color: Color(0xFFD9D9D9), // Gray border color
                                width: 1.0,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(
                                color: Color(0xFF109E88), // Green border when focused
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
                            onPressed: () async {
                              if (_judulController.text.isEmpty ||
                                  _sumberController.text.isEmpty ||
                                  _isiController.text.isEmpty ||
                                  _selectedImage == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Harap lengkapi semua field!'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }

                              try {
                                dynamic imageToUpload;

                                if (kIsWeb) {
                                  if (_selectedImage is Map<String, dynamic>) {
                                    final map = _selectedImage as Map<String, dynamic>;
                                    if (map['bytes'] is Uint8List) {
                                      imageToUpload = map['bytes'];
                                    } else {
                                      throw Exception('Format gambar tidak valid');
                                    }
                                  } else {
                                    throw Exception('Format gambar tidak dikenali');
                                  }
                                } else {
                                  imageToUpload = _selectedImage as File;
                                }

                                await ApiService.createArticle(
                                  judul: _judulController.text,
                                  sumber: _sumberController.text,
                                  isi: _isiController.text,
                                  image: imageToUpload,
                                );

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Artikel berhasil disimpan!'),
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
                              }
                            },
                            child: const Text(
                              'SIMPAN ARTIKEL',
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
    _sumberController.dispose();
    _isiController.dispose();
    super.dispose();
  }
}