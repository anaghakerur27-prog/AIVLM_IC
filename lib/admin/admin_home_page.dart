import 'package:flutter/material.dart';

import 'admin_statistics_service.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() =>
      _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  final AdminStatisticsService _statistics =
      AdminStatisticsService();

  bool _isLoading = true;

  int _totalMembers = 0;
  int _businessMembers = 0;
  int _nonBusinessMembers = 0;
  int _students = 0;
  int _totalBusinesses = 0;
  int _pendingBusinesses = 0;
  int _totalEnquiries = 0;
  int _totalInterests = 0;
  int _todayRegistrations = 0;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await Future.wait<int>([
        _statistics.getTotalMembers(),
        _statistics.getBusinessMembers(),
        _statistics.getNonBusinessMembers(),
        _statistics.getStudents(),
        _statistics.getTotalBusinesses(),
        _statistics.getPendingBusinesses(),
        _statistics.getTotalEnquiries(),
        _statistics.getTotalInterests(),
        _statistics.getTodayRegistrations(),
      ]);

      if (!mounted) return;

      setState(() {
        _totalMembers = results[0];
        _businessMembers = results[1];
        _nonBusinessMembers = results[2];
        _students = results[3];
        _totalBusinesses = results[4];
        _pendingBusinesses = results[5];
        _totalEnquiries = results[6];
        _totalInterests = results[7];
        _todayRegistrations = results[8];

        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to load dashboard statistics: $e',
          ),
        ),
      );

      debugPrint(
        'Dashboard Statistics Error: $e',
      );
    }
  }

  Widget _statCard({
    required String title,
    required int value,
    required IconData icon,
  }) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer,
              ),
              child: Icon(icon),
            ),

            const SizedBox(width: 15),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    value.toString(),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    int columns;

    if (width >= 1200) {
      columns = 3;
    } else if (width >= 700) {
      columns = 2;
    } else {
      columns = 1;
    }

    return RefreshIndicator(
      onRefresh: _loadStatistics,

      child: SingleChildScrollView(
        physics:
            const AlwaysScrollableScrollPhysics(),

        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,

              children: [
                const Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    Text(
                      'Dashboard Overview',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 5),

                    Text(
                      'AIVLM_I&C statistics and activity',
                    ),
                  ],
                ),

                IconButton(
                  tooltip: 'Refresh',
                  onPressed: _isLoading
                      ? null
                      : _loadStatistics,
                  icon: const Icon(
                    Icons.refresh,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),

            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(50),
                  child:
                      CircularProgressIndicator(),
                ),
              )
            else
              GridView.count(
                crossAxisCount: columns,

                shrinkWrap: true,

                physics:
                    const NeverScrollableScrollPhysics(),

                crossAxisSpacing: 16,
                mainAxisSpacing: 16,

                childAspectRatio:
                    width >= 700 ? 2.2 : 2.8,

                children: [
                  _statCard(
                    title: 'Total Members',
                    value: _totalMembers,
                    icon: Icons.people,
                  ),

                  _statCard(
                    title: 'Business Members',
                    value: _businessMembers,
                    icon: Icons.business_center,
                  ),

                  _statCard(
                    title: 'Non-Business Members',
                    value: _nonBusinessMembers,
                    icon: Icons.person,
                  ),

                  _statCard(
                    title: 'Students',
                    value: _students,
                    icon: Icons.school,
                  ),

                  _statCard(
                    title: 'Total Businesses',
                    value: _totalBusinesses,
                    icon: Icons.business,
                  ),

                  _statCard(
                    title: 'Pending Approval',
                    value: _pendingBusinesses,
                    icon: Icons.pending_actions,
                  ),

                  _statCard(
                    title: 'Total Enquiries',
                    value: _totalEnquiries,
                    icon: Icons.question_answer,
                  ),

                  _statCard(
                    title: 'Total Interests',
                    value: _totalInterests,
                    icon: Icons.favorite,
                  ),

                  _statCard(
                    title: "Today's Registrations",
                    value: _todayRegistrations,
                    icon: Icons.today,
                  ),
                ],
              ),

            const SizedBox(height: 35),

            const Text(
              'Recent Registrations',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            const Card(
              child: SizedBox(
                height: 150,
                child: Center(
                  child: Text(
                    'Recent registrations will be displayed here.',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}