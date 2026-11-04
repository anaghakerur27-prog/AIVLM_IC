
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SearchBusinessScreen extends StatefulWidget {
  final String? memberId;

  const SearchBusinessScreen({super.key, this.memberId});

  @override
  State<SearchBusinessScreen> createState() =>
      _SearchBusinessScreenState();
}

class SearchResult {
  final String id;
  final String resultType; // Profile or Enquiry
  final String memberType;
  final Map<String, dynamic> data;
  final Map<String, dynamic> memberData;

  const SearchResult({
    required this.id,
    required this.resultType,
    required this.memberType,
    required this.data,
    this.memberData = const {},
  });
}

class _SearchBusinessScreenState extends State<SearchBusinessScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController keywordController = TextEditingController();
  final TextEditingController otherIndustryController =
      TextEditingController();

  String? selectedIndustry;
  String? selectedDistrict;

  String selectedMemberType = 'All';
  String selectedResultType = 'All';
  String selectedSort = 'Latest first';

  bool isLoading = false;
  bool hasSearched = false;

  List<SearchResult> searchResults = [];

  final List<String> industries = [
    'Manufacturing',
    'Automobile & Auto Components',
    'Engineering & Fabrication',
    'Foundries & Castings',
    'Textile & Garments',
    'Food Processing & Beverages',
    'Pharmaceuticals',
    'Chemicals & Paints',
    'Plastics & Polymers',
    'Rubber Products',
    'Electrical & Electronics',
    'IT Hardware & Electronics Manufacturing',
    'Aerospace & Defence',
    'Machine Tools',
    'Packaging Industry',
    'Printing & Packaging',
    'Paper & Paper Products',
    'Steel & Metal Processing',
    'Aluminium & Copper Industries',
    'Cement & Building Materials',
    'Ceramic & Tiles',
    'Glass Manufacturing',
    'Warehouses & Logistics Parks',
    'Cold Storage Facilities',
    'Hotels & Resorts',
    'Hospitals & Healthcare',
    'Educational Institutions',
    'Shopping Malls & Retail Chains',
    'Apartment Complexes & Gated Communities',
    'Commercial Office Buildings',
    'Data Centres',
    'Agriculture Processing Units',
    'Dairy & Poultry Farms',
    'Rice, Flour & Oil Mills',
    'Breweries & Distilleries',
    'Renewable Energy Equipment Manufacturers',
    'MSMEs & Industrial Estates',
    'Other',
  ];

  final List<String> districts = [
    'Bagalkote',
    'Ballari',
    'Belagavi',
    'Bengaluru Rural',
    'Bengaluru Urban',
    'Bidar',
    'Chamarajanagar',
    'Chikkaballapur',
    'Chikkamagaluru',
    'Chitradurga',
    'Dakshina Kannada',
    'Davanagere',
    'Dharwad',
    'Gadag',
    'Hassan',
    'Haveri',
    'Kalaburagi',
    'Kodagu',
    'Kolar',
    'Koppal',
    'Mandya',
    'Mysuru',
    'Raichur',
    'Ramanagara',
    'Shivamogga',
    'Tumakuru',
    'Udupi',
    'Uttara Kannada',
    'Vijayapura',
    'Vijayanagara',
    'Yadgir',
  ];

  String _value(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return '';
  }

  String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .trim();
  }

  String _memberType(Map<String, dynamic> data) {
    final raw = _normalize(
      _value(data, ['memberType', 'userType', 'type']),
    );

    if (raw == 'business') return 'Business';
    if (raw == 'student') return 'Student';

    if (raw == 'non business' ||
        raw == 'nonbusiness' ||
        raw == 'non business member') {
      return 'Non-Business';
    }

    return raw.isEmpty ? 'Member' : raw;
  }

  String _memberName(Map<String, dynamic> data) {
    return _value(data, [
      'name',
      'memberName',
      'fullName',
      'ownerName',
      'businessName',
      'studentName',
    ]);
  }

  String _memberNumber(Map<String, dynamic> data) {
    return _value(data, [
      'membershipNumber',
      'memberNumber',
      'memberId',
      'membershipId',
    ]);
  }

  String _industry(Map<String, dynamic> data) {
    return _value(data, [
      'customIndustry',
      'industryType',
      'industry',
      'businessIndustry',
      'industryName',
      'businessType',
      'sector',
      'occupation',
      'fieldOfStudy',
      'course',
    ]);
  }

  String _district(Map<String, dynamic> data) {
    return _value(data, [
      'district',
      'businessDistrict',
      'locationDistrict',
    ]);
  }

  DateTime? _dateValue(Map<String, dynamic> data) {
    final value = data['createdAt'] ??
        data['postedAt'] ??
        data['registrationDate'] ??
        data['updatedAt'];

    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;

    return null;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Date not available';

    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');

    return '$day-$month-${local.year}';
  }

  bool _isActive(Map<String, dynamic> data) {
    // Exclude explicitly inactive records.
    // Records without an active field are retained.
    return data['active'] != false;
  }

  bool _matchesIndustry(Map<String, dynamic> data) {
    if (selectedIndustry == null) return true;

    final industry = _normalize(_industry(data));

    if (selectedIndustry == 'Other') {
      final custom = _normalize(otherIndustryController.text);

      if (custom.isNotEmpty) {
        return industry.contains(custom) ||
            _normalize(_value(data, [
              'customIndustry',
              'industry',
              'industryType',
            ]))
                .contains(custom);
      }

      return _normalize(_value(data, ['industryType'])) == 'other' ||
          _normalize(_value(data, ['industry'])) == 'other';
    }

    final selected = _normalize(selectedIndustry!);

    return industry == selected ||
        industry.contains(selected) ||
        selected.contains(industry);
  }

  bool _matchesKeywords(Map<String, dynamic> data) {
    final query = keywordController.text.trim().toLowerCase();

    if (query.isEmpty) return true;

    // Search relevant profile and enquiry information.
    // Contact details are intentionally excluded from keyword matching.
    const excludedKeys = {
      'phone',
      'phoneNumber',
      'mobile',
      'mobileNumber',
      'contactNumber',
      'email',
      'emailId',
      'mailId',
      'address',
      'residentialAddress',
      'businessAddress',
      'password',
      'otp',
    };

    final searchableValues = <String>[];

    void collect(Map<String, dynamic> source) {
      for (final entry in source.entries) {
        if (excludedKeys.contains(entry.key)) continue;

        final value = entry.value;

        if (value == null || value is Timestamp) continue;

        if (value is String ||
            value is num ||
            value is bool) {
          searchableValues.add(value.toString().toLowerCase());
        } else if (value is List) {
          searchableValues.add(
            value.map((item) => item.toString()).join(' ').toLowerCase(),
          );
        }
      }
    }

    collect(data);

    final searchableText = searchableValues.join(' ');
    final terms = query.split(RegExp(r'\s+'));

    return terms.every((term) => searchableText.contains(term));
  }

  bool _matchesDistrict(Map<String, dynamic> data) {
    if (selectedDistrict == null) return true;

    return _normalize(_district(data)) ==
        _normalize(selectedDistrict!);
  }

  bool _matchesFilters(SearchResult result) {
    if (selectedMemberType != 'All' &&
        result.memberType != selectedMemberType) {
      return false;
    }

    if (selectedResultType != 'All' &&
        result.resultType != selectedResultType) {
      return false;
    }

    final combinedData = {
      ...result.memberData,
      ...result.data,
    };

    if (!_matchesDistrict(combinedData)) return false;

    return true;
  }

  Future<void> searchBusiness() async {
    if (selectedIndustry == 'Other' &&
        otherIndustryController.text.trim().isEmpty &&
        keywordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter an industry name or keyword to search.'),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
      hasSearched = true;
      searchResults = [];
    });

    try {
      // Search all three collections.
      // No memberId restriction is applied.
      final snapshots = await Future.wait([
        _firestore.collection('businesses').get(),
        _firestore.collection('members').get(),
        _firestore.collection('enquiries').get(),
      ]);

final businessSnapshot = snapshots[0];
final memberSnapshot = snapshots[1];
final enquirySnapshot = snapshots[2];

      final memberMap = <String, Map<String, dynamic>>{};

      for (final doc in memberSnapshot.docs) {
        memberMap[doc.id] = doc.data();
      }

      final List<SearchResult> results = [];

      // --------------------------------------------------
      // 1. BUSINESS PROFILES
      // --------------------------------------------------
      for (final doc in businessSnapshot.docs) {
        final data = doc.data();

        if (!_isActive(data)) continue;
        if (!_matchesIndustry(data)) continue;
        if (!_matchesKeywords(data)) continue;

        final linkedMemberId = _value(data, [
          'memberId',
          'memberDocumentId',
          'ownerMemberId',
        ]);

        final linkedMember = memberMap[linkedMemberId] ?? {};

        results.add(
          SearchResult(
            id: doc.id,
            resultType: 'Profile',
            memberType: 'Business',
            data: data,
            memberData: linkedMember,
          ),
        );
      }

      // --------------------------------------------------
      // 2. NON-BUSINESS AND STUDENT MEMBER PROFILES
      // --------------------------------------------------
      for (final doc in memberSnapshot.docs) {
        final data = doc.data();

        if (!_isActive(data)) continue;

        final type = _memberType(data);

        // Business profiles are sourced from businesses.
        // Avoid showing the same Business member twice.
        if (type == 'Business') continue;

        if (type != 'Student' && type != 'Non-Business') {
          continue;
        }

        if (!_matchesIndustry(data)) continue;
        if (!_matchesKeywords(data)) continue;

        results.add(
          SearchResult(
            id: doc.id,
            resultType: 'Profile',
            memberType: type,
            data: data,
          ),
        );
      }

      // --------------------------------------------------
      // 3. ENQUIRIES FROM ALL MEMBER TYPES
      // --------------------------------------------------
      for (final doc in enquirySnapshot.docs) {
        final data = doc.data();

        if (!_matchesIndustry(data)) continue;
        if (!_matchesKeywords(data)) continue;

        final authorDocumentId = _value(data, ['memberId']);
        final authorData = memberMap[authorDocumentId] ?? {};

        final type = _memberType({
          ...authorData,
          ...data,
        });

        results.add(
          SearchResult(
            id: doc.id,
            resultType: 'Enquiry',
            memberType: type,
            data: data,
            memberData: authorData,
          ),
        );
      }

      // Apply filters after collecting records from all collections.
      final filteredResults =
          results.where(_matchesFilters).toList();

      // Sort the combined results.
      filteredResults.sort((a, b) {
        if (selectedSort == 'Alphabetical') {
          final nameA = _memberName({
            ...a.memberData,
            ...a.data,
          }).toLowerCase();

          final nameB = _memberName({
            ...b.memberData,
            ...b.data,
          }).toLowerCase();

          return nameA.compareTo(nameB);
        }

        final dateA = _dateValue(a.data) ??
            _dateValue(a.memberData) ??
            DateTime(2000);

        final dateB = _dateValue(b.data) ??
            _dateValue(b.memberData) ??
            DateTime(2000);

        return selectedSort == 'Oldest first'
            ? dateA.compareTo(dateB)
            : dateB.compareTo(dateA);
      });

      if (!mounted) return;

      setState(() {
        searchResults = filteredResults;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to search records: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Widget _detailRow(
    String label,
    String value, {
    IconData? icon,
  }) {
    if (value.trim().isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 17, color: Colors.blueGrey),
            const SizedBox(width: 7),
          ],
          SizedBox(
            width: 105,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(child: SelectableText(value)),
        ],
      ),
    );
  }

  Widget _resultCard(SearchResult result) {
    final data = result.data;
    final memberData = result.memberData;

    final combined = {
      ...memberData,
      ...data,
    };

    final name = _memberName(combined);
    final memberNumber = _memberNumber(combined);
    final industry = _industry(combined);
    final district = _district(combined);

    final isOwnRecord = widget.memberId != null &&
        widget.memberId!.isNotEmpty &&
        _value(data, ['memberId']) == widget.memberId;

    final title = result.resultType == 'Enquiry'
        ? _value(data, ['enquiryTitle', 'title']).isNotEmpty
            ? _value(data, ['enquiryTitle', 'title'])
            : 'Enquiry'
        : _value(data, [
            'businessName',
            'name',
            'memberName',
            'fullName',
          ]).isNotEmpty
            ? _value(data, [
                'businessName',
                'name',
                'memberName',
                'fullName',
              ])
            : name.isNotEmpty
                ? name
                : 'Member Profile';

    final description = _value(data, [
      'enquiryDescription',
      'description',
      'businessDescription',
      'about',
      'details',
      'products',
      'services',
    ]);

    final date = _dateValue(data) ?? _dateValue(memberData);

    final phone = _value(combined, [
      'phone',
      'phoneNumber',
      'mobile',
      'mobileNumber',
      'contactNumber',
    ]);

    final email = _value(combined, [
      'email',
      'emailId',
      'mailId',
    ]);

    final address = _value(combined, [
      'address',
      'businessAddress',
      'residentialAddress',
    ]);

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 7,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(
          15,
          0,
          15,
          15,
        ),
        leading: CircleAvatar(
          backgroundColor: result.resultType == 'Enquiry'
              ? Colors.orange.shade100
              : Colors.blue.shade100,
          child: Icon(
            result.resultType == 'Enquiry'
                ? Icons.campaign_outlined
                : Icons.person_outline,
            color: result.resultType == 'Enquiry'
                ? Colors.deepOrange
                : Colors.blue,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Wrap(
            spacing: 6,
            runSpacing: 5,
            children: [
              Chip(
                label: Text(result.memberType),
                visualDensity: VisualDensity.compact,
              ),
              Chip(
                label: Text(result.resultType),
                visualDensity: VisualDensity.compact,
              ),
              if (isOwnRecord)
                const Chip(
                  label: Text('My Record'),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ),
        children: [
          const Divider(),

          _detailRow(
            'Member Name',
            name.isEmpty ? 'Not available' : name,
            icon: Icons.person_outline,
          ),
          _detailRow(
            'Member ID',
            memberNumber.isNotEmpty
                ? memberNumber
                : 'Not available',
            icon: Icons.badge_outlined,
          ),
          _detailRow(
            'Member Type',
            result.memberType,
            icon: Icons.people_outline,
          ),
          _detailRow(
            'Industry',
            industry,
            icon: Icons.business_outlined,
          ),
          _detailRow(
            'District',
            district,
            icon: Icons.location_city_outlined,
          ),

          if (description.isNotEmpty)
            _detailRow(
              result.resultType == 'Enquiry'
                  ? 'Description'
                  : 'Details',
              description,
              icon: Icons.description_outlined,
            ),

          _detailRow(
            'Phone',
            phone,
            icon: Icons.phone_outlined,
          ),
          _detailRow(
            'Email',
            email,
            icon: Icons.email_outlined,
          ),
          _detailRow(
            'Address',
            address,
            icon: Icons.location_on_outlined,
          ),
          _detailRow(
            result.resultType == 'Enquiry'
                ? 'Posted On'
                : 'Date',
            _formatDate(date),
            icon: Icons.calendar_today_outlined,
          ),

          // Display other useful business fields when available.
          if (result.memberType == 'Business') ...[
            _detailRow(
              'Owner',
              _value(combined, ['ownerName', 'proprietorName']),
            ),
            _detailRow(
              'GST Number',
              _value(combined, ['gstNumber', 'gst']),
            ),
            _detailRow(
              'Website',
              _value(combined, ['website', 'websiteUrl']),
            ),
            _detailRow(
              'Approval Status',
              _value(combined, ['approvalStatus']),
            ),
          ],
        ],
      ),
    );
  }

  Widget _dropdown<T>({
    required String label,
    required T value,
    required List<T> values,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: values.map((item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(item.toString()),
        );
      }).toList(),
      onChanged: isLoading ? null : onChanged,
    );
  }

  Widget _buildFilters() {
    return Column(
      children: [
        _dropdown<String?>(
          label: 'Industry Type',
          value: selectedIndustry,
          values: [null, ...industries],
          onChanged: (value) {
            setState(() => selectedIndustry = value);
          },
        ),

        if (selectedIndustry == 'Other') ...[
          const SizedBox(height: 14),
          TextField(
            controller: otherIndustryController,
            enabled: !isLoading,
            decoration: const InputDecoration(
              labelText: 'Enter Industry Name',
              border: OutlineInputBorder(),
            ),
          ),
        ],

        const SizedBox(height: 14),

        TextField(
          controller: keywordController,
          enabled: !isLoading,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => searchBusiness(),
          decoration: const InputDecoration(
            labelText: 'Search by keyword',
            hintText: 'Example: automobile, fabrication, machinery',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
        ),

        const SizedBox(height: 14),

        _dropdown<String?>(
          label: 'District',
          value: selectedDistrict,
          values: [null, ...districts],
          onChanged: (value) {
            setState(() => selectedDistrict = value);
          },
        ),

        const SizedBox(height: 14),

        _dropdown<String>(
          label: 'Member Type',
          value: selectedMemberType,
          values: [
            'All',
            'Business',
            'Non-Business',
            'Student',
          ],
          onChanged: (value) {
            setState(() {
              selectedMemberType = value ?? 'All';
            });
          },
        ),

        const SizedBox(height: 14),

        _dropdown<String>(
          label: 'Result Type',
          value: selectedResultType,
          values: ['All', 'Profile', 'Enquiry'],
          onChanged: (value) {
            setState(() {
              selectedResultType = value ?? 'All';
            });
          },
        ),

        const SizedBox(height: 14),

        _dropdown<String>(
          label: 'Sort By',
          value: selectedSort,
          values: [
            'Latest first',
            'Oldest first',
            'Alphabetical',
          ],
          onChanged: (value) {
            setState(() {
              selectedSort = value ?? 'Latest first';
            });
          },
        ),

        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: isLoading ? null : searchBusiness,
            icon: const Icon(Icons.search),
            label: const Text(
              'SEARCH ALL MEMBERS',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResults() {
    if (!hasSearched || isLoading) {
      return const SizedBox.shrink();
    }

    if (searchResults.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 35),
        child: Column(
          children: [
            Icon(
              Icons.search_off,
              size: 55,
              color: Colors.grey,
            ),
            SizedBox(height: 12),
            Text(
              'No matching members or enquiries found.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Try another industry, keyword, or district.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final profileCount = searchResults
        .where((item) => item.resultType == 'Profile')
        .length;

    final enquiryCount = searchResults
        .where((item) => item.resultType == 'Enquiry')
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${searchResults.length} Matching Results',
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$profileCount Profiles  •  $enquiryCount Enquiries',
          style: TextStyle(color: Colors.grey.shade700),
        ),
        const SizedBox(height: 14),
        ...searchResults.map(_resultCard),
      ],
    );
  }

  @override
  void dispose() {
    keywordController.dispose();
    otherIndustryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Industry Search'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Search Across All Member Types',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Find Business, Non-Business and Student members, '
                  'along with enquiries related to an industry.',
                ),
                const SizedBox(height: 20),

                _buildFilters(),

                const SizedBox(height: 25),

                _buildResults(),
              ],
            ),
          ),

          if (isLoading)
            Positioned.fill(
              child: AbsorbPointer(
                child: Container(
                  color: Colors.black26,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
