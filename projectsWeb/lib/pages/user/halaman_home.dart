import 'dart:async';
import 'dart:convert';

import 'package:apskina/navigasi/navigasi_bar.dart';
import 'package:apskina/pages/user/detail_artikel.dart';
import 'package:apskina/pages/user/ruang_konsultasi.dart';
import 'package:apskina/pages/user/skincare_item.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_service.dart';
import 'detail_reservasi.dart';
import 'halaman_rutinitas.dart';

class HalamanHome extends StatefulWidget {
  @override
  _HalamanHomeState createState() => _HalamanHomeState();
}

class _HalamanHomeState extends State<HalamanHome> {
  String nama ='';
  String nearestReservation = '';
  String nearestReservationType = '';
  bool hasReservation = false;
  int poin = 0;
  int rutinitas = 0;
  bool isLoading = true;
  List<SkincareItem> userSkincareItems = [];
  List<Map<String, dynamic>> banners = [];
  Map<String, dynamic>? reservationData;
  int _currentBannerIndex = 0;
  Timer? _bannerTimer;
  PageController? _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.95);
    _loadUserData().then((_) {
      _loadUserSkincare();
      _loadBanners().catchError((error) {
        print('Failed to load banners: $error');
        setState(() {
          banners = [];
        });
      });
      _loadReservationData();
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _pageController?.dispose();
    super.dispose();
  }

  Future<void> _loadBanners() async {
    try {
      final bannersData = await ApiService.getBanners();

      // Debug: print first banner structure
      if (bannersData.isNotEmpty) {
        print('First banner keys: ${bannersData[0].keys}');
        print('First banner data: ${bannersData[0]}');
      }

      // Filter hanya banner yang aktif dan memiliki path yang valid
      final validBanners = bannersData.where((banner) {
        final path = banner['path']?.toString() ?? '';
        final isActive = banner['isActive'] ?? true;

        return path.isNotEmpty && isActive;
      }).toList();

      setState(() {
        banners = validBanners;
      });

      // Start automatic slideshow jika ada lebih dari 1 banner
      if (banners.length > 1) {
        _startBannerSlideshow();
      }
    } catch (e) {
      print('Error loading banners: $e');
      setState(() {
        banners = [];
      });
    }
  }

  void _startBannerSlideshow() {
    _bannerTimer?.cancel();

    // Hanya mulai slideshow jika ada banner
    if (banners.isEmpty) return;

    _bannerTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      if (mounted) {
        int nextPage;
        if (_currentBannerIndex >= banners.length - 1) {
          nextPage = 0; // Kembali ke awal
        } else {
          nextPage = _currentBannerIndex + 1;
        }

        // Animate to page dengan controller
        _pageController?.animateToPage(
          nextPage,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');

    if (userJson != null) {
      final userData = jsonDecode(userJson) as Map<String, dynamic>;
      setState(() {
        nama = userData['nama'];
        hasReservation = userData['reservasi'] ?? false;
        poin = userData['poin'] ?? 0;
        rutinitas = userData['rutinitasHarian'] ?? 0;
        isLoading = false;
      });

      try {
        final reservations = await ApiService.getUserReservations();

        // Cari reservasi yang statusnya bukan dibatalkan atau selesai
        final activeReservations = reservations.where((reservation) =>
        reservation['status'] != 'dibatalkan' &&
            reservation['status'] != 'selesai'
        ).toList();

        if (activeReservations.isNotEmpty) {
          // Sort by date to find the nearest one
          activeReservations.sort((a, b) {
            try {
              // Handle date format "dd/mm/yyyy"
              final datePartsA = (a['tanggalReservasi'] ?? '').toString().split('/');
              final datePartsB = (b['tanggalReservasi'] ?? '').toString().split('/');

              if (datePartsA.length == 3 && datePartsB.length == 3) {
                final dateA = DateTime.parse('${datePartsA[2]}-${datePartsA[1]}-${datePartsA[0]}');
                final dateB = DateTime.parse('${datePartsB[2]}-${datePartsB[1]}-${datePartsB[0]}');
                return dateA.compareTo(dateB);
              }
              return 0;
            } catch (e) {
              return 0;
            }
          });

          setState(() {
            hasReservation = true;
            nearestReservation = activeReservations.first['tipe'] ?? 'Reservasi';
          });
        } else {
          setState(() {
            hasReservation = false;
            nearestReservation = '';
          });
        }
      } catch (e) {
        print('Error loading reservations: $e');
        setState(() {
          hasReservation = false;
          nearestReservation = '';
        });
      }
    }
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _loadUserSkincare() async {
    try {
      final skincareData = await ApiService.getUserSkincare();
      setState(() {
        userSkincareItems = skincareData.map((item) => SkincareItem.fromMap(item)).toList();
      });
    } catch (e) {
      print('Error loading user skincare: $e');
    }
  }

  // Add this method to load reservation data
  Future<void> _loadReservationData() async {
    try {
      final reservations = await ApiService.getUserReservations();

      // Find active reservations
      final activeReservations = reservations.where((reservation) =>
      reservation['status'] != 'dibatalkan' &&
          reservation['status'] != 'selesai'
      ).toList();

      if (activeReservations.isNotEmpty) {
        // Sort by date to find the nearest one
        activeReservations.sort((a, b) {
          try {
            final datePartsA = (a['tanggalReservasi'] ?? '').toString().split('/');
            final datePartsB = (b['tanggalReservasi'] ?? '').toString().split('/');

            if (datePartsA.length == 3 && datePartsB.length == 3) {
              final dateA = DateTime.parse('${datePartsA[2]}-${datePartsA[1]}-${datePartsA[0]}');
              final dateB = DateTime.parse('${datePartsB[2]}-${datePartsB[1]}-${datePartsB[0]}');
              return dateA.compareTo(dateB);
            }
            return 0;
          } catch (e) {
            return 0;
          }
        });

        final nearestReservation = activeReservations.first;

        // If it's a medical/consultation reservation, get doctor info
        if (nearestReservation['tipe'] == 'MEDIS' || nearestReservation['tipe'] == 'KONSULTASI') {
          try {
            final doctors = await ApiService.getDokter();
            final doctor = doctors.firstWhere(
                    (doc) => doc['_id'] == nearestReservation['pic'] || doc['nama'] == nearestReservation['pic'],
                orElse: () => null
            );

            if (doctor != null) {
              setState(() {
                reservationData = {
                  ...nearestReservation,
                  'doctorInfo': doctor
                };
              });
            } else {
              setState(() {
                reservationData = nearestReservation;
              });
            }
          } catch (e) {
            print('Error loading doctor info: $e');
            setState(() {
              reservationData = nearestReservation;
            });
          }
        } else {
          setState(() {
            reservationData = nearestReservation;
          });
        }

        setState(() {
          hasReservation = true;
          nearestReservationType = nearestReservation['tipe'] ?? 'Reservasi';
        });
      } else {
        setState(() {
          hasReservation = false;
          nearestReservationType = '';
          reservationData = null;
        });
      }
    } catch (e) {
      print('Error loading reservations: $e');
      setState(() {
        hasReservation = false;
        nearestReservationType = '';
        reservationData = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final imageHeight = 140.0; // Tinggi gambar tetap

    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
        backgroundColor: Colors.white,
        body: CustomScrollView(
          slivers: [
            // Header section with green background
            SliverToBoxAdapter(
              child: Container(
                color: const Color(0xFF109E88),
                padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Selamat Datang, $nama!',
                              style: TextStyle(
                                fontFamily: 'Afacad',
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Pancarkan kecantikanmu',
                              style: TextStyle(
                                fontFamily: 'Afacad',
                                fontSize: 13,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const Icon(Icons.notifications, color: Colors.white, size: 28),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Reservasi Anda',
                          style: TextStyle(
                            fontFamily: 'Afacad',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Poin: $poin',
                          style: TextStyle(
                            fontFamily: 'Afacad',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Main content
            SliverList(
              delegate: SliverChildListDelegate([
                // Container reservasi
                // Di dalam build method, update bagian reservasi:
                Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (hasReservation && reservationData != null) ...[
                          // Tampilkan info dokter jika ada
                          if (reservationData!['doctorInfo'] != null)
                            Column(
                              children: [
                                // Foto dokter
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    image: DecorationImage(
                                      image: NetworkImage(
                                          '${ApiService.basedUrl}${reservationData!['doctorInfo']['foto']}'
                                      ),
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                // Nama dokter
                                Text(
                                  reservationData!['doctorInfo']['nama'] ?? 'Dokter',
                                  style: TextStyle(
                                    fontFamily: 'Afacad',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: const Color(0xFF109E88),
                                  ),
                                ),
                                // Spesialis dokter
                                Text(
                                  reservationData!['doctorInfo']['spesialis'] ?? 'Spesialis',
                                  style: TextStyle(
                                    fontFamily: 'Afacad',
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 10),
                              ],
                            ),

                          // Info reservasi
                          Text(
                            '${reservationData!['tipe']} - ${reservationData!['jamReservasi']}',
                            style: TextStyle(
                              fontFamily: 'Afacad',
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: const Color(0xFF109E88),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ] else
                          Text(
                            hasReservation ? 'Punya Reservasi' : 'Belum Ada Reservasi',
                            style: TextStyle(
                              fontFamily: 'Afacad',
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: const Color(0xFF109E88),
                            ),
                            textAlign: TextAlign.center,
                          ),

                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              if (hasReservation && reservationData != null) {
                                // Navigasi ke halaman detail reservasi
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DetailReservasi(
                                      reservation: reservationData!,
                                    ),
                                  ),
                                );
                              } else {
                                Navigator.pushNamed(context, '/reservasi');
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF109E88),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              hasReservation ? 'LIHAT RESERVASI' : 'BUAT RESERVASI',
                              style: TextStyle(
                                fontFamily: 'Afacad',
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    children: [
                      // Rutinitas Harian
                      // Rutinitas Harian - Menjadi clickable
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HalamanRutinitas(userSkincareItems: userSkincareItems),
                            ),
                          );
                        },
                        child: Container(
                          width: 250,
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: const Color(0xFF109E88),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today, color: Colors.white),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Rutinitas Harian',
                                    style: TextStyle(
                                      fontFamily: 'Afacad',
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '$rutinitas%',
                                style: TextStyle(
                                  fontFamily: 'Afacad',
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Banner Iklan
                      _buildBannerSection(),
                      const SizedBox(height: 20),

                      // Treatment Options - Responsive
                      // LayoutBuilder(
                      //   builder: (context, constraints) {
                      //     final treatmentSize = constraints.maxWidth / 5; // Responsive size based on screen width
                      //     return Row(
                      //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      //       children: [
                      //         _buildTreatmentOption('kondisi_kulit/jerawat.png', treatmentSize),
                      //         _buildTreatmentOption('images/kondisi_kulit/kusam.png', treatmentSize),
                      //         _buildTreatmentOption('images/kondisi_kulit/kerutan.png', treatmentSize),
                      //         _buildTreatmentOption('images/kondisi_kulit/flekhitam.png', treatmentSize),
                      //       ],
                      //     );
                      //   },
                      // ),
                      // const SizedBox(height: 20),

                      // Artikel Section - Fixed version
                      FutureBuilder<List<dynamic>>(
                        future: ApiService.getArticles(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'ARTIKEL KESEHATAN',
                                      style: TextStyle(
                                        fontFamily: 'Afacad',
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF109E88),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.pushNamed(context, '/artikel');
                                      },
                                      child: Text(
                                        'View All',
                                        style: TextStyle(
                                          fontFamily: 'Afacad',
                                          fontSize: 14,
                                          color: Color(0xFF109E88),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 10),
                                Center(child: CircularProgressIndicator()),
                              ],
                            );
                          }

                          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'ARTIKEL KESEHATAN',
                                      style: TextStyle(
                                        fontFamily: 'Afacad',
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF109E88),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.pushNamed(context, '/artikel');
                                      },
                                      child: Text(
                                        'View All',
                                        style: TextStyle(
                                          fontFamily: 'Afacad',
                                          fontSize: 14,
                                          color: Color(0xFF109E88),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 10),
                                Text('Tidak ada artikel tersedia'),
                              ],
                            );
                          }

                          final articles = snapshot.data!.take(3).toList(); // Show only 3 latest

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'ARTIKEL KESEHATAN',
                                    style: TextStyle(
                                      fontFamily: 'Afacad',
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF109E88),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.pushNamed(context, '/artikel');
                                    },
                                    child: Text(
                                      'View All',
                                      style: TextStyle(
                                        fontFamily: 'Afacad',
                                        fontSize: 14,
                                        color: Color(0xFF109E88),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 10),
                              Container(
                                height: imageHeight + 110, // Tinggi gambar + konten teks
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  padding: EdgeInsets.only(right: 20), // Hanya padding kanan, kiri tidak ada (rata kiri)
                                  itemCount: articles.length,
                                  separatorBuilder: (context, index) => SizedBox(width: 16), // Jarak antar artikel
                                  itemBuilder: (context, index) {
                                    final article = articles[index];
                                    final date = DateTime.parse(article['createdAt']);
                                    final formattedDate = DateFormat('dd MMM yyyy').format(date);

                                    return GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => DetailArtikel(articleId: article['_id']),
                                          ),
                                        );
                                      },
                                      child: _buildArtikelCard(
                                        article['judul'],
                                        formattedDate,
                                        article['gambar'],
                                        imageHeight,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ]),
            ),
          ],
        ),
        bottomNavigationBar: NavigasiBar(
          currentIndex: 0, // Current page index (4 for profile)
          context: context, // Pass the context
        )
    );
  }

  // Widget _buildTreatmentOption(String imagePath, double size) {
  //   return Column(
  //       children: [
  //         Container(
  //           width: size,
  //           height: size,
  //           decoration: BoxDecoration(
  //             borderRadius: BorderRadius.circular(15),
  //             image: DecorationImage(
  //               image: AssetImage(imagePath),
  //               fit: BoxFit.cover,
  //             ),
  //           ),
  //         ),
  //         Text(
  //           '$imagePath',
  //           style: TextStyle(
  //             fontSize: 12
  //           ),
  //         ),
  //       ]
  //   );
  // }

  Widget _buildArtikelCard(String title, String date, String imageUrl, double imageHeight) {
    final fullImageUrl = '${ApiService.basedUrl}$imageUrl';

    return Container(
      width: 180, // Lebar tetap 200px
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
            height: imageHeight,
            width: 180, // Lebar tetap 200px
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
            )
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Afacad',
                    fontSize: 13,
                    color: Color(0xFF109E88),
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  date,
                  style: const TextStyle(
                    fontFamily: 'Afacad',
                    fontSize: 10,
                    color: Color(0xFF109E88),
                  ),
                ),
              ],
            ),
          ),
        ],
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

  Widget _buildBannerSection() {
    if (banners.isEmpty) {
      return SizedBox.shrink();
    }

    return Container(
      height: 200,
      width: 300,
      child: Stack(
        children: [
          // Banner Image
          PageView.builder(
            controller: _pageController,

            itemCount: banners.length,
            onPageChanged: (index) {
              setState(() {
                _currentBannerIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final banner = banners[index];

              // Gunakan null-aware operator untuk menghindari error
              final path = banner['path']?.toString() ?? '';

              if (path.isEmpty) {
                return _buildBannerPlaceholder();
              }

              final imageUrl = '${ApiService.basedUrl}$path';

              return Container(
                margin: EdgeInsets.symmetric(horizontal: 5),

                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    width: double.infinity,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return _buildBannerPlaceholder();
                    },
                    errorBuilder: (context, error, stackTrace) {
                      print('Error loading banner image: $error');
                      return _buildBannerPlaceholder();
                    },
                  ),
                ),
              );
            },
          ),

          // Indicator dots (jika ada lebih dari 1 banner)
          if (banners.length > 1)
            Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(banners.length, (index) {
                  return Container(
                    width: 8,
                    height: 8,
                    margin: EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentBannerIndex == index
                          ? Colors.white
                          : Colors.white.withOpacity(0.5),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBannerPlaceholder() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Icon(Icons.image, color: Colors.grey[400], size: 40),
      ),
    );
  }
}


