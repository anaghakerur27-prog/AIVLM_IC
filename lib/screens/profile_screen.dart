import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

/// ---------------------------------------------------------------------
/// MODEL
/// ---------------------------------------------------------------------
/// Holds all the profile fields shown / edited on this screen.
/// Replace this with your real model / API response mapping.
class MemberProfile {
  String memberName;
  String membershipNumber;
  String phoneNumber;
  String businessName;
  String ownerName;
  String contactNumber;
  String email;
  String website;
  String address;
  String district;
  String pincode;
  String industryType;
  String productServiceDescription;

  /// Local file path or a network URL. If it starts with "http" we treat
  /// it as a remote file, otherwise as a local file path.
  String? companyProfilePdfPath;
  String? visitingCardImagePath;

  MemberProfile({
    required this.memberName,
    required this.membershipNumber,
    required this.phoneNumber,
    required this.businessName,
    required this.ownerName,
    required this.contactNumber,
    required this.email,
    required this.website,
    required this.address,
    required this.district,
    required this.pincode,
    required this.industryType,
    required this.productServiceDescription,
    this.companyProfilePdfPath,
    this.visitingCardImagePath,
  });

  MemberProfile copy() => MemberProfile(
    memberName: memberName,
    membershipNumber: membershipNumber,
    phoneNumber: phoneNumber,
    businessName: businessName,
    ownerName: ownerName,
    contactNumber: contactNumber,
    email: email,
    website: website,
    address: address,
    district: district,
    pincode: pincode,
    industryType: industryType,
    productServiceDescription: productServiceDescription,
    companyProfilePdfPath: companyProfilePdfPath,
    visitingCardImagePath: visitingCardImagePath,
  );
}

/// ---------------------------------------------------------------------
/// SCREEN
/// ---------------------------------------------------------------------
class ProfileScreen extends StatefulWidget {
  /// Pass an existing profile in (e.g. fetched from your API).
  /// If null, a sample/empty profile is used for demo purposes.
  final MemberProfile? profile;

  /// Called when the user saves changes. Hook this up to your
  /// API / repository call to persist the data.
  final Future<void> Function(MemberProfile updatedProfile)? onSave;

  const ProfileScreen({super.key, this.profile, this.onSave});

  static const String routeName = '/profile';

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late MemberProfile _profile;
  late MemberProfile _editableProfile; // working copy while editing

  bool _isEditing = false;

  /// True while the profile is being saved. Used to show a spinner
  /// on the Save button and disable inputs during the update.
  bool isLoading = false;

  // Controllers for every editable field
  late TextEditingController _memberNameCtrl;
  late TextEditingController _membershipNumberCtrl;
  late TextEditingController _phoneNumberCtrl;
  late TextEditingController _businessNameCtrl;
  late TextEditingController _ownerNameCtrl;
  late TextEditingController _contactNumberCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _websiteCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _districtCtrl;
  late TextEditingController _pincodeCtrl;
  late TextEditingController _industryTypeCtrl;
  late TextEditingController _productServiceCtrl;

  @override
  void initState() {
    super.initState();
    _profile = widget.profile ?? _sampleProfile();
    _editableProfile = _profile.copy();
    _initControllers();
  }

  MemberProfile _sampleProfile() {
    return MemberProfile(
      memberName: 'Rajesh Kumar',
      membershipNumber: 'MEM-00123',
      phoneNumber: '+91 98765 43210',
      businessName: 'Kumar Enterprises',
      ownerName: 'Rajesh Kumar',
      contactNumber: '+91 98765 43210',
      email: 'rajesh@kumarenterprises.com',
      website: 'www.kumarenterprises.com',
      address: '12, MG Road, Industrial Estate',
      district: 'Bengaluru Urban',
      pincode: '560001',
      industryType: 'Manufacturing',
      productServiceDescription:
          'Manufacturing of precision engineering components and tools.',
      companyProfilePdfPath: null,
      visitingCardImagePath: null,
    );
  }

  void _initControllers() {
    _memberNameCtrl = TextEditingController(text: _editableProfile.memberName);
    _membershipNumberCtrl = TextEditingController(
      text: _editableProfile.membershipNumber,
    );
    _phoneNumberCtrl = TextEditingController(
      text: _editableProfile.phoneNumber,
    );
    _businessNameCtrl = TextEditingController(
      text: _editableProfile.businessName,
    );
    _ownerNameCtrl = TextEditingController(text: _editableProfile.ownerName);
    _contactNumberCtrl = TextEditingController(
      text: _editableProfile.contactNumber,
    );
    _emailCtrl = TextEditingController(text: _editableProfile.email);
    _websiteCtrl = TextEditingController(text: _editableProfile.website);
    _addressCtrl = TextEditingController(text: _editableProfile.address);
    _districtCtrl = TextEditingController(text: _editableProfile.district);
    _pincodeCtrl = TextEditingController(text: _editableProfile.pincode);
    _industryTypeCtrl = TextEditingController(
      text: _editableProfile.industryType,
    );
    _productServiceCtrl = TextEditingController(
      text: _editableProfile.productServiceDescription,
    );
  }

  void _disposeControllers() {
    _memberNameCtrl.dispose();
    _membershipNumberCtrl.dispose();
    _phoneNumberCtrl.dispose();
    _businessNameCtrl.dispose();
    _ownerNameCtrl.dispose();
    _contactNumberCtrl.dispose();
    _emailCtrl.dispose();
    _websiteCtrl.dispose();
    _addressCtrl.dispose();
    _districtCtrl.dispose();
    _pincodeCtrl.dispose();
    _industryTypeCtrl.dispose();
    _productServiceCtrl.dispose();
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  // ---------------------------------------------------------------------
  // EDIT MODE HANDLING
  // ---------------------------------------------------------------------
  void _enterEditMode() {
    setState(() {
      _editableProfile = _profile.copy();
      _disposeControllers();
      _initControllers();
      _isEditing = true;
    });
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _editableProfile = _profile.copy();
      _disposeControllers();
      _initControllers();
    });
  }

  void _syncControllersIntoEditableProfile() {
    _editableProfile.memberName = _memberNameCtrl.text.trim();
    _editableProfile.membershipNumber = _membershipNumberCtrl.text.trim();
    _editableProfile.phoneNumber = _phoneNumberCtrl.text.trim();
    _editableProfile.businessName = _businessNameCtrl.text.trim();
    _editableProfile.ownerName = _ownerNameCtrl.text.trim();
    _editableProfile.contactNumber = _contactNumberCtrl.text.trim();
    _editableProfile.email = _emailCtrl.text.trim();
    _editableProfile.website = _websiteCtrl.text.trim();
    _editableProfile.address = _addressCtrl.text.trim();
    _editableProfile.district = _districtCtrl.text.trim();
    _editableProfile.pincode = _pincodeCtrl.text.trim();
    _editableProfile.industryType = _industryTypeCtrl.text.trim();
    _editableProfile.productServiceDescription = _productServiceCtrl.text
        .trim();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();
    _syncControllersIntoEditableProfile();

    setState(() {
      isLoading = true;
    });

    try {
      if (widget.onSave != null) {
        await widget.onSave!(_editableProfile);
      } else {
        // Simulated network delay when no onSave callback is supplied.
        await Future.delayed(const Duration(milliseconds: 600));
      }

      if (!mounted) return;

      setState(() {
        _profile = _editableProfile.copy();
        _isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save changes: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ---------------------------------------------------------------------
  // FILE PICKERS
  // ---------------------------------------------------------------------
  Future<void> _pickCompanyProfilePdf() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _editableProfile.companyProfilePdfPath = result.files.single.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not select PDF: $e')));
      }
    }
  }

  Future<void> _pickVisitingCardImage() async {
    try {
      final picker = ImagePicker();
      final XFile? picked = await showModalBottomSheet<XFile?>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take a photo'),
                onTap: () async {
                  final file = await picker.pickImage(
                    source: ImageSource.camera,
                  );
                  if (ctx.mounted) Navigator.pop(ctx, file);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from gallery'),
                onTap: () async {
                  final file = await picker.pickImage(
                    source: ImageSource.gallery,
                  );
                  if (ctx.mounted) Navigator.pop(ctx, file);
                },
              ),
            ],
          ),
        ),
      );

      if (picked != null) {
        setState(() {
          _editableProfile.visitingCardImagePath = picked.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not select image: $e')));
      }
    }
  }

  // ---------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Member Profile'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edit Profile',
              onPressed: _enterEditMode,
            )
          else
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Cancel',
              onPressed: isLoading ? null : _cancelEdit,
            ),
        ],
      ),
      body: _isEditing ? _buildEditForm() : _buildViewMode(),
      floatingActionButton: _isEditing
          ? FloatingActionButton.extended(
              onPressed: isLoading ? null : _saveChanges,
              icon: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save),
              label: Text(isLoading ? 'Saving...' : 'Save Changes'),
            )
          : null,
    );
  }

  // ---------------------------------------------------------------------
  // VIEW MODE
  // ---------------------------------------------------------------------
  Widget _buildViewMode() {
    final p = _profile;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionHeader('Membership Details'),
        _infoTile('Member Name', p.memberName),
        _infoTile('Membership Number', p.membershipNumber),
        _infoTile('Phone Number', p.phoneNumber),
        const SizedBox(height: 12),
        _sectionHeader('Business Information'),
        _infoTile('Business Name', p.businessName),
        _infoTile('Owner Name', p.ownerName),
        _infoTile('Contact Number', p.contactNumber),
        _infoTile('Email', p.email),
        _infoTile('Website', p.website),
        _infoTile('Address', p.address),
        _infoTile('District', p.district),
        _infoTile('Pincode', p.pincode),
        _infoTile('Industry Type', p.industryType),
        _infoTile('Product & Service Description', p.productServiceDescription),
        const SizedBox(height: 12),
        _sectionHeader('Documents'),
        _documentPreviewTile(
          label: 'Company Profile (PDF)',
          filePath: p.companyProfilePdfPath,
          icon: Icons.picture_as_pdf,
        ),
        const SizedBox(height: 12),
        _visitingCardPreviewTile(p.visitingCardImagePath),
        const SizedBox(height: 80), // space for content below app bar/fab
      ],
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _documentPreviewTile({
    required String label,
    required String? filePath,
    required IconData icon,
  }) {
    final hasFile = filePath != null && filePath.isNotEmpty;
    return Card(
      child: ListTile(
        leading: Icon(icon, color: hasFile ? Colors.red : Colors.grey),
        title: Text(label),
        subtitle: Text(hasFile ? filePath.split('/').last : 'No file uploaded'),
        trailing: hasFile
            ? const Icon(Icons.check_circle, color: Colors.green)
            : const Icon(Icons.error_outline, color: Colors.grey),
      ),
    );
  }

  Widget _visitingCardPreviewTile(String? imagePath) {
    final hasImage = imagePath != null && imagePath.isNotEmpty;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Visiting Card',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            if (hasImage)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(imagePath),
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stack) => Container(
                    height: 160,
                    color: Colors.grey.shade200,
                    alignment: Alignment.center,
                    child: const Text('Unable to load image'),
                  ),
                ),
              )
            else
              Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: const Text('No visiting card uploaded'),
              ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // EDIT MODE
  // ---------------------------------------------------------------------
  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          _sectionHeader('Membership Details'),
          _textField(
            controller: _memberNameCtrl,
            label: 'Member Name',
            validator: _requiredValidator,
            enabled: !isLoading,
          ),
          _textField(
            controller: _membershipNumberCtrl,
            label: 'Membership Number',
            enabled: false, // typically not user-editable
          ),
          _textField(
            controller: _phoneNumberCtrl,
            label: 'Phone Number',
            keyboardType: TextInputType.phone,
            validator: _requiredValidator,
            enabled: !isLoading,
          ),
          const SizedBox(height: 12),
          _sectionHeader('Business Information'),
          _textField(
            controller: _businessNameCtrl,
            label: 'Business Name',
            validator: _requiredValidator,
            enabled: !isLoading,
          ),
          _textField(
            controller: _ownerNameCtrl,
            label: 'Owner Name',
            validator: _requiredValidator,
            enabled: !isLoading,
          ),
          _textField(
            controller: _contactNumberCtrl,
            label: 'Contact Number',
            keyboardType: TextInputType.phone,
            validator: _requiredValidator,
            enabled: !isLoading,
          ),
          _textField(
            controller: _emailCtrl,
            label: 'Email',
            keyboardType: TextInputType.emailAddress,
            validator: _emailValidator,
            enabled: !isLoading,
          ),
          _textField(
            controller: _websiteCtrl,
            label: 'Website',
            keyboardType: TextInputType.url,
            enabled: !isLoading,
          ),
          _textField(
            controller: _addressCtrl,
            label: 'Address',
            maxLines: 2,
            validator: _requiredValidator,
            enabled: !isLoading,
          ),
          _textField(
            controller: _districtCtrl,
            label: 'District',
            validator: _requiredValidator,
            enabled: !isLoading,
          ),
          _textField(
            controller: _pincodeCtrl,
            label: 'Pincode',
            keyboardType: TextInputType.number,
            validator: _pincodeValidator,
            enabled: !isLoading,
          ),
          _textField(
            controller: _industryTypeCtrl,
            label: 'Industry Type',
            validator: _requiredValidator,
            enabled: !isLoading,
          ),
          _textField(
            controller: _productServiceCtrl,
            label: 'Product & Service Description',
            maxLines: 4,
            enabled: !isLoading,
          ),
          const SizedBox(height: 12),
          _sectionHeader('Documents'),
          _replaceFileTile(
            label: 'Company Profile (PDF)',
            filePath: _editableProfile.companyProfilePdfPath,
            icon: Icons.picture_as_pdf,
            buttonLabel: 'Replace PDF',
            onTap: isLoading ? null : _pickCompanyProfilePdf,
          ),
          const SizedBox(height: 12),
          _replaceImageTile(),
        ],
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          filled: !enabled,
          fillColor: enabled ? null : Colors.grey.shade100,
        ),
      ),
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  String? _emailValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    final emailRegex = RegExp(r'^[\w\.\-]+@[\w\-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _pincodeValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    if (!RegExp(r'^\d{4,10}$').hasMatch(value.trim())) {
      return 'Enter a valid pincode';
    }
    return null;
  }

  Widget _replaceFileTile({
    required String label,
    required String? filePath,
    required IconData icon,
    required String buttonLabel,
    required VoidCallback? onTap,
  }) {
    final hasFile = filePath != null && filePath.isNotEmpty;
    return Card(
      child: ListTile(
        leading: Icon(icon, color: hasFile ? Colors.red : Colors.grey),
        title: Text(label),
        subtitle: Text(hasFile ? filePath.split('/').last : 'No file uploaded'),
        trailing: TextButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.cloud_upload),
          label: Text(buttonLabel),
        ),
      ),
    );
  }

  Widget _replaceImageTile() {
    final imagePath = _editableProfile.visitingCardImagePath;
    final hasImage = imagePath != null && imagePath.isNotEmpty;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Visiting Card',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                TextButton.icon(
                  onPressed: isLoading ? null : _pickVisitingCardImage,
                  icon: const Icon(Icons.photo_camera),
                  label: const Text('Replace Image'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (hasImage)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(imagePath),
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stack) => Container(
                    height: 160,
                    color: Colors.grey.shade200,
                    alignment: Alignment.center,
                    child: const Text('Unable to load image'),
                  ),
                ),
              )
            else
              Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: const Text('No visiting card uploaded'),
              ),
          ],
        ),
      ),
    );
  }
}
