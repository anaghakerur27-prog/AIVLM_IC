import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'business_list_screen.dart';

class SearchBusinessScreen extends StatefulWidget {
  final String? memberId;

  const SearchBusinessScreen({super.key, this.memberId});

  @override
  State<SearchBusinessScreen> createState() => _SearchBusinessScreenState();
}

class _SearchBusinessScreenState extends State<SearchBusinessScreen> {
  String? selectedIndustry;

  String? selectedDistrict;

  bool isLoading = false;

  final TextEditingController otherIndustryController = TextEditingController();

  List<QueryDocumentSnapshot> businessList = [];

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

  Future<void> searchBusiness() async {
    setState(() {
      isLoading = true;
      businessList = [];
    });

    try {
      Query query = FirebaseFirestore.instance.collection('businesses');

      /// Industry Search
      if (selectedIndustry != null && selectedIndustry != 'Other') {
        query = query.where('industryType', isEqualTo: selectedIndustry);
      }

      /// Custom Industry Search
      if (selectedIndustry == 'Other' &&
          otherIndustryController.text.trim().isNotEmpty) {
        query = query.where(
          'customIndustry',
          isEqualTo: otherIndustryController.text.trim(),
        );
      }

      final snapshot = await query.get();

      List<QueryDocumentSnapshot> results = snapshot.docs;

      /// District Filter
      if (selectedDistrict != null && selectedDistrict!.trim().isNotEmpty) {
        results = results.where((doc) {
          final data = doc.data() as Map<String, dynamic>;

          return (data['district'] ?? '').toString().toLowerCase() ==
              selectedDistrict!.toLowerCase();
        }).toList();
      }

      if (!mounted) return;

      setState(() {
        businessList = results;
      });

      if (results.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BusinessListScreen(
              businesses: results,
              memberId: widget.memberId ?? '',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    otherIndustryController.dispose();

    super.dispose();
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            initialValue: selectedIndustry,
            decoration: const InputDecoration(
              labelText: "Industry Type",
              border: OutlineInputBorder(),
            ),
            items: industries.map((industry) {
              return DropdownMenuItem(value: industry, child: Text(industry));
            }).toList(),
            onChanged: isLoading
                ? null
                : (value) {
                    setState(() {
                      selectedIndustry = value;
                    });
                  },
          ),

          const SizedBox(height: 20),

          if (selectedIndustry == 'Other')
            TextField(
              controller: otherIndustryController,
              enabled: !isLoading,
              decoration: const InputDecoration(
                labelText: 'Enter Industry Type',
                border: OutlineInputBorder(),
              ),
            ),

          if (selectedIndustry == 'Other') const SizedBox(height: 20),

          DropdownButtonFormField<String>(
            initialValue: selectedDistrict,
            decoration: const InputDecoration(
              labelText: 'District (Optional)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.location_city),
            ),
            isExpanded: true,
            items: districts.map((district) {
              return DropdownMenuItem(value: district, child: Text(district));
            }).toList(),
            onChanged: isLoading
                ? null
                : (value) {
                    setState(() {
                      selectedDistrict = value;
                    });
                  },
          ),

          const SizedBox(height: 25),

          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: isLoading ? null : searchBusiness,
              child: isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text("SEARCH", style: TextStyle(fontSize: 18)),
            ),
          ),

          const SizedBox(height: 20),

          if (businessList.isNotEmpty == true)
            Text(
              "${businessList.length} Businesses Found",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        /// Your page
        Scaffold(
          appBar: AppBar(
            title: const Text("Search Requirements"),
            centerTitle: true,
          ),
          body: _buildBody(),
        ),

        /// Full-screen loading overlay
        /// - dims the background
        /// - blocks all taps behind it while a search is in progress
        if (isLoading)
          Positioned.fill(
            child: AbsorbPointer(
              absorbing: true,
              child: Container(
                color: Colors.black38,
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
          ),
      ],
    );
  }
}