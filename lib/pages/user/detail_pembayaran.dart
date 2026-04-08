import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:async';
import 'package:flutter/services.dart';

import '../../services/api_service.dart';
import 'halaman_kwitansi.dart'; // Untuk Clipboard

class PaymentPage extends StatefulWidget {
  final String paymentMethod;
  final Map<String, dynamic> reservationData;

  const PaymentPage({
    Key? key,
    required this.paymentMethod,
    required this.reservationData,
  }) : super(key: key);

  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  bool _isLoading = false;
  bool _paymentCreated = false;
  String? _errorMessage;
  Map<String, dynamic>? _paymentData;
  Timer? _paymentStatusTimer;
  String _currentStatus = 'MENUNGGU';

  // Instruksi pembayaran untuk sandbox - DIPERBAIKI: tidak pakai _currentStatus di initializer
  late final Map<String, String> sandboxInstructions;

  @override
  void initState() {
    super.initState();
    // Inisialisasi instructions di initState setelah _currentStatus ada
    sandboxInstructions = {
      'SHOPEEPAY': '''
🔧 MODE SANDBOX - UNTUK TESTING 🔧

VIRTUAL ACCOUNT: ██████████

CARA TEST SHOPEE PAY:
1. Ini adalah simulasi pembayaran
2. Virtual account hanya untuk testing
3. Klik "SIMULASI BAYAR" di bawah
4. Pilih status yang diinginkan
5. Pembayaran akan diproses otomatis

Status saat ini: $_currentStatus
''',
      'GRABPAY': '''
🔧 MODE SANDBOX - UNTUK TESTING 🔧

VIRTUAL ACCOUNT: ██████████

CARA TEST GRABPAY:
1. Ini adalah simulasi pembayaran
2. Virtual account hanya untuk testing
3. Klik "SIMULASI BAYAR" di bawah
4. Pilih status yang diinginkan
5. Pembayaran akan diproses otomatis

Status saat ini: $_currentStatus
''',
      'QR_CODE': '''
🔧 MODE SANDBOX - UNTUK TESTING 🔧

QR CODE SIMULASI:

CARA TEST QR CODE:
1. Ini adalah simulasi pembayaran
2. QR code hanya untuk testing
3. Klik "SIMULASI BAYAR" di bawah
4. Pilih status yang diinginkan
5. Pembayaran akan diproses otomatis

Status saat ini: $_currentStatus
'''
    };
    _createPayment();
  }

  @override
  void dispose() {
    _paymentStatusTimer?.cancel();
    super.dispose();
  }

  // Method untuk mendapatkan instruksi dengan status terkini
  String _getInstructions() {
    return '''
🔧 MODE SANDBOX - UNTUK TESTING 🔧

${widget.paymentMethod == 'QR_CODE' ? 'QR CODE SIMULASI:' : 'VIRTUAL ACCOUNT: ██████████'}

CARA TEST ${_getPaymentMethodName(widget.paymentMethod)}:
1. Ini adalah simulasi pembayaran
2. ${widget.paymentMethod == 'QR_CODE' ? 'QR code' : 'Virtual account'} hanya untuk testing
3. Klik "SIMULASI BAYAR" di bawah
4. Pilih status yang diinginkan
5. Pembayaran akan diproses otomatis

Status saat ini: $_currentStatus
''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SANDBOX - ${_getPaymentMethodName(widget.paymentMethod)}'),
        backgroundColor: Colors.orange,
      ),
      body: _isLoading
          ? _buildLoadingIndicator()
          : _errorMessage != null
          ? _buildErrorWidget()
          : _paymentCreated
          ? _buildSandboxPayment()
          : _buildPaymentInstructions(),
    );
  }

  Widget _buildSandboxPayment() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Sandbox
          _buildSandboxBanner(),

          // Virtual Account (jika ada)
          if (_paymentData?['virtualAccount'] != null)
            _buildVirtualAccountSection(),

          // QR Code (jika ada)
          if (_paymentData?['qrCodeUrl'] != null)
            _buildQRCodeSection(),

          // Instruksi Pembayaran Sandbox
          _buildSandboxInstructions(),

          // Detail Reservasi
          _buildReservationDetails(),

          // Tombol Simulasi
          _buildSimulationButtons(),

          // Status Pembayaran
          _buildPaymentStatus(),

          // Tombol Aksi
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildSandboxBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.orange[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange),
      ),
      child: Row(
        children: [
          const Icon(Icons.build, color: Colors.orange),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'MODE SANDBOX - UNTUK TESTING',
              style: TextStyle(
                color: Colors.orange[800],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVirtualAccountSection() {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Virtual Account Number (Sandbox)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _paymentData?['virtualAccount'] ?? '1234567890',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: _copyToClipboard,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Nomor virtual account sandbox untuk testing',
              style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQRCodeSection() {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'QR Code (Sandbox)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Center(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: QrImageView(
                  data: _paymentData?['qrCodeUrl'] ?? 'SANDBOX_QR_CODE_${DateTime.now().millisecondsSinceEpoch}',
                  version: QrVersions.auto,
                  size: 200,
                  gapless: false,
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'QR code sandbox untuk testing purposes',
              style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSandboxInstructions() {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Instruksi Testing Sandbox',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              _getInstructions(),
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimulationButtons() {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Simulasi Pembayaran',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text('Pilih status pembayaran untuk testing:'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _simulatePayment('paid'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text('BAYAR SUKSES'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _simulatePayment('failed'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text('BAYAR GAGAL'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => _simulatePayment('expired'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: const Text('KADALUARSA'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentStatus() {
    Color statusColor = Colors.orange;
    if (_currentStatus == 'SUKSES' || _currentStatus == 'PAID') statusColor = Colors.green;
    if (_currentStatus == 'GAGAL' || _currentStatus == 'FAILED') statusColor = Colors.red;
    if (_currentStatus == 'KADALUARSA' || _currentStatus == 'EXPIRED') statusColor = Colors.orange;

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.info, color: statusColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Status: $_currentStatus',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReservationDetails() {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detail Reservasi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildDetailRow('Nama Pasien', widget.reservationData['namaPasien']?.toString() ?? 'Tidak tersedia'),
            _buildDetailRow('Tipe Reservasi', widget.reservationData['tipe']?.toString() ?? 'Tidak tersedia'),
            _buildDetailRow('Tanggal', widget.reservationData['tanggalReservasi']?.toString() ?? 'Tidak tersedia'),
            _buildDetailRow('Waktu', widget.reservationData['waktuReservasi']?.toString() ?? 'Tidak tersedia'),
            _buildDetailRow('Total', 'Rp ${_paymentData?['amount']?.toString() ?? '150.000'}', isBold: true),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _checkPaymentStatus,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF109E88),
            minimumSize: const Size(double.infinity, 50),
          ),
          child: const Text(
            'REFRESH STATUS',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[300],
            minimumSize: const Size(double.infinity, 50),
          ),
          child: const Text(
            'KEMBALI',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Future<void> _createPayment() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final userData = jsonDecode(prefs.getString('user') ?? '{}');

      int amount = _calculateAmount();

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/create-payment'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'reservationId': widget.reservationData['_id'],
          'amount': amount,
          'paymentMethod': widget.paymentMethod,
          'customerName': userData['nama'] ?? 'Customer',
          'customerEmail': userData['email'] ?? 'test@example.com',
          'phoneNumber': userData['noHandphone'] ?? '+628123456789'
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success']) {
        setState(() {
          _paymentData = responseData['data'];
          _isLoading = false;
          _paymentCreated = true;
        });
      } else {
        throw Exception(responseData['message'] ?? 'Gagal membuat pembayaran sandbox');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Gagal membuat pembayaran sandbox: ${e.toString().replaceFirst('Exception: ', '')}';
      });
    }
  }

  Future<void> _simulatePayment(String status) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/simulate-payment'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'reservationId': widget.reservationData['_id'],
          'status': status
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success']) {
        setState(() {
          _currentStatus = _getStatusDisplayName(status);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status diubah: ${_getStatusDisplayName(status)}')),
        );

        // Jika status paid, tampilkan dialog sukses
        if (status == 'paid') {
          _showSuccessDialog();
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengubah status')),
      );
    }
  }

  String _getStatusDisplayName(String status) {
    switch (status) {
      case 'paid': return 'SUKSES';
      case 'failed': return 'GAGAL';
      case 'expired': return 'KADALUARSA';
      default: return status.toUpperCase();
    }
  }

  // Di dalam _showSuccessDialog method, ganti dengan:
  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('✅ Pembayaran Berhasil'),
        content: const Text('Pembayaran sandbox berhasil disimulasikan.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Tutup dialog
              // Navigate to payment success page
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PaymentSuccessPage(
                    paymentData: _paymentData!,
                    reservationData: widget.reservationData,
                  ),
                ),
              );
            },
            child: const Text('LIHAT KWITANSI'),
          ),
        ],
      ),
    );
  }

  Future<void> _checkPaymentStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/payment-status/${widget.reservationData['_id']}'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = jsonDecode(response.body);

      if (responseData['success']) {
        setState(() {
          _currentStatus = _getStatusDisplayName(responseData['data']['status'] ?? 'pending');
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status: $_currentStatus')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memuat status')),
      );
    }
  }

  Future<void> _copyToClipboard() async {
    if (_paymentData?['virtualAccount'] != null) {
      await Clipboard.setData(ClipboardData(text: _paymentData!['virtualAccount']));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nomor virtual account disalin')),
      );
    }
  }

  int _calculateAmount() {
    int amount = 150000;
    final reservationType = widget.reservationData['tipe']?.toString().toLowerCase();
    if (reservationType == 'medis') amount = 200000;
    else if (reservationType == 'non medis') amount = 250000;
    else if (reservationType == 'konsultasi') amount = 100000;
    return amount;
  }

  String _getPaymentMethodName(String method) {
    switch (method) {
      case 'SHOPEEPAY': return 'Shopee Pay';
      case 'GRABPAY': return 'GrabPay';
      case 'QR_CODE': return 'QR Code';
      default: return 'Pembayaran';
    }
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Memproses pembayaran...'),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 50),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Terjadi kesalahan',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Kembali'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentInstructions() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? const Color(0xFF109E88) : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}