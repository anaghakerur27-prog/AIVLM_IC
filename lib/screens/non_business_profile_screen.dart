import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Profile screen for Non-Business and Student members.
/// Phone is read-only because it identifies the member document and login.
class NonBusinessProfileScreen extends StatefulWidget {
  final String memberId;
  final Map<String, dynamic> initialData;
  final String categoryLabel;
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
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _addressCtrl;
  bool _isEditing = false;
  bool _isSaving = false;

  String _value(String key) {
    final value = widget.initialData[key];
    return value == null ? '' : value.toString();
  }

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _addressCtrl = TextEditingController();
    _loadData();
  }

  void _loadData() {
    _nameCtrl.text = _value('name');
    final phone = _value('phone');
    _phoneCtrl.text = phone.isNotEmpty ? phone : widget.memberId;
    _emailCtrl.text = _value('email');
    _addressCtrl.text = _value('address');
  }

  @override
  void didUpdateWidget(covariant NonBusinessProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.memberId != widget.memberId ||
        oldWidget.initialData != widget.initialData) {
      _loadData();
      _isEditing = false;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  void _cancelEdit() {
    setState(() {
      _loadData();
      _isEditing = false;
    });
  }

  Future<void> _save() async {
    if (_isSaving || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance
          .collection('members')
          .doc(widget.memberId)
          .set({
        'name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
      widget.onSaved?.call();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save changes: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
              onPressed: () => setState(() => _isEditing = true),
            )
          else
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Cancel',
              onPressed: _isSaving ? null : _cancelEdit,
            ),
        ],
      ),
      body: _isEditing ? _editForm() : _viewProfile(),
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

  Widget _viewProfile() => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _header('${widget.categoryLabel} Details'),
          _info('Name', _nameCtrl.text),
          _info('Phone Number', _phoneCtrl.text),
          _info('Address', _addressCtrl.text),
          _info('Email', _emailCtrl.text),
          const SizedBox(height: 80),
        ],
      );

  Widget _header(String title) => Padding(
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

  Widget _info(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 140,
              child: Text(label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  )),
            ),
            Expanded(child: Text(value.isEmpty ? '-' : value)),
          ],
        ),
      );

  Widget _editForm() => Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            _header('${widget.categoryLabel} Details'),
            _field(_nameCtrl, 'Name', validator: _required),
            _field(
              _phoneCtrl,
              'Phone Number',
              keyboardType: TextInputType.phone,
              enabled: false,
            ),
            _field(
              _addressCtrl,
              'Address',
              maxLines: 3,
              validator: _required,
            ),
            _field(
              _emailCtrl,
              'Email',
              keyboardType: TextInputType.emailAddress,
              validator: _email,
            ),
          ],
        ),
      );

  Widget _field(
    TextEditingController controller,
    String label, {
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool enabled = true,
  }) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: TextFormField(
          controller: controller,
          enabled: enabled && !_isSaving,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            filled: !enabled,
            fillColor: enabled ? null : Colors.grey.shade100,
          ),
        ),
      );

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required' : null;

  String? _email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return RegExp(r'^[\w.\-]+@[\w\-]+\.[a-zA-Z]{2,}$')
            .hasMatch(value.trim())
        ? null
        : 'Enter a valid email address';
  }
}
