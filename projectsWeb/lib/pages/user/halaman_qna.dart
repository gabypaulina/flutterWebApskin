import 'dart:convert';

import 'package:apskina/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HalamanQna extends StatefulWidget {
  final bool isMandatory;

  const HalamanQna({Key? key, required this.isMandatory}) : super(key: key);

  @override
  _HalamanQnaState createState() => _HalamanQnaState();
}

class _HalamanQnaState extends State<HalamanQna> {
  int currentQuestionIndex = 0;
  int? selectedAnswerIndex;
  List<dynamic> questions = [];
  bool isLoading = true;

  List<Map<String, dynamic>> userResponses = [];
  Map<int, int> allSelectedAnswers = {};

  @override
  void initState() {
    super.initState();
    if (widget.isMandatory) {
      _loadQuestions();
    } else {
      // Jika QnA tidak mandatory, arahkan ke home
      Future.microtask(() {
        Navigator.pushReplacementNamed(context, '/home');
      });
    }
  }

  Future<void> _loadQuestions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        _redirectToLoginWithMessage('Silakan login terlebih dahulu');
        return;
      }

      setState(() => isLoading = true);

      final loadedQuestions = await ApiService.getQuestions(token);

      if (loadedQuestions.isEmpty) {
        throw Exception('Tidak ada pertanyaan tersedia');
      }

      setState(() {
        questions = loadedQuestions;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);

      String errorMessage = 'Gagal memuat pertanyaan';
      if (e.toString().contains('Sesi telah berakhir')) {
        errorMessage = 'Sesi telah berakhir, silakan login kembali';
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('token');
        _redirectToLoginWithMessage(errorMessage);
        return;
      } else if (e.toString().contains('koneksi') || e.toString().contains('timeout')) {
        errorMessage = 'Masalah koneksi: ${e.toString()}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage))
      );
    }
  }

  void _redirectToLogin() {
    Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
            (route) => false
    );
  }

  void _redirectToLoginWithMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message))
    );
    _redirectToLogin();
  }

  void _handleAnswerSelection(int index) {
    final currentQuestion = questions[currentQuestionIndex];

    setState(() {
      selectedAnswerIndex = index;
      allSelectedAnswers[currentQuestionIndex] = index;

      // Dapatkan path gambar untuk pertanyaan dan jawaban
      final questionImage = currentQuestion['image'];
      final answerImage = currentQuestion['answers'][index]['content'];
      final answerType = currentQuestion['answers'][index]['type'];

      // Update response dengan menyimpan informasi gambar
      userResponses.removeWhere((r) => r['questionId'] == currentQuestion['id']);
      userResponses.add({
        'questionId': currentQuestion['id'],
        'answerIndex': index,
        'questionText': currentQuestion['question'],
        'questionImage': questionImage, // Simpan gambar pertanyaan
        'answerText': currentQuestion['answers'][index]['text'] ??
            currentQuestion['answers'][index]['content'],
        'answerImage': answerType == 'image' ? answerImage : null, // Simpan gambar jawaban jika ada
        'answerType': answerType,
      });

      print('Jawaban tersimpan dengan gambar: ${userResponses.last}');
    });
  }

  Future<void> _submitAnswers() async {
    try {
      setState(() => isLoading = true);

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final userJson = prefs.getString('user');

      if (token == null) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      // Validasi responses
      if (allSelectedAnswers.length != questions.length) {
        throw Exception('Harap jawab semua pertanyaan');
      }

      // submit ke backend
      await ApiService.submitAnswers(token, userResponses);

      // update status
      if (userJson != null) {
        final userData = jsonDecode(userJson) as Map<String, dynamic>;
        final newUserData = {
          ...userData,
          'hasCompletedQna': true, // Pastikan diupdate
        };
        await prefs.setString('user', jsonEncode(newUserData));
      }

      // 4. Navigasi ke home
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/home',
            (route) => false,
      );
    }catch(e){
      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan: ${e.toString()}'),
          duration: Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Coba Lagi',
            onPressed: _submitAnswers,
          ),
        ),
      );
    }
  }

  void _goToNextQuestion() {
    if (selectedAnswerIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Harap pilih jawaban terlebih dahulu')),
      );
      return;
    }

    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        selectedAnswerIndex = allSelectedAnswers[currentQuestionIndex];
      });
    } else {
      _submitAnswers();
    }
  }

  Widget _buildAnswerOption(int answerIndex) {
    try {
      // Safely get current question and answers
      final currentQuestion = questions[currentQuestionIndex];
      final answers = currentQuestion['answers'] ?? []; // Handle both field names
      final answer = answers[answerIndex];

      // Handle null values safely
      final isTextAnswer = (answer['type'] as String? ?? 'text') == 'text';
      final isSelected = allSelectedAnswers[currentQuestionIndex] == answerIndex;
      final content = answer['content']?.toString() ?? '';
      final answerText = answer['text']?.toString() ?? '';

      // Split text for formatting
      final textParts = answerText.split(':');
      final mainText = textParts[0].trim().toUpperCase();
      final descriptionText = textParts.length > 1 ? textParts[1].trim() : '';

      return GestureDetector(
        onTap: () => _handleAnswerSelection(answerIndex),
        child: Container(
          width: isTextAnswer ? double.infinity : null,
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: isTextAnswer ? const EdgeInsets.symmetric(vertical: 12) : null,
          decoration: BoxDecoration(
            color: isTextAnswer && isSelected ? const Color(0xFF109E88) : Colors.white,
            border: isSelected || isTextAnswer
                ? Border.all(
              color: const Color(0xFF109E88),
              width: isTextAnswer ? 1.0 : 2.0,
            )
                : null,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected && !isTextAnswer
                ? [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3),
              )
            ]
                : null,
          ),
          child: isTextAnswer
              ? Text(
            content.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Afacad',
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: isSelected ? Colors.white : const Color(0xFF109E88),
            ),
          )
              : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (answer['content'] != null)
                Image.asset(
                  'assets/images/${answer['content']}',
                  width: 80,
                  height: 80,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    print('GAGAL LOAD: assets/images/${answer['content']}');
                    print(error);
                    return const Icon(Icons.error, size: 80, color: Colors.red);
                  },
                ),

              const SizedBox(height: 8),
              Column(
                children: [
                  Text(
                    mainText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Afacad',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF109E88),
                    ),
                  ),
                  if (descriptionText.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        descriptionText,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Afacad',
                          fontSize: 10,
                          color: Color(0xFF109E88),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      // Log error and return a placeholder widget
      debugPrint('Error building answer option: $e');
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.red),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'Invalid answer option',
          style: TextStyle(color: Colors.red),
        ),
      );
    }
  }

  Widget _buildAnswerGrid() {
    try {
      final currentQuestion = questions[currentQuestionIndex];
      final answers = currentQuestion['answers'] ?? [];
      final answerCount = answers.length;

      print('Building grid for $answerCount answers');

      if (answerCount == 2) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(child: _buildAnswerOption(0)),
            SizedBox(width: 16),
            Expanded(child: _buildAnswerOption(1)),
          ],
        );
      } else if (answerCount == 5) {
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(child: _buildAnswerOption(0)),
                SizedBox(width: 16),
                Expanded(child: _buildAnswerOption(1)),
                SizedBox(width: 16),
                Expanded(child: _buildAnswerOption(2)),
              ],
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(child: _buildAnswerOption(3)),
                SizedBox(width: 16),
                Expanded(child: _buildAnswerOption(4)),
              ],
            ),
          ],
        );
      } else if (answerCount == 6) {
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(child: _buildAnswerOption(0)),
                SizedBox(width: 16),
                Expanded(child: _buildAnswerOption(1)),
                SizedBox(width: 16),
                Expanded(child: _buildAnswerOption(2)),
              ],
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(child: _buildAnswerOption(3)),
                SizedBox(width: 16),
                Expanded(child: _buildAnswerOption(4)),
                SizedBox(width: 16),
                Expanded(child: _buildAnswerOption(5)),
              ],
            ),
          ],
        );
      } else if (answerCount == 4 && answers[0]['type'] == 'image') {
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(child: _buildAnswerOption(0)),
                SizedBox(width: 16),
                Expanded(child: _buildAnswerOption(1)),
              ],
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(child: _buildAnswerOption(2)),
                SizedBox(width: 16),
                Expanded(child: _buildAnswerOption(3)),
              ],
            ),
          ],
        );
      } else {
        return Column(
          children: List.generate(
            answerCount,
                (index) => _buildAnswerOption(index),
          ),
        );
      }
    }catch(e) {
      print('Error building answer grid: $e');
      return Center(
        child: Text(
          'Gagal memuat jawaban',
          style: TextStyle(color: Colors.red),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Memuat pertanyaan...'),
            ],
          ),
        ),
      );
    }

    if (questions.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 50, color: Colors.red),
              SizedBox(height: 20),
              Text('Tidak ada pertanyaan tersedia'),
              TextButton(
                onPressed: _loadQuestions,
                child: Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    final isLastQuestion = currentQuestionIndex == questions.length - 1;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Center(
            child: Container(
              width: 400,
              height: 550,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              questions[currentQuestionIndex]['question'],
                              style: TextStyle(
                                fontFamily: 'Afacad',
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF109E88),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          SizedBox(height: 24),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: _buildAnswerGrid(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                '${currentQuestionIndex + 1} dari ${questions.length} pertanyaan',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: selectedAnswerIndex != null
          ? FloatingActionButton(
              backgroundColor: isLastQuestion ? Color(0xFF109E88) : Colors.white,
              onPressed: _goToNextQuestion,
              child: Icon(
                Icons.arrow_forward,
                color: isLastQuestion ? Colors.white : Color(0xFF109E88),
              ),
              shape: CircleBorder(
                side: BorderSide(
                  color: Color(0xFF109E88),
                  width: 2,
                ),
              ),
            )
          : null,
    );
  }
}