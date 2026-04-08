import 'package:flutter/material.dart';
import 'package:apskina/services/api_service.dart';
import 'package:apskina/pages/user/ruang_konsultasi.dart'; // Import halaman konsultasi


class DetailReservasi extends StatefulWidget {
  final Map<String, dynamic> reservation;

  const DetailReservasi({Key? key, required this.reservation}) : super(key: key);

  @override
  _DetailReservasiState createState() => _DetailReservasiState();
}

class _DetailReservasiState extends State<DetailReservasi> {
  Map<String, dynamic>? qnaData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQnaData();
  }

  Future<void> _loadQnaData() async {
    try {
      final qnaHistory = await ApiService.getQnaHistory();
      if (qnaHistory['data'] != null) {
        setState(() {
          qnaData = qnaHistory['data'];
        });
      }
    } catch (e) {
      print('Error loading QnA data: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _startConsultation() {
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => RuangKonsultasi(reservation: widget.reservation),
    //   ),
    // );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detail Reservasi'),
        backgroundColor: Color(0xFF109E88),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.reservation['status'] == 'dikonfirmasi' ||
                widget.reservation['status'] == 'berlangsung')
              Container(
                width: double.infinity,
                margin: EdgeInsets.only(bottom: 16),
                child: ElevatedButton(
                  onPressed: _startConsultation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF109E88),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'MULAI KONSULTASI',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

            // Info Dokter
            if (widget.reservation['doctorInfo'] != null)
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Foto Dokter
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: NetworkImage(
                                '${ApiService.basedUrl}${widget.reservation['doctorInfo']['foto']}'
                            ),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      // Info Dokter
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.reservation['doctorInfo']['nama'],
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              widget.reservation['doctorInfo']['spesialis'],
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            SizedBox(height: 16),

            // Info Reservasi
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Detail Reservasi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    _buildInfoRow('Tanggal', widget.reservation['tanggalReservasi']),
                    _buildInfoRow('Jam', widget.reservation['jamReservasi']),
                    _buildInfoRow('Tipe', widget.reservation['tipe']),
                    if (widget.reservation['treatment'] != null)
                      _buildInfoRow('Treatment', widget.reservation['treatment']),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Produk Skincare
            if (widget.reservation['produkSkincare'] != null &&
                widget.reservation['produkSkincare'].length > 0)
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Produk Skincare Anda',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      ...widget.reservation['produkSkincare'].map<Widget>((product) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: Text(
                            '• ${product['name']} (${product['productType']})',
                            style: TextStyle(fontSize: 16),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),

            SizedBox(height: 16),

            // Hasil QnA
            if (qnaData != null)
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hasil Assesmen Kulit',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Tanggal Assesmen: ${_formatDate(qnaData!['completedAt'])}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 12),
                      ...qnaData!['responses'].map<Widget>((response) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                response['questionText'],
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                response['answerText'],
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Tidak diketahui';
    try {
      final dateTime = DateTime.parse(date);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return date.toString();
    }
  }
}