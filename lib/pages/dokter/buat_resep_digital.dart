import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../services/socket_service.dart';

class BuatResepPage extends StatefulWidget {
  final Map<String, dynamic> reservation;
  final List<dynamic>? existingResep;
  final bool isEdit;
  final String? messageId;

  const BuatResepPage({
    Key? key,
    required this.reservation,
    this.existingResep,
    this.isEdit = false,
    this.messageId,
  }) : super(key: key);

  @override
  _BuatResepPageState createState() => _BuatResepPageState();
}

class _BuatResepPageState extends State<BuatResepPage> {

  List<Map<String, TextEditingController>> obatList = [
    {
      'nama': TextEditingController(),
      'dosis': TextEditingController(),
    }
  ];

  void tambahObat() {
    setState(() {
      obatList.add({
        'nama': TextEditingController(),
        'dosis': TextEditingController(),
      });
    });
  }

  void hapusObat(int index) {
    if (obatList.length == 1) return;

    setState(() {
      obatList.removeAt(index);
    });
  }

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

  Future<void> simpanResep() async {
    if (widget.isEdit) {
      await ApiService.updateResep(
        reservationId: widget.reservation['_id'],
        resep: obatList.map((o) {
          return {
            'namaObat': o['nama']!.text,
            'dosis': o['dosis']!.text,
          };
        }).toList(),
      );
    } else {
      for (var o in obatList) {
        await ApiService.sendResep(
          reservationId: widget.reservation['_id'],
          namaObat: o['nama']!.text,
          dosis: o['dosis']!.text,
        );
      }
    }

    SocketService.sendMessage({
      '_id': widget.messageId,
      'reservationId': widget.reservation['_id'],
      'text': 'Resep Dokter',
      'senderType': 'doctor',
      'timestamp': DateTime.now().toIso8601String(),
      'type': 'resep',
      'resep': obatList.map((o) {
        return {
          'namaObat': o['nama']!.text,
          'dosis': o['dosis']!.text,
        };
      }).toList(),
    });

    Navigator.pop(context, {
      'type': 'resep',
      'time': DateTime.now().toIso8601String(),
      'resep': obatList.map((o) {
        return {
          'namaObat': o['nama']!.text,
          'dosis': o['dosis']!.text,
        };
      }).toList(),
    });
  }

  @override
  void initState() {
    super.initState();
    print(widget.existingResep);

    if (widget.isEdit && widget.existingResep != null) {
      final List obatData = widget.existingResep ?? [];

      obatList = obatData.map<Map<String, TextEditingController>>((item) {
        return {
          'nama': TextEditingController(
            text: item['namaObat']?.toString() ?? '',
          ),
          'dosis': TextEditingController(
            text: item['dosis']?.toString() ?? '',
          ),
        };
      }).toList();
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
                'RESEP DIGITAL',
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

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Resep Dokter :",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Afacad',
                      color: Color(0xFF109E88)
                  ),
                ),
                /// 🔥 TAMBAH OBAT
                ElevatedButton.icon(
                  onPressed: tambahObat,
                  icon: Icon(Icons.add, color: Color(0xFF109E88)),
                  label: Text(
                    "Tambah Obat",
                    style: TextStyle(
                      fontFamily: 'Afacad',
                      fontSize: 18,
                      color: Color(0xFF109E88)
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    elevation: 0, // ❌ hilangkan shadow
                    padding: EdgeInsets.all(18),
                    side: BorderSide(
                      color: Color(0xFF109E88), // border warna
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    shadowColor: Colors.transparent, // tambahan biar benar-benar clean
                  ),
                ),
              ],
            ),

            SizedBox(height: 20),

            /// 🔥 LIST OBAT
            Expanded(
              child: ListView.builder(
                itemCount: obatList.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: obatList[index]['nama'],
                            decoration: InputDecoration(
                              labelText: "Nama Obat",
                              labelStyle: TextStyle(
                                fontFamily: 'Afacad',
                                fontSize: 16,
                              ),
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
                          ),
                        ),
                        SizedBox(width: 18),
                        Expanded(
                          child: TextField(
                            controller: obatList[index]['dosis'],
                            decoration: InputDecoration(
                              labelText: "Dosis Penggunaan",
                              labelStyle: TextStyle(
                                fontFamily: 'Afacad',
                                fontSize: 16,
                              ),
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
                          ),
                        ),
                        SizedBox(height: 10),
                        /// 🔥 BUTTON HAPUS
                        IconButton(
                          onPressed: () => hapusObat(index),
                          icon: Icon(
                            Icons.delete,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            SizedBox(height: 10),

            /// 🔥 SIMPAN
            ElevatedButton(
              onPressed: simpanResep,
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