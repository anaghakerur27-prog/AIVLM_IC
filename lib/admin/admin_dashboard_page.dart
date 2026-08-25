import 'package:flutter/material.dart';

import 'admin_auth_service.dart';
import 'admin_home_page.dart';
import 'admin_drawer.dart';
import 'admin_login_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    AdminHomePage(),
    Center(child: Text('Members')),
    Center(child: Text('Businesses')),
    Center(child: Text('Enquiries')),
    Center(child: Text('Interests')),
    Center(child: Text('Notifications')),
    Center(child: Text('Reports')),
    Center(child: Text('Settings')),
  ];

  final List<String> _titles = const [
    'Dashboard',
    'Members',
    'Businesses',
    'Enquiries',
    'Interests',
    'Notifications',
    'Reports',
    'Settings',
  ];

  Future<void> _logout() async {
    await AdminAuthService().logout();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const AdminLoginPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
      ),

      drawer: AdminDrawer(
        selectedIndex: _selectedIndex,
        onItemSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });

          Navigator.pop(context);
        },
        onLogout: _logout,
      ),

      body: _pages[_selectedIndex],
    );
  }
}