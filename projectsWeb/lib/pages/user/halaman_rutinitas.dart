import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:apskina/pages/user/skincare_item.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart'; // Add this import
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../services/api_service.dart';

class HalamanRutinitas extends StatefulWidget {
  final List<SkincareItem> userSkincareItems;

  HalamanRutinitas({required this.userSkincareItems});

  @override
  _HalamanRutinitasState createState() => _HalamanRutinitasState();
}

class _HalamanRutinitasState extends State<HalamanRutinitas> {
  final PageController _pageController = PageController(viewportFraction: 0.2);
  int _currentPage = DateTime.now().day - 1;
  String _selectedTime = 'PAGI';
  // New variables for QnA history, consultations, and skin insights
  Map<DateTime, Map<String, dynamic>> _qnaHistory = {};
  Map<DateTime, List<Map<String, dynamic>>> _consultationHistory = {};
  Map<DateTime, int> _routineCompletion = {}; // 0-100% completion rate
  DateTime? _routineStartDate;

  Map<DateTime, int> _dailyRoutineCompletion = {};
  Map<DateTime, Map<String, dynamic>> _qnaData = {};
  bool _showSkinInsight = false;


  // New variable to control calendar visibility
  bool _showFullCalendar = false;

  // Track completion for each date and time
  Map<DateTime, Map<String, List<bool>>> _completedTasks = {};

  // Track selected times for each skincare
  Map<DateTime, Map<String, List<String>>> _selectedTimes = {};

  // Current selected date
  DateTime get _selectedDate => _dates[_currentPage];

  // Get all dates of the current month
  List<DateTime> get _dates {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final lastDay = DateTime(now.year, now.month + 1, 0);

    return List.generate(lastDay.day, (index) =>
        DateTime(now.year, now.month, index + 1));
  }

  // Urutan skincare yang benar
  static const List<String> _skincareOrder = [
    'Facial Wash',
    'Toner',
    'Essence',
    'Serum',
    'Moisturizer',
    'Obat Jerawat',
    'Sunscreen'
  ];

  // Filter dan urutkan skincare items
  List<SkincareItem> get _filteredSkincareItems {
    // Gunakan Map untuk menghindari duplikasi jenis skincare
    final Map<String, SkincareItem> uniqueItems = {};

    for (var item in widget.userSkincareItems) {
      // Jika jenis skincare belum ada di map, tambahkan
      if (!uniqueItems.containsKey(item.type)) {
        uniqueItems[item.type] = item;
      }
    }

    // Urutkan berdasarkan urutan yang ditentukan
    return _skincareOrder
        .where((type) => uniqueItems.containsKey(type))
        .map((type) => uniqueItems[type]!)
        .toList();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pageController.jumpToPage(_currentPage);
      _loadAdditionalData();
    });

    // Initialize data for all dates based on filtered skincare items
    for (final date in _dates) {
      _completedTasks[date] = {
        'PAGI': List.generate(_filteredSkincareItems.length, (index) => false),
        'MALAM': List.generate(_filteredSkincareItems.length, (index) => false),
      };

      // Set default times based on skincare type
      _selectedTimes[date] = {
        'PAGI': _getDefaultTimes('PAGI'),
        'MALAM': _getDefaultTimes('MALAM'),
      };
      _routineCompletion[date] = 0;
    }
  }

  Future<void> _loadAdditionalData() async {
    try {
      // Load QnA history
      final qnaHistory = await ApiService.getQnaHistory();
      if (qnaHistory['data'] != null) {
        final completedAt = DateTime.parse(qnaHistory['data']['completedAt']);
        _qnaData[completedAt] = qnaHistory['data'];
      }

      // Load consultation history
      final reservations = await ApiService.getUserReservations();
      for (var reservation in reservations) {
        final dateParts = reservation['tanggalReservasi'].split('/');
        final date = DateTime(
            int.parse(dateParts[2]),
            int.parse(dateParts[1]),
            int.parse(dateParts[0])
        );

        if (!_consultationHistory.containsKey(date)) {
          _consultationHistory[date] = [];
        }
        _consultationHistory[date]!.add(reservation);
      }

      // Load routine completion data
      _loadRoutineCompletionData();

    } catch (e) {
      print('Error loading additional data: $e');
    }
  }

  void _loadRoutineCompletionData() {
    // Initialize completion data for all dates
    for (final date in _dates) {
      int completion = 0;

      // Check if both morning and night routines are completed
      final morningCompleted = _completedTasks[date]?['PAGI']?.every((task) => task) ?? false;
      final nightCompleted = _completedTasks[date]?['MALAM']?.every((task) => task) ?? false;

      if (morningCompleted && nightCompleted) {
        completion = 100;
      } else if (morningCompleted || nightCompleted) {
        completion = 50;
      }

      _dailyRoutineCompletion[date] = completion;
    }
  }

  // Load user data including QnA history and consultations
  Future<void> _loadUserData() async {
    try {
      await _loadQnaHistory();
      await _loadConsultationHistory();
      await _loadRoutineCompletion();
      await _loadRoutineStartDate();
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _loadQnaHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      // Simulate API call - replace with actual API endpoint
      // final response = await http.get(
      //   Uri.parse('${ApiService.baseUrl}/qna/history'),
      //   headers: {'Authorization': 'Bearer $token'},
      // );

      // Mock data for demonstration
      final mockQnaData = {
        DateTime(2025, 9, 10): {
          'completed': true,
          'score': 85,
          'skinType': 'Combination',
          'concerns': ['Acne', 'Pores']
        },
        DateTime(2025, 9, 14): {
          'completed': true,
          'score': 92,
          'skinType': 'Combination',
          'concerns': ['Acne', 'Hydration']
        }
      };

      setState(() {
        _qnaHistory = Map<DateTime, Map<String, dynamic>>.from(mockQnaData);
      });
    } catch (e) {
      print('Error loading QnA history: $e');
    }
  }

  Future<void> _loadConsultationHistory() async {
    try {
      // Mock data for demonstration
      final mockConsultationData = {
        DateTime(2025, 9, 14): [
          {
            'type': 'KONSULTASI',
            'doctor': 'Dr. Sarah',
            'time': '14:00',
            'status': 'Completed'
          }
        ],
        DateTime(2025, 9, 15): [
          {
            'type': 'MEDIS',
            'treatment': 'Acne Treatment',
            'time': '10:00',
            'status': 'Scheduled'
          }
        ]
      };

      setState(() {
        _consultationHistory = Map<DateTime, List<Map<String, dynamic>>>.from(mockConsultationData);
      });
    } catch (e) {
      print('Error loading consultation history: $e');
    }
  }

  Future<void> _loadRoutineCompletion() async {
    try {
      // Mock data for demonstration
      final mockCompletionData = {
        DateTime(2025, 9, 14): 75,
        DateTime(2025, 9, 15): 100,
        DateTime(2025, 9, 16): 50,
      };

      setState(() {
        _routineCompletion = Map<DateTime, int>.from(mockCompletionData);
      });
    } catch (e) {
      print('Error loading routine completion: $e');
    }
  }

  Future<void> _loadRoutineStartDate() async {
    try {
      // Load routine start date from shared preferences
      final prefs = await SharedPreferences.getInstance();
      final startDateMillis = prefs.getInt('routine_start_date');

      if (startDateMillis != null) {
        setState(() {
          _routineStartDate = DateTime.fromMillisecondsSinceEpoch(startDateMillis);
        });
      }
    } catch (e) {
      print('Error loading routine start date: $e');
    }
  }

  Future<void> _saveRoutineStartDate(DateTime date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('routine_start_date', date.millisecondsSinceEpoch);

      setState(() {
        _routineStartDate = date;
      });
    } catch (e) {
      print('Error saving routine start date: $e');
    }
  }

  // Get default times based on time of day with 15 minutes interval
  List<String> _getDefaultTimes(String timeOfDay) {
    List<String> defaultTimes = [];

    // Waktu mulai berdasarkan pagi atau malam
    int baseHour = timeOfDay == 'PAGI' ? 7 : 20;
    int baseMinute = 0;

    for (int i = 0; i < _filteredSkincareItems.length; i++) {
      // Hitung menit dan jam
      int totalMinutes = baseMinute + (i * 15);
      int hours = baseHour + (totalMinutes ~/ 60);
      int minutes = totalMinutes % 60;

      // Format waktu
      String time = '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
      defaultTimes.add(time);
    }

    return defaultTimes;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _filteredSkincareItems;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(
                color: Color(0xFF109E88),
                width: 1.0,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: 30.0, left: 20, right: 20),
            child: AppBar(
              leading: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Color(0xFF109E88),
                    width: 1.0,
                  ),
                ),
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: Color(0xFF109E88)),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              title: const Text(
                'Kalender Rutinitas',
                style: TextStyle(
                  fontFamily: 'Afacad',
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: Color(0xFF109E88),
                ),
              ),
              actions: [
                if (!_showFullCalendar && !_showSkinInsight)
                  IconButton(
                    icon: Icon(Icons.calendar_today, color: Color(0xFF109E88)),
                    onPressed: () {
                      setState(() {
                        _showFullCalendar = true;
                      });
                    },
                  ),
                if (_showFullCalendar || _showSkinInsight)
                  IconButton(
                    icon: Icon(Icons.close, color: Color(0xFF109E88)),
                    onPressed: () {
                      setState(() {
                        _showFullCalendar = false;
                        _showSkinInsight = false;
                      });
                    },
                  ),
              ],
              elevation: 0,
              centerTitle: true,
              backgroundColor: Colors.transparent,
            ),
          ),
        ),
      ),
      body: filteredItems.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sentiment_dissatisfied, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Belum ada skincare',
              style: TextStyle(
                fontFamily: 'Afacad',
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Tambahkan skincare terlebih dahulu',
              style: TextStyle(
                fontFamily: 'Afacad',
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/tambah_skincare');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF109E88),
              ),
              child: Text(
                'Tambah Skincare',
                style: TextStyle(
                  fontFamily: 'Afacad',
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      )
          : _showSkinInsight
          ? _buildSkinInsightView()
          : _showFullCalendar
          ? _buildFullCalendarView()
          : _buildNormalView(),
    );
  }

  // Build the normal view (original content)
  Widget _buildNormalView() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _showSkinInsight = true;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF109E88),
              ),
              child: Text(
                'Lihat Insight Kulit',
                style: TextStyle(
                  fontFamily: 'Afacad',
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(height: 20),
          // Calendar dates
          Container(
            height: 60,
            child: PageView.builder(
              controller: _pageController,
              itemCount: _dates.length,
              onPageChanged: (int page) {
                setState(() {
                  _currentPage = page;
                });
              },
              itemBuilder: (context, index) {
                final date = _dates[index];
                final isSelected = index == _currentPage;
                final isToday = date.day == DateTime.now().day &&
                    date.month == DateTime.now().month &&
                    date.year == DateTime.now().year;

                return GestureDetector(
                  onTap: () => _showDateDetails(_selectedDate),
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: isToday ? Color(0xFF109E88) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? Color(0xFF109E88) : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('E').format(date),
                          style: TextStyle(
                            fontFamily: 'Afacad',
                            fontSize: isSelected ? 10 : 8,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isToday ? Colors.white : (isSelected ? Color(0xFF109E88) : Colors.grey),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          date.day.toString(),
                          style: TextStyle(
                            fontFamily: 'Afacad',
                            fontSize: isSelected ? 16 : 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isToday ? Colors.white : (isSelected ? Color(0xFF109E88) : Colors.black),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          DateFormat('MMM').format(date),
                          style: TextStyle(
                            fontFamily: 'Afacad',
                            fontSize: isSelected ? 8 : 6,
                            color: isToday ? Colors.white : (isSelected ? Color(0xFF109E88) : Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 30),

          // Time selection (PAGI/MALAM)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTimeOption('PAGI'),
              _buildTimeOption('MALAM'),
            ],
          ),
          SizedBox(height: 30),

          // Skincare tasks
          Text(
            'Skincare Routine - ${DateFormat('dd MMM yyyy').format(_selectedDate)}',
            style: TextStyle(
              fontFamily: 'Afacad',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF109E88),
            ),
          ),
          SizedBox(height: 15),

          // Skincare tasks based on user's items
          Column(
            children: List.generate(_filteredSkincareItems.length, (index) {
              return _buildSkincareTask(index);
            }),
          ),
        ],
      ),
    );
  }

  // Build the full calendar view
  Widget _buildFullCalendarView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            child: TableCalendar(
              firstDay: DateTime.utc(DateTime.now().year - 1, 1, 1),
              lastDay: DateTime.utc(DateTime.now().year + 1, 12, 31),
              focusedDay: _selectedDate,
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDate, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  if (selectedDay.month == DateTime.now().month &&
                      selectedDay.year == DateTime.now().year) {
                    _currentPage = selectedDay.day - 1;
                    _pageController.jumpToPage(_currentPage);
                  }
                  _showFullCalendar = false;
                });
              },
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  fontFamily: 'Afacad',
                  fontSize: 16, // Reduced font size
                  color: Color(0xFF109E88),
                  fontWeight: FontWeight.bold,
                ),
                leftChevronIcon: Icon(Icons.chevron_left, color: Color(0xFF109E88), size: 20),
                rightChevronIcon: Icon(Icons.chevron_right, color: Color(0xFF109E88), size: 20),
                headerPadding: EdgeInsets.symmetric(vertical: 8), // Reduced padding
              ),
              calendarStyle: CalendarStyle(
                selectedDecoration: BoxDecoration(
                  color: Color(0xFF109E88),
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Color(0xFF109E88).withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                weekendTextStyle: TextStyle(color: Colors.red),
                defaultTextStyle: TextStyle(fontSize: 12), // Smaller text
                holidayTextStyle: TextStyle(fontSize: 12),
                selectedTextStyle: TextStyle(fontSize: 12, color: Colors.white),
                todayTextStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: TextStyle(
                  fontFamily: 'Afacad',
                  color: Colors.black,
                  fontSize: 10, // Smaller weekday text
                ),
                weekendStyle: TextStyle(
                  fontFamily: 'Afacad',
                  color: Colors.red,
                  fontSize: 10,
                ),
              ),
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  final completion = _dailyRoutineCompletion[date] ?? 0;
                  final hasQna = _qnaData.containsKey(date);
                  final hasConsultation = _consultationHistory.containsKey(date);

                  if (completion > 0 || hasQna || hasConsultation) {
                    return Positioned(
                      bottom: 1,
                      right: 1,
                      child: Container(
                        width: 10, // Smaller indicator
                        height: 10,
                        decoration: BoxDecoration(
                          color: completion == 100 ? Colors.green :
                          completion == 50 ? Colors.orange : Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                        child: completion == 100 ? Icon(
                          Icons.check,
                          size: 6, // Smaller icon
                          color: Colors.white,
                        ) : null,
                      ),
                    );
                  }
                  return SizedBox.shrink();
                },
              ),
            ),
          ),

          // Date details section
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: _buildDateDetails(_selectedDate),
          ),

          SizedBox(height: 16),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _showFullCalendar = false;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF109E88),
                minimumSize: Size(double.infinity, 48), // Full width button
              ),
              child: Text(
                'Kembali ke Rutinitas',
                style: TextStyle(
                  fontFamily: 'Afacad',
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDateDetails(DateTime date) {
    final qnaData = _qnaData[date];
    final consultations = _consultationHistory[date] ?? [];
    final completion = _dailyRoutineCompletion[date] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 16),
        Text(
          'Detail Tanggal ${DateFormat('dd MMM yyyy').format(date)}',
          style: TextStyle(
            fontFamily: 'Afacad',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF109E88),
          ),
        ),
        SizedBox(height: 12),

        // Progress section
        Row(
          children: [
            Icon(Icons.assignment_turned_in, size: 16, color: Colors.grey),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Progress Rutinitas: $completion%',
                style: TextStyle(
                  fontFamily: 'Afacad',
                  fontSize: 14,
                  color: completion == 100 ? Colors.green :
                  completion == 50 ? Colors.orange : Colors.grey,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),

        // QnA section
        if (qnaData != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.quiz, size: 16, color: Colors.blue),
                  SizedBox(width: 8),
                  Text(
                    'Assessment Kulit',
                    style: TextStyle(
                      fontFamily: 'Afacad',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Padding(
                padding: EdgeInsets.only(left: 24),
                child: Text(
                  'Telah mengisi QnA kulit',
                  style: TextStyle(
                    fontFamily: 'Afacad',
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              SizedBox(height: 12),
            ],
          ),

        // Consultation section
        Row(
          children: [
            Icon(Icons.medical_services, size: 16, color: Colors.purple),
            SizedBox(width: 8),
            Text(
              'Riwayat Konsultasi',
              style: TextStyle(
                fontFamily: 'Afacad',
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 4),

        if (consultations.isEmpty)
          Padding(
            padding: EdgeInsets.only(left: 24),
            child: Text(
              'Belum ada data konsultasi pada tanggal ini',
              style: TextStyle(
                fontFamily: 'Afacad',
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          )
        else
          ...consultations.map((consultation) => Padding(
            padding: EdgeInsets.only(left: 24, bottom: 4),
            child: Text(
              '• ${consultation['tipe']} - ${consultation['status']}',
              style: TextStyle(
                fontFamily: 'Afacad',
                fontSize: 12,
              ),
            ),
          )).toList(),
      ],
    );
  }

  Widget _buildQnaDataSection() {
    final qnaData = _qnaHistory[_selectedDate];
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12),
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📊 Hasil QnA Kulit',
            style: TextStyle(
              fontFamily: 'Afacad',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue[800],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Tipe Kulit: ${qnaData!['skinType']}',
            style: TextStyle(fontFamily: 'Afacad'),
          ),
          Text(
            'Skor: ${qnaData['score']}/100',
            style: TextStyle(fontFamily: 'Afacad'),
          ),
          Text(
            'Kekhawatiran: ${qnaData['concerns'].join(', ')}',
            style: TextStyle(fontFamily: 'Afacad'),
          ),
        ],
      ),
    );
  }

  Widget _buildConsultationSection() {
    final consultations = _consultationHistory[_selectedDate] ?? [];
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12),
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🏥 Riwayat Konsultasi',
            style: TextStyle(
              fontFamily: 'Afacad',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.green[800],
            ),
          ),
          SizedBox(height: 8),
          if (consultations.isEmpty)
            Text(
              'Belum ada data konsultasi pada tanggal ini',
              style: TextStyle(fontFamily: 'Afacad'),
            ),
          ...consultations.map((consultation) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '• ${consultation['type']} - ${consultation['time']}',
                style: TextStyle(fontFamily: 'Afacad', fontWeight: FontWeight.bold),
              ),
              if (consultation['doctor'] != null)
                Text('   Dokter: ${consultation['doctor']}', style: TextStyle(fontFamily: 'Afacad')),
              if (consultation['treatment'] != null)
                Text('   Treatment: ${consultation['treatment']}', style: TextStyle(fontFamily: 'Afacad')),
              Text('   Status: ${consultation['status']}', style: TextStyle(fontFamily: 'Afacad')),
              SizedBox(height: 8),
            ],
          )),
        ],
      ),
    );
  }

  Widget _buildRoutineCompletionSection() {
    final completion = _routineCompletion[_selectedDate] ?? 0;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12),
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📈 Progress Rutinitas',
            style: TextStyle(
              fontFamily: 'Afacad',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.orange[800],
            ),
          ),
          SizedBox(height: 8),
          LinearProgressIndicator(
            value: completion / 100,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              completion >= 80 ? Colors.green :
              completion >= 50 ? Colors.orange : Colors.red,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '$completion% selesai',
            style: TextStyle(fontFamily: 'Afacad'),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeOption(String time) {
    final isSelected = _selectedTime == time;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTime = time;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF109E88) : Colors.grey[200],
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(
          time,
          style: TextStyle(
            fontFamily: 'Afacad',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildSkincareTask(int index) {
    final skincare = _filteredSkincareItems[index];
    final isCompleted = _completedTasks[_selectedDate]![_selectedTime]![index];
    String selectedTime = _selectedTimes[_selectedDate]![_selectedTime]![index];

    return Container(
      margin: EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          // Background image dengan error handling
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              image: DecorationImage(
                image: _getImageProvider(skincare.getImagePath()),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                color: Colors.black.withOpacity(0.3),
              ),
              padding: EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Judul dengan nama produk
                  Text(
                    '${skincare.getDisplayTitle()}',
                    style: TextStyle(
                      fontFamily: 'Afacad',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 5),
                  Text(
                    '${skincare.name}',
                    style: TextStyle(
                      fontFamily: 'Afacad',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => _showTimeInputDialog(index),
                    child: Row(
                      children: [
                        Icon(Icons.access_time, size: 16, color: Colors.white),
                        SizedBox(width: 5),
                        Text(
                          selectedTime,
                          style: TextStyle(
                            fontFamily: 'Afacad',
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Check button (outside the image, bottom right)
          Positioned(
            bottom: 10,
            right: 10,
            child: GestureDetector(
              onTap: () {
                if (!isCompleted) {
                  _showConfirmationDialog(index, skincare.getDisplayTitle(), skincare.name);
                } else {
                  setState(() {
                    _completedTasks[_selectedDate]![_selectedTime]![index] = false;
                  });
                }
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isCompleted ? Color(0xFF109E88) : Colors.grey[300],
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.check,
                  color: isCompleted ? Colors.white : Colors.grey[600],
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method untuk handle image loading dengan error handling
  ImageProvider _getImageProvider(String imagePath) {
    try {
      // Coba load sebagai asset
      return AssetImage(imagePath);
    } catch (e) {
      // Jika gagal, gunakan placeholder
      print('Error loading image: $imagePath, error: $e');
      return AssetImage('assets/images/skincare/default.png');
    }
  }

  void _showConfirmationDialog(int index, String skincareTitle, String productName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Konfirmasi',
            style: TextStyle(
              fontFamily: 'Afacad',
              color: Color(0xFF109E88),
            ),
          ),
          content: Text(
            'Apakah Anda yakin telah menyelesaikan $skincareTitle dengan produk $productName?',
            style: TextStyle(
              fontFamily: 'Afacad',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Batal',
                style: TextStyle(
                  fontFamily: 'Afacad',
                  color: Colors.grey,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                _completeTask(index);
                Navigator.of(context).pop();
              },
              child: Text(
                'Ya',
                style: TextStyle(
                  fontFamily: 'Afacad',
                  color: Color(0xFF109E88),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _completeTask(int index) {
    setState(() {
      _completedTasks[_selectedDate]![_selectedTime]![index] = true;

      // Calculate completion percentage
      final completedTasks = _completedTasks[_selectedDate]![_selectedTime]!.where((task) => task).length;
      final totalTasks = _completedTasks[_selectedDate]![_selectedTime]!.length;
      final completionPercentage = ((completedTasks / totalTasks) * 100).round();

      _routineCompletion[_selectedDate] = completionPercentage;

      // Set routine start date if this is the first completion
      if (_routineStartDate == null) {
        _saveRoutineStartDate(_selectedDate);
      }

      // Schedule notification for next step if applicable
      _scheduleNextStepNotification(index);
    });
  }

  void _scheduleNextStepNotification(int currentIndex) {
    if (currentIndex < _filteredSkincareItems.length - 1) {
      final nextIndex = currentIndex + 1;
      final nextSkincare = _filteredSkincareItems[nextIndex];
      final nextTime = _selectedTimes[_selectedDate]![_selectedTime]![nextIndex];

      // Parse the time and schedule notification
      final timeParts = nextTime.split(':');
      if (timeParts.length == 2) {
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);

        // Schedule notification (this is a simplified example)
        // In a real app, you would use a package like flutter_local_notifications
        print('Scheduling notification for $nextTime: Gunakan ${nextSkincare.getDisplayTitle()}');

        // For demonstration, we'll just show a snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Notifikasi dijadwalkan untuk $nextTime: ${nextSkincare.getDisplayTitle()}',
              style: TextStyle(fontFamily: 'Afacad'),
            ),
          ),
        );
      }
    }
  }

  void _showTimeInputDialog(int index) {
    TextEditingController controller = TextEditingController(
        text: _selectedTimes[_selectedDate]![_selectedTime]![index]
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Atur Waktu Skincare',
            style: TextStyle(
              fontFamily: 'Afacad',
              color: Color(0xFF109E88),
            ),
          ),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'HH:MM (contoh: 07:30)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.datetime,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Batal',
                style: TextStyle(
                  fontFamily: 'Afacad',
                  color: Colors.grey,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                final newTime = controller.text.trim();
                // Validasi format waktu sederhana
                if (_isValidTimeFormat(newTime)) {
                  setState(() {
                    _selectedTimes[_selectedDate]![_selectedTime]![index] = newTime;
                  });
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Format waktu tidak valid. Gunakan format HH:MM (contoh: 07:30)',
                        style: TextStyle(fontFamily: 'Afacad'),
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text(
                'Simpan',
                style: TextStyle(
                  fontFamily: 'Afacad',
                  color: Color(0xFF109E88),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDateDetails(DateTime date) {
    final qnaData = _qnaData[date];
    final consultations = _consultationHistory[date] ?? [];
    final completion = _dailyRoutineCompletion[date] ?? 0;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Detail Tanggal ${DateFormat('dd MMM yyyy').format(date)}',
            style: TextStyle(
              fontFamily: 'Afacad',
              color: Color(0xFF109E88),
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rutinitas Skincare: $completion% selesai',
                  style: TextStyle(
                    fontFamily: 'Afacad',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),

                if (qnaData != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hasil QnA:',
                        style: TextStyle(
                          fontFamily: 'Afacad',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Telah mengisi assessment kulit',
                        style: TextStyle(fontFamily: 'Afacad'),
                      ),
                      SizedBox(height: 10),
                    ],
                  ),

                Text(
                  'Riwayat Konsultasi:',
                  style: TextStyle(
                    fontFamily: 'Afacad',
                    fontWeight: FontWeight.bold,
                  ),
                ),

                if (consultations.isEmpty)
                  Text(
                    'Belum ada data konsultasi pada tanggal ini',
                    style: TextStyle(fontFamily: 'Afacad'),
                  )
                else
                  ...consultations.map((consultation) => Text(
                    '• ${consultation['tipe']} - ${consultation['status']}',
                    style: TextStyle(fontFamily: 'Afacad'),
                  )),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Tutup', style: TextStyle(fontFamily: 'Afacad')),
            ),
          ],
        );
      },
    );
  }

  void _showSkinInsights() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            '📊 Insight Perkembangan Kulit',
            style: TextStyle(
              fontFamily: 'Afacad',
              color: Color(0xFF109E88),
            ),
          ),
          content: Container(
            width: double.maxFinite,
            height: 300,
            child: _buildSkinInsightsChart(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Tutup',
                style: TextStyle(
                  fontFamily: 'Afacad',
                  color: Color(0xFF109E88),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSkinInsightView() {
    final last7Days = List.generate(7, (index)
    => DateTime.now().subtract(Duration(days: index)));

    final completionData = last7Days.map((date) {
      return _dailyRoutineCompletion[date] ?? 0;
    }).toList();

    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Insight Perkembangan Kulit',
            style: TextStyle(
              fontFamily: 'Afacad',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF109E88),
            ),
          ),
          SizedBox(height: 20),
          Container(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                barTouchData: BarTouchData(
                  enabled: false,
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final date = last7Days[value.toInt()];
                        return Text(
                          DateFormat('dd/MM').format(date),
                          style: TextStyle(
                            fontFamily: 'Afacad',
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}%',
                          style: TextStyle(
                            fontFamily: 'Afacad',
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: const Color(0xff37434d), width: 1),
                ),
                barGroups: completionData.asMap().entries.map((entry) {
                  final index = entry.key;
                  final value = entry.value;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: value.toDouble(),
                        color: _getCompletionColor(value),
                        width: 16,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          SizedBox(height: 20),
          Row(
            children: [
              _buildLegendItem(Colors.green, '100% Completed'),
              SizedBox(width: 10),
              _buildLegendItem(Colors.orange, '50% Completed'),
              SizedBox(width: 10),
              _buildLegendItem(Colors.blue, 'QnA/Consultation'),
            ],
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _showSkinInsight = false;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF109E88),
            ),
            child: Text(
              'Kembali ke Kalender',
              style: TextStyle(
                fontFamily: 'Afacad',
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          color: color,
        ),
        SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(
            fontFamily: 'Afacad',
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Color _getCompletionColor(int percentage) {
    if (percentage == 100) return Colors.green;
    if (percentage == 50) return Colors.orange;
    return Colors.blue;
  }

  Widget _buildSkinInsightsChart() {
    // Sample data for the chart with proper typing
    final List<Map<String, dynamic>> chartData = [
      {'date': '10 Sep', 'completion': 60, 'skinScore': 75},
      {'date': '11 Sep', 'completion': 80, 'skinScore': 78},
      {'date': '12 Sep', 'completion': 40, 'skinScore': 72},
      {'date': '13 Sep', 'completion': 90, 'skinScore': 82},
      {'date': '14 Sep', 'completion': 100, 'skinScore': 85},
      {'date': '15 Sep', 'completion': 70, 'skinScore': 83},
    ];

    return Column(
      children: [
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  color: Colors.blue,
                ),
                SizedBox(width: 4),
                Text('Rutinitas (%)', style: TextStyle(fontFamily: 'Afacad', fontSize: 12)),
              ],
            ),
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  color: Colors.green,
                ),
                SizedBox(width: 4),
                Text('Skor Kulit', style: TextStyle(fontFamily: 'Afacad', fontSize: 12)),
              ],
            ),
          ],
        ),
        SizedBox(height: 16),
        // Chart
        Expanded(
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              Container(
                width: chartData.length * 60.0,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 100,
                    barTouchData: BarTouchData(enabled: false),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index >= 0 && index < chartData.length) {
                              final date = chartData[index]['date'] as String;
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  date,
                                  style: TextStyle(fontFamily: 'Afacad', fontSize: 10),
                                ),
                              );
                            }
                            return Text('');
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              '${value.toInt()}%',
                              style: TextStyle(fontFamily: 'Afacad', fontSize: 10),
                            );
                          },
                        ),
                      ),
                    ),
                    gridData: FlGridData(show: true),
                    borderData: FlBorderData(show: false),
                    barGroups: chartData.asMap().entries.map((entry) {
                      final index = entry.key;
                      final data = entry.value;

                      // Safely extract values with null checks and type casting
                      final completion = (data['completion'] as int?)?.toDouble() ?? 0.0;
                      final skinScore = (data['skinScore'] as int?)?.toDouble() ?? 0.0;

                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: completion,
                            color: Colors.blue,
                            width: 16,
                          ),
                          BarChartRodData(
                            toY: skinScore,
                            color: Colors.green,
                            width: 16,
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16),
        Text(
          'Konsistensi rutinitas mempengaruhi kesehatan kulit',
          style: TextStyle(fontFamily: 'Afacad', fontSize: 12, fontStyle: FontStyle.italic),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // Validasi format waktu HH:MM
  bool _isValidTimeFormat(String time) {
    final timeRegex = RegExp(r'^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$');
    return timeRegex.hasMatch(time);
  }

  // void _scheduleSkincareNotification(int index, String time, String skincareName) async {
  //   final timeParts = time.split(':');
  //   final hour = int.parse(timeParts[0]);
  //   final minute = int.parse(timeParts[1]);
  //
  //   final now = DateTime.now();
  //   final scheduledTime = DateTime(now.year, now.month, now.day, hour, minute);
  //
  //   // Use flutter_local_notifications package
  //   await FlutterLocalNotificationsPlugin().schedule(
  //     index,
  //     'Waktu Skincare',
  //     'Saatnya menggunakan $skincareName',
  //     scheduledTime,
  //     NotificationDetails(
  //       android: AndroidNotificationDetails(
  //         'skincare_channel',
  //         'Skincare Reminders',
  //         channelDescription: 'Reminders for skincare routine',
  //         importance: Importance.high,
  //         priority: Priority.high,
  //       ),
  //     ),
  //   );
  // }

}