import 'package:flutter/material.dart';

class NavigasiBar extends StatelessWidget {
  final int currentIndex;
  final BuildContext context; // Add context parameter

  const NavigasiBar({
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
          '/home',
              (route) => false,
        );
        break;
      case 1:
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/reservasi',
              (route) => false,
        );
        break;
      case 2:
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/histori',
              (route) => false,
        );
        break;
      case 3:
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/treatment',
              (route) => false,
        );
        break;
      case 4:
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/profile',
              (route) => false,
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      onTap: _onItemTapped,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Beranda',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today),
          label: 'Reservasi',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.history),
          label: 'Histori',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.menu),
          label: 'Treatment',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Akun',
        ),
      ],
      selectedItemColor: const Color(0xFF109E88),
      unselectedItemColor: Colors.grey,
    );
  }
}