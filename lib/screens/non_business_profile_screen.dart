import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Profile screen for Non-Business and Student members.
///
/// Shows exactly what they filled in at registration — Name, Phone,
/// Email, Address, Pincode — and lets them edit everything except the
/// phone number (that's the Firestore doc id and tied to Firebase Auth,
/// so it stays locked here, same pattern as the phone field on the
/// registration screen once it's verified).
class NonBusinessProfileScreen extends StatefulWidget {
  /// Cleaned 10-digit phone number — Firestore doc id.
  final String memberId;

  /// The member doc's data, as already fetched by MemberProfileRouter.
  final Map<String, dynamic> initialData;

  /// "Non-Business" or "Student" — used in the app bar title / headers.
  final String categoryLabel;

  /// Called after a successful save, so the router can refresh its data.
  final VoidCallback? onSaved;

  const NonBusinessProfileScreen({
    super.key,
    required this.memberId,
    required this.initialData,
    required this.categoryLabel,
    this.onSaved,
  });

  @override
  State<NonBusinessProfileScreen> createState() =>
      _NonBusinessProfileScreenState();
}

class _NonBusinessProfileScreenState extends State<NonBusinessProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _pincodeCtrl;

  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  String _field(String key) => (widget.initialData[key] as String?) ?? '';

  void _initControllers() {
    _nameCtrl = TextEditingController(text: _field('name'));
    _phoneCtrl = TextEditingController(
      text: _field('phone').isNotEmpty ? _field('phone') : widget.memberId,
    );
    _emailCtrl = TextEditingController(text: _field('email'));
    _addressCtrl = TextEditingController(text: _field('address'));
    _pincodeCtrl = TextEditingController(text: _field('pincode'));
  }

  void _disposeControllers() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _pincodeCtrl.dispose();
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _enterEditMode() {
    setState(() => _isEditing = true);
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _disposeControllers();
      _initControllers();
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance
          .collection('members')
          .doc(widget.memberId)
          .set({
        'name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'pincode': _pincodeCtrl.text.trim(),
      }, SetOptions(merge: true));

      if (!mounted) return;

      setState(() {
        _isEditing = false;
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );

      widget.onSaved?.call();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save changes: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.categoryLabel} Profile'),
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
              onPressed: _isSaving ? null : _cancelEdit,
            ),
        ],
      ),
      body: _isEditing ? _buildEditForm() : _buildViewMode(),
      floatingActionButton: _isEditing
          ? FloatingActionButton.extended(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save),
              label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
            )
          : null,
    );
  }

  // ---------------------------------------------------------------------
  // VIEW MODE
  // ---------------------------------------------------------------------
  Widget _buildViewMode() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionHeader('${widget.categoryLabel} Details'),
        _infoTile('Name', _nameCtrl.text),
        _infoTile('Phone Number', _phoneCtrl.text),
        _infoTile('Email', _emailCtrl.text),
        _infoTile('Address', _addressCtrl.text),
        _infoTile('Pincode', _pincodeCtrl.text),
        const SizedBox(height: 80),
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
            width: 140,
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

  // ---------------------------------------------------------------------
  // EDIT MODE
  // ---------------------------------------------------------------------
  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          _sectionHeader('${widget.categoryLabel} Details'),
          _textField(
            controller: _nameCtrl,
            label: 'Name',
            validator: _requiredValidator,
          ),
          _textField(
            controller: _phoneCtrl,
            label: 'Phone Number',
            keyboardType: TextInputType.phone,
            enabled: false, // locked: tied to Firebase Auth + doc id
          ),
          _textField(
            controller: _emailCtrl,
            label: 'Email',
            keyboardType: TextInputType.emailAddress,
            validator: _emailValidator,
          ),
          _textField(
            controller: _addressCtrl,
            label: 'Address',
            maxLines: 3,
            validator: _requiredValidator,
          ),
          _textField(
            controller: _pincodeCtrl,
            label: 'Pincode',
            keyboardType: TextInputType.number,
            validator: _pincodeValidator,
          ),
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
        enabled: enabled && !_isSaving,
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
}
