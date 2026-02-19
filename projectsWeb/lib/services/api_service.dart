import 'dart:convert';
// import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import '../pages/admin/menu_iklan.dart'; // Untuk SocketException

class ApiService {
  static const String baseUrl = 'http://192.168.0.4:3000/api';
  static const String basedUrl = 'http://192.168.0.4:3000';

  // Helper method for making POST requests
  static Future<Map<String, dynamic>> postRequest(
      String endpoint,
      Map<String, dynamic> body,
      ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      final responseBody = jsonDecode(utf8.decode(response.bodyBytes)); // Use bodyBytes for better encoding handling

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return responseBody;
      } else {
        throw Exception(responseBody['message'] ??
            'Server error: ${response.statusCode}');
      }
    } on FormatException catch (e) {
      throw Exception('Invalid server response format. Please check the API endpoint.');
    } catch (e) {
      throw Exception('Network error: ${e.toString()}');
    }
  }

  // GET PATIENT HISTORY (COMPLETED APPOINTMENTS)
  static Future<List<dynamic>> getPatientHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/reservasi/history-completed'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseBody['data'] ?? [];
      } else {
        throw Exception(responseBody['message'] ?? 'Failed to get patient history');
      }
    } catch (e) {
      print('Error getting patient history: $e');
      throw Exception('Error getting patient history: ${e.toString()}');
    }
  }

  // GET PATIENT HISTORY (COMPLETED APPOINTMENTS)
  static Future<List<dynamic>> getPatientHistoryy() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/reservasi/history-completedd'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseBody['data'] ?? [];
      } else {
        throw Exception(responseBody['message'] ?? 'Failed to get patient history');
      }
    } catch (e) {
      print('Error getting patient history: $e');
      throw Exception('Error getting patient history: ${e.toString()}');
    }
  }

  // LOGIN
  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    print(response.statusCode);
    print(response.body);

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);

      // Simpan data dokter jika role adalah dokter
      if (responseData['user']['role'] == 'dokter') {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('doctorId', responseData['doctorId'] ?? '');
        await prefs.setString('doctorName', responseData['doctorName'] ?? '');
        await prefs.setString('spesialis', responseData['spesialis'] ?? '');
      }

      return responseData;    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Login gagal');
    }
  }

  // REGISTER
  static Future<Map<String, dynamic>> register(
      String nama,
      String email,
      String tanggalLahir,
      String noHandphone,
      String alamat,
      String password,
      String konfirmPassword,
      ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nama': nama,
        'email': email,
        'tanggalLahir': tanggalLahir,
        'noHandphone': noHandphone,
        'alamat': alamat,
        'password': password,
        'konfirmPassword': konfirmPassword,
      }),
    );

    final responseBody = jsonDecode(response.body);
    print(response.statusCode);
    print(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return responseBody;
    } else {
      throw Exception(responseBody['message'] ?? 'Register gagal');
    }
  }

  // GET TOTAL USERS
  static Future<int> getTotalUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/total'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseBody['total'] ?? 0;
      } else {
        throw Exception(responseBody['message'] ?? 'Failed to get total users');
      }
    } catch (e) {
      print('Error getting total users: $e');
      throw Exception('Error getting total users: ${e.toString()}');
    }
  }

  // GET TOTAL TRANSACTIONS (Paid Reservations)
  static Future<int> getTotalTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/reservations/total-transactions'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseBody['total'] ?? 0;
      } else {
        throw Exception(responseBody['message'] ?? 'Failed to get total transactions');
      }
    } catch (e) {
      print('Error getting total transactions: $e');
      throw Exception('Error getting total transactions: ${e.toString()}');
    }
  }

  // GET TOTAL NON-MEDIS RESERVATIONS
  static Future<int> getTotalNonMedisReservations() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/reservasi/total-nonmedis'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseBody['total'] ?? 0;
      } else {
        throw Exception(responseBody['message'] ?? 'Failed to get total non-medis reservations');
      }
    } catch (e) {
      print('Error getting total non-medis reservations: $e');
      throw Exception('Error getting total non-medis reservations: ${e.toString()}');
    }
  }

// GET TODAY'S NON-MEDIS APPOINTMENTS
  static Future<List<dynamic>> getTodayNonMedisAppointments() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/reservasi/today-nonmedis'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseBody['data'] ?? [];
      } else {
        throw Exception(responseBody['message'] ?? 'Failed to get today non-medis appointments');
      }
    } catch (e) {
      print('Error getting today non-medis appointments: $e');
      throw Exception('Error getting today non-medis appointments: ${e.toString()}');
    }
  }

  // UPDATE PROFIL
  static Future<Map<String, dynamic>> updateProfile({
    required String nama,
    required String email,
    required String alamat,
    required String tanggalLahir,
    required String noHandphone,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.put(
      Uri.parse('$baseUrl/user/update'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'nama': nama,
        'email': email,
        'alamat': alamat,
        'tanggalLahir': tanggalLahir,
        'noHandphone': noHandphone,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update profile: ${response.body}');
    }
  }

  // SIMPAN SKINCARE
  static Future<Map<String, dynamic>> saveSkincareProducts(List<Map<String, dynamic>> products) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/addSkincare'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'products': products,
        }),
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseBody;
      } else {
        throw Exception(responseBody['message'] ?? 'Failed to save skincare: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      throw Exception('Network error: ${e.message}');
    } on FormatException catch (e) {
      throw Exception('Invalid server response: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: ${e.toString()}');
    }
  }

  // GET USER SKINCARE
  static Future<List<dynamic>> getUserSkincare() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/skincare'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseBody['data'] ?? [];
      } else {
        throw Exception(responseBody['message'] ?? 'Failed to get user skincare');
      }
    } catch (e) {
      print('Error getting user skincare: $e');
      throw Exception('Error getting user skincare: ${e.toString()}');
    }
  }

  // ALL SKINCARE
  static Future<List<dynamic>> getSkincareProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('$baseUrl/skincare'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data']['products'] ?? [];
    } else {
      throw Exception('Failed to load skincare: ${response.body}');
    }
  }

  // FAVORIT DOKTER
  static Future<Map<String, dynamic>> toggleFavoriteDoctor(
      String doctorId,
      String doctorName,
      bool isFavorite
      ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/favoriteDoctor'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'doctorId': doctorId,
          'doctorName': doctorName,
          'isFavorite': isFavorite,
        }),
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseBody;
      } else {
        throw Exception(responseBody['message'] ?? 'Failed to update favorite');
      }
    } catch (e) {
      throw Exception('Error toggling favorite: ${e.toString()}');
    }
  }

  // ALL DOKTER
  static Future<List<dynamic>> getFavoriteDoctors() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/favoriteDoctors'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseBody['favoriteDoctors'] ?? [];
      } else {
        throw Exception(responseBody['message'] ?? 'Failed to get favorites');
      }
    } catch (e) {
      throw Exception('Error getting favorites: ${e.toString()}');
    }
  }

  // BUAT RESERVASI
  static Future<Map<String, dynamic>> createReservation({
    required String type,
    String? treatment,
    String? doctor,
    String? pic,
    required String reservationTime,
    required DateTime reservationDate,
    String? notes,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final formattedDate =
        '${reservationDate.day.toString().padLeft(2, '0')}/'
        '${reservationDate.month.toString().padLeft(2, '0')}/'
        '${reservationDate.year}';

    try {
      // Siapkan data yang akan dikirim
      Map<String, dynamic> requestData = {
        'tipe': type,
        'waktuReservasi': reservationTime,
        'tanggalReservasi': formattedDate,
      };

      // Tambahkan field sesuai tipe reservasi
      if (type == 'NON_MEDIS') {
        requestData['treatment'] = treatment;
        requestData['pic'] = pic ?? 'terapis';
        // Untuk NON_MEDIS, jangan kirim field dokter (backend akan auto set pic ke 'terapis')
      } else if (type == 'MEDIS' || type == 'KONSULTASI') {
        requestData['dokter'] = doctor;
        // Untuk MEDIS/KONSULTASI, kirim field dokter
      }

      // Tambahkan catatan tambahan jika ada
      if (notes != null && notes.isNotEmpty) {
        requestData['catatanTambahan'] = notes;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/reservasi'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestData),
      );

      print('Response status: ${response.statusCode}');  // Debug log
      print('Response body: ${response.body}');  // Debug log

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return responseBody;
      } else {
        throw Exception(responseBody['message'] ?? 'Failed to create reservation');
      }
    } on SocketException {
      throw Exception('No Internet connection');
    } on FormatException {
      throw Exception('Bad response format');
    } catch (e) {
      throw Exception('Failed to create reservation: ${e.toString()}');
    }
  }

  // ALL RESERVASI
  static Future<List<dynamic>> getUserReservations() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/reservasi'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseBody['data'] ?? [];
      } else {
        throw Exception(responseBody['message'] ?? 'Failed to get reservations');
      }
    } catch (e) {
      throw Exception('Error getting reservations: ${e.toString()}');
    }
  }

  // GET RESERVASI BY DOCTOR
  static Future<List<dynamic>> getDoctorReservations(String doctorId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/reservasi/doctor/$doctorId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseBody['data'] ?? [];
      } else {
        throw Exception(responseBody['message'] ?? 'Failed to get doctor reservations');
      }
    } catch (e) {
      throw Exception('Error getting doctor reservations: ${e.toString()}');
    }
  }

  // SLOT WAKTU
  static Future<List<String>> getAvailableTimeSlots(String tanggalReservasi) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/reservasi/waktuTersedia?tanggalReservasi=$tanggalReservasi'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return List<String>.from(responseBody['data']);
      } else {
        throw Exception(responseBody['message'] ?? 'Failed to get available time slots');
      }
    } catch (e) {
      throw Exception('Error getting available time slots: ${e.toString()}');
    }
  }

  // GET BOOKED TIMES FOR A SPECIFIC DATE AND TYPE
  static Future<List<String>> getBookedTimes(String tanggalReservasi, String type) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/reservasi/booked-times?tanggalReservasi=$tanggalReservasi&type=$type'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return List<String>.from(responseBody['data'] ?? []);
      } else {
        throw Exception(responseBody['message'] ?? 'Failed to get booked times');
      }
    } catch (e) {
      print('Error getting booked times: $e');
      throw Exception('Error getting booked times: ${e.toString()}');
    }
  }

  // UPDATE STATUS RESERVASI
  static Future<Map<String, dynamic>> updateReservationStatus({
    required String reservationId,
    required String status,
    String? hasilTreatment,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/reservasi/$reservationId/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'status': status,
          'hasilTreatment': hasilTreatment,
        }),
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseBody;
      } else {
        throw Exception(responseBody['message'] ?? 'Failed to update reservation status');
      }
    } catch (e) {
      print('Error updating reservation status: $e');
      throw Exception('Error updating reservation status: ${e.toString()}');
    }
  }



  // VERIFIKASI TOKEN
  static Future<bool> verifyToken(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/verify'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // QNA
  static Future<List<dynamic>> getQuestions(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/qna/questions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data;
        } else {
          throw Exception('Format data tidak valid - Diharapkan array');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Sesi telah berakhir, silakan login kembali');
      } else {
        throw Exception('Gagal memuat pertanyaan. Status: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('SocketException')) {
        throw Exception('Tidak ada koneksi internet');
      } else if (e.toString().contains('TimeoutException')) {
        throw Exception('Koneksi timeout');
      } else {
        throw Exception('Terjadi kesalahan: ${e.toString()}');
      }
    }
  }

  // JAWABAN QNA
  static Future<void> submitAnswers(
      String token,
      List<Map<String, dynamic>> responses
      ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/qna/submit'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'responses': responses.map((r) =>
          {
            'questionId': r['questionId'],
            'answerIndex': r['answerIndex'],
            'questionText': r['questionText'],
            'answerText': r['answerText'],
          }).toList(),
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true && responseData['hasCompletedQna'] == true) {
          return ;
        }
        return;
      }
      throw Exception('Failed to save answers');
    } catch (e) {
      print('Error submitting answers: $e'); // Debug 5
      rethrow;
    };
  }

  // GET QnA History
  static Future<Map<String, dynamic>> getQnaHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/qna/history'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final responseBody = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200) {
        return responseBody;
      } else {
        throw Exception(responseBody['message'] ?? 'Failed to get QnA history');
      }
    } catch (e) {
      throw Exception('Error getting QnA history: ${e.toString()}');
    }
  }

  // Get chat history
  static Future<List<dynamic>> getChatHistory(String reservationId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/chat/$reservationId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['messages'] ?? [];
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  // Send text message
  static Future<bool> sendTextMessage(Map<String, dynamic> messageData) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat/send'),
        headers: {
          'Authorization': 'Bearer $token',
        },
        body: json.encode(messageData),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Upload image message
  // static Future<Map<String, dynamic>> uploadImage( String reservationId, File imageFile) async {
  //   // try {
  //   //   final headers = await _getHeaders();
  //   //   var request = http.MultipartRequest(
  //   //     'POST',
  //   //     Uri.parse('$baseUrl/api/chat/upload-image'),
  //   //   );
  //   //
  //   //   // Add headers
  //   //   request.headers['Authorization'] = headers['Authorization']!;
  //   //
  //   //   // Add fields
  //   //   request.fields['reservationId'] = reservationId;
  //   //   request.fields['senderType'] = 'user';
  //   //   request.fields['timestamp'] = DateTime.now().toIso8601String();
  //   //
  //   //   // Add image file
  //   //   request.files.add(await http.MultipartFile.fromPath(
  //   //     'image',
  //   //     imageFile.path,
  //   //   ));
  //   //
  //   //   final response = await request.send();
  //   //   final responseData = await response.stream.bytesToString();
  //   //
  //   //   if (response.statusCode == 200) {
  //   //     return json.decode(responseData);
  //   //   } else {
  //   //     return {'error': 'Failed to upload image'};
  //   //   }
  //   // } catch (e) {
  //   //   return {'error': 'Error: $e'};
  //   // }
  // }

  // CREATE ARTICLE
  static Future<Map<String, dynamic>> createArticle({
    required String judul,
    required String sumber,
    required String isi,
    required dynamic image, // Bisa File (mobile) atau Uint8List (web)
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/artikel'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['judul'] = judul;
      request.fields['sumber'] = sumber;
      request.fields['isi'] = isi;

      // Handle upload gambar
      if (kIsWeb) {
        if (image is Uint8List) {
          // Gunakan filename dengan extension yang jelas
          request.files.add(http.MultipartFile.fromBytes(
            'gambar',
            image,
            filename: 'image_${DateTime.now().millisecondsSinceEpoch}.jpg', // Force .jpg extension
          ));
        } else if (image is Map<String, dynamic>) {
          final String filename = image['filename'] ?? 'image.jpg';
          request.files.add(http.MultipartFile.fromBytes(
            'gambar',
            image['bytes'],
            filename: filename,
          ));
        }
      } else {
        File file = image;
        var stream = http.ByteStream(file.openRead());
        var length = await file.length();

        request.files.add(http.MultipartFile(
          'gambar',
          stream,
          length,
          filename: file.path.split('/').last,
        ));
      }

      var response = await request.send();
      var responseString = await response.stream.bytesToString();

      if (response.statusCode == 201) {
        return jsonDecode(responseString);
      } else {
        throw Exception('Upload gagal: ${response.statusCode} - $responseString');
      }
    } catch (e) {
      throw Exception('Error: ${e.toString()}');
    }
  }

  // Helper function untuk web
  // static Future<Uint8List> _getWebFileBytes(dynamic webFile) async {
  //   if (webFile is html.File) {
  //     final reader = html.FileReader();
  //     reader.readAsArrayBuffer(webFile);
  //     await reader.onLoad.first;
  //     return reader.result as Uint8List;
  //   } else if (webFile is Uint8List) {
  //     return webFile;
  //   } else if (webFile is String && webFile.startsWith('data:image')) {
  //     // Handle data URL
  //     return base64Decode(webFile.split(',').last);
  //   }
  //   throw Exception('Format file tidak didukung');
  // }

  // GET ALL ARTICLES
  static Future<List<dynamic>> getArticles() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/artikel'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final responseBody = jsonDecode(response.body);
      print('Get articles response: ${response.statusCode}'); // Debug
      print('Get articles data: ${responseBody}'); // Debug

      if (response.statusCode == 200) {
        return responseBody['data'] ?? [];
      } else {
        throw Exception(responseBody['message'] ?? 'Failed to get articles');
      }
    } catch (e) {
      print('Error getting articles: $e'); // Debug
      throw Exception('Error getting articles: ${e.toString()}');
    }
  }

  // GET SINGLE ARTICLE
  static Future<Map<String, dynamic>> getArticle(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/artikel/$id'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseBody['data'];
      } else {
        throw Exception(responseBody['message'] ?? 'Failed to get article');
      }
    } catch (e) {
      throw Exception('Error getting article: ${e.toString()}');
    }
  }

  // UPDATE ARTICLE
  static Future<Map<String, dynamic>> updateArticle({
    required String articleId,
    required String judul,
    required String sumber,
    required String isi,
    dynamic image, // Bisa null jika tidak update gambar
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/artikel/$articleId'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['judul'] = judul;
      request.fields['sumber'] = sumber;
      request.fields['isi'] = isi;

      // Jika ada gambar baru, tambahkan ke request
      if (image != null) {
        if (kIsWeb) {
          Uint8List bytes;
          String filename;

          if (image is Uint8List) {
            bytes = image;
            filename = 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
          }else if (image is Map<String, dynamic>) {
            bytes = image['bytes'] as Uint8List;
            filename = image['filename'] ?? 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
          }else{
            throw Exception('Format gambar tidak dikenali');
          }

          var multipartFile = http.MultipartFile.fromBytes(
              'gambar',
              bytes,
            filename: filename
          );
          request.files.add(multipartFile);
        } else {
          File file = image;
          var stream = http.ByteStream(file.openRead());
          var length = await file.length();

          var multipartFile = http.MultipartFile(
            'gambar', // NAMA FIELD HARUS SAMA DENGAN BACKEND
            stream,
            length,
            filename: file.path.split('/').last,
          );
          request.files.add(multipartFile);
        }
      }

      var response = await request.send();
      var responseString = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return jsonDecode(responseString);
      } else {
        throw Exception('Update gagal: ${response.statusCode} - $responseString');
      }
    } catch (e) {
      throw Exception('Error: ${e.toString()}');
    }
  }

  // DELETE ARTICLE
  static Future<Map<String, dynamic>> deleteArticle(String articleId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/artikel/$articleId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final responseBody = jsonDecode(response.body);

      print('Delete response: ${response.statusCode}');
      print('Delete response body: $responseBody');

      if (response.statusCode == 200) {
        return responseBody;
      } else {
        throw Exception(responseBody['message'] ?? 'Failed to delete article');
      }
    } catch (e) {
      print('Delete error: $e');
      throw Exception('Error deleting article: ${e.toString()}');
    }
  }

  // CREATE TREATMENT
  static Future<void> createTreatment({
    required String judul,
    required String pic,
    required String isi,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/treatment'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization' : 'Bearer $token',
        },
        body: jsonEncode({
          'judul' : judul,
          'pic' : pic,
          'isi' : isi,
        })
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Upload gagal: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: ${e.toString()}');
    }
  }

  // GET ALL TREATMENTS
  static Future<List<dynamic>> getTreatments() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/treatment'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final responseBody = jsonDecode(response.body);
      print('Get treatments response: ${response.statusCode}'); // Debug
      print('Get treatments data: ${responseBody}'); // Debug

      if (response.statusCode == 200) {
        return responseBody['data'] ?? [];
      } else {
        throw Exception(responseBody['message'] ?? 'Failed to get treatments');
      }
    } catch (e) {
      print('Error getting treatments: $e'); // Debug
      throw Exception('Error getting treatments: ${e.toString()}');
    }
  }

  // GET SINGLE TREATMENT
  static Future<Map<String, dynamic>> getTreatment(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/treatment/$id'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseBody['data'];
      } else {
        throw Exception(responseBody['message'] ?? 'Failed to get treatment');
      }
    } catch (e) {
      throw Exception('Error getting treatment: ${e.toString()}');
    }
  }

  // UPDATE TREATMENT
  static Future<void> updateTreatment({
    required String treatmentId,
    required String judul,
    required String pic,
    required String isi,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.put(
          Uri.parse('$baseUrl/treatment/$treatmentId'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization' : 'Bearer $token',
          },
          body: jsonEncode({
            'judul' : judul,
            'pic' : pic,
            'isi' : isi,
          })
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Update gagal: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: ${e.toString()}');
    }
  }

  // DELETE TREATMENT
  static Future<Map<String, dynamic>> deleteTreatment(String treatmentId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/treatment/$treatmentId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final responseBody = jsonDecode(response.body);

      print('Delete response: ${response.statusCode}');
      print('Delete response body: $responseBody');

      if (response.statusCode == 200) {
        return responseBody;
      } else {
        throw Exception(responseBody['message'] ?? 'Failed to delete treatment');
      }
    } catch (e) {
      print('Delete error: $e');
      throw Exception('Error deleting treatment: ${e.toString()}');
    }
  }

  // GET BANNER - Perbaiki method ini
  static Future<List<Map<String, dynamic>>> getBanners() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/banners'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final responseBody = jsonDecode(response.body);
      print('Get banners response: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Pastikan mengembalikan List<Map<String, dynamic>>
        return List<Map<String, dynamic>>.from(responseBody['data'] ?? []);
      } else {
        throw Exception(responseBody['message'] ?? 'Failed to get banners');
      }
    } catch (e) {
      print('Error getting banners: $e');
      throw Exception('Error getting banners: ${e.toString()}');
    }
  }

  // ADD BANNER
  static Future<Map<String, dynamic>> uploadBanner(File imageFile) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/banner/upload'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      // Tambahkan file gambar
      var stream = http.ByteStream(imageFile.openRead());
      var length = await imageFile.length();

      var multipartFile = http.MultipartFile(
        'banner',
        stream,
        length,
        filename: imageFile.path.split('/').last,
      );

      request.files.add(multipartFile);

      var response = await request.send();
      var responseString = await response.stream.bytesToString();
      var responseJson = jsonDecode(responseString);

      print('Upload banner response: ${response.statusCode}');
      print('Upload banner response body: $responseString');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return responseJson;
      } else {
        throw Exception(responseJson['message'] ?? 'Upload gagal: ${response.statusCode}');
      }
    } catch (e) {
      print('Error uploading banner: $e');
      throw Exception('Error uploading banner: ${e.toString()}');
    }
  }

  // Upload multiple banners untuk web
  static Future<Map<String, dynamic>> uploadBannersWeb(List<Uint8List> imageBytesList, List<String> fileNames) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/banner/upload-multiple'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      // Tambahkan semua file gambar
      for (int i = 0; i < imageBytesList.length; i++) {
        var multipartFile = http.MultipartFile.fromBytes(
          'banners',
          imageBytesList[i],
          filename: fileNames[i],
        );
        request.files.add(multipartFile);
      }

      var response = await request.send();
      var responseString = await response.stream.bytesToString();
      var responseJson = jsonDecode(responseString);

      print('Upload multiple banners response: ${response.statusCode}');
      print('Upload multiple banners response body: $responseString');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return responseJson;
      } else {
        throw Exception(responseJson['message'] ?? 'Upload gagal: ${response.statusCode}');
      }
    } catch (e) {
      print('Error uploading multiple banners: $e');
      throw Exception('Error uploading multiple banners: ${e.toString()}');
    }
  }

// Upload multiple banners untuk mobile
  static Future<Map<String, dynamic>> uploadBanners(List<File> imageFiles) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/banner/upload-multiple'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      // Tambahkan semua file gambar
      for (var imageFile in imageFiles) {
        var stream = http.ByteStream(imageFile.openRead());
        var length = await imageFile.length();

        var multipartFile = http.MultipartFile(
          'banners',
          stream,
          length,
          filename: imageFile.path.split('/').last,
        );
        request.files.add(multipartFile);
      }

      var response = await request.send();
      var responseString = await response.stream.bytesToString();
      var responseJson = jsonDecode(responseString);

      print('Upload multiple banners response: ${response.statusCode}');
      print('Upload multiple banners response body: $responseString');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return responseJson;
      } else {
        throw Exception(responseJson['message'] ?? 'Upload gagal: ${response.statusCode}');
      }
    } catch (e) {
      print('Error uploading multiple banners: $e');
      throw Exception('Error uploading multiple banners: ${e.toString()}');
    }
  }

  // DELETE BANNER
  static Future<Map<String, dynamic>> deleteBanner(String bannerId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/banner/$bannerId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseBody;
      } else {
        throw Exception(responseBody['message'] ?? 'Failed to delete banner');
      }
    } catch (e) {
      throw Exception('Error deleting banner: ${e.toString()}');
    }
  }

  // GET semua dokter
  static Future<List<dynamic>> getDokter() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/dokter'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseBody['data'] ?? [];
      } else {
        throw Exception(responseBody['message'] ?? 'Failed to get doctors');
      }
    } catch (e) {
      throw Exception('Error getting doctors: ${e.toString()}');
    }
  }

  // GET waktu tersedia berdasarkan dokter dan tanggal
  static Future<List<String>> getAvailableTimeSlotsByDoctor(
      String doctorId,
      String tanggalReservasi
      ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/reservasi/waktuTersedia?doctorId=$doctorId&tanggalReservasi=$tanggalReservasi'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return List<String>.from(responseBody['data']);
      } else {
        throw Exception(responseBody['message'] ?? 'Failed to get available time slots');
      }
    } catch (e) {
      throw Exception('Error getting available time slots: ${e.toString()}');
    }
  }

// POST tambah dokter baru
  static Future<Map<String, dynamic>> createDokter({
    required String nama,
    required String spesialis,
    required List<Map<String, dynamic>> jadwal,
    dynamic foto, // Bisa File (mobile) atau Uint8List (web)
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/dokter'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['nama'] = nama;
      request.fields['spesialis'] = spesialis;
      request.fields['jadwal'] = jsonEncode(jadwal);

      // Handle upload gambar
      if (foto != null) {
        if (kIsWeb) {
          Uint8List bytes;
          String filename;

          if (foto is Uint8List) {
            bytes = foto;
            filename = 'dokter_${DateTime.now().millisecondsSinceEpoch}.jpg';
          } else if (foto is Map<String, dynamic>) {
            bytes = foto['bytes'] as Uint8List;
            filename = foto['filename'] ?? 'dokter_${DateTime.now().millisecondsSinceEpoch}.jpg';
          } else {
            throw Exception('Format gambar tidak dikenali');
          }

          request.files.add(http.MultipartFile.fromBytes(
            'foto',
            bytes,
            filename: filename,
          ));
        } else {
          File file = foto;
          var stream = http.ByteStream(file.openRead());
          var length = await file.length();

          request.files.add(http.MultipartFile(
            'foto',
            stream,
            length,
            filename: file.path.split('/').last,
          ));
        }
      }

      var response = await request.send();
      var responseString = await response.stream.bytesToString();

      if (response.statusCode == 201) {
        return jsonDecode(responseString);
      } else {
        throw Exception('Upload gagal: ${response.statusCode} - $responseString');
      }
    } catch (e) {
      throw Exception('Error: ${e.toString()}');
    }
  }

// PUT update dokter
  static Future<Map<String, dynamic>> updateDokter({
    required String dokterId,
    required String nama,
    required String spesialis,
    required List<Map<String, dynamic>> jadwal,
    dynamic foto, // Bisa null jika tidak update gambar
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/dokter/$dokterId'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['nama'] = nama;
      request.fields['spesialis'] = spesialis;
      request.fields['jadwal'] = jsonEncode(jadwal);

      // Jika ada gambar baru, tambahkan ke request
      if (foto != null) {
        if (kIsWeb) {
          Uint8List bytes;
          String filename;

          if (foto is Uint8List) {
            bytes = foto;
            filename = 'dokter_${DateTime.now().millisecondsSinceEpoch}.jpg';
          } else if (foto is Map<String, dynamic>) {
            bytes = foto['bytes'] as Uint8List;
            filename = foto['filename'] ?? 'dokter_${DateTime.now().millisecondsSinceEpoch}.jpg';
          } else {
            throw Exception('Format gambar tidak dikenali');
          }

          request.files.add(http.MultipartFile.fromBytes(
            'foto',
            bytes,
            filename: filename,
          ));
        } else {
          File file = foto;
          var stream = http.ByteStream(file.openRead());
          var length = await file.length();

          request.files.add(http.MultipartFile(
            'foto',
            stream,
            length,
            filename: file.path.split('/').last,
          ));
        }
      }

      var response = await request.send();
      var responseString = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return jsonDecode(responseString);
      } else {
        throw Exception('Update gagal: ${response.statusCode} - $responseString');
      }
    } catch (e) {
      throw Exception('Error: ${e.toString()}');
    }
  }

// DELETE dokter
  static Future<Map<String, dynamic>> deleteDokter(String dokterId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/dokter/$dokterId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseBody;
      } else {
        throw Exception(responseBody['message'] ?? 'Failed to delete doctor');
      }
    } catch (e) {
      throw Exception('Error deleting doctor: ${e.toString()}');
    }
  }

  // Di ApiService class, update createPayment method
  static Future<Map<String, dynamic>> createPayment({
    required String reservationId,
    required int amount,
    required String paymentMethod,
    required String customerName,
    required String customerEmail,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.post(
      Uri.parse('$baseUrl/create-payment'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'reservationId': reservationId,
        'amount': amount,
        'paymentMethod': paymentMethod,
        'customerName': customerName,
        'customerEmail': customerEmail,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create payment: ${response.body}');
    }
  }

  // Di ApiService class, tambahkan method untuk cek status pembayaran
  static Future<Map<String, dynamic>> checkPaymentStatus(String paymentId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('$baseUrl/payment-status/$paymentId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to check payment status: ${response.body}');
    }
  }

  // GET TODAY'S APPOINTMENTS WITH FILTERED PAYMENT STATUS
  static Future<List<dynamic>> getTodayFilteredAppointments() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/reservasi/today-filtered'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseBody['data'] ?? [];
      } else {
        throw Exception(responseBody['message'] ?? 'Failed to get today filtered appointments');
      }
    } catch (e) {
      print('Error getting today filtered appointments: $e');
      throw Exception('Error getting today filtered appointments: ${e.toString()}');
    }
  }

  // GET NOTIFIKASI USER
  static Future<List<dynamic>> getUserNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/notifications'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseBody['data'] ?? [];
      } else {
        throw Exception(responseBody['message'] ?? 'Failed to get notifications');
      }
    } catch (e) {
      print('Error getting notifications: $e');
      throw Exception('Error getting notifications: ${e.toString()}');
    }
  }

// UPDATE FCM TOKEN
  static Future<void> updateFCMToken(String fcmToken) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      await http.post(
        Uri.parse('$baseUrl/user/fcm-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'fcmToken': fcmToken}),
      );
    } catch (e) {
      print('Error updating FCM token: $e');
    }
  }

// SEND NOTIFICATION (ADMIN)
  static Future<void> sendNotificationToUsers({
    required String title,
    required String body,
    required String type,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/admin/send-notification'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'title': title,
          'body': body,
          'type': type,
        }),
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode != 200) {
        throw Exception(responseBody['message'] ?? 'Failed to send notification');
      }
    } catch (e) {
      print('Error sending notification: $e');
      throw Exception('Error sending notification: ${e.toString()}');
    }
  }


}

