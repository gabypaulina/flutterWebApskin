import 'package:flutter/material.dart';
import 'package:apskina/navigasi/navigasi_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../services/api_service.dart';

class HalamanTreatment extends StatefulWidget {
  const HalamanTreatment({Key? key}) : super(key: key);

  @override
  _HalamanTreatmentState createState() => _HalamanTreatmentState();
}

class _HalamanTreatmentState extends State<HalamanTreatment> {
  List<Treatment> treatments = [];
  bool showFavoritesOnly = false;
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadTreatments();
  }

  Future<void> _loadTreatments() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      final data = await ApiService.getTreatments();

      setState(() {
        treatments = data.map((treatmentData) => Treatment(
          id: treatmentData['_id'] ?? '',
          name: treatmentData['judul'] ?? 'No Title',
          description: treatmentData['isi'] ?? 'No Description',
          isFavorite: false,
          createdAt: treatmentData['createdAt'] != null
              ? DateTime.parse(treatmentData['createdAt'])
              : DateTime.now(),
        )).toList();

        isLoading = false;
      });

    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Gagal memuat data treatment: ${e.toString()}';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _toggleFavorite(int index) {
    setState(() {
      treatments[index].isFavorite = !treatments[index].isFavorite;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100.0),
        child: Padding(
          padding: const EdgeInsets.only(top: 30.0),
          child: Expanded( // Menggunakan Expanded agar teks mengambil ruang yang tersedia
            child: Center( // Memusatkan teks di dalam Expanded
              child: Text(
                'Treatment',
                style: TextStyle(
                  fontFamily: 'Afacad',
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: Color(0xFF109E88),
                ),
              ),
            ),
          ),
        ),
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const SizedBox(height: 10),
              // Filter indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Filter: ',
                    style: TextStyle(
                      fontFamily: 'Afacad',
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF109E88).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(2),
                    child: IconButton(
                      icon: Icon(
                        showFavoritesOnly ? Icons.star : Icons.star_border,
                        color: showFavoritesOnly ? Colors.yellow : Colors.grey,
                        size: 18,
                      ),
                      onPressed: () {
                        setState(() {
                          showFavoritesOnly = !showFavoritesOnly;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Loading indicator
              if (isLoading)
                Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF109E88),
                  ),
                ),

              // Error message
              if (errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    errorMessage,
                    style: TextStyle(
                      color: Colors.red,
                      fontFamily: 'Afacad',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Empty state
              if (!isLoading && treatments.isEmpty && errorMessage.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.spa,
                        size: 64,
                        color: Colors.grey[300],
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Tidak ada treatment tersedia',
                        style: TextStyle(
                          fontFamily: 'Afacad',
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),

              // Treatment cards - filtered based on showFavoritesOnly
              if (!isLoading && treatments.isNotEmpty)
                ..._buildFilteredTreatments(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigasiBar(
        currentIndex: 3,
        context: context,
      ),
    );
  }

  List<Widget> _buildFilteredTreatments() {
    final filteredTreatments = treatments
        .where((treatment) => !showFavoritesOnly || treatment.isFavorite)
        .toList();

    if (filteredTreatments.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Tidak ada treatment favorit',
            style: TextStyle(
              fontFamily: 'Afacad',
              color: Colors.grey[600],
            ),
          ),
        ),
      ];
    }

    return filteredTreatments
        .map((treatment) => _buildTreatmentCard(treatment))
        .toList();
  }

  Widget _buildTreatmentCard(Treatment treatment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF109E88).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    treatment.name,
                    style: const TextStyle(
                      fontFamily: 'Afacad',
                      color: Color(0xFF109E88),
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    treatment.isFavorite ? Icons.star : Icons.star_border,
                    color: treatment.isFavorite ? Colors.yellow : Colors.grey,
                    size: 20,
                  ),
                  onPressed: () {
                    final index = treatments.indexWhere((t) => t.id == treatment.id);
                    if (index != -1) {
                      _toggleFavorite(index);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              treatment.description,
              style: const TextStyle(
                fontFamily: 'Afacad',
                fontSize: 12,
                color: Colors.black87,
                height: 1.4,
              ),
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 8)
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class Treatment {
  String id;
  String name;
  String description;
  bool isFavorite;
  DateTime createdAt;

  Treatment({
    required this.id,
    required this.name,
    required this.description,
    required this.isFavorite,
    required this.createdAt,
  });
}