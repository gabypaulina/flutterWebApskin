import 'package:apskina/pages/user/detail_artikel.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';

class HalamanArtikel extends StatefulWidget {
  const HalamanArtikel({Key? key}) : super(key: key);

  @override
  _HalamanArtikelState createState() => _HalamanArtikelState();
}

class _HalamanArtikelState extends State<HalamanArtikel> {
  List<dynamic> articles = [];
  bool isLoading = true;
  int currentPage = 1;
  final int itemsPerPage = 8;
  int totalArticles = 0;

  @override
  void initState() {
    super.initState();
    _loadArticles();
  }

  Future<void> _loadArticles() async {
    try {
      final data = await ApiService.getArticles();
      setState(() {
        articles = data;
        totalArticles = data.length;
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

  List<dynamic> get paginatedArticles {
    final startIndex = (currentPage - 1) * itemsPerPage;
    final endIndex = startIndex + itemsPerPage;
    return articles.sublist(
      startIndex,
      endIndex > articles.length ? articles.length : endIndex,
    );
  }

  int get totalPages => (totalArticles / itemsPerPage).ceil();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final imageHeight = 140.0; // Tinggi gambar tetap, sama dengan home

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100.0),
        child: Padding(
          padding: const EdgeInsets.only(top: 30.0, left: 20, right: 20, bottom: 30.0),
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
              Expanded(
                child: Center(
                  child: Text(
                    'Daftar Artikel',
                    style: TextStyle(
                      fontFamily: 'Afacad',
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      color: Color(0xFF109E88),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Center(
                child: Container(
                  constraints: BoxConstraints(maxWidth: 900),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: screenWidth > 800 ? 3 : 2,
                      childAspectRatio: 180 / (imageHeight + 150), // Sesuaikan aspect ratio
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                    ),
                    itemCount: paginatedArticles.length,
                    itemBuilder: (context, index) {
                      final article = paginatedArticles[index];
                      final date = DateTime.parse(article['createdAt']);
                      final formattedDate = DateFormat('dd MMM yyyy').format(date);

                      return _buildArtikelCard(
                        article['judul'],
                        formattedDate,
                        article['gambar'],
                        article['_id'],
                        imageHeight,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          if (totalPages > 1)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.chevron_left),
                    onPressed: currentPage > 1
                        ? () {
                      setState(() {
                        currentPage--;
                      });
                    }
                        : null,
                  ),
                  for (int i = 1; i <= totalPages; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            currentPage = i;
                          });
                        },
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: currentPage == i ? Color(0xFF109E88) : Colors.transparent,
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                              color: currentPage == i ? Color(0xFF109E88) : Colors.grey,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$i',
                            style: TextStyle(
                              color: currentPage == i ? Colors.white : Colors.black,
                              fontFamily: 'Afacad',
                            ),
                          ),
                        ),
                      ),
                    ),
                  IconButton(
                    icon: Icon(Icons.chevron_right),
                    onPressed: currentPage < totalPages
                        ? () {
                      setState(() {
                        currentPage++;
                      });
                    }
                        : null,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildArtikelCard(String title, String date, String image, String articleId, double imageHeight) {
    final fullImageUrl = '${ApiService.basedUrl}$image';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailArtikel(articleId: articleId),
          ),
        );
      },
      child: Container(
        width: 180, // Lebar sama dengan home (180px)
        height: imageHeight + 150, // Tinggi sama dengan home (140 + 110 = 250px)
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.grey[300]!,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: imageHeight, // Tinggi gambar sama dengan home
              width: 180, // Lebar sama dengan home
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
              ),
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
                  return _buildImagePlaceholder();
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                        fontFamily: 'Afacad',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF109E88)
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 6),
                  Text(
                    date,
                    style: TextStyle(
                      fontFamily: 'Afacad',
                      fontSize: 10,
                      color: Colors.grey[600],
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

  Widget _buildImagePlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_not_supported, size: 40, color: Colors.grey[400]),
          SizedBox(height: 8),
          Text(
            'Gambar tidak tersedia',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}