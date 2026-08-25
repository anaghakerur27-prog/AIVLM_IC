import 'package:flutter/material.dart';

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(
              icon,
              size: 40,
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Welcome to AIVLM_I&C Admin Dashboard',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 25),

          GridView.count(
            crossAxisCount:
                MediaQuery.of(context).size.width > 900 ? 4 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            childAspectRatio: 2.2,
            children: [
              _statCard(
                title: 'Total Members',
                value: '0',
                icon: Icons.people,
              ),
              _statCard(
                title: 'Businesses',
                value: '0',
                icon: Icons.business,
              ),
              _statCard(
                title: 'Enquiries',
                value: '0',
                icon: Icons.question_answer,
              ),
              _statCard(
                title: 'Students',
                value: '0',
                icon: Icons.school,
              ),
            ],
          ),

          const SizedBox(height: 30),

          const Text(
            'Recent Registrations',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 15),

          const Card(
            child: Padding(
              padding: EdgeInsets.all(25),
              child: Center(
                child: Text(
                  'Recent registrations will appear here.',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}