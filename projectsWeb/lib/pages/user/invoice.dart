import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'detail_pembayaran.dart';

class InvoicePage extends StatelessWidget {
  final Map<String, dynamic> reservationData;

  const InvoicePage({Key? key, required this.reservationData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Gunakan nilai default untuk semua field yang mungkin digunakan
    final doctorName = reservationData['dokter']?.toString() ??
        reservationData['doctor']?.toString() ??
        'Tidak tersedia';

    final patientName = reservationData['namaPasien']?.toString() ??
        reservationData['patientName']?.toString() ??
        'Tidak tersedia';

    final reservationType = reservationData['tipe']?.toString() ??
        reservationData['type']?.toString() ??
        'Tidak tersedia';

    final reservationTime = reservationData['waktuReservasi']?.toString() ??
        reservationData['reservationTime']?.toString() ??
        'Tidak tersedia';

    final reservationDate = reservationData['tanggalReservasi']?.toString() ??
        reservationData['reservationDate']?.toString() ??
        'Tidak tersedia';

    // Format tanggal invoice
    final invoiceDate = DateFormat('dd MMMM yyyy').format(DateTime.now());

    // Format tanggal reservasi
    String formattedReservationDate = 'Tanggal tidak tersedia';
    try {
      final reservationDateParts = (reservationData['tanggalReservasi'] ?? '').toString().split('/');
      if (reservationDateParts.length == 3) {
        final reservationDate = DateFormat('dd/MM/yyyy').parse(
            '${reservationDateParts[0]}/${reservationDateParts[1]}/${reservationDateParts[2]}');
        formattedReservationDate = DateFormat('dd MMMM yyyy').format(reservationDate);
      }
    } catch (e) {
      formattedReservationDate = reservationData['tanggalReservasi']?.toString() ?? 'Tanggal tidak valid';
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100.0), // Tinggi AppBar + padding
        child: Padding(
          padding: const EdgeInsets.only(top: 30.0), // Padding di atas AppBar
          child: Expanded( // Menggunakan Expanded agar teks mengambil ruang yang tersedia
            child: Center( // Memusatkan teks di dalam Expanded
              child: Text(
                'Invoice',
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
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildClinicHeader(),
            const SizedBox(height: 20),
            _buildInvoiceDetails(invoiceDate, formattedReservationDate),
            const SizedBox(height: 30),
            _buildFooter(context), // PASS CONTEXT YANG BENAR
          ],
        ),
      ),
    );
  }

  Widget _buildClinicHeader() {
    return Column(
      children: [
        Image.asset('assets/images/logo.png', width: 100),
        const SizedBox(height: 5),
        const Text(
          'PAKUWON SQUARE BLOK AK NO. 49',
          style: TextStyle(fontFamily: 'Afacad', fontSize: 12, color: Color(0xFF109E88)),
        ),
        const Text(
          'JL. MAYJEN YONO SOEWOYO NO. 88',
          style: TextStyle(fontFamily: 'Afacad', fontSize: 12, color: Color(0xFF109E88)),
        ),
        const Text(
          'Telp. 031-9942 222 / 9942 2800',
          style: TextStyle(fontFamily: 'Afacad', fontSize: 12, color: Color(0xFF109E88)),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildInvoiceDetails(String invoiceDate, String reservationDate) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nama Pasien',
                    style: TextStyle(
                      fontFamily: 'Afacad',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF109E88)
                    ),
                  ),
                  Text(
                    reservationData['namaPasien']?.toString() ?? 'Tidak tersedia',
                    style: TextStyle(
                        fontFamily: 'Afacad',
                        fontSize: 16,
                        color: const Color(0xFF109E88)
                    ),
                  )
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tanggal Invoice',
                    style: TextStyle(
                        fontFamily: 'Afacad',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF109E88)
                    ),
                  ),
                  Text(
                    invoiceDate,
                    style: TextStyle(
                        fontFamily: 'Afacad',
                        fontSize: 16,
                        color: const Color(0xFF109E88)
                    ),
                  )
                ],
              )
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Keterangan :',
            style: TextStyle(
                fontFamily: 'Afacad',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF109E88)
            ),
          ),
          const SizedBox(height: 10),
          if (reservationData['dokter'] != null)
            Column(
              children: [
                _buildDetailRow('Nama Dokter', reservationData['dokter'].toString()),
                const SizedBox(height: 10),
              ],
            ),
          _buildDetailRow('Tipe Reservasi', reservationData['tipe']?.toString() ?? 'Tidak tersedia'),
          const SizedBox(height: 10),
          _buildDetailRow('Tanggal Reservasi', reservationDate),
          const SizedBox(height: 10),
          _buildDetailRow('Waktu Reservasi', reservationData['waktuReservasi']?.toString() ?? 'Tidak tersedia'),
          const SizedBox(height: 10),
          _buildDetailRow('Poin', '+50 poin', isHighlighted: true),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isHighlighted = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontFamily: 'Afacad', fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF109E88))),
        Text(value, style: TextStyle(
          fontFamily: 'Afacad',
          fontSize: 16,
          fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
          color: const Color(0xFF109E88),
        )),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Column(
      children: [
        const Text(
          'PILIH METODE PEMBAYARAN',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF109E88),
          ),
        ),
        const SizedBox(height: 15),

        // Pilihan metode pembayaran baru
        _buildPaymentOption('Shopee Pay', 'assets/images/shopee.png', 'SHOPEEPAY', context),
        const SizedBox(height: 10),
        _buildPaymentOption('GrabPay', 'assets/images/grabpay.png', 'GRABPAY', context),
        const SizedBox(height: 10),
        _buildPaymentOption('QR Code', 'assets/images/qrcode.png', 'QR_CODE', context),

        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[300],
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text(
            'KEMBALI',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentOption(String paymentName, String iconPath, String paymentMethod, BuildContext context) {
    return GestureDetector(
      onTap: () => _handlePaymentSelection(paymentMethod, context),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF109E88)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Image.asset(iconPath, width: 40, height: 40),
            const SizedBox(width: 15),
            Text(
              paymentName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF109E88),
              ),
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF109E88)),
          ],
        ),
      ),
    );
  }

  void _handlePaymentSelection(String paymentMethod, BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentPage(
          paymentMethod: paymentMethod,
          reservationData: reservationData,
        ),
      ),
    );
  }
}