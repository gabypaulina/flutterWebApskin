import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../services/socket_service.dart';

class BuatCatatanPage extends StatefulWidget {
  final Map<String, dynamic> reservation;
  final Map<String, dynamic>? existingCatatan;
  final bool isEdit;

  const BuatCatatanPage({
    Key? key,
    required this.reservation,
    this.existingCatatan,
    this.isEdit = false,
  }) : super(key: key);

  @override
  _BuatCatatanPageState createState() => _BuatCatatanPageState();
}

class _BuatCatatanPageState extends State<BuatCatatanPage> {
  final diagnosisController = TextEditingController();
  final catatanController = TextEditingController();

  String formatTanggal(String rawDate) {
    try {
      // format backend: 12/04/2026
      List<String> parts = rawDate.split('/');

      int day = int.parse(parts[0]);
      int month = int.parse(parts[1]);
      int year = int.parse(parts[2]);

      DateTime date = DateTime(year, month, day);

      return DateFormat('d MMMM yyyy', 'id_ID').format(date);
    } catch (e) {
      return rawDate;
    }
  }

  Future<void> simpanCatatan() async {
    final catatanData = {
      'reservationId': widget.reservation['_id'],
      'text': 'Catatan Dokter',
      'senderType': 'doctor',
      'type': 'catatan',
      'timestamp': DateTime.now().toIso8601String(),
      'diagnosis': diagnosisController.text,
      'note': catatanController.text,
    };

    if (widget.isEdit) {
      await ApiService.updateCatatan(
        reservationId: widget.reservation['_id'],
        diagnosis: diagnosisController.text,
        note: catatanController.text,
      );

      // 🔥 TAMBAHKAN INI (UPDATE REALTIME)
      SocketService.sendMessage({
        ...catatanData,
        '_id': widget.existingCatatan?['_id'], // sekarang sudah benar karena full message dikirim
      });

    } else {
      await ApiService.sendCatatan(
        reservationId: widget.reservation['_id'],
        diagnosis: diagnosisController.text,
        note: catatanController.text,
      );

      SocketService.sendMessage(catatanData);
    }

    Navigator.pop(context, {
      'type': 'catatan',
      'time': DateTime.now().toIso8601String(),
      'diagnosis': diagnosisController.text,
      'note': catatanController.text,
    });
  }

  @override
  void initState() {
    super.initState();

    print("RAW DATA CATATAN: ${widget.existingCatatan}");

    if (widget.isEdit && widget.existingCatatan != null) {
      final data = widget.existingCatatan!;

      // 🔥 ambil dari 2 kemungkinan struktur
      diagnosisController.text = (data['diagnosis'] ?? '').toString();
      catatanController.text = (data['note'] ?? '').toString();

      print("DATA MASUK EDIT: $data");

    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.reservation;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
          ),
          child:
          Padding(
            padding: const EdgeInsets.only(top: 30.0, left: 50, right: 50),
            child: AppBar(
              automaticallyImplyLeading: false,
              leading: Center(
                child: Container(
                  width: 55,
                  height: 55,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Color(0xFF109E88),
                      width: 1,
                    ),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                    iconSize: 24,
                    icon: Icon(Icons.arrow_back, color: Color(0xFF109E88)),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
              ),
              title: Text(
                'CATATAN DOKTER',
                style: TextStyle(
                  fontFamily: 'Afacad',
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF109E88),
                ),
              ),
              elevation: 0,
              centerTitle: true,
              backgroundColor: Colors.transparent,
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 150, vertical: 50),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Nama Dokter : ${data['pic']}",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Afacad',
                      color: Color(0xFF109E88)
                  ),
                ),
                Text(
                  "Tanggal : ${formatTanggal(data['tanggalReservasi'])}",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Afacad',
                      color: Color(0xFF109E88)
                  ),
                ),
              ],
            ),
            SizedBox(height: 40),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Data Pasien",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Afacad',
                      color: Color(0xFF109E88)
                  ),
                ),
                Text(
                  "${data['namaPasien']} / ${data['age']} tahun",
                  style: TextStyle(
                      fontSize: 20,
                      fontFamily: 'Afacad',
                      color: Color(0xFF109E88)
                  ),
                ),
              ],
            ),

            SizedBox(height: 20),

            Text(
              "Diagnosis :",
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Afacad',
                  color: Color(0xFF109E88)
              ),
            ),
            SizedBox(height: 20),
            /// 🔥 DIAGNOSIS
            TextField(
              controller: diagnosisController,
              decoration: InputDecoration(
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: Colors.grey, // warna border normal
                    width: 1.5,
                  ),
                ),

                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: Color(0xFF109E88), // warna saat fokus
                    width: 2,
                  ),
                ),
              ),
              maxLines: 2,
            ),

            SizedBox(height: 30),

            Text(
              "Catatan Dokter :",
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Afacad',
                  color: Color(0xFF109E88)
              ),
            ),
            SizedBox(height: 20),
            /// 🔥 CATATAN
            TextField(
              controller: catatanController,
              decoration: InputDecoration(
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: Colors.grey, // warna border normal
                    width: 1.5,
                  ),
                ),

                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: Color(0xFF109E88), // warna saat fokus
                    width: 2,
                  ),
                ),
              ),
              maxLines: 4,
            ),

            SizedBox(height: 20),

            /// 🔥 SIMPAN
            ElevatedButton(
              onPressed: simpanCatatan,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF109E88),
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                widget.isEdit ? "Update" : "SIMPAN",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Afacad',
                  fontSize: 20
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}