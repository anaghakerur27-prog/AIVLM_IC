import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Shows every enquiry ever posted, newest first, so a client can browse
/// and pick among multiple posts. Pass [industryFilter] to narrow the list
/// down to enquiries under a single industry (e.g. when the user tapped an
/// industry card on the dashboard).
///
/// Each enquiry tile is joined against the poster's `businesses/{memberId}`
/// document so the full profile — organization name, owner, contact number,
/// email, website, address, district, pincode, description, visiting card
/// image and company profile PDF — is shown alongside the enquiry itself.
///
/// Reads every field defensively - a missing field never throws, it just
/// falls back to a sensible default.
class AllEnquiriesScreen extends StatelessWidget {
  const AllEnquiriesScreen({super.key, this.industryFilter});

  static const String routeName = '/all-enquiries';

  final String? industryFilter;

  static T? _safe<T>(Map<String, dynamic> map, String key) {
    if (!map.containsKey(key)) return null;
    final value = map[key];
    if (value is T) return value;
    return null;
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

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('enquiries')
        .orderBy('createdAt', descending: true)
        .snapshots();

    final bool hasFilter = industryFilter != null && industryFilter!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(hasFilter ? industryFilter! : 'All Enquiries'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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
                  'Could not load enquiries.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          var docs = snapshot.data?.docs ?? [];

          if (hasFilter) {
            docs = docs
                .where((doc) => _industryLabel(doc.data()) == industryFilter)
                .toList();
          }

          if (docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  hasFilter
                      ? 'No enquiries posted under $industryFilter yet.'
                      : 'No enquiries posted yet.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final data = docs[index].data();
              return _EnquiryTile(data: data);
            },
          );
        },
      ),
    );
  }
}

class _EnquiryTile extends StatelessWidget {
  const _EnquiryTile({required this.data});

  final Map<String, dynamic> data;

  /// Fields already rendered elsewhere in the tile (chip, location, time) -
  /// these are never repeated in the generic details list below.
  static const Set<String> _handledKeys = {
    'industryType',
    'customIndustry',
    'district',
    'createdAt',
    'memberId',
    'userId',
  };

  /// Likely field names for the enquiry's main heading, checked in order.
  static const List<String> _titleCandidates = [
    'title',
    'requirement',
    'subject',
    'productName',
    'enquiryTitle',
    'requirementTitle',
    'name',
  ];

  static T? _safe<T>(Map<String, dynamic> map, String key) {
    if (!map.containsKey(key)) return null;
    final value = map[key];
    if (value is T) return value;
    return null;
  }

  static bool _isMeaningful(dynamic value) {
    if (value == null) return false;
    final text = value.toString().trim();
    return text.isNotEmpty;
  }

  /// Turns a camelCase / snake_case Firestore field name into a readable
  /// label, e.g. "contactNumber" -> "Contact Number".
  static String _readableLabel(String key) {
    final spaced = key
        .replaceAllMapped(
          RegExp(r'(?<=[a-z0-9])(?=[A-Z])'),
          (m) => ' ',
        )
        .replaceAll('_', ' ');
    return spaced
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  static String _formatValue(dynamic value) {
    if (value is Timestamp) {
      final d = value.toDate();
      return '${d.day}/${d.month}/${d.year}';
    }
    if (value is List) {
      return value.map((e) => e.toString()).join(', ');
    }
    return value.toString();
  }

  /// Looks up the poster's full business profile from `businesses/{memberId}`.
  /// Returns an empty map (never throws / never null) if there is no
  /// `memberId` on the enquiry or no matching business document.
  Future<Map<String, dynamic>> _fetchBusiness() async {
    final String? memberId = _safe<String>(data, 'memberId');
    if (memberId == null || memberId.isEmpty) return {};

    try {
      final doc = await FirebaseFirestore.instance
          .collection('businesses')
          .doc(memberId)
          .get();
      return doc.data() ?? {};
    } catch (_) {
      return {};
    }
  }

  Future<void> _launch(String url) async {
    final uri = Uri.tryParse(
      url.startsWith('http') ? url : 'https://$url',
    );
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String industryType = _safe<String>(data, 'industryType') ?? '';
    final String customIndustry = _safe<String>(data, 'customIndustry') ?? '';
    final String district = _safe<String>(data, 'district') ?? '';
    final Timestamp? createdAt = _safe<Timestamp>(data, 'createdAt');

    final String industryLabel =
        (industryType == 'Other' && customIndustry.isNotEmpty)
            ? customIndustry
            : industryType;

    final String timeLabel =
        createdAt != null ? _formatTimestamp(createdAt.toDate()) : '';

    // Pick a heading from the first meaningful candidate field present.
    String? titleKey;
    for (final candidate in _titleCandidates) {
      if (_isMeaningful(data[candidate])) {
        titleKey = candidate;
        break;
      }
    }
    final String title = titleKey != null
        ? data[titleKey].toString()
        : (industryLabel.isNotEmpty ? industryLabel : 'Enquiry');

    // Every remaining field the post actually has, shown generically so
    // real content always appears regardless of the exact field names used
    // when the enquiry was saved.
    final detailEntries = data.entries.where((entry) {
      if (_handledKeys.contains(entry.key)) return false;
      if (entry.key == titleKey) return false;
      return _isMeaningful(entry.value);
    }).toList();

    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ExpansionTile(
        shape: const Border(),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              if (industryLabel.isNotEmpty)
                Flexible(
                  child: Chip(
                    label: Text(
                      industryLabel,
                      style: const TextStyle(fontSize: 11),
                    ),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    backgroundColor: Colors.blue.withValues(alpha: 0.1),
                  ),
                ),
              if (district.isNotEmpty) ...[
                const SizedBox(width: 8),
                Icon(Icons.location_city, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 2),
                Text(
                  district,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ],
          ),
        ),
        trailing: Text(
          timeLabel,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Colors.grey),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---- Raw enquiry fields (whatever was posted) ----
                  if (detailEntries.isEmpty)
                    Text(
                      'No further enquiry details provided.',
                      style: TextStyle(color: Colors.grey.shade800),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: detailEntries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(
                                color: Colors.grey.shade800,
                                fontSize: 14,
                              ),
                              children: [
                                TextSpan(
                                  text: '${_readableLabel(entry.key)}: ',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                TextSpan(text: _formatValue(entry.value)),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 14),

                  // ---- Poster's full business profile ----
                  Text(
                    'Posted By',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Colors.indigo.shade400,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<Map<String, dynamic>>(
                    future: _fetchBusiness(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }

                      final business = snapshot.data ?? {};
                      if (business.isEmpty) {
                        return Text(
                          'No business profile available for this poster.',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                            fontSize: 13,
                          ),
                        );
                      }

                      return _BusinessProfile(
                        business: business,
                        onLaunch: _launch,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
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
    return '${date.day}/${date.month}/${date.year}';
  }
}

/// Renders the full business profile pulled from `businesses/{memberId}`:
/// organization name, owner, contact number, email, website, address,
/// district, pincode, industry, description, visiting card image and a
/// link to the company profile PDF.
class _BusinessProfile extends StatelessWidget {
  const _BusinessProfile({required this.business, required this.onLaunch});

  final Map<String, dynamic> business;
  final Future<void> Function(String url) onLaunch;

  static T? _safe<T>(Map<String, dynamic> map, String key) {
    if (!map.containsKey(key)) return null;
    final value = map[key];
    if (value is T) return value;
    return null;
  }

  Widget _row(IconData icon, String label, String value, {VoidCallback? onTap}) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: TextStyle(color: Colors.grey.shade800, fontSize: 14),
                  children: [
                    TextSpan(
                      text: '$label: ',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    TextSpan(
                      text: value,
                      style: onTap != null
                          ? const TextStyle(
                              color: Colors.indigo,
                              decoration: TextDecoration.underline,
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String businessName = _safe<String>(business, 'businessName') ?? '';
    final String ownerName = _safe<String>(business, 'ownerName') ?? '';
    final String contactNumber = _safe<String>(business, 'contactNumber') ?? '';
    final String email = _safe<String>(business, 'email') ?? '';
    final String website = _safe<String>(business, 'website') ?? '';
    final String address = _safe<String>(business, 'address') ?? '';
    final String district = _safe<String>(business, 'district') ?? '';
    final String pincode = _safe<String>(business, 'pincode') ?? '';
    final String industryType = _safe<String>(business, 'industryType') ?? '';
    final String customIndustry =
        _safe<String>(business, 'customIndustry') ?? '';
    final String description = _safe<String>(business, 'description') ?? '';
    final String companyProfileUrl =
        _safe<String>(business, 'companyProfileUrl') ?? '';
    final String visitingCardUrl =
        _safe<String>(business, 'visitingCardUrl') ?? '';

    final String industryLabel =
        (industryType == 'Other' && customIndustry.isNotEmpty)
            ? customIndustry
            : industryType;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (businessName.isNotEmpty)
            Text(
              businessName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          if (industryLabel.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 8),
              child: Text(
                industryLabel,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.indigo.shade300,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            const SizedBox(height: 6),

          _row(Icons.person, 'Owner', ownerName),
          _row(
            Icons.phone,
            'Contact',
            contactNumber,
            onTap: contactNumber.isNotEmpty
                ? () => onLaunch('tel:$contactNumber')
                : null,
          ),
          _row(
            Icons.email,
            'Email',
            email,
            onTap: email.isNotEmpty ? () => onLaunch('mailto:$email') : null,
          ),
          _row(
            Icons.language,
            'Website',
            website,
            onTap: website.isNotEmpty ? () => onLaunch(website) : null,
          ),
          _row(Icons.home, 'Address', address),
          _row(Icons.location_city, 'District', district),
          _row(Icons.pin_drop, 'Pincode', pincode),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Description',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              description,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 10),
          ],

          if (visitingCardUrl.isNotEmpty || companyProfileUrl.isNotEmpty)
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (visitingCardUrl.isNotEmpty)
                  GestureDetector(
                    onTap: () => showDialog(
                      context: context,
                      builder: (_) => Dialog(
                        child: InteractiveViewer(
                          child: Image.network(visitingCardUrl),
                        ),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        visitingCardUrl,
                        height: 90,
                        width: 130,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          height: 90,
                          width: 130,
                          color: Colors.grey.shade200,
                          alignment: Alignment.center,
                          child: const Icon(Icons.broken_image, size: 20),
                        ),
                      ),
                    ),
                  ),
                if (companyProfileUrl.isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: () => onLaunch(companyProfileUrl),
                    icon: const Icon(Icons.picture_as_pdf, size: 16),
                    label: const Text('Company Profile PDF'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}