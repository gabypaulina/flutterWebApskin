import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PaymentSuccessPage extends StatelessWidget {
  final Map<String, dynamic> paymentData;
  final Map<String, dynamic> reservationData;

  const PaymentSuccessPage({
    Key? key,
    required this.paymentData,
    required this.reservationData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('dd-MM-yyyy, HH:mm:ss').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kwitansi Pembayaran'),
        backgroundColor: const Color(0xFF109E88),
        automaticallyImplyLeading: false, // Hilangkan tombol back
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Success
            Center(
              child: Column(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 60),
                  const SizedBox(height: 10),
                  const Text(
                    'PEMBAYARAN BERHASIL',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Terima kasih telah melakukan pembayaran',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Card Kwitansi
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('ID Reservasi', reservationData['id']?.toString() ?? 'N/A'),
                    const Divider(),
                    _buildDetailRow('Total Pembayaran', 'Rp ${paymentData['amount']?.toStringAsFixed(0) ?? '0'}'),
                    const Divider(),
                    _buildDetailRow('Waktu Pembayaran', formattedDate),
                    const Divider(),
                    _buildDetailRow('Metode Pembayaran', _getPaymentMethodName(paymentData['paymentMethod'] ?? '')),
                    const Divider(),
                    FutureBuilder(
                      future: _getUserName(),
                      builder: (context, snapshot) {
                        return _buildDetailRow('Nama User', snapshot.data ?? 'User');
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Informasi Tambahan
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: const Text(
                'Reservasi Anda telah dikonfirmasi. Silakan datang sesuai jadwal yang telah ditentukan.',
                style: TextStyle(
                  fontSize: 14,
                  color: const Color(0xFF109E88),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 30),

            // Tombol Selesai
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _navigateToHome(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF109E88),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'SELESAI',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: const Color(0xFF109E88),
            ),
          ),
        ],
      ),
    );
  }

  String _getPaymentMethodName(String method) {
    switch (method) {
      case 'SHOPEEPAY':
        return 'Shopee Pay';
      case 'GRABPAY':
        return 'GrabPay';
      case 'QR_CODE':
        return 'QR Code';
      default:
        return method;
    }
  }

  Future<String> _getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    if (userJson != null) {
      final userData = jsonDecode(userJson) as Map<String, dynamic>;
      return userData['nama'] ?? 'User';
    }
    return 'User';
  }

  void _navigateToHome(BuildContext context) {
    // Navigate to home and remove all previous routes
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/home',
          (route) => false,
    );
  }
}