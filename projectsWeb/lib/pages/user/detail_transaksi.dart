import 'package:apskina/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class DetailTransaksiUser extends StatefulWidget {
  final String reservationId;
  final String transactionType;

  const DetailTransaksiUser({
    Key? key,
    required this.reservationId,
    required this.transactionType,
  }) : super(key: key);

  @override
  _DetailTransaksiUserState createState() => _DetailTransaksiUserState();
}

class _DetailTransaksiUserState extends State<DetailTransaksiUser> {
  Map<String, dynamic> _transactionDetail = {};
  bool _isLoading = true;
  String _errorMessage = '';
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _loadTransactionDetail();
  }

  Future<void> _loadTransactionDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/reservasi/${widget.reservationId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        setState(() {
          _transactionDetail = responseData['data'] ?? {};
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Gagal memuat detail transaksi';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Terjadi kesalahan: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  String _formatDate(String dateString) {
    try {
      if (dateString.contains('/')) {
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
      }
      return dateString;
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildDetailItem(String title, String value, {bool isImportant = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              title,
              style: TextStyle(
                fontFamily: 'Afacad',
                fontSize: 14,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'Afacad',
                fontSize: 14,
                color: isImportant ? Color(0xFF109E88) : Colors.black,
                fontWeight: isImportant ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Detail Transaksi',
          style: TextStyle(
            fontFamily: 'Afacad',
            fontWeight: FontWeight.bold,
            color: Color(0xFF109E88),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF109E88)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF109E88)),
        ),
      )
          : _errorMessage.isNotEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage,
              style: TextStyle(
                fontFamily: 'Afacad',
                fontSize: 16,
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadTransactionDetail,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF109E88),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Coba Lagi',
                style: TextStyle(
                  fontFamily: 'Afacad',
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      )
          : SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Transaksi Berhasil',
                      style: TextStyle(
                        fontFamily: 'Afacad',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF109E88),
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'ID: ${_transactionDetail['id'] ?? widget.reservationId}',
                      style: TextStyle(
                        fontFamily: 'Afacad',
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // Informasi Transaksi
            Text(
              'Informasi Transaksi',
              style: TextStyle(
                fontFamily: 'Afacad',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF109E88),
              ),
            ),
            SizedBox(height: 10),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildDetailItem(
                      'Jenis Layanan',
                      _transactionDetail['tipe']?.toString().toUpperCase() ?? widget.transactionType.toUpperCase(),
                    ),
                    Divider(),
                    _buildDetailItem(
                      'Nama Pasien',
                      _transactionDetail['namaPasien'] ?? 'Tidak tersedia',
                    ),
                    Divider(),
                    _buildDetailItem(
                      'PIC',
                      _transactionDetail['pic'] ?? 'Tidak tersedia',
                    ),
                    Divider(),
                    _buildDetailItem(
                      'Treatment',
                      _transactionDetail['treatment'] ?? 'Tidak tersedia',
                    ),
                    Divider(),
                    _buildDetailItem(
                      'Tanggal',
                      _formatDate(_transactionDetail['tanggalReservasi'] ?? ''),
                    ),
                    Divider(),
                    _buildDetailItem(
                      'Waktu',
                      _transactionDetail['jamReservasi'] ?? 'Tidak tersedia',
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // Hasil Treatment
            if (_transactionDetail['hasilTreatment'] != null &&
                _transactionDetail['hasilTreatment'].toString().isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hasil Treatment',
                    style: TextStyle(
                      fontFamily: 'Afacad',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF109E88),
                    ),
                  ),
                  SizedBox(height: 10),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        _transactionDetail['hasilTreatment'],
                        style: TextStyle(
                          fontFamily: 'Afacad',
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ),

            // Informasi Pembayaran
            Text(
              'Informasi Pembayaran',
              style: TextStyle(
                fontFamily: 'Afacad',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF109E88),
              ),
            ),
            SizedBox(height: 10),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildDetailItem(
                      'Status Pembayaran',
                      _transactionDetail['paymentStatus'] == 'paid'
                          ? 'LUNAS'
                          : 'BELUM LUNAS',
                      isImportant: true,
                    ),
                    Divider(),
                    _buildDetailItem(
                      'Total Pembayaran',
                      _currencyFormat.format(250000),
                      isImportant: true,
                    ),
                    Divider(),
                    _buildDetailItem(
                      'Waktu Pembayaran',
                      _transactionDetail['paidAt'] != null
                          ? DateFormat('dd MMMM yyyy, HH:mm').format(
                        DateTime.parse(_transactionDetail['paidAt']).toLocal(),
                      )
                          : 'Menunggu pembayaran',
                    ),
                    Divider(),
                    _buildDetailItem(
                      'Metode Pembayaran',
                      _transactionDetail['paymentMethod'] ?? 'Transfer Bank',
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 30),

            // Button Kembali
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF109E88),
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Kembali',
                  style: TextStyle(
                    fontFamily: 'Afacad',
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}