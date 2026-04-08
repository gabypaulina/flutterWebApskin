import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class JadwalReservasi extends StatefulWidget {
  const JadwalReservasi({Key? key}) : super(key: key);

  @override
  State<JadwalReservasi> createState() => _JadwalReservasiState();
}

class _JadwalReservasiState extends State<JadwalReservasi> {
  Map<String, List<dynamic>> grouped = {};
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      DateTime now = DateTime.now();
      DateTime endMonth = DateTime(now.year, now.month + 1, 0);

      final response = await http.get(
        Uri.parse(
          "http://192.168.0.3:3000/reservasi"
              "?start=${now.toIso8601String()}"
              "&end=${endMonth.toIso8601String()}",
        ),
      );

      if (response.statusCode != 200) {
        throw Exception("Server error: ${response.statusCode}");
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! List) {
        throw Exception("Invalid data format");
      }

      Map<String, List<dynamic>> temp = {};

      for (var r in decoded) {
        final date = r['tanggalReservasi'] ?? 'Tanpa Tanggal';
        temp.putIfAbsent(date, () => []);
        temp[date]!.add(r);
      }

      setState(() {
        grouped = temp;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  String formatTanggal(String rawDate) {
    try {
      final date = DateTime.parse(rawDate);
      return "${date.day}/${date.month}/${date.year}";
    } catch (_) {
      return rawDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Jadwal Reservasi Bulan Ini"),
        backgroundColor: const Color(0xFF109E88),
      ),
      body: RefreshIndicator(
        onRefresh: fetchData,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF109E88),
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Text(
          errorMessage!,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    if (grouped.isEmpty) {
      return const Center(
        child: Text(
          "Tidak ada reservasi bulan ini",
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF109E88),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: grouped.keys.map((date) {
        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16),
            title: Text(
              formatTanggal(date),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF109E88),
              ),
            ),
            children: grouped[date]!.map<Widget>((r) {
              final nama = r['namaPasien'] ?? 'Tanpa Nama';
              final jam = r['jamReservasi'] ?? '-';
              final status = r['status'] ?? 'MENUNGGU';

              return ListTile(
                title: Text(
                  nama,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text("Jam: $jam"),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    status.toString().toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'BERLANGSUNG':
        return Colors.red;
      case 'SELESAI':
        return const Color(0xFFADD11A);
      case 'MENUNGGU':
        return const Color(0xFF37B0FF);
      default:
        return Colors.grey;
    }
  }
}