import 'package:apskina/pages/user/detail_transaksi.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../navigasi/navigasi_bar.dart';
import '../../services/api_service.dart';

class HalamanHistori extends StatefulWidget {
  @override
  _HalamanHistoriState createState() => _HalamanHistoriState();
}

class _HalamanHistoriState extends State<HalamanHistori> {
  String selectedFilter = "SEMUA";
  final ScrollController _scrollController = ScrollController();
  bool _showScrolledAppBar = false;
  bool _isLoading = true;
  String _errorMessage = '';
  bool _isRefreshing = false;

  List<Map<String, dynamic>> transactions = [];

  // Data dummy untuk fallback
  final List<Map<String, dynamic>> dummyTransactions = [
    {
      'date': '14 April 2025',
      'time': '10.45',
      'type': 'MEDIS',
      'doctor': 'dr. Intan',
      'specialization': 'Spesialis Recomilien',
      'status': 'selesai',
      'treatment': 'Ronauftesi',
      'reservationId': '65f1c9b9c4f3e82a6a1d1234',
      'hasTreatmentResult': true,
    },
    {
      'date': '6 Maret 2025',
      'time': '10.00',
      'type': 'NON MEDIS',
      'doctor': '',
      'specialization': '',
      'status': 'selesai',
      'treatment': 'Facial Detox',
      'reservationId': '65f1c9b9c4f3e82a6a1d1234',
      'hasTreatmentResult': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _loadTransactionHistory();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadTransactionHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Menggunakan API service untuk mendapatkan riwayat transaksi
      final historyData = await ApiService.getPatientHistoryy();

      setState(() {
        transactions = List<Map<String, dynamic>>.from(historyData.map((item) {
          return {
            'date': _formatDate(item['tanggalReservasi'] ?? ''),
            'time': item['jamReservasi'] ?? '',
            'type': _mapReservationType(item['tipe'] ?? ''),
            'doctor': item['pic'] ?? '',
            'specialization': item['spesialis'] ?? '',
            'status': _mapStatus(item['status'] ?? ''),
            'treatment': item['treatment'] ?? 'Treatment',
            'reservationId': item['id'] ?? '',
            'hasTreatmentResult': item['hasilTreatment'] != null &&
                item['hasilTreatment'].toString().isNotEmpty,
          };
        }));
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading transaction history: $e');

      // Fallback ke data dummy jika API error
      setState(() {
        _errorMessage = 'Tidak dapat terhubung ke server. Menampilkan data contoh.';
        transactions = dummyTransactions;
        _isLoading = false;
      });
    }
  }

  String _formatDate(String dateString) {
    try {
      if (dateString.isEmpty) return 'Tanggal tidak tersedia';

      // Coba berbagai format tanggal
      if (dateString.contains('/')) {
        // Format: "dd/mm/yyyy"
        final parts = dateString.split('/');
        if (parts.length == 3) {
          final day = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final year = int.parse(parts[2]);

          final months = [
            'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
            'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
          ];

          return '$day ${months[month - 1]} $year';
        }
      } else if (dateString.contains('-')) {
        // Format: "yyyy-mm-dd"
        final parts = dateString.split('-');
        if (parts.length == 3) {
          final year = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final day = int.parse(parts[2]);

          final months = [
            'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
            'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
          ];

          return '$day ${months[month - 1]} $year';
        }
      }

      return dateString;
    } catch (e) {
      return dateString;
    }
  }

  String _mapReservationType(String type) {
    switch (type) {
      case 'MEDIS': return 'MEDIS';
      case 'KONSULTASI': return 'KONSULTASI';
      case 'NON_MEDIS': return 'NON MEDIS';
      default: return type;
    }
  }

  String _mapStatus(String status) {
    switch (status) {
      case 'selesai': return 'SELESAI';
      case 'menunggu': return 'MENUNGGU';
      case 'berlangsung': return 'BERLANGSUNG';
      case 'reschedule': return 'RESCHEDULE';
      default: return status.toUpperCase();
    }
  }

  List<Map<String, dynamic>> get filteredTransactions {
    if (selectedFilter == "SEMUA") return transactions;
    return transactions.where((t) => t['type'] == selectedFilter).toList();
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Filter Transaksi',
            style: TextStyle(
              fontFamily: 'Afacad',
              color: Color(0xFF109E88),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFilterOption("SEMUA"),
              _buildFilterOption("MEDIS"),
              _buildFilterOption("NON MEDIS"),
              _buildFilterOption("KONSULTASI"),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterOption(String value) {
    return ListTile(
      title: Text(
        value,
        style: TextStyle(
          fontFamily: 'Afacad',
          color: selectedFilter == value ? Color(0xFF109E88) : Colors.black,
        ),
      ),
      trailing: selectedFilter == value
          ? Icon(Icons.check, color: Color(0xFF109E88))
          : null,
      onTap: () {
        setState(() {
          selectedFilter = value;
        });
        Navigator.of(context).pop();
      },
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'MEDIS':
        return Colors.redAccent;
      case 'NON MEDIS':
        return Colors.green;
      case 'KONSULTASI':
        return Colors.blue;
      default:
        return Color(0xFF109E88);
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'selesai':
        return Colors.green;
      case 'MENUNGGU':
        return Colors.orange;
      case 'BERLANGSUNG':
        return Colors.blue;
      case 'RESCHEDULE':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  void _scrollListener() {
    if (_scrollController.offset > 0 && !_showScrolledAppBar) {
      setState(() {
        _showScrolledAppBar = true;
      });
    } else if (_scrollController.offset <= 0 && _showScrolledAppBar) {
      setState(() {
        _showScrolledAppBar = false;
      });
    }
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _isRefreshing = true;
    });
    await _loadTransactionHistory();
    setState(() {
      _isRefreshing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(100.0),
          child: Padding(
            padding: const EdgeInsets.only(top: 30.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      'Histori Transaksi',
                      style: TextStyle(
                        fontFamily: 'Afacad',
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        color: Color(0xFF109E88),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.filter_list, color: Color(0xFF109E88)),
                  onPressed: () => _showFilterDialog(context),
                ),
              ],
            ),
          ),
        ),

        body: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF109E88)),
                ),
              )
            : Column(
                children: [
                  if (_errorMessage.isNotEmpty)
                    Container(
                      padding: EdgeInsets.all(12),
                      color: Colors.orange[100],
                      child: Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange[800]),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage,
                              style: TextStyle(
                                fontFamily: 'Afacad',
                                color: Colors.orange[800],
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, color: Colors.orange[800]),
                            onPressed: () {
                              setState(() {
                                _errorMessage = '';
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _handleRefresh,
                      color: Color(0xFF109E88),
                      child: _buildTransactionList(),
                    ),
                  ),
                ],
              ),
        bottomNavigationBar: NavigasiBar(
          currentIndex: 2,
          context: context,
        )
      );
    }

  Widget _buildTransactionList() {
    if (transactions.isEmpty) {
      return SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.only(top: 100.0),
          child: Column(
            children: [
              Icon(
                Icons.history,
                size: 64,
                color: Colors.grey[300],
              ),
              SizedBox(height: 16),
              Text(
                'Tidak ada transaksi',
                style: TextStyle(
                  fontFamily: 'Afacad',
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Transaksi yang telah selesai akan muncul di sini',
                style: TextStyle(
                  fontFamily: 'Afacad',
                  fontSize: 14,
                  color: Colors.grey[400],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loadTransactionHistory,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF109E88),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Muat Ulang',
                  style: TextStyle(
                    fontFamily: 'Afacad',
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      physics: AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(20),
      itemCount: filteredTransactions.length,
      itemBuilder: (context, index) {
        final transaction = filteredTransactions[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bagian tanggal, jam, dan jenis tindakan
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${transaction['date']}, ${transaction['time']}',
                    style: TextStyle(
                      fontFamily: 'Afacad',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF109E88),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(transaction['status']),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          transaction['status'],
                          style: TextStyle(
                            fontFamily: 'Afacad',
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getTypeColor(transaction['type']),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          transaction['type'].toUpperCase(),
                          style: TextStyle(
                            fontFamily: 'Afacad',
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Card untuk dokter atau treatment
            if (transaction['type'] == 'MEDIS' || transaction['type'] == 'KONSULTASI')
              _buildDoctorCard(transaction, context)
            else
              _buildTreatmentCard(transaction, context),

            SizedBox(height: 20),
          ],
        );
      },
    );
  }

  Widget _buildDoctorCard(Map<String, dynamic> transaction, BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      color: Colors.white,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    transaction['treatment'].toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'Afacad',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF109E88),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    final id = transaction['reservationId'];

                    if (id == null || id.toString().length != 24) {
                      print("ID reservasi tidak valid: $id");
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Data contoh tidak memiliki detail reservasi")),
                      );
                      return;
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailTransaksiUser(
                          reservationId: transaction['reservationId'],
                          transactionType: transaction['type'],
                        ),
                      ),
                    );
                  },
                  child: Text(
                    'Selengkapnya',
                    style: TextStyle(
                      fontFamily: 'Afacad',
                      color: Color(0xFF109E88),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            if (transaction['doctor'].isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction['doctor'],
                    style: TextStyle(
                      fontFamily: 'Afacad',
                      fontSize: 14,
                      color: Color(0xFF109E88),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (transaction['specialization'].isNotEmpty)
                    Text(
                      transaction['specialization'],
                      style: TextStyle(
                        fontFamily: 'Afacad',
                        fontSize: 12,
                        color: Color(0xFF109E88),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTreatmentCard(Map<String, dynamic> transaction, BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      color: Colors.white,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                transaction['treatment'].toUpperCase(),
                style: TextStyle(
                  fontFamily: 'Afacad',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF109E88),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetailTransaksiUser(
                      reservationId: transaction['reservationId'],
                      transactionType: transaction['type'],
                    ),
                  ),
                );
              },
              child: Text(
                transaction['hasTreatmentResult'] ? 'Lihat Hasil' : 'Hasil Belum Ada',
                style: TextStyle(
                  fontFamily: 'Afacad',
                  color: transaction['hasTreatmentResult'] ? Color(0xFF109E88) : Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}