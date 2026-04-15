import 'package:apskina/pages/dokter/menu_jadwal.dart';
import 'package:apskina/pages/dokter/menu_laporan.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../../navigasi/navigasi_sidebar_dokpis.dart';
import 'hasil_konsultasi.dart';
import 'menu_dashboard.dart';

class DoctorMainPage extends StatefulWidget {
  final int initialIndex;

  const DoctorMainPage({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  State<DoctorMainPage> createState() => _DoctorMainPageState();
}

class _DoctorMainPageState extends State<DoctorMainPage> {
  int index = 0;
  Map<String, dynamic>? selectedKonsultasi;
  bool showDetail = false;

  void openDetail(Map<String, dynamic> data) {
    setState(() {
      selectedKonsultasi = data;
      showDetail = true;
    });
  }

  void closeDetail() {
    setState(() {
      showDetail = false;
    });
  }


  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: Row(
        children: [
          SizedBox(
            width: 250,
            child: NavigationSidebarDokpis(
              currentIndex: index,
              context: context,
              onTap: (i) {
                setState(() {
                  index = i;
                  showDetail = false; // reset kalau pindah menu
                });
              },
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: index,
              children: [
                MenuDashboardDok(),
                MenuJadwalDok(),
                showDetail
                    ? HasilKonsultasi(
                  data: selectedKonsultasi!,
                  onBack: closeDetail,
                )
                    : MenuLaporanDok(
                  onOpenDetail: openDetail,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}