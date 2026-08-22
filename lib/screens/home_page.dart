import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'business_details_screen.dart';
import 'search_business_screen.dart';
import 'post_enquiry_screen.dart';
import 'settings_screen.dart';
import 'member_profile_router.dart';
import 'all_enquiries_screen.dart';

class DashboardPage extends StatefulWidget {
  final String memberId;

  const DashboardPage({super.key, required this.memberId});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int selectedIndex = 0;

  /// Small rectangular curved-shape button (size/shape changed only,
  /// colors kept exactly the same as before)
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  /// Reads a field from a Firestore doc without ever throwing, even if the
  /// field is missing or the wrong type.
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
        builder: (_) => AllEnquiriesScreen(industryFilter: industryFilter),
      ),
    );
  }

  /// Resolves the display label for an enquiry's industry: the custom text
  /// when "Other" was picked, otherwise the industry type itself.
  static String _industryLabel(Map<String, dynamic> data) {
    final String industryType = _safe<String>(data, 'industryType') ?? '';
    final String customIndustry = _safe<String>(data, 'customIndustry') ?? '';
    if (industryType == 'Other' && customIndustry.isNotEmpty) {
      return customIndustry;
    }
    return industryType;
  }

  /// One small card representing an industry with at least one posted
  /// enquiry, meant to sit in a horizontally scrolling row ("one beside
  /// another"). Tapping a card opens the full list of posted enquiries
  /// filtered to that industry, so the client can browse and choose among
  /// multiple posts under it.
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
            const Icon(Icons.question_answer, size: 20, color: Colors.blue),
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
                Icon(Icons.list_alt, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '$count ${count == 1 ? 'enquiry' : 'enquiries'} available',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
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

  /// Live-streamed row of industries that have posted enquiries, laid out
  /// horizontally (one card beside another). Each card shows the industry
  /// name and how many enquiries are available under it. Tapping a card
  /// opens the full list of posted enquiries filtered to that industry.
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
              "Recent Enquiries",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: _openAllEnquiries,
              child: const Text("See all"),
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
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Could not load enquiries.',
                    style: TextStyle(color: Colors.red.shade400),
                  ),
                );
              }

              final docs = snapshot.data?.docs ?? [];

              if (docs.isEmpty) {
                return Center(
                  child: Text(
                    'No enquiries posted yet.',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                );
              }

              // Group enquiries by industry, keeping the order in which
              // each industry first appears (most recently posted first)
              // and counting how many fall under each one.
              final Map<String, int> industryCounts = {};
              for (final doc in docs) {
                final label = _industryLabel(doc.data());
                if (label.isEmpty) continue;
                industryCounts[label] = (industryCounts[label] ?? 0) + 1;
              }

              final industryEntries = industryCounts.entries.toList();

              if (industryEntries.isEmpty) {
                return Center(
                  child: Text(
                    'No enquiries posted yet.',
                    style: TextStyle(color: Colors.grey.shade600),
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

  Widget homeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.blue, Colors.indigo],
              ),
              borderRadius: BorderRadius.circular(25),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Welcome Member 👋",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  "ALL INDIA VEERA SHAIVA\nLINGAYAT MAHASABHA\nINDUSTRY & COMMERCE",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          /// Small rectangular tabs laid out in a single row
          /// (replaces the old 2x2 big-card grid)
          Row(
            children: [
              Expanded(
                child: dashboardCard(
                  title: "Business Details",
                  icon: Icons.business,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            BusinessDetailsScreen(memberId: widget.memberId),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: dashboardCard(
                  title: "Search Business",
                  icon: Icons.search,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            SearchBusinessScreen(memberId: widget.memberId),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: dashboardCard(
                  title: "Post Enquiry",
                  icon: Icons.question_answer,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            PostEnquiryScreen(memberId: widget.memberId),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          recentEnquiriesSection(),
        ],
      ),
    );
  }

  Widget searchTab() {
    return SearchBusinessScreen(memberId: widget.memberId);
  }

  /// Profile tab now routes to the right profile screen for this member:
  /// business members get the existing ProfileScreen (used internally by
  /// MemberProfileRouter), non-business and student members get the
  /// simpler NonBusinessProfileScreen. The router decides which one to
  /// show based on the member's `userType` field in Firestore, so this
  /// tab doesn't need to guess.
  Widget profileTab() {
    return MemberProfileRouter(memberId: widget.memberId);
  }

  Widget settingsTab() {
    return const SettingsScreen();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(title: const Text("AIVLM-I&C"), centerTitle: true),

      body: tabs[selectedIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        type: BottomNavigationBarType.fixed,
        onTap: onBottomTap,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Search"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "Settings",
          ),
        ],
      ),
    );
  }
}