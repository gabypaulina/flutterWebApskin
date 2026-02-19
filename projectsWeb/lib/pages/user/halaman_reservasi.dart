import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../navigasi/navigasi_bar.dart';
import '../../services/api_service.dart';
import 'invoice.dart';

class HalamanReservasi extends StatefulWidget {
  const HalamanReservasi({Key? key}) : super(key: key);

  @override
  _HalamanReservasiState createState() => _HalamanReservasiState();
}

class _HalamanReservasiState extends State<HalamanReservasi> {
  int _selectedTabIndex = 0;
  final List<String> _tabLabels = ['MEDIS', 'NON MEDIS', 'KONSULTASI'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(150.0),
          child: Padding(
            padding: const EdgeInsets.only(top: 30.0),
            child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: Text(
                        'Reservasi',
                        style: TextStyle(
                          fontFamily: 'Afacad',
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                          color: Color(0xFF109E88),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final availableWidth = constraints.maxWidth - 32;
                        final buttonWidth = (availableWidth - 16) / 3;

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(
                            _tabLabels.length,
                                (index) => SizedBox(
                              width: buttonWidth,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: _selectedTabIndex == index
                                        ? Colors.transparent
                                        : const Color(0xFF109E88),
                                  ),
                                  backgroundColor: _selectedTabIndex == index
                                      ? const Color(0xFF109E88)
                                      : Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _selectedTabIndex = index;
                                  });
                                },
                                child: Text(
                                  _tabLabels[index],
                                  style: TextStyle(
                                    fontFamily: 'Afacad',
                                    fontSize: availableWidth < 300 ? 11 : 13,
                                    fontWeight: FontWeight.bold,
                                    color: _selectedTabIndex == index
                                        ? Colors.white
                                        : const Color(0xFF109E88),
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ]
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: _buildReservasiContent(),
        ),
        bottomNavigationBar: NavigasiBar(
          currentIndex: 1,
          context: context,
        )
    );
  }

  Widget _buildReservasiContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _MedisReservasiContent();
      case 1:
        return _NonMedisReservasiContent();
      case 2:
        return _KonsultasiReservasiContent();
      default:
        return Container();
    }
  }
}

Widget _buildDoctorSchedule(List<dynamic> jadwalPraktik) {
  if (jadwalPraktik.isEmpty) {
    return Text(
      'Jadwal belum tersedia',
      style: TextStyle(
        fontFamily: 'Afacad',
        fontSize: 12,
        color: Colors.grey,
      ),
    );
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: jadwalPraktik.map<Widget>((jadwal) {
      return Text(
        '${jadwal['hari']}: ${jadwal['jamPraktik'].map((j) => '${j['jamMulai']} - ${j['jamAkhir']}').join(', ')}',
        style: TextStyle(
          fontFamily: 'Afacad',
          fontSize: 12,
          color: Color(0xFF109E88),
        ),
      );
    }).toList(),
  );
}

class DoctorCard extends StatelessWidget {
  final Map<String, dynamic> doctor;
  final bool isSelected;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  const DoctorCard({
    Key? key,
    required this.doctor,
    required this.isSelected,
    required this.isFavorite,
    required this.onTap,
    required this.onToggleFavorite,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? const Color(0xFF109E88) : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Foto dokter
              Container(
                width: 60,
                height: 60,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: doctor['foto'] != null
                      ? Image.network(
                          '${ApiService.basedUrl}${doctor['foto']}',
                          width: 60,
                          height: 60,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.person,
                              size: 30,
                              color: Color(0xFF109E88),
                            );
                          },
                      )
                      : Icon(
                        Icons.person,
                        size: 30,
                        color: Color(0xFF109E88),
                      ),
                ),
              ),
              SizedBox(width: 12),
              // Informasi dokter
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            doctor['nama'] ?? 'Nama tidak tersedia',
                            style: TextStyle(
                              fontFamily: 'Afacad',
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFF109E88),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          iconSize: 20,
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                          icon: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite ? const Color(0xFF109E88) : Colors.grey,
                            size: 20,
                          ),
                          onPressed: onToggleFavorite,
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      doctor['spesialis'] ?? 'Dokter Umum',
                      style: TextStyle(
                        fontFamily: 'Afacad',
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 8),
                    _buildDoctorSchedule(doctor['jadwalPraktik'] ?? []),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MedisReservasiContent extends StatefulWidget {
  @override
  __MedisReservasiContentState createState() => __MedisReservasiContentState();
}

class __MedisReservasiContentState extends State<_MedisReservasiContent> {
  String? _selectedDoctorId;
  bool _isOfflineSelected = false;
  DateTime? _selectedDate;
  String? _selectedTime;
  final TextEditingController _notesController = TextEditingController();
  List<Map<String, dynamic>> _favoriteDoctors = [];
  List<Map<String, dynamic>> _allDoctors = [];
  List<String> _availableTimeOptions = [];
  bool _isLoadingDoctors = false;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    setState(() {
      _isLoadingDoctors = true;
    });

    try {
      final doctors = await ApiService.getDokter();
      setState(() {
        _allDoctors = List<Map<String, dynamic>>.from(doctors);
        _isLoadingDoctors = false;
      });
    } catch (e) {
      print('Error loading doctors: $e');
      setState(() {
        _isLoadingDoctors = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data dokter')),
      );
    }
  }

  Future<void> _loadFavorites() async {
    try {
      final favorites = await ApiService.getFavoriteDoctors();
      setState(() {
        _favoriteDoctors = List<Map<String, dynamic>>.from(favorites);
      });
    } catch (e) {
      print('Error loading favorites: $e');
    }
  }

  Future<void> _toggleFavorite(String doctorId, String doctorName) async {
    try {
      final isCurrentlyFavorite = _favoriteDoctors.any(
            (doc) => doc['doctorId'] == doctorId && doc['isFavorite'] == true,
      );

      await ApiService.toggleFavoriteDoctor(
        doctorId,
        doctorName,
        !isCurrentlyFavorite,
      );
      await _loadFavorites();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengupdate favorit')),
      );
    }
  }

  bool _isFavorite(String doctorId) {
    return _favoriteDoctors.any(
          (doc) => doc['doctorId'] == doctorId && doc['isFavorite'] == true,
    );
  }

  Future<void> _loadAvailableTimeSlots() async {
    if (_selectedDate == null || _selectedDoctorId == null) return;

    try {
      final formattedDate = _formatDateForApi(_selectedDate!);
      final availableTimes = await ApiService.getAvailableTimeSlotsByDoctor(
        _selectedDoctorId!,
        formattedDate,
      );

      setState(() {
        _availableTimeOptions = availableTimes;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat waktu tersedia: ${e.toString()}')),
      );
    }
  }

  String _formatDateForApi(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _submitReservation() async {
    try {
      if (_selectedDoctorId == null) {
        throw Exception('Silakan pilih dokter terlebih dahulu');
      }

      if (_selectedDate == null || _selectedTime == null) {
        throw Exception('Silakan pilih tanggal dan waktu terlebih dahulu');
      }

      final selectedDoctor = _allDoctors.firstWhere(
            (doctor) => doctor['_id'] == _selectedDoctorId,
      );

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      await ApiService.createReservation(
        type: 'MEDIS',
        doctor: selectedDoctor['nama'],
        reservationTime: _selectedTime!,
        reservationDate: _selectedDate!,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reservasi MEDIS berhasil dibuat')),
      );

      _notesController.clear();
      setState(() {
        _selectedDoctorId = null;
        _selectedTime = null;
        _selectedDate = null;
        _availableTimeOptions = [];
      });
    } catch (e) {
      if (Navigator.canPop(context)) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuat reservasi: ${e.toString()}')),
      );
      print('Reservation error: $e');
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'TIM DOKTER',
          style: TextStyle(
            fontSize: 18,
            fontFamily: 'Afacad',
            fontWeight: FontWeight.bold,
            color: Color(0xFF109E88),
          ),
        ),
        const SizedBox(height: 10),

        if (_isLoadingDoctors)
          const Center(child: CircularProgressIndicator())
        else if (_allDoctors.isEmpty)
          const Center(
            child: Text(
              'Tidak ada dokter tersedia',
              style: TextStyle(
                fontFamily: 'Afacad',
                color: Colors.grey,
              ),
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;

              if (isMobile) {
                // Tampilan list untuk mobile
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _allDoctors.length,
                  itemBuilder: (context, index) {
                    final doctor = _allDoctors[index];
                    final isSelected = _selectedDoctorId == doctor['_id'];
                    final isFavorite = _isFavorite(doctor['_id']);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: DoctorCard(
                        doctor: doctor,
                        isSelected: isSelected,
                        isFavorite: isFavorite,
                        onTap: () {
                          setState(() {
                            _selectedDoctorId = doctor['_id'];
                            _selectedTime = null;
                          });
                          _loadAvailableTimeSlots();
                        },
                        onToggleFavorite: () => _toggleFavorite(doctor['_id'], doctor['nama']),
                      ),
                    );
                  },
                );
              } else {
                // Tampilan grid untuk tablet/desktop
                final crossAxisCount = constraints.maxWidth > 900 ? 3 : 2;

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: 2.5,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: _allDoctors.length,
                  itemBuilder: (context, index) {
                    final doctor = _allDoctors[index];
                    final isSelected = _selectedDoctorId == doctor['_id'];
                    final isFavorite = _isFavorite(doctor['_id']);

                    return DoctorCard(
                      doctor: doctor,
                      isSelected: isSelected,
                      isFavorite: isFavorite,
                      onTap: () {
                        setState(() {
                          _selectedDoctorId = doctor['_id'];
                          _selectedTime = null;
                        });
                        _loadAvailableTimeSlots();
                      },
                      onToggleFavorite: () => _toggleFavorite(doctor['_id'], doctor['nama']),
                    );
                  },
                );
              }
            },
          ),
        const SizedBox(height: 20),

        // Tipe Reservasi
        const Text(
          'TIPE RESERVASI',
          style: TextStyle(
            fontSize: 18,
            fontFamily: 'Afacad',
            fontWeight: FontWeight.bold,
            color: Color(0xFF109E88),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: _isOfflineSelected
                  ? Colors.transparent
                  : const Color(0xFF109E88),
            ),
            backgroundColor: _isOfflineSelected
                ? const Color(0xFF109E88)
                : Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () {
            setState(() {
              _isOfflineSelected = !_isOfflineSelected;
            });
          },
          child: Text(
            'OFFLINE',
            style: TextStyle(
              fontFamily: 'Afacad',
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: _isOfflineSelected
                  ? Colors.white
                  : const Color(0xFF109E88),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Tanggal dan Waktu
        _CommonReservasiSections(
          selectedDate: _selectedDate,
          selectedTime: _selectedTime,
          availableTimeOptions: _availableTimeOptions,
          onDateSelected: (date) {
            setState(() {
              _selectedDate = date;
              _selectedTime = null;
            });
            _loadAvailableTimeSlots();
          },
          onTimeSelected: (time) {
            setState(() {
              _selectedTime = time;
            });
          },
          notesController: _notesController,
          doctorSelected: _selectedDoctorId != null,
        ),
        const SizedBox(height: 30),

        // Tombol Reservasi
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _submitReservation,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF109E88),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text(
              'RESERVASI',
              style: TextStyle(
                fontFamily: 'Afacad',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Bagian NonMedis dan Konsultasi tetap sama seperti sebelumnya
class _NonMedisReservasiContent extends StatefulWidget {
  @override
  __NonMedisReservasiContentState createState() =>
      __NonMedisReservasiContentState();
}

class __NonMedisReservasiContentState extends State<_NonMedisReservasiContent> {
  String? _selectedTreatment;
  DateTime? _selectedDate;
  String? _selectedTime;
  final TextEditingController _notesController = TextEditingController();
  List<String> _treatmentOptions = []; // Ubah dari static ke variabel state
  bool _isLoadingTreatments = false;
  List<String> _availableTimeOptions = [];

  // Daftar waktu default untuk non-medis
  final List<String> _defaultTimeOptions = [
    '08:00 - 09:00',
    '09:00 - 10:00',
    '10:00 - 11:00',
    '11:00 - 12:00',
    '13:00 - 14:00',
    '14:00 - 15:00',
    '15:00 - 16:00',
    '16:00 - 17:00'
  ];

  String _formatDateForApi(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  void initState() {
    super.initState();
    _loadTreatments(); // Panggil fungsi untuk load treatments
  }

  // Fungsi untuk memuat waktu tersedia berdasarkan tanggal yang dipilih
  Future<void> _loadAvailableTimeSlots() async {
    if (_selectedDate == null) return;

    try {
      final formattedDate = _formatDateForApi(_selectedDate!);

      // Untuk non-medis, kita perlu mengecek waktu yang sudah dipesan
      // dan memfilter waktu default yang masih tersedia
      final bookedTimes = await _getBookedTimesForDate(formattedDate);

      setState(() {
        // Filter waktu default yang belum dipesan
        _availableTimeOptions = _defaultTimeOptions
            .where((time) => !bookedTimes.contains(time))
            .toList();
      });
    } catch (e) {
      print('Error loading available time slots: $e');
      // Fallback ke semua waktu default jika error
      setState(() {
        _availableTimeOptions = _defaultTimeOptions;
      });
    }
  }

  // Fungsi untuk mendapatkan waktu yang sudah dipesan pada tanggal tertentu
  Future<List<String>> _getBookedTimesForDate(String formattedDate) async {
    try {
      // Anda mungkin perlu membuat endpoint baru di API untuk ini
      // atau menggunakan endpoint yang sudah ada dengan parameter yang sesuai
      final response = await ApiService.getBookedTimes(formattedDate, 'NON_MEDIS');
      return response;
    } catch (e) {
      print('Error getting booked times: $e');
      return [];
    }
  }

  // Fungsi untuk mengambil treatments dari database
  Future<void> _loadTreatments() async {
    setState(() {
      _isLoadingTreatments = true;
    });

    try {
      final treatments = await ApiService.getTreatments();
      setState(() {
        // Ambil judul treatment dari data yang dikembalikan
        _treatmentOptions = treatments.map<String>((treatment) {
          return treatment['judul'] ?? 'Treatment';
        }).toList();
        _isLoadingTreatments = false;
      });
    } catch (e) {
      print('Error loading treatments: $e');
      setState(() {
        _isLoadingTreatments = false;
      });
      // Fallback ke default options jika gagal
      _treatmentOptions = [
        'Facial Treatment',
        'Skin Care',
        'Hair Treatment',
        'Nail Care',
        'Body Treatment',
      ];
    }
  }

  Future<void> _submitReservation() async {
    try {
      if (_selectedTreatment == null) {
        throw Exception('Silakan pilih treatment terlebih dahulu');
      }

      if (_selectedDate == null || _selectedTime == null) {
        throw Exception('Silakan pilih tanggal dan waktu terlebih dahulu');
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // PERBAIKAN: Kirim parameter pic untuk non-medis
      await ApiService.createReservation(
        type: 'NON_MEDIS', // Pastikan format sesuai backend
        treatment: _selectedTreatment!,
        pic: 'terapis', // Explicitly set pic untuk non-medis
        reservationTime: _selectedTime!,
        reservationDate: _selectedDate!,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reservasi NON MEDIS berhasil dibuat')),
      );

      // Reset form
      _notesController.clear();
      setState(() {
        _selectedTreatment = null;
        _selectedTime = null;
        _selectedDate = null;
      });
    } catch (e) {
      if (Navigator.canPop(context)) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuat reservasi: ${e.toString()}')),
      );
      print('Reservation error: $e');
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pilihan Treatment
        const Text(
          'PILIH TREATMENT',
          style: TextStyle(
            fontSize: 18,
            fontFamily: 'Afacad',
            fontWeight: FontWeight.bold,
            color: Color(0xFF109E88),
          ),
        ),
        const SizedBox(height: 10),

        if (_isLoadingTreatments)
          const Center(child: CircularProgressIndicator())
        else
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF109E88)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF109E88)),
              ),
            ),
            style: const TextStyle(
              fontFamily: 'Afacad',
              color: Color(0xFF109E88),
              fontWeight: FontWeight.bold,
            ),
            hint: const Text(
              'Pilih Treatment',
              style: TextStyle(
                fontFamily: 'Afacad',
                color: Color(0xFF109E88),
                fontWeight: FontWeight.bold,
              ),
            ),
            value: _selectedTreatment,
            items: _treatmentOptions.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Afacad',
                    color: Color(0xFF109E88),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }).toList(),
            onChanged: (newValue) {
              setState(() {
                _selectedTreatment = newValue;
              });
            },
          ),
        const SizedBox(height: 20),

        // Tanggal dan Waktu
        _CommonReservasiSections(
          selectedDate: _selectedDate,
          selectedTime: _selectedTime,
          availableTimeOptions: _availableTimeOptions,
          onDateSelected: (date) {
            setState(() {
              _selectedDate = date;
              _selectedTime = null;
            });
            _loadAvailableTimeSlots();
          },
          onTimeSelected: (time) {
            setState(() {
              _selectedTime = time;
            });
          },
          notesController: _notesController,
          doctorSelected: true, // Non-medis doesn't need doctor selection
        ),
        const SizedBox(height: 30),

        // Tombol Reservasi
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _submitReservation,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF109E88),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text(
              'RESERVASI',
              style: TextStyle(
                fontFamily: 'Afacad',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _KonsultasiReservasiContent extends StatefulWidget {
  @override
  __KonsultasiReservasiContentState createState() =>
      __KonsultasiReservasiContentState();
}

class __KonsultasiReservasiContentState extends State<_KonsultasiReservasiContent> {
  String? _selectedDoctorId;
  bool _isOfflineSelected = false;
  DateTime? _selectedDate;
  String? _selectedTime;
  final TextEditingController _notesController = TextEditingController();
  List<Map<String, dynamic>> _favoriteDoctors = [];
  List<String> _availableTimeOptions = [];
  List<Map<String, dynamic>> _allDoctors = [];
  bool _isLoadingDoctors = false;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    setState(() {
      _isLoadingDoctors = true;
    });

    try {
      final doctors = await ApiService.getDokter();
      setState(() {
        _allDoctors = List<Map<String, dynamic>>.from(doctors);
        _isLoadingDoctors = false;
      });
    } catch (e) {
      print('Error loading doctors: $e');
      setState(() {
        _isLoadingDoctors = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data dokter')),
      );
    }
  }

  Future<void> _loadFavorites() async {
    try {
      final favorites = await ApiService.getFavoriteDoctors();
      setState(() {
        _favoriteDoctors = List<Map<String, dynamic>>.from(favorites);
      });
    } catch (e) {
      print('Error loading favorites: $e');
    }
  }

  Future<void> _toggleFavorite(String doctorId, String doctorName) async {
    try {
      final isCurrentlyFavorite = _favoriteDoctors.any(
            (doc) => doc['doctorId'] == doctorId && doc['isFavorite'] == true,
      );

      await ApiService.toggleFavoriteDoctor(
        doctorId,
        doctorName,
        !isCurrentlyFavorite,
      );
      await _loadFavorites();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengupdate favorit')),
      );
    }
  }

  bool _isFavorite(String doctorId) {
    return _favoriteDoctors.any(
          (doc) => doc['doctorId'] == doctorId && doc['isFavorite'] == true,
    );
  }

  Future<void> _loadAvailableTimeSlots() async {
    if (_selectedDate == null || _selectedDoctorId == null) return;

    try {
      final formattedDate = _formatDateForApi(_selectedDate!);
      final availableTimes = await ApiService.getAvailableTimeSlotsByDoctor(
        _selectedDoctorId!,
        formattedDate,
      );

      setState(() {
        _availableTimeOptions = availableTimes;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat waktu tersedia: ${e.toString()}')),
      );
    }
  }

  String _formatDateForApi(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Widget _buildDoctorSchedule(List<dynamic> jadwalPraktik) {
    if (jadwalPraktik.isEmpty) {
      return Text(
        'Jadwal belum tersedia',
        style: TextStyle(
          fontFamily: 'Afacad',
          fontSize: 12,
          color: Colors.grey,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: jadwalPraktik.map<Widget>((jadwal) {
        return Text(
          '${jadwal['hari']}: ${jadwal['jamPraktik'].map((j) => '${j['jamMulai']} - ${j['jamAkhir']}').join(', ')}',
          style: TextStyle(
            fontFamily: 'Afacad',
            fontSize: 12,
            color: Color(0xFF109E88),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _submitReservation() async {
    try {
      if (_selectedDoctorId == null) {
        throw Exception('Silakan pilih dokter terlebih dahulu');
      }

      if (_selectedDate == null || _selectedTime == null) {
        throw Exception('Silakan pilih tanggal dan waktu terlebih dahulu');
      }

      final selectedDoctor = _allDoctors.firstWhere(
            (doctor) => doctor['_id'] == _selectedDoctorId,
      );

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Panggil API untuk membuat reservasi
      final reservationResponse = await ApiService.createReservation(
        type: 'KONSULTASI',
        doctor: selectedDoctor['nama'],
        reservationTime: _selectedTime!,
        reservationDate: _selectedDate!,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      Navigator.pop(context); // Tutup loading dialog

      // Dapatkan data user dari shared preferences untuk nama pasien
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user');
      final userData = userJson != null ? jsonDecode(userJson) : {};
      final userName = userData['nama'] ?? 'User';

      // Gabungkan semua data dari response API dengan data tambahan
      final Map<String, dynamic> completeReservationData = {
        // Data dari response API
        ...reservationResponse['data'] ?? {},
        // Data tambahan yang mungkin tidak ada di response
        'dokter': selectedDoctor['nama'],
        'namaPasien': userName,
        'tipe': 'KONSULTASI',
        'tanggalReservasi': _formatDateForApi(_selectedDate!),
        'waktuReservasi': _selectedTime!,
      };

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => InvoicePage(
            reservationData: completeReservationData,
          ),
        ),
      );

      _notesController.clear();
      setState(() {
        _selectedDoctorId = null;
        _selectedTime = null;
        _selectedDate = null;
        _availableTimeOptions = [];
      });

    } catch (e) {
      if (Navigator.canPop(context)) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuat reservasi: ${e.toString()}')),
      );
      print('Reservation error: $e');
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'TIM DOKTER',
          style: TextStyle(
            fontSize: 18,
            fontFamily: 'Afacad',
            fontWeight: FontWeight.bold,
            color: Color(0xFF109E88),
          ),
        ),
        const SizedBox(height: 10),

        if (_isLoadingDoctors)
          const Center(child: CircularProgressIndicator())
        else if (_allDoctors.isEmpty)
          const Center(
            child: Text(
              'Tidak ada dokter tersedia',
              style: TextStyle(
                fontFamily: 'Afacad',
                color: Colors.grey,
              ),
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;

              if (isMobile) {
                // Tampilan list untuk mobile
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _allDoctors.length,
                  itemBuilder: (context, index) {
                    final doctor = _allDoctors[index];
                    final isSelected = _selectedDoctorId == doctor['_id'];
                    final isFavorite = _isFavorite(doctor['_id']);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: DoctorCard(
                        doctor: doctor,
                        isSelected: isSelected,
                        isFavorite: isFavorite,
                        onTap: () {
                          setState(() {
                            _selectedDoctorId = doctor['_id'];
                            _selectedTime = null;
                          });
                          _loadAvailableTimeSlots();
                        },
                        onToggleFavorite: () => _toggleFavorite(doctor['_id'], doctor['nama']),
                      ),
                    );
                  },
                );
              } else {
                // Tampilan grid untuk tablet/desktop
                final crossAxisCount = constraints.maxWidth > 900 ? 3 : 2;

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: 2.5,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: _allDoctors.length,
                  itemBuilder: (context, index) {
                    final doctor = _allDoctors[index];
                    final isSelected = _selectedDoctorId == doctor['_id'];
                    final isFavorite = _isFavorite(doctor['_id']);

                    return DoctorCard(
                      doctor: doctor,
                      isSelected: isSelected,
                      isFavorite: isFavorite,
                      onTap: () {
                        setState(() {
                          _selectedDoctorId = doctor['_id'];
                          _selectedTime = null;
                        });
                        _loadAvailableTimeSlots();
                      },
                      onToggleFavorite: () => _toggleFavorite(doctor['_id'], doctor['nama']),
                    );
                  },
                );
              }
            },
          ),
        const SizedBox(height: 10),

        // Tipe Reservasi (always ONLINE for konsultasi)
        const Text(
          'TIPE RESERVASI',
          style: TextStyle(
            fontSize: 18,
            fontFamily: 'Afacad',
            fontWeight: FontWeight.bold,
            color: Color(0xFF109E88),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF109E88),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'ONLINE',
            style: TextStyle(
              fontFamily: 'Afacad',
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Tanggal dan Waktu
        _CommonReservasiSections(
          selectedDate: _selectedDate,
          selectedTime: _selectedTime,
          availableTimeOptions: _availableTimeOptions,
          onDateSelected: (date) {
            setState(() {
              _selectedDate = date;
              _selectedTime = null; // Reset waktu saat tanggal berubah
            });
          },
          onTimeSelected: (time) {
            setState(() {
              _selectedTime = time;
            });
          },
          notesController: _notesController,
          doctorSelected: _selectedDoctorId != null,
        ),
        const SizedBox(height: 30),

        // Tombol Reservasi
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _submitReservation,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF109E88),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text(
              'RESERVASI',
              style: TextStyle(
                fontFamily: 'Afacad',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Bagian CommonReservasiSections tetap sama seperti sebelumnya
class _CommonReservasiSections extends StatefulWidget {
  final DateTime? selectedDate;
  final String? selectedTime;
  final List<String> availableTimeOptions;
  final Function(DateTime) onDateSelected;
  final Function(String) onTimeSelected;
  final TextEditingController notesController;
  final bool doctorSelected;

  const _CommonReservasiSections({
    Key? key,
    required this.selectedDate,
    required this.selectedTime,
    required this.availableTimeOptions,
    required this.onDateSelected,
    required this.onTimeSelected,
    required this.notesController,
    required this.doctorSelected,
  }) : super(key: key);

  @override
  __CommonReservasiSectionsState createState() => __CommonReservasiSectionsState();
}

class __CommonReservasiSectionsState extends State<_CommonReservasiSections> {
  String _formatDate(DateTime? date) {
    if (date == null) return 'Pilih tanggal';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tanggal Reservasi
        const Text(
          'TANGGAL RESERVASI',
          style: TextStyle(
            fontSize: 18,
            fontFamily: 'Afacad',
            fontWeight: FontWeight.bold,
            color: Color(0xFF109E88),
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          readOnly: true,
          style: const TextStyle(
            fontFamily: 'Afacad',
            color: Color(0xFF109E88),
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            hintText: _formatDate(widget.selectedDate),
            hintStyle: const TextStyle(
              fontFamily: 'Afacad',
              color: Color(0xFF109E88),
              fontWeight: FontWeight.bold,
            ),
            suffixIcon: const Icon(Icons.calendar_today, color: Color(0xFF109E88)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF109E88)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF109E88)),
            ),
          ),
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: widget.selectedDate ?? DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime(DateTime.now().year + 1),
            );
            if (picked != null && picked != widget.selectedDate) {
              widget.onDateSelected(picked);
            }
          },
        ),
        const SizedBox(height: 20),

        // Waktu Reservasi
        const Text(
          'WAKTU RESERVASI',
          style: TextStyle(
            fontSize: 18,
            fontFamily: 'Afacad',
            fontWeight: FontWeight.bold,
            color: Color(0xFF109E88),
          ),
        ),
        const SizedBox(height: 10),

        if (widget.availableTimeOptions.isEmpty && widget.selectedDate != null)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF109E88)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Tidak ada waktu tersedia untuk tanggal ini',
              style: TextStyle(
                fontFamily: 'Afacad',
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        else
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF109E88)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF109E88)),
              ),
            ),
            style: const TextStyle(
              fontFamily: 'Afacad',
              color: Color(0xFF109E88),
              fontWeight: FontWeight.bold,
            ),
            hint: Text(
              widget.selectedDate == null
                  ? 'Pilih tanggal terlebih dahulu'
                  : 'Pilih waktu',
              style: const TextStyle(
                fontFamily: 'Afacad',
                color: Color(0xFF109E88),
                fontWeight: FontWeight.bold,
              ),
            ),
            value: widget.selectedTime,
            items: widget.availableTimeOptions.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Afacad',
                    color: Color(0xFF109E88),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }).toList(),
            onChanged: widget.selectedDate == null
                ? null
                : (newValue) {
              if (newValue != null) {
                widget.onTimeSelected(newValue);
              }
            },
          ),
        const SizedBox(height: 20),
      ],
    );
  }
}