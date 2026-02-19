import 'dart:convert';
import 'package:apskina/navigasi/navigasi_sidebar_terapis.dart';
import 'package:flutter/material.dart';
import '../../navigasi/navigasi_sidebar_dokpis.dart';
import '../../services/api_service.dart';

class HasilTreatment extends StatefulWidget {
  const HasilTreatment({Key? key, required Map<String, String> appointmentData}) : super(key: key);

  @override
  _HasilTreatmentState createState() => _HasilTreatmentState();
}

class _HasilTreatmentState extends State<HasilTreatment> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationSidebarTerapis(
            currentIndex: 1,
            context: context,
          ),
          Expanded(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.only(left: 40.0, top: 16.0, right: 40.0),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF109E88),
                            width: 1,
                          ),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back),
                          color: const Color(0xFF109E88),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Text(
                        'Hasil Treatment',
                        style: TextStyle(
                          fontFamily: 'HindSiliguri',
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF109E88),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(left: 40.0, bottom: 16.0, top: 16.0, right: 40.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Form Section with left padding
                        Padding(
                            padding: const EdgeInsets.only(left: 60.0),
                            child: Container (
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFF109E88),
                                  width: 1,
                                ),
                              ),
                              padding: const EdgeInsets.all(50),
                              child : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Pasien : ',
                                            style: TextStyle(
                                              fontFamily: 'Afacad',
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF109E88),
                                            ),
                                          ),
                                          const SizedBox(width: 20),
                                          Text(
                                            'Michael David',
                                            style: TextStyle(
                                              fontFamily: 'Afacad',
                                              fontSize: 16,
                                              color: const Color(0xFF109E88),
                                            ),
                                          ),
                                        ],
                                      ),

                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            children: [
                                              Icon(
                                                Icons.calendar_today_outlined,
                                                color: const Color(0xFF109E88),
                                                size: 24,
                                              ),
                                              const SizedBox(width: 20),
                                              Text(
                                                '10 April 2025',
                                                style: TextStyle(
                                                  fontFamily: 'Afacad',
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: const Color(0xFF109E88),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(width: 40),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            children: [
                                              Icon(
                                                Icons.watch_later_outlined,
                                                color: const Color(0xFF109E88),
                                                size: 24,
                                              ),
                                              const SizedBox(width: 20),
                                              Text(
                                                '14:00',
                                                style: TextStyle(
                                                  fontFamily: 'Afacad',
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: const Color(0xFF109E88),
                                                ),
                                              ),
                                            ],
                                          )
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),

                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Treatment yang diambil : ',
                                        style: TextStyle(
                                          fontFamily: 'Afacad',
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF109E88),
                                        ),
                                      ),
                                      const SizedBox(width: 20),
                                      Text(
                                        'Laser Blackdoll',
                                        style: TextStyle(
                                          fontFamily: 'Afacad',
                                          fontSize: 16,
                                          color: const Color(0xFF109E88),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),

                                  Text(
                                    'Hasil Treatment : ',
                                    style: TextStyle(
                                      fontFamily: 'Afacad',
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF109E88),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.',
                                    style: TextStyle(
                                      fontFamily: 'Afacad',
                                      fontSize: 16,
                                      color: const Color(0xFF109E88),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                ],
                              ),
                            )
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),

          ),
        ],
      ),
    );
  }
}