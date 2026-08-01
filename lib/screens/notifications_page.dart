// lib/screens/notifications/notifications_page.dart
//
// Notifications list screen.
// Flutter 3.x + Firebase (cloud_firestore, firebase_auth)
//
// Expected Firestore schema (adjust to match your project):
//
//   notifications {
//     userId: String,
//     title: String,
//     message: String,        // body text
//     targetType: String?,    // e.g. "enquiry", "interest", "business" - optional
//     targetId: String?,      // id of the related document - optional
//     isRead: bool?,          // optional
//     createdAt: Timestamp,
//   }
//
// This screen defensively reads every field so a missing field never
// throws a "Bad state: field ... does not exist" error - it falls back
// to a sensible default instead.
//
// Required pubspec.yaml dependencies:
//   cloud_firestore: ^5.0.0
//   firebase_auth: ^5.0.0
//   intl: ^0.19.0

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  static const String routeName = '/notifications';

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: uid == null
          ? const Center(
              child: Text('Please sign in to view your notifications.'),
            )
          : _NotificationsList(uid: uid),
    );
  }
}

class _NotificationsList extends StatelessWidget {
  const _NotificationsList({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Could not load notifications.\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No notifications yet.\nYou\'re all caught up!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: docs.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final data = docs[index].data();
            return _NotificationTile(data: data);
          },
        );
      },
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.data});

  final Map<String, dynamic> data;

  /// Safe getter: never throws even if the field is missing or the wrong type.
  static T? _safe<T>(Map<String, dynamic> map, String key) {
    if (!map.containsKey(key)) return null;
    final value = map[key];
    if (value is T) return value;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final String title = _safe<String>(data, 'title') ?? 'Notification';
    final String message = _safe<String>(data, 'message') ?? '';
    final String? targetType = _safe<String>(data, 'targetType');
    final bool isRead = _safe<bool>(data, 'isRead') ?? false;
    final Timestamp? createdAt = _safe<Timestamp>(data, 'createdAt');

    final String timeLabel = createdAt != null
        ? _formatTimestamp(createdAt.toDate())
        : '';

    return ListTile(
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
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.isNotEmpty)
            Text(message, maxLines: 2, overflow: TextOverflow.ellipsis),
          if (targetType != null && targetType.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                targetType,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
      isThreeLine: message.isNotEmpty && targetType != null,
      trailing: Text(
        timeLabel,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: Colors.grey),
      ),
      onTap: () {
        final String? targetId = _safe<String>(data, 'targetId');
        if (targetType != null && targetId != null) {
          Navigator.of(
            context,
          ).pushNamed('/${targetType}s', arguments: targetId);
        }
      },
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
