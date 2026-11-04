
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'business_details_screen.dart';
import 'search_business_screen.dart';
import 'post_enquiry_screen.dart';
import 'settings_screen.dart';
import 'member_profile_router.dart';
import 'all_enquiries_screen.dart';
import 'enquiry_feed.dart';

class DashboardPage extends StatefulWidget {
  final String memberId;

  const DashboardPage({super.key, required this.memberId});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int selectedIndex = 0;

  /// Small rectangular curved-shape button.
  Widget dashboardCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 78,
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: Colors.blue),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static T? _safe<T>(Map<String, dynamic> map, String key) {
    if (!map.containsKey(key)) return null;

    final value = map[key];

    if (value is T) return value;

    return null;
  }

  void _openAllEnquiries({String? industryFilter}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AllEnquiriesScreen(
          industryFilter: industryFilter,
        ),
      ),
    );
  }

  static String _industryLabel(Map<String, dynamic> data) {
    final String industryType =
        _safe<String>(data, 'industryType') ?? '';

    final String customIndustry =
        _safe<String>(data, 'customIndustry') ?? '';

    if (industryType == 'Other' && customIndustry.isNotEmpty) {
      return customIndustry;
    }

    return industryType;
  }

  Widget _industryCard(String industry, int count) {
    return InkWell(
      onTap: () => _openAllEnquiries(industryFilter: industry),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.question_answer,
              size: 20,
              color: Colors.blue,
            ),
            const SizedBox(height: 8),
            Text(
              industry,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.list_alt,
                  size: 14,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '$count ${count == 1 ? 'enquiry' : 'enquiries'} available',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------
  // RECENT ENQUIRIES - INDUSTRY SUMMARY
  // --------------------------------------------------

  Widget recentEnquiriesSection() {
    final stream = FirebaseFirestore.instance
        .collection('enquiries')
        .orderBy('createdAt', descending: true)
        .limit(200)
        .snapshots();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Enquiry Categories',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: _openAllEnquiries,
              child: const Text('See all'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 140,
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: stream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Could not load enquiries.',
                    style: TextStyle(
                      color: Colors.red.shade400,
                    ),
                  ),
                );
              }

              final docs = snapshot.data?.docs ?? [];

              if (docs.isEmpty) {
                return Center(
                  child: Text(
                    'No enquiries posted yet.',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
                );
              }

              final Map<String, int> industryCounts = {};

              for (final doc in docs) {
                final label = _industryLabel(doc.data());

                if (label.isEmpty) continue;

                industryCounts[label] =
                    (industryCounts[label] ?? 0) + 1;
              }

              final industryEntries = industryCounts.entries.toList();

              if (industryEntries.isEmpty) {
                return Center(
                  child: Text(
                    'No enquiries posted yet.',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
                );
              }

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: industryEntries.length,
                itemBuilder: (context, index) {
                  final entry = industryEntries[index];

                  return _industryCard(entry.key, entry.value);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------
  // PERSONALIZED MEMBER WELCOME CARD
  // --------------------------------------------------

  Widget _memberWelcomeCard() {
    final memberStream = FirebaseFirestore.instance
        .collection('members')
        .doc(widget.memberId)
        .snapshots();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: memberStream,
      builder: (context, snapshot) {
        Widget buildBanner(List<Widget> children) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.blue, Colors.indigo],
              ),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return buildBanner([
            const Text(
              'Loading your member details...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
          ]);
        }

        if (snapshot.hasError) {
          return buildBanner([
            const Text(
              'Unable to load member details.',
              style: TextStyle(color: Colors.white),
            ),
          ]);
        }

        final data = snapshot.data?.data();

        if (data == null) {
          return buildBanner([
            const Text(
              'Member record not found.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
          ]);
        }

        String readField(String key) {
          final value = data[key];
          return value is String ? value.trim() : '';
        }

        final name = readField('name');

        final memberId = readField('memberId').isNotEmpty
            ? readField('memberId')
            : readField('membershipNumber');

        return buildBanner([
          Text(
            'Welcome, ${name.isNotEmpty ? name : 'Member'}! 👋',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            'Member ID: ${memberId.isNotEmpty ? memberId : 'Not available'}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'ALL INDIA VEERA SHAIVA\n'
            'LINGAYAT MAHASABHA\n'
            'INDUSTRY & COMMERCE',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
        ]);
      },
    );
  }

  // --------------------------------------------------
  // DASHBOARD NAVIGATION CARDS
  // --------------------------------------------------

  Widget _dashboardNavigationCards() {
    final memberStream = FirebaseFirestore.instance
        .collection('members')
        .doc(widget.memberId)
        .snapshots();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: memberStream,
      builder: (context, snapshot) {
        final data = snapshot.data?.data();

        final userType = (data?['userType'] ?? '')
            .toString()
            .trim()
            .toLowerCase();

        final isActive = data?['active'] == true;

        // Only active Business members can see Business Details.
        final showBusinessDetails =
            snapshot.hasData &&
            snapshot.data!.exists &&
            !snapshot.hasError &&
            userType == 'business' &&
            isActive;

        final cards = <Widget>[];

        if (showBusinessDetails) {
          cards.add(
            dashboardCard(
              title: 'Business Details',
              icon: Icons.business,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BusinessDetailsScreen(
                      memberId: widget.memberId,
                    ),
                  ),
                );
              },
            ),
          );
        }

        cards.add(
          dashboardCard(
            title: 'Search Business',
            icon: Icons.search,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SearchBusinessScreen(
                    memberId: widget.memberId,
                  ),
                ),
              );
            },
          ),
        );

        cards.add(
          dashboardCard(
            title: 'Post Enquiry',
            icon: Icons.question_answer,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PostEnquiryScreen(
                    memberId: widget.memberId,
                  ),
                ),
              );
            },
          ),
        );

        return Row(
          children: [
            for (int i = 0; i < cards.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(child: cards[i]),
            ],
          ],
        );
      },
    );
  }

  // --------------------------------------------------
  // HOME TAB WITH SCROLLABLE ENQUIRY FEED
  // --------------------------------------------------

  Widget homeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),

          _memberWelcomeCard(),

          const SizedBox(height: 30),

          _dashboardNavigationCards(),

          const SizedBox(height: 30),

          recentEnquiriesSection(),

          const SizedBox(height: 25),

          const Text(
            'Latest Enquiries',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            'Latest posts from Business, Non-Business and Student members',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 12),

          // Independently scrollable, paginated enquiry feed.
          SizedBox(
            height: 650,
            child: EnquiryFeed(
              key: ValueKey('enquiry-feed-${widget.memberId}'),
              memberId: widget.memberId,
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // SEARCH TAB
  // --------------------------------------------------

  Widget searchTab() {
    return SearchBusinessScreen(
      memberId: widget.memberId,
    );
  }

  // --------------------------------------------------
  // PROFILE TAB
  // --------------------------------------------------

  Widget profileTab() {
    return MemberProfileRouter(
      memberId: widget.memberId,
    );
  }

  // --------------------------------------------------
  // SETTINGS TAB
  // --------------------------------------------------

  Widget settingsTab() {
    return SettingsScreen(
      memberId: widget.memberId,
    );
  }

  List<Widget> get tabs => [
        homeTab(),
        searchTab(),
        profileTab(),
        settingsTab(),
      ];

  void onBottomTap(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  // --------------------------------------------------
  // MAIN BUILD
  // --------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('123'),
        centerTitle: true,
      ),
      body: tabs[selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        type: BottomNavigationBarType.fixed,
        onTap: onBottomTap,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
