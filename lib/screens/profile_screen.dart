import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Business profile data.
/// Document fields contain local paths before upload and Firebase Storage
/// download URLs after a successful save.
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

  MemberProfile copy() {
    return MemberProfile(
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
}

class ProfileScreen extends StatefulWidget {
  final MemberProfile? profile;
  final Future<void> Function(MemberProfile updatedProfile)? onSave;

  const ProfileScreen({
    super.key,
    this.profile,
    this.onSave,
  });

  static const String routeName = '/profile';

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late MemberProfile _profile;
  late MemberProfile _editableProfile;

  bool _isEditing = false;
  bool isLoading = false;

  late final TextEditingController _memberNameCtrl;
  late final TextEditingController _membershipNumberCtrl;
  late final TextEditingController _phoneNumberCtrl;
  late final TextEditingController _businessNameCtrl;
  late final TextEditingController _ownerNameCtrl;
  late final TextEditingController _contactNumberCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _websiteCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _districtCtrl;
  late final TextEditingController _pincodeCtrl;
  late final TextEditingController _industryTypeCtrl;
  late final TextEditingController _productServiceCtrl;

  @override
  void initState() {
    super.initState();

    // Never show fabricated sample member details.
    _profile = widget.profile?.copy() ?? _emptyProfile();
    _editableProfile = _profile.copy();

    _memberNameCtrl = TextEditingController();
    _membershipNumberCtrl = TextEditingController();
    _phoneNumberCtrl = TextEditingController();
    _businessNameCtrl = TextEditingController();
    _ownerNameCtrl = TextEditingController();
    _contactNumberCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _websiteCtrl = TextEditingController();
    _addressCtrl = TextEditingController();
    _districtCtrl = TextEditingController();
    _pincodeCtrl = TextEditingController();
    _industryTypeCtrl = TextEditingController();
    _productServiceCtrl = TextEditingController();

    _fillControllers(_editableProfile);
  }

  MemberProfile _emptyProfile() {
    return MemberProfile(
      memberName: '',
      membershipNumber: '',
      phoneNumber: '',
      businessName: '',
      ownerName: '',
      contactNumber: '',
      email: '',
      website: '',
      address: '',
      district: '',
      pincode: '',
      industryType: '',
      productServiceDescription: '',
    );
  }

  void _fillControllers(MemberProfile profile) {
    _memberNameCtrl.text = profile.memberName;
    _membershipNumberCtrl.text = profile.membershipNumber;
    _phoneNumberCtrl.text = profile.phoneNumber;
    _businessNameCtrl.text = profile.businessName;
    _ownerNameCtrl.text = profile.ownerName;
    _contactNumberCtrl.text = profile.contactNumber;
    _emailCtrl.text = profile.email;
    _websiteCtrl.text = profile.website;
    _addressCtrl.text = profile.address;
    _districtCtrl.text = profile.district;
    _pincodeCtrl.text = profile.pincode;
    _industryTypeCtrl.text = profile.industryType;
    _productServiceCtrl.text = profile.productServiceDescription;
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.profile != null && widget.profile != oldWidget.profile) {
      _profile = widget.profile!.copy();
      _editableProfile = _profile.copy();
      _fillControllers(_editableProfile);
      _isEditing = false;
    }
  }

  @override
  void dispose() {
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

    super.dispose();
  }

  void _enterEditMode() {
    setState(() {
      _editableProfile = _profile.copy();
      _fillControllers(_editableProfile);
      _isEditing = true;
    });
  }

  void _cancelEdit() {
    setState(() {
      _editableProfile = _profile.copy();
      _fillControllers(_editableProfile);
      _isEditing = false;
    });
  }

  void _syncFormToProfile() {
    _editableProfile
      ..memberName = _memberNameCtrl.text.trim()
      ..businessName = _businessNameCtrl.text.trim()
      ..ownerName = _ownerNameCtrl.text.trim()
      ..contactNumber = _contactNumberCtrl.text.trim()
      ..email = _emailCtrl.text.trim()
      ..website = _websiteCtrl.text.trim()
      ..address = _addressCtrl.text.trim()
      ..district = _districtCtrl.text.trim()
      ..pincode = _pincodeCtrl.text.trim()
      ..industryType = _industryTypeCtrl.text.trim()
      ..productServiceDescription = _productServiceCtrl.text.trim();

    // Membership number and registered phone number remain unchanged.
  }

  Future<void> _saveChanges() async {
    if (isLoading) return;

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    _syncFormToProfile();

    setState(() {
      isLoading = true;
    });

    try {
      final save = widget.onSave;

      if (save == null) {
        throw Exception('Profile saving is not configured.');
      }

      await save(_editableProfile);

      if (!mounted) return;

      setState(() {
        _profile = _editableProfile.copy();
        _isEditing = false;
      });

      _showMessage('Profile updated successfully');
    } catch (e) {
      _showMessage('Failed to save changes: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  /// Select a PDF using the file_picker static API.
  /// FilePicker.pickFiles returns a FilePickerResult?, and the selected
  /// files are in its `.files` list.
  Future<void> _pickCompanyProfilePdf() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      // Handle cancellation or an empty selection.
      if (result == null || result.files.isEmpty) {
        return;
      }

      final path = result.files.first.path;

      if (path == null || path.isEmpty) {
        throw Exception('Could not access selected PDF.');
      }

      if (!mounted) return;

      setState(() {
        _editableProfile.companyProfilePdfPath = path;
      });
    } catch (e) {
      _showMessage('Could not select PDF: $e');
    }
  }

  /// Select a visiting card image from camera or gallery.
  Future<void> _pickVisitingCardImage() async {
    try {
      final picker = ImagePicker();

      final XFile? picked = await showModalBottomSheet<XFile?>(
        context: context,
        builder: (ctx) {
          Future<void> choose(ImageSource source) async {
            try {
              final file = await picker.pickImage(source: source);

              if (ctx.mounted) {
                Navigator.pop(ctx, file);
              }
            } catch (e) {
              if (ctx.mounted) {
                Navigator.pop(ctx);
              }
              _showMessage('Could not select image: $e');
            }
          }

          return SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_camera),
                  title: const Text('Take a photo'),
                  onTap: () => choose(ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Choose from gallery'),
                  onTap: () => choose(ImageSource.gallery),
                ),
              ],
            ),
          );
        },
      );

      if (picked == null || picked.path.isEmpty || !mounted) {
        return;
      }

      setState(() {
        _editableProfile.visitingCardImagePath = picked.path;
      });
    } catch (e) {
      _showMessage('Could not select image: $e');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  bool _isUrl(String? path) {
    if (path == null || path.isEmpty) return false;

    return path.startsWith('https://') || path.startsWith('http://');
  }

  String _displayFileName(String path) {
    return path.split('?').first.split('/').last;
  }

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
              onPressed: isLoading ? null : _enterEditMode,
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
              label: Text(
                isLoading ? 'Saving...' : 'Save Changes',
              ),
            )
          : null,
    );
  }

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
        _infoTile(
          'Product & Service Description',
          p.productServiceDescription,
        ),

        const SizedBox(height: 12),

        _sectionHeader('Documents'),

        _documentTile(
          label: 'Company Profile (PDF)',
          path: p.companyProfilePdfPath,
          icon: Icons.picture_as_pdf,
        ),

        const SizedBox(height: 12),

        _visitingCardTile(
          p.visitingCardImagePath,
          editable: false,
        ),

        const SizedBox(height: 80),
      ],
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 8,
        top: 4,
      ),
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
            child: Text(value.isEmpty ? '-' : value),
          ),
        ],
      ),
    );
  }

  Widget _documentTile({
    required String label,
    required String? path,
    required IconData icon,
  }) {
    final bool exists = path != null && path.isNotEmpty;

    return Card(
      child: ListTile(
        leading: Icon(
          icon,
          color: exists ? Colors.red : Colors.grey,
        ),
        title: Text(label),
        subtitle: Text(
          exists ? _displayFileName(path) : 'No file uploaded',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Icon(
          exists ? Icons.check_circle : Icons.error_outline,
          color: exists ? Colors.green : Colors.grey,
        ),
      ),
    );
  }

  Widget _imageError(double height) {
    return Container(
      height: height,
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: const Text('Unable to load image'),
    );
  }

  Widget _image(String path, double height) {
    final Widget image;

    if (_isUrl(path)) {
      image = Image.network(
        path,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _imageError(height);
        },
      );
    } else {
      image = Image.file(
        File(path),
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _imageError(height);
        },
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: image,
    );
  }

  Widget _visitingCardTile(
    String? path, {
    required bool editable,
  }) {
    final bool exists = path != null && path.isNotEmpty;

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
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (editable)
                  TextButton.icon(
                    onPressed: isLoading ? null : _pickVisitingCardImage,
                    icon: const Icon(Icons.photo_camera),
                    label: const Text('Replace Image'),
                  ),
              ],
            ),

            const SizedBox(height: 8),

            if (exists)
              _image(path, 160)
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

  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          _sectionHeader('Membership Details'),

          _field(
            _memberNameCtrl,
            'Member Name',
            validator: _required,
          ),

          _field(
            _membershipNumberCtrl,
            'Membership Number',
            enabled: false,
          ),

          _field(
            _phoneNumberCtrl,
            'Phone Number',
            keyboardType: TextInputType.phone,
            enabled: false,
          ),

          const SizedBox(height: 12),

          _sectionHeader('Business Information'),

          _field(
            _businessNameCtrl,
            'Business Name',
            validator: _required,
          ),

          _field(
            _ownerNameCtrl,
            'Owner Name',
            validator: _required,
          ),

          _field(
            _contactNumberCtrl,
            'Contact Number',
            keyboardType: TextInputType.phone,
            validator: _required,
          ),

          _field(
            _emailCtrl,
            'Email',
            keyboardType: TextInputType.emailAddress,
            validator: _email,
          ),

          _field(
            _websiteCtrl,
            'Website',
            keyboardType: TextInputType.url,
          ),

          _field(
            _addressCtrl,
            'Address',
            maxLines: 2,
            validator: _required,
          ),

          _field(
            _districtCtrl,
            'District',
            validator: _required,
          ),

          _field(
            _pincodeCtrl,
            'Pincode',
            keyboardType: TextInputType.number,
            validator: _pincode,
          ),

          _field(
            _industryTypeCtrl,
            'Industry Type',
            validator: _required,
          ),

          _field(
            _productServiceCtrl,
            'Product & Service Description',
            maxLines: 4,
          ),

          const SizedBox(height: 12),

          _sectionHeader('Documents'),

          _documentTile(
            label: 'Company Profile (PDF)',
            path: _editableProfile.companyProfilePdfPath,
            icon: Icons.picture_as_pdf,
          ),

          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: isLoading ? null : _pickCompanyProfilePdf,
              icon: const Icon(Icons.cloud_upload),
              label: const Text('Select / Replace PDF'),
            ),
          ),

          _visitingCardTile(
            _editableProfile.visitingCardImagePath,
            editable: true,
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controller,
        enabled: enabled && !isLoading,
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

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }

    return null;
  }

  String? _email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }

    final valid = RegExp(
      r'^[\w.\-]+@[\w\-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(value.trim());

    return valid ? null : 'Enter a valid email address';
  }

  String? _pincode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }

    return RegExp(r'^\d{4,10}$').hasMatch(value.trim())
        ? null
        : 'Enter a valid pincode';
  }
}