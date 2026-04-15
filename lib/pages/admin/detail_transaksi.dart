import 'dart:convert';
import 'package:apskina/navigasi/navigasi_sidebar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

class DetailTransaksi extends StatefulWidget {
  final Map<String, dynamic> data;

  const DetailTransaksi({Key? key, required this.data}) : super(key: key);

  @override
  _DetailTransaksiState createState() => _DetailTransaksiState();
}

class _DetailTransaksiState extends State<DetailTransaksi> {
  // Data dummy untuk simulasi (dalam aplikasi nyata, data ini akan berasal dari API)
  final List<Map<String, dynamic>> treatments = [
    {
      'name': 'Paket 1x Athenapeel Facial',
      'quantity': 1,
      'price': 365000,
    },
    {
      'name': 'Konsultasi Dokter',
      'quantity': 1,
      'price': 150000,
    },
    {
      'name': 'Therapy Wajah',
      'quantity': 2,
      'price': 250000,
    },
  ];
  late Map<String, dynamic> trx;

  @override
  void initState() {
    super.initState();
    trx = widget.data;
  }

  // Format currency
  String formatCurrency(int amount) {
    return 'Rp ${amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
    )}';
  }

  String formatDateTime(String? date) {
    if (date == null || date.isEmpty) return '-';

    final dt = DateTime.tryParse(date);
    if (dt == null) return '-';

    final local = dt.toLocal();

    return DateFormat('dd/MM/yyyy').format(local);
  }

  String formatTime(String? date) {
    if (date == null || date.isEmpty) return '-';

    final dt = DateTime.tryParse(date);
    if (dt == null) return '-';

    final local = dt.toLocal();

    return DateFormat('HH:mm').format(local);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationSidebar(
            currentIndex: 5,
            context: context,
          ),
          Expanded(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.only(left: 40.0, top: 16.0, right: 40.0),
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
                        'Detail Transaksi',
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
                            child: Container (
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFF109E88),
                                  width: 1,
                                ),
                              ),
                              padding: const EdgeInsets.all(50),
                              child : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 40),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Nama Pasien : ',
                                            style: TextStyle(
                                              fontFamily: 'Afacad',
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF109E88),
                                            ),
                                          ),
                                          const SizedBox(width: 20),
                                          Text(
                                            trx['nama'] ?? '-',
                                            style: TextStyle(
                                              fontFamily: 'Afacad',
                                              fontSize: 16,
                                              color: const Color(0xFF109E88),
                                            ),
                                          ),
                                        ],
                                      ),

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
                                                formatDateTime(trx['paidAt']),
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
                                                formatTime(trx['paidAt']),
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
                                    ],
                                  ),
                                  const SizedBox(height: 20),

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
                                        trx['tipe'] ?? '-',
                                        style: TextStyle(
                                          fontFamily: 'Afacad',
                                          fontSize: 16,
                                          color: const Color(0xFF109E88),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),

                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Text(
                                        'PIC : ',
                                        style: TextStyle(
                                          fontFamily: 'Afacad',
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF109E88),
                                        ),
                                      ),
                                      const SizedBox(width: 20),
                                      Text(
                                        trx['pic'] ?? '-',
                                        style: TextStyle(
                                          fontFamily: 'Afacad',
                                          fontSize: 16,
                                          color: const Color(0xFF109E88),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),

                                  Text(
                                    'Treatment yang diambil : ',
                                    style: TextStyle(
                                      fontFamily: 'Afacad',
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF109E88),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    trx['treatment'] ?? '-',
                                    style: TextStyle(
                                      fontFamily: 'Afacad',
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF109E88),
                                    ),
                                  ),

                                  const SizedBox(height: 20),

                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Total Pembayaran : ',
                                        style: TextStyle(
                                          fontFamily: 'Afacad',
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF109E88),
                                        ),
                                      ),
                                      const SizedBox(width: 20),
                                      Text(
                                        formatCurrency(int.parse(trx['amount'].toString())),
                                        style: TextStyle(
                                          fontFamily: 'Afacad',
                                          fontSize: 16,
                                          color: const Color(0xFF109E88),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                ],
                              ),
                            )
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
}