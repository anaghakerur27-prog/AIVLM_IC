import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EnquiryFeed extends StatefulWidget {
  final String memberId;

  const EnquiryFeed({
    super.key,
    required this.memberId,
  });

  @override
  State<EnquiryFeed> createState() => _EnquiryFeedState();
}

class _EnquiryFeedState extends State<EnquiryFeed> {
  static const int pageSize = 20;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _headDocs = [];
final List<QueryDocumentSnapshot<Map<String, dynamic>>> _olderDocs = [];

  bool _isLoadingMore = false;
  bool _hasMore = true;
  Object? _error;

  Query<Map<String, dynamic>> get _baseQuery =>
      FirebaseFirestore.instance
          .collection('enquiries')
          .orderBy('createdAt', descending: true);

  @override
  void initState() {
    super.initState();
    _listenToLatestEnquiries();
  }

  void _listenToLatestEnquiries() {
    _subscription = _baseQuery
        .limit(pageSize)
        .snapshots()
        .listen(
      (snapshot) {
        if (!mounted) return;

        final newHead = snapshot.docs;
        final newHeadIds = newHead.map((doc) => doc.id).toSet();

        // Keep documents that were previously in the live first page
        // but have moved out because newer enquiries were posted.
        final movedOut = _headDocs
            .where((doc) => !newHeadIds.contains(doc.id))
            .toList();

        final existingOlderIds =
            _olderDocs.map((doc) => doc.id).toSet();

        for (final doc in movedOut) {
          if (!existingOlderIds.contains(doc.id)) {
            _olderDocs.add(doc);
          }
        }

        _headDocs = newHead;
        _sortOlderDocs();

        setState(() {
          _error = null;
          if (snapshot.docs.length < pageSize && _olderDocs.isEmpty) {
            _hasMore = false;
          } else {
            _hasMore = true;
          }
        });
      },
      onError: (error) {
        if (!mounted) return;
        setState(() => _error = error);
      },
    );
  }

  DateTime _createdAt(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final value = doc.data()['createdAt'];

    if (value is Timestamp) {
      return value.toDate();
    }

    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  void _sortOlderDocs() {
    _olderDocs.sort(
      (a, b) => _createdAt(b).compareTo(_createdAt(a)),
    );
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> get _allDocs {
    final combined = <String,
        QueryDocumentSnapshot<Map<String, dynamic>>>{};

    for (final doc in _headDocs) {
      combined[doc.id] = doc;
    }

    for (final doc in _olderDocs) {
      combined[doc.id] = doc;
    }

    final result = combined.values.toList();

    result.sort(
      (a, b) => _createdAt(b).compareTo(_createdAt(a)),
    );

    return result;
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    final currentDocs = _allDocs;
    if (currentDocs.isEmpty) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final lastDocument = currentDocs.last;

      final snapshot = await _baseQuery
          .startAfterDocument(lastDocument)
          .limit(pageSize)
          .get();

      if (!mounted) return;

      final knownIds = _allDocs.map((doc) => doc.id).toSet();

      for (final doc in snapshot.docs) {
        if (!knownIds.contains(doc.id)) {
          _olderDocs.add(doc);
          knownIds.add(doc.id);
        }
      }

      _sortOlderDocs();

      setState(() {
        _hasMore = snapshot.docs.length == pageSize;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to load more enquiries: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  String _value(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];

      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }

    return '';
  }

  String _memberType(Map<String, dynamic> data) {
    final raw = _value(data, ['memberType', 'userType'])
        .toLowerCase()
        .trim();

    if (raw == 'business') return 'Business';
    if (raw == 'student') return 'Student';

    if (raw == 'non_business' ||
        raw == 'non-business' ||
        raw == 'nonbusiness') {
      return 'Non-Business';
    }

    return raw.isEmpty ? 'Member' : raw;
  }

  String _formatDate(dynamic value) {
    if (value is! Timestamp) {
      return 'Date not available';
    }

    final date = value.toDate().toLocal();

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;

    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '$day-$month-$year, $hour:$minute $period';
  }

  Future<Map<String, dynamic>> _getMemberDetails(
    Map<String, dynamic> enquiry,
  ) async {
    final memberId = _value(enquiry, ['memberId']);

    if (memberId.isEmpty) return {};

    final snapshot = await FirebaseFirestore.instance
        .collection('members')
        .doc(memberId)
        .get();

    return snapshot.data() ?? {};
  }

  void _showFullDetails(
    Map<String, dynamic> enquiry,
    Map<String, dynamic> memberData,
  ) {
    final title = _value(enquiry, ['enquiryTitle', 'title']);
    final description = _value(
      enquiry,
      ['enquiryDescription', 'description'],
    );
    final industry = _value(enquiry, ['customIndustry']).isNotEmpty
        ? _value(enquiry, ['customIndustry'])
        : _value(enquiry, ['industryType']);

    final name = _value(enquiry, ['postedByName']).isNotEmpty
        ? _value(enquiry, ['postedByName'])
        : _value(memberData, ['name', 'memberName', 'fullName']);

    final memberNumber =
        _value(enquiry, ['postedByMemberNumber']).isNotEmpty
            ? _value(enquiry, ['postedByMemberNumber'])
            : _value(memberData, ['membershipNumber', 'memberId']);

    final phone = _value(enquiry, ['postedByPhone']).isNotEmpty
        ? _value(enquiry, ['postedByPhone'])
        : _value(
            memberData,
            ['phone', 'phoneNumber', 'mobile', 'mobileNumber'],
          );

    final email = _value(enquiry, ['postedByEmail']).isNotEmpty
        ? _value(enquiry, ['postedByEmail'])
        : _value(memberData, ['email', 'emailId', 'mailId']);

    final address = _value(enquiry, ['postedByAddress']).isNotEmpty
        ? _value(enquiry, ['postedByAddress'])
        : _value(
            memberData,
            ['address', 'residentialAddress', 'businessAddress'],
          );

    final memberType = _value(enquiry, ['memberType']).isNotEmpty
        ? _memberType(enquiry)
        : _memberType(memberData);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.isEmpty ? 'Enquiry Details' : title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),

                _detail('Description', description),
                _detail('Industry', industry),
                _detail('Posted by', name),
                _detail(
                  'Member ID',
                  memberNumber.isEmpty
                      ? _value(enquiry, ['memberId'])
                      : memberNumber,
                ),
                _detail('Member Type', memberType),
                _detail('Phone', phone),
                _detail('Email', email),
                _detail('Address', address),
                _detail(
                  'Posted on',
                  _formatDate(enquiry['createdAt']),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detail(String label, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
            ),
          ),
          const SizedBox(height: 3),
          SelectableText(value),
        ],
      ),
    );
  }

  Widget _enquiryCard(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();

    final title = _value(data, ['enquiryTitle', 'title']);
    final description = _value(
      data,
      ['enquiryDescription', 'description'],
    );
    final industry = _value(data, ['customIndustry']).isNotEmpty
        ? _value(data, ['customIndustry'])
        : _value(data, ['industryType']);

    final authorId = _value(data, ['memberId']);
    final isOwnPost = authorId.isNotEmpty && authorId == widget.memberId;

    return FutureBuilder<Map<String, dynamic>>(
      future: _getMemberDetails(data),
      builder: (context, snapshot) {
        final memberData = snapshot.data ?? {};

        final name = _value(data, ['postedByName']).isNotEmpty
            ? _value(data, ['postedByName'])
            : _value(memberData, ['name', 'memberName', 'fullName']);

        final memberNumber =
            _value(data, ['postedByMemberNumber']).isNotEmpty
                ? _value(data, ['postedByMemberNumber'])
                : _value(memberData, ['membershipNumber', 'memberId']);

        final memberType = _value(data, ['memberType']).isNotEmpty
            ? _memberType(data)
            : _memberType(memberData);

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _showFullDetails(data, memberData),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title.isEmpty ? 'Enquiry' : title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (isOwnPost)
                        const Chip(
                          label: Text('My Post'),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),

                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (industry.isNotEmpty)
                        Chip(
                          avatar: const Icon(
                            Icons.business_outlined,
                            size: 16,
                          ),
                          label: Text(industry),
                        ),
                      Chip(
                        avatar: const Icon(Icons.people_outline, size: 16),
                        label: Text(memberType),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Posted by: ${name.isEmpty ? "Member" : name}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),

                  if (memberNumber.isNotEmpty)
                    Text('Member ID: $memberNumber'),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 15,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          _formatDate(data['createdAt']),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      const Text(
                        'View details',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: Colors.blue,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final documents = _allDocs;

    if (_error != null && documents.isEmpty) {
      return Center(
        child: Text('Unable to load enquiries: $_error'),
      );
    }

    if (documents.isEmpty && _headDocs.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (documents.isEmpty) {
      return const Center(
        child: Text('No enquiries have been posted yet.'),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.pixels >=
            notification.metrics.maxScrollExtent - 250) {
          _loadMore();
        }
        return false;
      },
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        itemCount: documents.length + 1,
        itemBuilder: (context, index) {
          if (index < documents.length) {
            return _enquiryCard(documents[index]);
          }

          if (_isLoadingMore) {
            return const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (_hasMore) {
            return Padding(
              padding: const EdgeInsets.all(12),
              child: Center(
                child: TextButton(
                  onPressed: _loadMore,
                  child: const Text('Load more enquiries'),
                ),
              ),
            );
          }

          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(
              child: Text('You have reached the end of the feed.'),
            ),
          );
        },
      ),
    );
  }
}