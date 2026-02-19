import 'package:apskina/pages/admin/tambah_treatment.dart';
import 'package:flutter/material.dart';
import '../../navigasi/navigasi_sidebar.dart';
import '../../services/api_service.dart';
import 'edit_treatment.dart';

class MenuTreatment extends StatefulWidget {
  const MenuTreatment({Key? key}) : super(key: key);

  @override
  _MenuTreatmentState createState() => _MenuTreatmentState();
}

class _MenuTreatmentState extends State<MenuTreatment> {
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
            child: TreatmentContent(),
          ),
        ],
      ),
    );
  }
}

class TreatmentContent extends StatefulWidget {
  const TreatmentContent({Key? key}) : super(key: key);

  @override
  _TreatmentContentState createState() => _TreatmentContentState();
}

class _TreatmentContentState extends State<TreatmentContent> {
  List<dynamic> treatments = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadTreatments();
  }

  void _deleteTreatments(String treatmentId) async {
    // Simpan data treatment yang akan dihapus untuk fallback
    final treatmentToDelete = treatments.firstWhere(
          (treatment) => treatment['_id'] == treatmentId,
      orElse: () => {},
    );

    // Optimistic update: hapus dari UI dulu
    setState(() {
      treatments.removeWhere((treatment) => treatment['_id'] == treatmentId);
    });

    try {
      // Panggil API delete
      await ApiService.deleteTreatment(treatmentId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Treatment berhasil dihapus'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Jika gagal, kembalikan data treatment
      if (treatmentToDelete.isNotEmpty) {
        setState(() {
          treatments.add(treatmentToDelete);
          // Urutkan kembali berdasarkan tanggal terbaru
          treatments.sort((a, b) {
            final dateA = DateTime.parse(a['createdAt'] ?? a['tanggalPembuatan'] ?? '');
            final dateB = DateTime.parse(b['createdAt'] ?? b['tanggalPembuatan'] ?? '');
            return dateB.compareTo(dateA);
          });
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus treatment: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDeleteConfirmation(String treatmentId, String judul) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Hapus Treatment',
            style: TextStyle(
              fontFamily: 'Afacad',
              fontWeight: FontWeight.bold,
              color: Color(0xFF109E88),
            ),
          ),
          content: Text(
            'Apakah Anda yakin ingin menghapus treatment "${judul.length > 50 ? '${judul.substring(0, 50)}...' : judul}"?',
            style: TextStyle(
              fontFamily: 'Afacad',
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Batal',
                style: TextStyle(
                  fontFamily: 'Afacad',
                  color: Colors.grey[600],
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Tutup dialog
                _deleteTreatments(treatmentId);
              },
              child: Text(
                'Hapus',
                style: TextStyle(
                  fontFamily: 'Afacad',
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _editTreatment(String treatmentId) {
    // Cari treatment yang dipilih
    final treatment = treatments.firstWhere((art) => art['_id'] == treatmentId,
        orElse: () => {});

    if (treatment.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditTreatment(treatment: treatment),
        ),
      ).then((result) {
        // Refresh data setelah edit
        if (result == true) {
          _loadTreatments();
        }
      });
    }
  }

  Future<void> _loadTreatments() async {
    setState(() {
      isLoading = false;
    });

    try {
      final data = await ApiService.getTreatments();
      setState(() {
        treatments = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Gagal memuat treatment: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.only(left: 40.0, bottom: 16.0, top: 16.0, right: 40.0),
          child : Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF109E88),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    // Navigate to TambahTreatment dan tunggu result
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const TambahTreatment()),
                    ).then((result) {
                      // Jika result adalah true, refresh data treatment
                      if (result == true) {
                        _loadTreatments(); // Panggil method untuk reload data
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Treatment berhasil ditambahkan!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    });
                  },
                  child: const Text(
                    'TAMBAH TREATMENT',
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
          )
        ),

        Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(left: 40.0, bottom: 16.0, right: 40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isLoading)
                    Center(child: CircularProgressIndicator(color: Color(0xFF109E88)))
                  else if (errorMessage.isNotEmpty)
                    Center(
                      child: Text(
                        errorMessage,
                        style: TextStyle(
                          fontFamily: 'Afacad',
                          fontSize: 16,
                          color: Colors.red,
                        ),
                      ),
                    )
                  else if (treatments.isEmpty)
                      Center(
                        child: Text(
                          'Belum ada treatment',
                          style: TextStyle(
                            fontFamily: 'Afacad',
                            fontSize: 16,
                            color: Color(0xFF109E88),
                          ),
                        ),
                      )
                    else
                      Column(
                        children: treatments.map((treatment) {
                          return Column(
                            children: [
                              _buildTreatmentCard(
                                treatment['judul'] ?? 'No Title',
                                treatment['pic'] ?? 'Unknown',
                                treatment['isi'] ?? 'No Content',
                                treatment['_id'] ?? '',
                              ),
                              const SizedBox(height: 16),
                            ],
                          );
                        }).toList(),
                      ),
                ]
              ),
            )
        )
      ],
    );
  }

  Widget _buildTreatmentCard(String judul, String pic, String isi, String treatmentId) {
    final truncatedIsi = isi.length > 500 ? '${isi.substring(0, 500)}...' : isi;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: Colors.grey.withOpacity(0.25),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Treatment Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$judul - $pic',
                              style: const TextStyle(
                                fontFamily: 'Afacad',
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF109E88),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                          ],
                        ),
                      ),
                      // Edit and Delete Icons
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Color(0xFF109E88)),
                            onPressed: () {
                              // Handle edit
                              _editTreatment(treatmentId);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Color(0xFF109E88)),
                            onPressed: () {
                              // Handle delete
                              _showDeleteConfirmation(treatmentId, judul);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    truncatedIsi,
                    style: const TextStyle(
                      fontFamily: 'Afacad',
                      fontSize: 16,
                      color: Color(0xFF109E88),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
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
              'Treatment',
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