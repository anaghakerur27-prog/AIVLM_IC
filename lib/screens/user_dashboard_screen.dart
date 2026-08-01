// lib/screens/dashboard/user_dashboard_screen.dart
//
// Production-ready User Dashboard Screen
// Flutter 3.x + Firebase (cloud_firestore, firebase_auth)
//
// Expected Firestore schema (adjust collection/field names to match your project):
//
//   businesses_viewed  { userId: String, businessId: String, viewedAt: Timestamp }
//   enquiries          { userId: String, ... , createdAt: Timestamp }
//   interests_sent     { fromUserId: String, ... , createdAt: Timestamp }
//   interests_received { toUserId: String,   ... , createdAt: Timestamp }
//   notifications      { userId: String, title: String, body: String,
//                         type: String, isRead: bool, createdAt: Timestamp }
//
// Required pubspec.yaml dependencies:
//   cloud_firestore: ^5.0.0
//   firebase_auth: ^5.0.0
//   intl: ^0.19.0
//
// Adjust collection names / query fields (marked with `// SCHEMA:`) to match
// your actual Firestore structure.

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UserDashboardScreen extends StatefulWidget {
  const UserDashboardScreen({super.key});

  static const String routeName = '/dashboard';

  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  // Used to force-rebuild StreamBuilders on pull-to-refresh.
  Key _refreshKey = UniqueKey();

  Future<void> _onRefresh() async {
    // Firestore streams are already real-time, but pull-to-refresh gives the
    // user explicit feedback and re-establishes the listeners cleanly.
    setState(() => _refreshKey = UniqueKey());
    await Future.delayed(const Duration(milliseconds: 600));
  }

  @override
  Widget build(BuildContext context) {
    final uid = _uid;

    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dashboard')),
        body: const Center(
          child: Text('Please sign in to view your dashboard.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            tooltip: 'Notifications',
            onPressed: () => Navigator.of(context).pushNamed('/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Profile',
            onPressed: () => Navigator.of(context).pushNamed('/profile'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: CustomScrollView(
          key: _refreshKey,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _WelcomeHeader(uid: uid, firestore: _firestore),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              sliver: SliverToBoxAdapter(
                child: _DashboardStatsGrid(uid: uid, firestore: _firestore),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              sliver: SliverToBoxAdapter(
                child: _RecentNotificationsSection(
                  uid: uid,
                  firestore: _firestore,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------
// Welcome header
// -----------------------------------------------------------------------
class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader({required this.uid, required this.firestore});

  final String uid;
  final FirebaseFirestore firestore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        // SCHEMA: users/{uid} document with a `name` field.
        stream: firestore.collection('users').doc(uid).snapshots(),
        builder: (context, snapshot) {
          String name = 'there';
          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data();
            name = (data?['name'] as String?)?.trim().isNotEmpty == true
                ? data!['name'] as String
                : name;
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back,',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                name,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          );
        },
      ),
    );
  }
}

// -----------------------------------------------------------------------
// 2x2 responsive stats grid
// -----------------------------------------------------------------------
class _DashboardStatsGrid extends StatelessWidget {
  const _DashboardStatsGrid({required this.uid, required this.firestore});

  final String uid;
  final FirebaseFirestore firestore;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive: 2 columns on phones, up to 4 on wide screens.
        final width = constraints.maxWidth;
        final crossAxisCount = width > 900 ? 4 : (width > 600 ? 3 : 2);

        final cards = <Widget>[
          _StatCard(
            title: 'Businesses Viewed',
            icon: Icons.storefront_outlined,
            color: Colors.indigo,
            // SCHEMA: businesses_viewed collection, filtered by userId.
            stream: firestore
                .collection('businesses_viewed')
                .where('userId', isEqualTo: uid)
                .snapshots(),
            onTap: () => Navigator.of(context).pushNamed('/businesses-viewed'),
          ),
          _StatCard(
            title: 'Enquiries Posted',
            icon: Icons.forum_outlined,
            color: Colors.teal,
            // SCHEMA: enquiries collection, filtered by userId.
            stream: firestore
                .collection('enquiries')
                .where('userId', isEqualTo: uid)
                .snapshots(),
            onTap: () => Navigator.of(context).pushNamed('/enquiries'),
          ),
          _StatCard(
            title: 'Interests Sent',
            icon: Icons.send_outlined,
            color: Colors.orange,
            // SCHEMA: interests_sent collection, filtered by fromUserId.
            stream: firestore
                .collection('interests_sent')
                .where('fromUserId', isEqualTo: uid)
                .snapshots(),
            onTap: () => Navigator.of(context).pushNamed('/interests-sent'),
          ),
          _StatCard(
            title: 'Interests Received',
            icon: Icons.inbox_outlined,
            color: Colors.purple,
            // SCHEMA: interests_received collection, filtered by toUserId.
            stream: firestore
                .collection('interests_received')
                .where('toUserId', isEqualTo: uid)
                .snapshots(),
            onTap: () => Navigator.of(context).pushNamed('/interests-received'),
          ),
        ];

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 1.15,
          children: cards,
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.stream,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color color;
  final Stream<QuerySnapshot<Map<String, dynamic>>> stream;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(18),
      elevation: 1.5,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 12),
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: stream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 28,
                      width: 28,
                      child: CircularProgressIndicator(strokeWidth: 2.4),
                    );
                  }
                  if (snapshot.hasError) {
                    return Tooltip(
                      message: 'Failed to load: ${snapshot.error}',
                      child: const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 26,
                      ),
                    );
                  }
                  final count = snapshot.data?.docs.length ?? 0;
                  return Text(
                    '$count',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------
// Recent notifications section
// -----------------------------------------------------------------------
class _RecentNotificationsSection extends StatelessWidget {
  const _RecentNotificationsSection({
    required this.uid,
    required this.firestore,
  });

  final String uid;
  final FirebaseFirestore firestore;

  static const int _limit = 10;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Notifications',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pushNamed('/notifications'),
              child: const Text('See all'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          // SCHEMA: notifications collection, filtered by userId,
          // ordered by createdAt desc, limited to the most recent items.
          stream: firestore
              .collection('notifications')
              .where('userId', isEqualTo: uid)
              .orderBy('createdAt', descending: true)
              .limit(_limit)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return _InlineMessage(
                icon: Icons.error_outline,
                color: Colors.red,
                message: 'Could not load notifications.\n${snapshot.error}',
              );
            }

            final docs = snapshot.data?.docs ?? [];

            if (docs.isEmpty) {
              return const _InlineMessage(
                icon: Icons.notifications_none_rounded,
                color: Colors.grey,
                message: 'No notifications yet.\nYou\'re all caught up!',
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final data = docs[index].data();
                return _NotificationTile(data: data);
              },
            );
          },
        ),
      ],
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final String title = (data['title'] as String?) ?? 'Notification';
    final String body = (data['body'] as String?) ?? '';
    final bool isRead = (data['isRead'] as bool?) ?? false;
    final Timestamp? ts = data['createdAt'] as Timestamp?;
    final String timeLabel = ts != null ? _formatTimestamp(ts.toDate()) : '';

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: isRead
            ? Colors.grey.shade200
            : Colors.blue.withValues(alpha: 0.15),
        child: Icon(
          isRead ? Icons.notifications_none : Icons.notifications_active,
          color: isRead ? Colors.grey : Colors.blue,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isRead ? FontWeight.normal : FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: body.isNotEmpty
          ? Text(body, maxLines: 2, overflow: TextOverflow.ellipsis)
          : null,
      trailing: Text(
        timeLabel,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: Colors.grey),
      ),
    );
  }

  static String _formatTimestamp(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(date);
  }
}

// -----------------------------------------------------------------------
// Shared empty/error state widget
// -----------------------------------------------------------------------
class _InlineMessage extends StatelessWidget {
  const _InlineMessage({
    required this.icon,
    required this.color,
    required this.message,
  });

  final IconData icon;
  final Color color;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Center(
        child: Column(
          children: [
            Icon(icon, color: color, size: 36),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
