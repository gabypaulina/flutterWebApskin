import 'package:flutter/material.dart';
import 'halaman_login.dart';

class HalamanStart extends StatefulWidget {
  @override
  _HalamanStartState createState() => _HalamanStartState();
}

class _HalamanStartState extends State<HalamanStart> {
  @override
  void initState() {
    super.initState();
    // Set timer untuk pindah ke halaman login setelah 10 detik
    Future.delayed(Duration(milliseconds: 10000), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HalamanLogin()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo di tengah layar
            Image.asset('assets/images/logo.png', width: 200),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}