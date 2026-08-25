import 'package:flutter/material.dart';

import 'admin_auth_service.dart';
import 'admin_drawer.dart';
import 'admin_home_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() =>
      _AdminDashboardPageState();
}

class _AdminDashboardPageState
    extends State<AdminDashboardPage> {
  final AdminAuthService _authService = AdminAuthService();

  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    AdminHomePage(),

    Center(
      child: Text(
        'Members',
        style: TextStyle(fontSize: 24),
      ),
    ),

    Center(
      child: Text(
        'Businesses',
        style: TextStyle(fontSize: 24),
      ),
    ),

    Center(
      child: Text(
        'Enquiries',
        style: TextStyle(fontSize: 24),
      ),
    ),

    Center(
      child: Text(
        'Interests',
        style: TextStyle(fontSize: 24),
      ),
    ),

    Center(
      child: Text(
        'Notifications',
        style: TextStyle(fontSize: 24),
      ),
    ),

    Center(
      child: Text(
        'Reports',
        style: TextStyle(fontSize: 24),
      ),
    ),

    Center(
      child: Text(
        'Settings',
        style: TextStyle(fontSize: 24),
      ),
    ),
  ];

  String get _pageTitle {
    switch (_selectedIndex) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Members';
      case 2:
        return 'Businesses';
      case 3:
        return 'Enquiries';
      case 4:
        return 'Interests';
      case 5:
        return 'Notifications';
      case 6:
        return 'Reports';
      case 7:
        return 'Settings';
      default:
        return 'Dashboard';
    }
  }

  void _selectPage(int index) {
    setState(() {
      _selectedIndex = index;
    });

    Navigator.of(context).maybePop();
  }

  Future<void> _logout() async {
    await _authService.logout();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const Scaffold(
          body: Center(
            child: Text(
              'Please restart the Admin Panel.',
              style: TextStyle(fontSize: 18),
            ),
          ),
        ),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'AIVLM_I&C ADMIN',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
            ),
            child: Center(
              child: Text(
                _authService.currentUser?.email ??
                    'Administrator',
                style: const TextStyle(
                  fontSize: 14,
                ),
              ),
            ),
          ),

          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 10),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
            child: const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Icon(Icons.account_circle),
            ),
          ),
        ],
      ),

      drawer: AdminDrawer(
        selectedIndex: _selectedIndex,
        onItemSelected: _selectPage,
        onLogout: _logout,
      ),

      body: Row(
        children: [
          if (MediaQuery.of(context).size.width >= 900)
            SizedBox(
              width: 240,
              child: AdminDrawer(
                selectedIndex: _selectedIndex,
                onItemSelected: _selectPage,
                onLogout: _logout,
              ),
            ),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    _pageTitle,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                Expanded(
                  child: _pages[_selectedIndex],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}