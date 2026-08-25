import 'package:flutter/material.dart';

class AdminDrawer extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final VoidCallback onLogout;

  const AdminDrawer({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.onLogout,
  });

  Widget _menuItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    required String title,
  }) {
    final bool selected = selectedIndex == index;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: selected
            ? Theme.of(context)
                .colorScheme
                .primaryContainer
            : null,
      ),
      child: ListTile(
        leading: Icon(icon),
        title: Text(
          title,
          style: TextStyle(
            fontWeight:
                selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        selected: selected,
        onTap: () {
          onItemSelected(index);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: const Column(
                children: [
                  Icon(
                    Icons.admin_panel_settings,
                    size: 50,
                  ),

                  SizedBox(height: 10),

                  Text(
                    'AIVLM_I&C',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 4),

                  Text(
                    'ADMIN PANEL',
                    style: TextStyle(
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(),

            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _menuItem(
                    context: context,
                    index: 0,
                    icon: Icons.dashboard,
                    title: 'Dashboard',
                  ),

                  _menuItem(
                    context: context,
                    index: 1,
                    icon: Icons.people,
                    title: 'Members',
                  ),

                  _menuItem(
                    context: context,
                    index: 2,
                    icon: Icons.business,
                    title: 'Businesses',
                  ),

                  _menuItem(
                    context: context,
                    index: 3,
                    icon: Icons.question_answer,
                    title: 'Enquiries',
                  ),

                  _menuItem(
                    context: context,
                    index: 4,
                    icon: Icons.favorite,
                    title: 'Interests',
                  ),

                  _menuItem(
                    context: context,
                    index: 5,
                    icon: Icons.notifications,
                    title: 'Notifications',
                  ),

                  _menuItem(
                    context: context,
                    index: 6,
                    icon: Icons.bar_chart,
                    title: 'Reports',
                  ),

                  _menuItem(
                    context: context,
                    index: 7,
                    icon: Icons.settings,
                    title: 'Settings',
                  ),
                ],
              ),
            ),

            const Divider(),

            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: onLogout,
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}