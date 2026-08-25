import 'package:flutter/material.dart';

class AdminDrawer extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final VoidCallback onLogout;

  const AdminDrawer({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.admin_panel_settings,
                  size: 50,
                ),
                SizedBox(height: 10),
                Text(
                  'AIVLM_I&C',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text('Admin Panel'),
              ],
            ),
          ),

          _item(
            context,
            icon: Icons.dashboard,
            title: 'Dashboard',
            index: 0,
          ),

          _item(
            context,
            icon: Icons.people,
            title: 'Members',
            index: 1,
          ),

          _item(
            context,
            icon: Icons.business,
            title: 'Businesses',
            index: 2,
          ),

          _item(
            context,
            icon: Icons.question_answer,
            title: 'Enquiries',
            index: 3,
          ),

          _item(
            context,
            icon: Icons.favorite,
            title: 'Interests',
            index: 4,
          ),

          _item(
            context,
            icon: Icons.notifications,
            title: 'Notifications',
            index: 5,
          ),

          _item(
            context,
            icon: Icons.bar_chart,
            title: 'Reports',
            index: 6,
          ),

          _item(
            context,
            icon: Icons.settings,
            title: 'Settings',
            index: 7,
          ),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: onLogout,
          ),
        ],
      ),
    );
  }

  Widget _item(
    BuildContext context, {
    required IconData icon,
    required String title,
    required int index,
  }) {
    return ListTile(
      selected: selectedIndex == index,
      leading: Icon(icon),
      title: Text(title),
      onTap: () => onItemSelected(index),
    );
  }
}