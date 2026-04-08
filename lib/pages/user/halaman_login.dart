import 'dart:convert';

import 'package:apskina/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:apskina/services/api_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../wrappers/auth_wrapper.dart';

class HalamanLogin extends StatefulWidget {
  @override
  _HalamanLoginState createState() => _HalamanLoginState();
}

class _HalamanLoginState extends State<HalamanLogin> {
  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    // auth.logout();
  }

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login(AuthProvider auth) async {
    print('Memulai proses login...');
    print('Data yang akan dikirim:');
    print('Email: ${_emailController.text}');
    print('Password: ${_passwordController.text}');

    setState(() {
      _isLoading = true;
    });

    try{
      print('Mengirim request ke backend...');
      final response = await ApiService.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      final prefs = await SharedPreferences.getInstance();

      // simpan token
      await prefs.setString('token', response['token']);

      // simpan user (opsional tapi bagus)
      await prefs.setString('user', jsonEncode(response['user']));

      if (response['user']['favoriteDoctors'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('favoriteDoctors',
            jsonEncode(response['user']['favoriteDoctors']));
      }

      await auth.login(response['token'], response['user']);

      // Cukup pop sampai root dan biarkan AuthWrapper rebuild
      // Navigator.of(context).popUntil((route) => route.isFirst);

      print('Response dari backend: $response');
      //otw qna
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login berhasil!'))
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => AuthWrapper()),
            (route) => false,
      );
    }catch(e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login gagal: ${e.toString()}')),
      );
    }finally{
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 50),
              Image.asset('assets/images/logo.png', width: 200),
              SizedBox(height: 30),
              Text(
                'Welcome!',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF109E88),
                  fontFamily: 'HindSiliguri'
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Login to your account',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF109E88),
                  fontFamily: 'Afacad'
                ),
              ),
              SizedBox(height: 40),

              Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.8, // Lebar 80% dari layar
                  child: Column(
                    children: [
                      _buildConnectedInputField(Icons.email, 'Email', controller: _emailController),
                      SizedBox(height: 20),
                      _buildConnectedInputField(Icons.lock, 'Password', isPassword: true, controller: _passwordController),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 50),

              // Login Button
              Container(
                width: MediaQuery.of(context).size.width * 0.5, // Lebar 50% dari layar
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () => _login(auth),
                  child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                    'MASUK',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Afacad',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF109E88),
                    minimumSize: Size(double.infinity, 50), // Tinggi tetap 50
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Register Text
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/register');
                },
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      color: Color(0xFF109E88),
                      fontSize: 16,
                      fontFamily: 'Afacad',
                    ),
                    children: [
                      TextSpan(text: 'Belum punya akun? '),
                      TextSpan(
                        text: 'Register disini',
                        style: TextStyle(
                          color: Color(0xFF109E88),
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Afacad',
                          decoration: TextDecoration.underline,
                          decorationColor: Color(0xFF109E88),
                          decorationThickness: 1.5,
                          height: 6, // Controls space between text and underline
                        ),
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectedInputField(IconData icon, String hintText, {bool isPassword = false, TextEditingController? controller}) {
    return Container(
      height: 50,
      child: Stack(
        children: [
          // Background container for the text field
          Positioned(
            left: 25, // Half of the circle width
            right: 0,
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(25),
                  bottomRight: Radius.circular(25),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),

          // Icon and Text Field
          Row(
            children: [
              // Icon Circle
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: Color(0xFF109E88),
                    size: 20,
                  ),
                ),
              ),

              // Text Field
              Expanded(
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                  ),
                  child: Padding(
                    padding: EdgeInsets.only(left: 15), // Adjust this value as needed
                    child: TextField(
                      controller: controller,
                      obscureText: isPassword,
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                        hintText: hintText,
                        hintStyle: TextStyle(color: Color(0xFF109E88), fontFamily: 'Afacad'),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 15),
                      ),
                      style: TextStyle(color: Color(0xFF109E88), fontFamily: 'Afacad'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}