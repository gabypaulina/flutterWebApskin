import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

class DetailArtikel extends StatefulWidget {
  final String articleId;

  const DetailArtikel({
    Key? key,
    required this.articleId,
  }) : super(key: key);

  @override
  _DetailArtikelState createState() => _DetailArtikelState();
}

class _DetailArtikelState extends State<DetailArtikel> {
  Map<String, dynamic>? article;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadArticle();
  }

  Future<void> _loadArticle() async {
    try {
      final data = await ApiService.getArticle(widget.articleId);
      setState(() {
        article = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat artikel: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar('Memuat...'),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (article == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar('Artikel Tidak Ditemukan'),
        body: Center(child: Text('Artikel tidak ditemukan')),
      );
    }

    final date = DateTime.parse(article!['createdAt']);
    final formattedDate = DateFormat('dd MMMM yyyy').format(date);
    final String imageUrl = article!['gambar'].startsWith('http')
      ? article!['gambar']
      : '${ApiService.basedUrl}${article!['gambar']}';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(article!['judul']),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image_not_supported,
                              size: 40, color: Colors.grey[400]),
                          SizedBox(height: 8),
                          Text(
                            'Gambar tidak dapat dimuat',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                              fontFamily: 'Afacad',
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            SizedBox(height: 40),
            Row(
              children: [
                Icon(Icons.person_outline, size: 16, color: Color(0xFF109E88)),
                SizedBox(width: 4),
                Text(
                  article!['sumber'],
                  style: TextStyle(
                    fontFamily: 'Afacad',
                    fontSize: 14,
                    color: Color(0xFF109E88),
                  ),
                ),
                Spacer(),
                Icon(Icons.calendar_today, size: 16, color: Color(0xFF109E88)),
                SizedBox(width: 4),
                Text(
                  formattedDate,
                  style: TextStyle(
                    fontFamily: 'Afacad',
                    fontSize: 14,
                    color: Color(0xFF109E88),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Text(
              article!['isi'],
              style: TextStyle(
                fontFamily: 'Afacad',
                fontSize: 16,
                height: 1.6,
                color: Color(0xFF109E88)
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(String title) {
    return PreferredSize(
      preferredSize: Size.fromHeight(120.0), // Tinggi yang lebih besar untuk menampung 2 baris
      child: Container(
        padding: const EdgeInsets.only(top: 30.0, left: 20, right: 20, bottom: 20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Color(0xFF109E88),
                  width: 1.0,
                ),
              ),
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: Color(0xFF109E88)),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            SizedBox(width: 16), // Jarak antara tombol back dan judul
            Expanded(
              child: Container(
                alignment: Alignment.center,
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Afacad',
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    color: Color(0xFF109E88),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2, // Maksimal 2 baris
                  overflow: TextOverflow.ellipsis, // ... jika masih terlalu panjang
                ),
              ),
            ),
            SizedBox(width: 48), // Spacer untuk menyeimbangkan layout
          ],
        ),
      ),
    );
  }
}