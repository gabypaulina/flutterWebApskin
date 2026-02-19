import 'package:apskina/pages/admin/tambah_artikel.dart';
import 'package:flutter/material.dart';
import '../../navigasi/navigasi_sidebar.dart';
import '../../services/api_service.dart';
import 'edit_artikel.dart';

class MenuArtikel extends StatefulWidget {
  const MenuArtikel({Key? key}) : super(key: key);

  @override
  _MenuArtikelState createState() => _MenuArtikelState();
}

class _MenuArtikelState extends State<MenuArtikel> {
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
            child: ArtikelContent(),
          ),
        ],
      ),
    );
  }
}

class ArtikelContent extends StatefulWidget {
  const ArtikelContent({Key? key}) : super(key: key);

  @override
  _ArtikelContentState createState() => _ArtikelContentState();
}

class _ArtikelContentState extends State<ArtikelContent> {
  List<dynamic> articles = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadArticles();
  }

  void _deleteArticle(String articleId) async {
    // Simpan data artikel yang akan dihapus untuk fallback
    final articleToDelete = articles.firstWhere(
          (article) => article['_id'] == articleId,
      orElse: () => {},
    );

    // Optimistic update: hapus dari UI dulu
    setState(() {
      articles.removeWhere((article) => article['_id'] == articleId);
    });

    try {
      // Panggil API delete
      await ApiService.deleteArticle(articleId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Artikel berhasil dihapus'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Jika gagal, kembalikan data artikel
      if (articleToDelete.isNotEmpty) {
        setState(() {
          articles.add(articleToDelete);
          // Urutkan kembali berdasarkan tanggal terbaru
          articles.sort((a, b) {
            final dateA = DateTime.parse(a['createdAt'] ?? a['tanggalPembuatan'] ?? '');
            final dateB = DateTime.parse(b['createdAt'] ?? b['tanggalPembuatan'] ?? '');
            return dateB.compareTo(dateA);
          });
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus artikel: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _editArticle(String articleId) {
    // Cari artikel yang dipilih
    final article = articles.firstWhere((art) => art['_id'] == articleId,
        orElse: () => {});

    if (article.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditArtikel(artikel: article),
        ),
      ).then((result) {
        // Refresh data setelah edit
        if (result == true) {
          _loadArticles();
        }
      });
    }
  }

  // Di _ArtikelContentState tambahkan method ini:
  void _showDeleteConfirmation(String articleId, String judul) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Hapus Artikel',
            style: TextStyle(
              fontFamily: 'Afacad',
              fontWeight: FontWeight.bold,
              color: Color(0xFF109E88),
            ),
          ),
          content: Text(
            'Apakah Anda yakin ingin menghapus artikel "${judul.length > 50 ? '${judul.substring(0, 50)}...' : judul}"?',
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
                _deleteArticle(articleId);
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

  Future<void> _loadArticles() async {
    setState(() {
      isLoading = true;
    });

    try {
      final data = await ApiService.getArticles();
      setState(() {
        articles = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Gagal memuat artikel: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  // Format tanggal menjadi "dd Month yyyy"
  String _formatTanggal(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final monthNames = {
        1: 'Jan', 2: 'Feb', 3: 'Mar', 4: 'Apr', 5: 'Mei', 6: 'Jun',
        7: 'Jul', 8: 'Agu', 9: 'Sep', 10: 'Okt', 11: 'Nov', 12: 'Des'
      };

      final day = date.day.toString().padLeft(2, '0');
      final month = monthNames[date.month] ?? 'Jan';
      final year = date.year;

      return '$day $month $year';
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header dan Tombol Tambah Artikel yang tetap di atas
        Container(
          padding: const EdgeInsets.only(left: 40.0, top: 16.0, right: 40.0),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 30),
              // Tambah Artikel Button - sekarang bagian dari header yang tetap
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
                    // Navigate to TambahArtikel dan tunggu result
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const TambahArtikel()),
                    ).then((result) {
                      // Jika result adalah true, refresh data artikel
                      if (result == true) {
                        _loadArticles(); // Panggil method untuk reload data
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Artikel berhasil ditambahkan!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    });
                  },
                  child: const Text(
                    'TAMBAH ARTIKEL',
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

        // Hanya Artikel List yang bisa discroll
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
                else if (articles.isEmpty)
                    Center(
                      child: Text(
                        'Belum ada artikel',
                        style: TextStyle(
                          fontFamily: 'Afacad',
                          fontSize: 16,
                          color: Color(0xFF109E88),
                        ),
                      ),
                    )
                  else
                    Column(
                      children: articles.map((article) {
                        return Column(
                          children: [
                            _buildArtikelCard(
                              article['judul'] ?? 'No Title',
                              article['sumber'] ?? 'Unknown Source',
                              article['isi'] ?? 'No Content',
                              _formatTanggal(article['createdAt'] ?? article['tanggalPembuatan'] ?? DateTime.now().toString()),
                              article['gambar'] ?? '',
                              article['_id'] ?? '',
                            ),
                            const SizedBox(height: 16),
                          ],
                        );
                      }).toList(),
                    ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildArtikelCard(String judul, String sumber, String isi, String tanggal, String gambarUrl, String articleId) {
    final truncatedIsi = isi.length > 200 ? '${isi.substring(0, 200)}...' : isi;
    final fullImageUrl = '${ApiService.basedUrl}$gambarUrl';

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
            // Artikel Image
            Container(
                width: 200,
                height: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      fullImageUrl,
                      fit: BoxFit.contain,
                      width: 200,
                      height: 140,
                      loadingBuilder: (context,child, loadingProgress) {
                        if(loadingProgress == null) return child;
                        return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                  : null,
                              color: Color(0xFF109E88),
                            )
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.contain,
                          width: 200,
                          height: 140,
                        );
                      },
                    )
                )
            ),
            const SizedBox(width: 16),
            // Artikel Content
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
                              judul,
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
                            Text(
                              'Sumber: $sumber',
                              style: const TextStyle(
                                fontFamily: 'Afacad',
                                fontSize: 16,
                                color: Color(0xFF109E88),
                              ),
                            ),
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
                              _editArticle(articleId);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Color(0xFF109E88)),
                            onPressed: () {
                              // Handle delete
                              _showDeleteConfirmation(articleId, judul);
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
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      tanggal,
                      style: const TextStyle(
                        fontFamily: 'Afacad',
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ),
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
              'Artikel',
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