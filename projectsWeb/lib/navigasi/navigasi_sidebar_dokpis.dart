import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

class NavigationSidebarDokpis extends StatelessWidget {
  final int currentIndex;
  final BuildContext context; // Add context parameter

  const NavigationSidebarDokpis({
    Key? key,
    required this.currentIndex,
    required this.context, // Require context in constructor
  }) : super(key: key);

  void _onItemTapped(int index) {
    if (index == currentIndex) return; // Don't navigate if already on the page

    switch (index) {
      case 0:
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/dokter/dashboard',
              (route) => false,
        );
        break;
      case 1:
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/dokter/jadwal',
              (route) => false,
        );
        break;
      case 2:
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/dokter/laporan',
              (route) => false,
        );
        break;
      case 3:
       _logout();
        break;
    }
  }

  // Fungsi logout
  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Konfirmasi Logout',
            style: TextStyle(
              fontFamily: 'Afacad',
              color: Color(0xFF109E88),
            ),
          ),
          content: Text(
            'Apakah Anda yakin ingin logout?',
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
              onPressed: () async {
                Navigator.of(context).pop();

                try {
                  // Gunakan AuthProvider untuk logout
                  final auth = Provider.of<AuthProvider>(context, listen: false);
                  await auth.logout();

                  // Navigate to login and clear all routes
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                        (route) => false,
                  );

                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Logout berhasil'),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal logout: ${e.toString()}')),
                  );
                }
              },
              child: Text(
                'Logout',
                style: TextStyle(
                  fontFamily: 'Afacad',
                  color: Colors.red,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20.0, top: 20.0, bottom: 20.0),
      child: Container(
        width: 250,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Navigation Items
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Image.asset('assets/images/logo.png', width: 150),
                  ),
                  _buildNavItem(Icons.dashboard, 'Dashboard', 0),
                  _buildNavItem(Icons.article, 'Jadwal', 1),
                  _buildNavItem(Icons.ad_units, 'Laporan', 2),
                  _buildNavItem(Icons.logout, 'Logout', 3),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String title, int index) {
    return Container(
      width: 200, // Fixed width for the outline
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        border: currentIndex == index
            ? Border.all(
          color: const Color(0xFF109E88),
          width: 1,
        )
            : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF109E88)),
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Afacad',
            fontSize: 20,
            color: Color(0xFF109E88),
          ),
        ),
        onTap: () => _onItemTapped(index),
      ),
    );
  }
}