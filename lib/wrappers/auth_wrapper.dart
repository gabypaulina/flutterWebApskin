import 'package:apskina/pages/dokter/menu_dashboard.dart';
import 'package:apskina/pages/terapis/menu_dashboard.dart';
import 'package:apskina/pages/user/halaman_home.dart';
import 'package:apskina/pages/user/halaman_login.dart';
import 'package:apskina/pages/user/halaman_qna.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../pages/admin/menu_dashboard.dart';
import '../providers/auth_provider.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.loadUser();
    setState(() {
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if(_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(),)
      );
    }

    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        print('AuthWrapper rebuild - isAuthenticated: ${auth.isAuthenticated}');
        if(!auth.isAuthenticated){
          return HalamanLogin();
        }else if (auth.isAdmin){
          return const MenuDashboard();
        }else if (auth.isDokter){
          return const MenuDashboardDok();
        }else if (auth.isTerapis){
          return const MenuDashboardTerapis();
        }else {
          return auth.hasCompletedQna ? HalamanHome() : const HalamanQna(isMandatory: true);
        }
      }
    );
  }
}