import 'dart:convert';
import 'package:apskina/pages/dokter/ruang_konsultasi_dokter.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../navigasi/navigasi_sidebar_dokpis.dart';
import '../../services/api_service.dart';
import 'package:http/http.dart' as http;


class DetailAppointment extends StatefulWidget {
  final Map<String, dynamic> reservation;

  const DetailAppointment({Key? key, required this.reservation}) : super(key: key);

  @override
  _DetailAppointmentState createState() => _DetailAppointmentState();
}

class _DetailAppointmentState extends State<DetailAppointment> {
  bool _isLoading = false;

  Future<void> _startConsultation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Update status reservasi menjadi 'berlangsung'
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.put(
        Uri.parse('${ApiService.baseUrl}/reservasi/${widget.reservation['_id']}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'status': 'berlangsung'
        }),
      );

      if (response.statusCode == 200) {
        // Navigate to chat room
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RuangKonsultasiDokter(
              reservation: widget.reservation,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memulai konsultasi')),
        );
      }
    } catch (e) {
      print('Error starting consultation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationSidebarDokpis(
            currentIndex: 1,
            context: context,
          ),
          Expanded(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.only(left: 40.0, bottom: 16.0, top: 16.0, right: 40.0),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF109E88),
                            width: 1,
                          ),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back),
                          color: const Color(0xFF109E88),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Text(
                        'Detail Appointment',
                        style: TextStyle(
                          fontFamily: 'HindSiliguri',
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF109E88),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
                
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(left: 40.0, bottom: 16.0, top: 16.0, right: 40.0),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Form Section with left padding
                        Padding(
                          padding: const EdgeInsets.only(left: 60.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        children: [
                                          Icon(
                                            Icons.calendar_today_outlined,
                                            color: const Color(0xFF109E88),
                                            size: 24,
                                          ),
                                          const SizedBox(width: 20),
                                          Text(
                                            '10 April 2025',
                                            style: TextStyle(
                                              fontFamily: 'Afacad',
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF109E88),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 40),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        children: [
                                          Icon(
                                            Icons.watch_later_outlined,
                                            color: const Color(0xFF109E88),
                                            size: 24,
                                          ),
                                          const SizedBox(width: 20),
                                          Text(
                                            '14:00',
                                            style: TextStyle(
                                              fontFamily: 'Afacad',
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF109E88),
                                            ),
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                  SizedBox(
                                    width: 200,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF109E88),
                                        padding: EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      onPressed: _isLoading ? null : _startConsultation,
                                      child: _isLoading
                                          ? CircularProgressIndicator(color: Colors.white)
                                          : const Text(
                                        'BERLANGSUNG',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontFamily: 'Afacad',
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 30),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Text(
                                    'Pertemuan ke : ',
                                    style: TextStyle(
                                      fontFamily: 'Afacad',
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF109E88),
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Text(
                                    '1',
                                    style: TextStyle(
                                      fontFamily: 'Afacad',
                                      fontSize: 16,
                                      color: const Color(0xFF109E88),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Text(
                                    'Pasien : ',
                                    style: TextStyle(
                                      fontFamily: 'Afacad',
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF109E88),
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Text(
                                    'Michael David / 22 tahun',
                                    style: TextStyle(
                                      fontFamily: 'Afacad',
                                      fontSize: 16,
                                      color: const Color(0xFF109E88),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Text(
                                    'Tipe : ',
                                    style: TextStyle(
                                      fontFamily: 'Afacad',
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF109E88),
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Text(
                                    'Online',
                                    style: TextStyle(
                                      fontFamily: 'Afacad',
                                      fontSize: 16,
                                      color: const Color(0xFF109E88),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 30),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Text(
                                    'Laporan Rutinitas Skincare : ',
                                    style: TextStyle(
                                      fontFamily: 'Afacad',
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF109E88),
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Text(
                                    '80% - Sangat Rutin',
                                    style: TextStyle(
                                      fontFamily: 'Afacad',
                                      fontSize: 16,
                                      color: const Color(0xFF109E88),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 30),

                              Row(
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Produk Skincare Yang Digunakan : ',
                                        style: TextStyle(
                                          fontFamily: 'Afacad',
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF109E88),
                                        ),
                                      ),
                                      const SizedBox(height: 10),

                                      _buildSkincareTable(),
                                    ],
                                  ),
                                  const SizedBox(width: 100),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Data Tipe Kulit : ',
                                        style: TextStyle(
                                          fontFamily: 'Afacad',
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF109E88),
                                        ),
                                      ),
                                      const SizedBox(height: 10),

                                      Row(
                                        children: [
                                          Column(
                                            children: [
                                              Text(
                                                'Jenis Kulit : ',
                                                style: TextStyle(
                                                  fontFamily: 'Afacad',
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: const Color(0xFF109E88),
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                              Text(
                                                'Normal',
                                                style: TextStyle(
                                                  fontFamily: 'Afacad',
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: const Color(0xFF109E88),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(width: 20),

                                          Column(
                                            children: [
                                              Text(
                                                'Kondisi Kulit : ',
                                                style: TextStyle(
                                                  fontFamily: 'Afacad',
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: const Color(0xFF109E88),
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                              Text(
                                                'Kerutan',
                                                style: TextStyle(
                                                  fontFamily: 'Afacad',
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: const Color(0xFF109E88),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(width: 20),

                                          Column(
                                            children: [
                                              Text(
                                                'Kebiasaan makan : ',
                                                style: TextStyle(
                                                  fontFamily: 'Afacad',
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: const Color(0xFF109E88),
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                              Text(
                                                'Makanan manis',
                                                style: TextStyle(
                                                  fontFamily: 'Afacad',
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: const Color(0xFF109E88),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(width: 20),

                                          Column(
                                            children: [
                                              Text(
                                                'Minuman yang dikonsumsi : ',
                                                style: TextStyle(
                                                  fontFamily: 'Afacad',
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: const Color(0xFF109E88),
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                              Text(
                                                'Kopi/teh',
                                                style: TextStyle(
                                                  fontFamily: 'Afacad',
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: const Color(0xFF109E88),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(width: 20),
                                        ],
                                      ),
                                      const SizedBox(width: 20),

                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Penggunaan Sunscreen : ',
                                                style: TextStyle(
                                                  fontFamily: 'Afacad',
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: const Color(0xFF109E88),
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                              Text(
                                                'Setiap beberapa jam sekali',
                                                style: TextStyle(
                                                  fontFamily: 'Afacad',
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: const Color(0xFF109E88),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 20),

                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Penggunaan Skincare : ',
                                                style: TextStyle(
                                                  fontFamily: 'Afacad',
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: const Color(0xFF109E88),
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                              Text(
                                                'Kadang-kadang',
                                                style: TextStyle(
                                                  fontFamily: 'Afacad',
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: const Color(0xFF109E88),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 20),

                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Makanan Cepat Saji : ',
                                                style: TextStyle(
                                                  fontFamily: 'Afacad',
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: const Color(0xFF109E88),
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                              Text(
                                                'Beberapa kali seminggu',
                                                style: TextStyle(
                                                  fontFamily: 'Afacad',
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: const Color(0xFF109E88),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 20),

                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Durasi Tidur : ',
                                                style: TextStyle(
                                                  fontFamily: 'Afacad',
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: const Color(0xFF109E88),
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                              Text(
                                                '> 8 jam',
                                                style: TextStyle(
                                                  fontFamily: 'Afacad',
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: const Color(0xFF109E88),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 20),

                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Gangguan Tidur : ',
                                                style: TextStyle(
                                                  fontFamily: 'Afacad',
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: const Color(0xFF109E88),
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                              Text(
                                                'Normal',
                                                style: TextStyle(
                                                  fontFamily: 'Afacad',
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: const Color(0xFF109E88),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 20),

                                        ],
                                      )
                                    ],
                                  ),
                                ],
                              ),

                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
            
          ),
        ],
      ),
    );
  }

  Widget _buildSkincareTable() {
    return Table(
      border: TableBorder.all(
        color: Colors.grey.withOpacity(0.25),
        width: 1,
        borderRadius: BorderRadius.circular(10)
      ),
      defaultColumnWidth: const IntrinsicColumnWidth(),
      children: [
        TableRow(
          children: [
            _buildTableHeaderCell('JENIS'),
            _buildTableHeaderCell('PRODUK'),
          ],
        ),
        TableRow(
          children: [
            _buildTableCell('TONER'),
            _buildProductCell(
              product: 'Skintific 5X Ceramide Smooting Toner',
              ingredients: 'Probotic Complex, Calendula',
            ),
          ],
        ),
        TableRow(
          children: [
            _buildTableCell('SERUM'),
            _buildProductCell(
              product: 'Skintific 5X Ceramide Barrier Repair Serum',
              ingredients: 'BFL Probotic, Centella Asiatica',
            ),
          ],
        ),
        TableRow(
          children: [
            _buildTableCell('MOISTURIZER'),
            _buildProductCell(
              product: 'Skintific 5X Ceramide Barrier Moisture Gel',
              ingredients: 'Hyaluronic, Centella, Marine-Collagen',
            ),
          ],
        ),
        TableRow(
          children: [
            _buildTableCell('OBAT JERAWAT'),
            _buildProductCell(
              product: 'Vitacid',
              ingredients: '0,025% tretinoin',
            ),
          ],
        ),
        TableRow(
          children: [
            _buildTableCell('SUNSCREEN'),
            _buildProductCell(
              product: 'Aqua Light Daily Sunscreen',
              ingredients: 'Allantoin, Trehalose',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTableHeaderCell(String text) {
    return Padding(
        padding: const EdgeInsets.all(14.0),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'Afacad',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF109E88),
            ),
          ),
        )
    );
  }

  Widget _buildTableCell(String text) {
    return Padding(
        padding: const EdgeInsets.all(14.0),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'Afacad',
              fontSize: 14,
              color: const Color(0xFF109E88),
            ),
          ),
        )
    );
  }

  Widget _buildProductCell({required String product, required String ingredients}) {
    return Padding(
      padding: const EdgeInsets.all(14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: Text(
              product,
              style: TextStyle(
                fontFamily: 'Afacad',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF109E88),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              '( $ingredients )',
              style: TextStyle(
                fontFamily: 'Afacad',
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: const Color(0xFF109E88).withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}