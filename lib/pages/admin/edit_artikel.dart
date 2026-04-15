import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:universal_html/html.dart' as html;
// import 'dart:html' as html;
import '../../navigasi/navigasi_sidebar.dart';
import '../../services/api_service.dart';

class EditArtikel extends StatefulWidget {
  final Map<String, dynamic> artikel;

  const EditArtikel({Key? key, required this.artikel}) : super(key: key);

  @override
  _EditArtikelState createState() => _EditArtikelState();
}

class _EditArtikelState extends State<EditArtikel> {
  dynamic _selectedImage;
  final TextEditingController _judulController = TextEditingController();
  final TextEditingController _sumberController = TextEditingController();
  final TextEditingController _isiController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  String? _currentImageUrl;

  @override
  void initState() {
    super.initState();
    // Inisialisasi form dengan data artikel yang dipilih
    _judulController.text = widget.artikel['judul'] ?? '';
    _sumberController.text = widget.artikel['sumber'] ?? '';
    _isiController.text = widget.artikel['isi'] ?? '';
    _currentImageUrl = widget.artikel['gambar'];
  }

   Future<void> _pickImage() async {
    if (kIsWeb) {
      final html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
      uploadInput.accept = 'image/*';
      uploadInput.click();

      uploadInput.onChange.listen((e) async {
        final files = uploadInput.files;
        if (files != null && files.isNotEmpty) {
          final file = files[0];

          if (!file.type.startsWith('image/')) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Hanya file gambar yang diperbolehkan'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }

          final reader = html.FileReader();
          reader.readAsArrayBuffer(file);
          await reader.onLoad.first;

          final arrayBuffer = reader.result;
          final bytes = Uint8List.fromList(arrayBuffer as List<int>);

          setState(() {
            _selectedImage = {
              'bytes': bytes,
              'filename': file.name,
              'type': file.type,
              'size': file.size
            };
            _currentImageUrl = null; // Reset current image URL jika memilih gambar baru
          });

          print('File selected: ${file.name}, type: ${file.type}, size: ${file.size} bytes');
        }
      });
    } else {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 600,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _currentImageUrl = null; // Reset current image URL jika memilih gambar baru
        });
        print('File selected: ${pickedFile.path}');
      }
    }
   }

  Future<void> _updateArtikel() async {
    if (_judulController.text.isEmpty ||
        _sumberController.text.isEmpty ||
        _isiController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Judul, sumber, dan isi harus diisi!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Jika tidak ada gambar baru yang dipilih, kirim null
      dynamic imageToUpload = _selectedImage;

      await _updateArticleApi(
        judul: _judulController.text,
        sumber: _sumberController.text,
        isi: _isiController.text,
        image: imageToUpload, // Bisa null jika tidak update gambar
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Artikel berhasil diperbarui!'),
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

  // Method untuk update artikel menggunakan ApiService
  Future<void> _updateArticleApi({
    required String judul,
    required String sumber,
    required String isi,
    required dynamic image,
  }) async {
    try {
      await ApiService.updateArticle(
        articleId: widget.artikel['_id'], // ID artikel yang diedit
        judul: judul,
        sumber: sumber,
        isi: isi,
        image: image, // Bisa null jika tidak ada gambar baru
      );
    } catch (e) {
      print('API Update error: $e'); // Debug
      throw Exception('Gagal memperbarui artikel: ${e.toString()}');
    }
  }

  Widget _buildImagePreview() {
    if (_selectedImage != null) {
      return SizedBox(
        width: 150,
        height: 100,
        child: kIsWeb
            ? Image.memory(
          _selectedImage['bytes'] as Uint8List,
          fit: BoxFit.cover,
        )
            : Image.file(
          _selectedImage as File,
          fit: BoxFit.cover,
        ),
      );
    } else if (_currentImageUrl != null) {
      // Tampilkan gambar saat ini dari URL
      final fullImageUrl = '${ApiService.basedUrl}$_currentImageUrl';
      return SizedBox(
        width: 150,
        height: 100,
        child: Image.network(
          fullImageUrl,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 40,
            );
          },
        ),
      );
    } else {
      return Column(
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
      );
    }
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
                        'Edit Artikel',
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
                        Text(
                          'Gambar Artikel :',
                          style: TextStyle(
                            fontFamily: 'Afacad',
                            fontSize: 20,
                            color: const Color(0xFF109E88),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            GestureDetector(
                              onTap:  _pickImage,
                              child: Container(
                                width: 150,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Color(0xFF109E88), // Green border when focused
                                    width: 1.5,
                                  ),
                                ),
                                child: _buildImagePreview(),
                              ),
                            ),
                            if (_currentImageUrl != null && _selectedImage == null)
                              Padding(
                                padding: const EdgeInsets.only(left: 16.0),
                                child: Text(
                                  'Gambar saat ini\n(Tap untuk mengubah)',
                                  style: TextStyle(
                                    fontFamily: 'Afacad',
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),

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
                                color: Color(0xFF109E88), // Green border when focused
                                width: 1.5,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(
                                color: Color(0xFF109E88), // Green border when focused
                                width: 1.5,
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
                                color: Color(0xFF109E88), // Green border when focused
                                width: 1.5,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(
                                color: Color(0xFF109E88), // Green border when focused
                                width: 1.5,
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
                                color: Color(0xFF109E88), // Green border when focused
                                width: 1.5,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(
                                color: Color(0xFF109E88), // Green border when focused
                                width: 1.5,
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
                          height: 40,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF109E88),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: _isLoading ? null : _updateArtikel,
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
                              'UPDATE ARTIKEL',
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'Afacad',
                                fontSize: 18,
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