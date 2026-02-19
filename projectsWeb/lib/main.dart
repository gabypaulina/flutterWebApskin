import 'dart:convert';

import 'package:apskina/pages/admin/menu_artikel.dart';
import 'package:apskina/pages/admin/menu_dashboard.dart';
import 'package:apskina/pages/admin/menu_dokter.dart';
import 'package:apskina/pages/admin/menu_iklan.dart';
import 'package:apskina/pages/admin/menu_jadwal_appointment.dart';
import 'package:apskina/pages/admin/menu_laporan.dart';
import 'package:apskina/pages/admin/menu_treatment.dart';
import 'package:apskina/pages/admin/tambah_artikel.dart';
import 'package:apskina/pages/dokter/menu_dashboard.dart';
import 'package:apskina/pages/dokter/menu_jadwal.dart';
import 'package:apskina/pages/dokter/menu_laporan.dart';
import 'package:apskina/pages/terapis/menu_dashboard.dart';
import 'package:apskina/pages/terapis/menu_jadwal.dart';
import 'package:apskina/pages/terapis/menu_laporan.dart';
import 'package:apskina/pages/user/detail_artikel.dart';
import 'package:apskina/pages/user/detail_reservasi.dart';
import 'package:apskina/pages/user/detail_transaksi.dart';
import 'package:apskina/pages/user/halaman_artikel.dart';
import 'package:apskina/pages/user/halaman_histori.dart';
import 'package:apskina/pages/user/halaman_reservasi.dart';
import 'package:apskina/pages/user/halaman_treatment.dart';
import 'package:apskina/pages/user/tambah_skincare.dart';
import 'package:apskina/services/firebase_service.dart';
import 'package:apskina/wrappers/auth_wrapper.dart';
// import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
// import 'package:apskina/pages/user/halaman_start.dart';
import 'package:apskina/pages/user/halaman_login.dart';
import 'package:apskina/pages/user/halaman_register.dart';
import 'package:apskina/pages/user/halaman_qna.dart';
import 'package:apskina/pages/user/halaman_home.dart';
import 'package:apskina/pages/user/halaman_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:apskina/providers/auth_provider.dart';
import 'package:provider/provider.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  // final String initialRoute;

  // const MyApp({Key? key, required this.initialRoute}) : super(key:key);  // Pastikan ada keyword const di sini
  const MyApp({Key? key}) : super(key:key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SKIN A',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        primarySwatch: Colors.blue,
      ),
      home:  const AuthWrapper(),
      routes: {
        '/register' : (context) => HalamanRegister(),
        '/login' : (context) => HalamanLogin(),

        // ROUTE USER
        '/qna': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return HalamanQna(
            isMandatory: args?['isMandatory'] ?? true,
          );
        },
        '/home' : (context) => HalamanHome(),
        '/artikel' : (context) => HalamanArtikel(),
        '/detail-artikel': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return DetailArtikel(
            articleId: args['articleId'],
          );
        },
        '/profile' : (context) => HalamanProfile(),
        '/reservasi' : (context) => HalamanReservasi(),
        '/histori' : (context) => HalamanHistori(),
        '/treatment' : (context) => HalamanTreatment(),
        '/detail_reservasi': (context) => DetailReservasi(
          reservation: ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>,
        ),
        '/tambah_skincare' : (context) => HalamanTambahSkincare(),

        // ROUTE ADMIN
        '/admin/dashboard' : (context) => MenuDashboard(),
        '/admin/artikel' : (context) => MenuArtikel(),
        '/admin/iklan' : (context) => MenuIklan(),
        '/admin/dokter' : (context) => MenuDokter(),
        '/admin/treatment' : (context) => MenuTreatment(),
        '/admin/laporan' : (context) => MenuLaporan(),
        '/admin/jadwal' : (context) => MenuJadwal(),

        // ROUTE DOKTER
        '/dokter/dashboard' : (context) => MenuDashboardDok(),
        '/dokter/jadwal' : (context) => MenuJadwalDok(),
        '/dokter/laporan' : (context) => MenuLaporanDok(),
        // '/dokter/catatan_dokter' : (context) => ,
        // '/dokter/resep_digital' : (context) => ,

        // ROUTE TERAPIS
        '/terapis/dashboard' : (context) => MenuDashboardTerapis(),
        // '/terapis/jadwal' : (context) => MenuJadwalTerapis(),
        '/terapis/laporan' : (context) => MenuLaporanTerapis(),
        // '/terapis/hasil_treatment' : (context) => ,
        // '/terapis/detail_hasil_treatment' : (context) => ,
      },
      debugShowCheckedModeBanner: false, // Sembunyikan debug banner
      onUnknownRoute: (settings) {
        // Handle unknown routes
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            body: Center(
              child: Text('Halaman tidak ditemukan: ${settings.name}'),
            ),
          ),
        );
      },
    );
  }
}