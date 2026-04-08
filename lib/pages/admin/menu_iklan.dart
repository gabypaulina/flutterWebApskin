import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../navigasi/navigasi_sidebar.dart';
import 'dart:io';
// import 'dart:html' as html;
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';

class MenuIklan extends StatefulWidget {
  const MenuIklan({Key? key}) : super(key: key);

  @override
  _MenuIklanState createState() => _MenuIklanState();
}

class _MenuIklanState extends State<MenuIklan> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationSidebar(
            currentIndex: 2,
            context: context,
          ),
          Expanded(
            child: IklanContent(),
          ),
        ],
      ),
    );
  }
}

class IklanContent extends StatefulWidget {
  const IklanContent({Key? key}) : super(key: key);

  @override
  _IklanContentState createState() => _IklanContentState();
}

class _IklanContentState extends State<IklanContent> {
  List<Map<String, dynamic>> _banners = [];
  final ImagePicker _picker = ImagePicker();
  int _selectedSection = 0;
  bool _isLoading = false;

  // Variabel untuk menyimpan gambar yang dipilih per box
  Map<int, File> _selectedImages = {}; // Untuk mobile: box index -> File
  Map<int, Uint8List> _selectedImagesBytes = {}; // Untuk web: box index -> bytes
  Map<int, String> _selectedImageFileNames = {}; // box index -> filename

  // Variabel untuk form notifikasi
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _judulController = TextEditingController();
  final TextEditingController _isiController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadBanners();
  }

  Future<void> _loadBanners() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final bannersData = await ApiService.getBanners();
      setState(() {
        _banners = bannersData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat banner: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickImageFromGallery(int boxIndex) async {
    // if (kIsWeb) {
    //   // Handle untuk web
    //   final html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
    //   uploadInput.accept = 'image/*';
    //   uploadInput.click();
    //
    //   uploadInput.onChange.listen((e) async {
    //     final files = uploadInput.files;
    //     if (files != null && files.isNotEmpty) {
    //       final file = files[0];
    //       final reader = html.FileReader();
    //
    //       reader.readAsArrayBuffer(file);
    //       reader.onLoadEnd.listen((event) async {
    //         if (reader.result != null) {
    //           final bytes = reader.result as Uint8List;
    //           setState(() {
    //             _selectedImagesBytes[boxIndex] = bytes;
    //             _selectedImageFileNames[boxIndex] = file.name;
    //           });
    //         }
    //       });
    //     }
    //   });
    // } else {
    //   // Handle untuk mobile
    //   final XFile? image = await _picker.pickImage(
    //     source: ImageSource.gallery,
    //     imageQuality: 85,
    //   );
    //
    //   if (image != null) {
    //     setState(() {
    //       _selectedImages[boxIndex] = File(image.path);
    //     });
    //   }
    // }
  }

  Future<void> _uploadBanners() async {
    // Cek apakah ada gambar yang dipilih
    final hasSelectedImages = kIsWeb
        ? _selectedImagesBytes.isNotEmpty
        : _selectedImages.isNotEmpty;

    if (!hasSelectedImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Silakan pilih foto terlebih dahulu!'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (kIsWeb) {
        // Upload untuk web menggunakan bytes
        if (_selectedImagesBytes.isEmpty || _selectedImageFileNames.isEmpty) {
          throw Exception('File data tidak lengkap');
        }

        // Konversi map ke list
        final bytesList = _selectedImagesBytes.values.toList();
        final fileNamesList = _selectedImageFileNames.values.toList();

        final result = await ApiService.uploadBannersWeb(bytesList, fileNamesList);

        setState(() {
          _selectedImagesBytes.clear();
          _selectedImageFileNames.clear();
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Banner berhasil diupload!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        // Upload untuk mobile menggunakan file
        final fileList = _selectedImages.values.toList();
        final result = await ApiService.uploadBanners(fileList);

        setState(() {
          _selectedImages.clear();
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Banner berhasil diupload!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }

      _loadBanners();

    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal upload banner: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _deleteBanner(String bannerId) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Hapus Banner'),
          content: Text('Apakah Anda yakin ingin menghapus banner ini?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                setState(() {
                  _isLoading = true;
                });

                try {
                  await ApiService.deleteBanner(bannerId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Banner berhasil dihapus!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadBanners();
                } catch (e) {
                  setState(() {
                    _isLoading = false;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal menghapus banner: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  // void _submitNotifikasi() {
  //   if (_formKey.currentState!.validate()) {
  //     final judul = _judulController.text;
  //     final isi = _isiController.text;
  //
  //     // Kirim notifikasi ke semua user
  //     ApiService.sendNotificationToUsers(
  //       title: judul,
  //       body: isi,
  //       type: 'advertisement',
  //     ).then((_) {
  //       // Tampilkan dialog konfirmasi
  //       showDialog(
  //         context: context,
  //         builder: (BuildContext context) {
  //           return AlertDialog(
  //             title: Text('Notifikasi Berhasil Dibuat'),
  //             content: Column(
  //               mainAxisSize: MainAxisSize.min,
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 Text('Judul: $judul'),
  //                 SizedBox(height: 8),
  //                 Text('Isi: $isi'),
  //                 SizedBox(height: 8),
  //                 Text('Notifikasi telah dikirim ke semua user'),
  //               ],
  //             ),
  //             actions: [
  //               TextButton(
  //                 onPressed: () {
  //                   Navigator.of(context).pop();
  //                 },
  //                 child: Text('OK'),
  //               ),
  //             ],
  //           );
  //         },
  //       );
  //
  //       // Reset form
  //       _judulController.clear();
  //       _isiController.clear();
  //     }).catchError((error) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text('Gagal mengirim notifikasi: $error'),
  //           backgroundColor: Colors.red,
  //         ),
  //       );
  //     });
  //   }
  // }

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
              _buildButtonSelector(),
              const SizedBox(height: 30),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(left: 40.0, bottom: 16.0, right: 40.0),
            child: _buildCurrentSection(),
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
            onPressed: () {
              setState(() {
                _selectedSection = 0;
              });
            },
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
              'IKLAN UTAMA',
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
            onPressed: () {
              setState(() {
                _selectedSection = 1;
              });
            },
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
              'IKLAN NOTIFIKASI',
              style: TextStyle(
                color: _selectedSection == 1 ? Colors.white : Color(0xFF109E88),
                fontFamily: 'Afacad',
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                _selectedSection = 2;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _selectedSection == 2 ? Color(0xFF109E88) : Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: _selectedSection == 2 ? Colors.transparent : Color(0xFF109E88),
                  width: 1,
                ),
              ),
              elevation: 0,
            ),
            child: Text(
              'DAFTAR IKLAN YANG DIUPLOAD',
              style: TextStyle(
                color: _selectedSection == 2 ? Colors.white : Color(0xFF109E88),
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

  Widget _buildCurrentSection() {
    switch (_selectedSection) {
      case 0:
        return _buildBannerSection();
      case 1:
        return _buildNotifikasiSection();
      case 2:
        return _buildDaftarIklanSection();
      default:
        return _buildBannerSection();
    }
  }

  Widget _buildBannerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'UPLOAD BANNER IKLAN',
              style: TextStyle(
                fontFamily: 'Afacad',
                fontSize: 20,
                color: const Color(0xFF109E88),
                fontWeight: FontWeight.bold,
              ),
            ),
            ElevatedButton(
              onPressed: _uploadBanners,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: Text(
                  'UPLOAD SEMUA',
                style: TextStyle(
                  fontFamily: 'Afacad',
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // HAPUS TOMBOL "PILIH BANNER" KARENA SUDAH TIDAK DIBUTUHKAN
          ],
        ),

        SizedBox(height: 20),

        if (_isLoading) Center(child: CircularProgressIndicator()),

        // Tampilkan jumlah gambar yang dipilih
        if (_selectedImages.isNotEmpty || _selectedImagesBytes.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              '${kIsWeb ? _selectedImagesBytes.length : _selectedImages.length} banner dipilih',
              style: TextStyle(
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),

        // Informasi instruksi untuk user
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            'Klik pada kotak kosong untuk menambahkan banner',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontFamily: 'Afacad'
            ),
          ),
        ),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 350/260,
          ),
          itemCount: 5, // 5 box untuk banner
          itemBuilder: (context, index) {
            // Cek apakah box ini sudah ada gambar yang dipilih
            final hasSelectedImage = kIsWeb
                ? _selectedImagesBytes.containsKey(index)
                : _selectedImages.containsKey(index);

            // Cek apakah box ini sudah ada banner dari server
            final hasServerBanner = index < _banners.length;

            if (hasSelectedImage) {
              return _buildSelectedBannerCard(index);
            } else if (hasServerBanner) {
              return _buildBannerCard(_banners[index], index);
            } else {
              return _buildEmptyBannerCard(index);
            }
          },
        )
      ],
    );
  }

  Widget _buildSelectedBannerCard(int boxIndex) {
    return GestureDetector(
      onTap: () => _pickImageFromGallery(boxIndex),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF109E88), width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            // Tampilkan gambar yang dipilih
            if (kIsWeb && _selectedImagesBytes.containsKey(boxIndex))
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.memory(
                  _selectedImagesBytes[boxIndex]!,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.contain,
                ),
              )
            else if (!kIsWeb && _selectedImages.containsKey(boxIndex))
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.file(
                  _selectedImages[boxIndex]!,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

            // Overlay untuk ganti gambar
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(Icons.edit, color: Colors.white, size: 16),
              ),
            ),

            // Tombol hapus gambar
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    if (kIsWeb) {
                      _selectedImagesBytes.remove(boxIndex);
                      _selectedImageFileNames.remove(boxIndex);
                    } else {
                      _selectedImages.remove(boxIndex);
                    }
                  });
                },
                child: Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(Icons.close, color: Colors.white, size: 16),
                ),
              ),
            ),

            // Nomor box
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${boxIndex + 1}',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerCard(Map<String, dynamic> banner, int index) {
    final path = banner['path']?.toString() ?? '';
    final originalName = banner['originalName']?.toString() ?? 'Unknown';
    final isActive = banner['isActive'] ?? true;
    final bannerId = banner['_id']?.toString() ?? banner['id']?.toString() ?? '';

    return GestureDetector(
      onTap: () => _pickImageFromGallery(index),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                '${ApiService.basedUrl}$path',
                width: double.infinity,
                height: double.infinity,
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
                  return Container(
                    color: Colors.grey[200],
                    child: Icon(Icons.error_outline, color: Colors.red),
                  );
                },
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: Icon(Icons.delete, color: Colors.white, size: 18),
                onPressed: () => _deleteBanner(bannerId),
              ),
            ),
          ),
          if (!isActive)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: Colors.black54,
                child: Center(
                  child: Text(
                    'NON-AKTIF',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyBannerCard(int index) {
    return GestureDetector(
      onTap: () => _pickImageFromGallery(index),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey[400]),
            SizedBox(height: 8),
            Text(
              'Klik untuk upload',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Banner ${index + 1}',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotifikasiSection() {
    return Container(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Judul Notifikasi :',
              style: TextStyle(
                fontFamily: 'Afacad',
                fontSize: 20,
                color: const Color(0xFF109E88),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _judulController,
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
                hintText: 'Masukkan judul notifikasi',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Judul tidak boleh kosong';
                }
                return null;
              },
            ),
            SizedBox(height: 20),
            Text(
              'Isi Notifikasi :',
              style: TextStyle(
                fontFamily: 'Afacad',
                fontSize: 20,
                color: const Color(0xFF109E88),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _isiController,
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
                hintText: 'Masukkan isi notifikasi',
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Isi notifikasi tidak boleh kosong';
                }
                return null;
              },
            ),
            SizedBox(height: 20),
            // SizedBox(
            //   width: double.infinity,
            //   child: ElevatedButton(
            //     onPressed: /* _submitNotifikasi,*/
            //     style: ElevatedButton.styleFrom(
            //       backgroundColor: Color(0xFF109E88),
            //       padding: EdgeInsets.symmetric(vertical: 16),
            //       shape: RoundedRectangleBorder(
            //         borderRadius: BorderRadius.circular(8),
            //       ),
            //     ),
            //     child: Text(
            //       'KIRIM NOTIFIKASI',
            //       style: TextStyle(
            //         color: Colors.white,
            //         fontFamily: 'Afacad',
            //         fontWeight: FontWeight.bold,
            //         fontSize: 16,
            //       ),
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildDaftarIklanSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Daftar Iklan yang Diupload',
          style: TextStyle(
            fontFamily: 'HindSiliguri',
            fontSize: 20,
            color: const Color(0xFF109E88),
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 20),

        if (_isLoading)
          Center(child: CircularProgressIndicator()),

        if (_banners.isEmpty && !_isLoading)
          Center(
            child: Text(
              'Belum ada iklan yang diupload',
              style: TextStyle(
                fontFamily: 'Afacad',
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ),

        if (_banners.isNotEmpty)
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: _banners.length,
            itemBuilder: (context, index) {
              final banner = _banners[index];
              final originalName = banner['originalName']?.toString() ?? 'Unknown';
              final uploadedAt = _parseDate(banner['uploadedAt']);
              final uploadedByName = banner['uploadedBy'] != null
                  ? (banner['uploadedBy']['nama']?.toString() ?? 'Unknown')
                  : 'Unknown';
              final isActive = banner['isActive'] ?? true;

              return Container(
                margin: EdgeInsets.only(bottom: 12),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Color(0xFFD9D9D9),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            originalName,
                            style: TextStyle(
                              fontFamily: 'Afacad',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Tanggal: ${_formatDate(uploadedAt)}',
                            style: TextStyle(
                              fontFamily: 'Afacad',
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Diupload oleh: $uploadedByName',
                            style: TextStyle(
                              fontFamily: 'Afacad',
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isActive ? Colors.green[100] : Colors.red[100],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        isActive ? 'Aktif' : 'Tidak Aktif',
                        style: TextStyle(
                          color: isActive ? Colors.green[800] : Colors.red[800],
                          fontFamily: 'Afacad',
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  DateTime _parseDate(dynamic date) {
    if (date is String) {
      return DateTime.parse(date);
    } else if (date is Map<String, dynamic> && date['\$date'] != null) {
      return DateTime.parse(date['\$date']);
    } else {
      return DateTime.now();
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Iklan',
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

