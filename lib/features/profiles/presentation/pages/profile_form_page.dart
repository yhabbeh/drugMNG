import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:drug/features/profiles/domain/entities/caregiver_profile.dart';
import 'package:drug/features/profiles/presentation/bloc/profiles_bloc.dart';

class ProfileFormPage extends StatefulWidget {
  const ProfileFormPage({super.key, this.profile});

  final CaregiverProfile? profile;

  @override
  State<ProfileFormPage> createState() => _ProfileFormPageState();
}

class _ProfileFormPageState extends State<ProfileFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _avatarUrlController;
  late Relationship _relationship;
  int? _color;

  bool get _isEditing => widget.profile != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile?.displayName ?? '');
    _avatarUrlController = TextEditingController(text: widget.profile?.avatarUrl ?? '');
    _relationship = widget.profile?.relationship ?? Relationship.self;
    _color = widget.profile?.color;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _avatarUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = _isEditing ? 'Edit Profile' : 'Add Profile';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Display Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Relationship>(
                initialValue: _relationship,
                decoration: const InputDecoration(
                  labelText: 'Relationship',
                  border: OutlineInputBorder(),
                ),
                items: Relationship.values.map((r) {
                  return DropdownMenuItem(value: r, child: Text(r.name));
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _relationship = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _avatarUrlController,
                decoration: const InputDecoration(
                  labelText: 'Avatar URL (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              _ColorPicker(
                selectedColor: _color,
                onColorSelected: (color) => setState(() => _color = color),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _submit,
                child: Text(_isEditing ? 'Save Changes' : 'Create Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final profile = CaregiverProfile(
      id: widget.profile?.id ?? '',
      ownerUid: widget.profile?.ownerUid ?? '',
      displayName: _nameController.text.trim(),
      relationship: _relationship,
      avatarUrl: _avatarUrlController.text.trim().isEmpty
          ? null
          : _avatarUrlController.text.trim(),
      color: _color,
      createdAt: widget.profile?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    if (_isEditing) {
      context.read<ProfilesBloc>().add(ProfileUpdated(profile));
    } else {
      context.read<ProfilesBloc>().add(ProfileCreated(profile));
    }
    context.pop();
  }
}

final class _ColorPicker extends StatelessWidget {
  const _ColorPicker({required this.selectedColor, required this.onColorSelected});

  final int? selectedColor;
  final ValueChanged<int?> onColorSelected;

  static const _colors = [
    0xFF4CAF50,
    0xFF2196F3,
    0xFFFF9800,
    0xFFE91E63,
    0xFF9C27B0,
    0xFF00BCD4,
    0xFFFF5722,
    0xFF607D8B,
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Avatar Color'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._colors.map((color) => GestureDetector(
                  onTap: () => onColorSelected(color),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(color),
                      shape: BoxShape.circle,
                      border: selectedColor == color
                          ? Border.all(color: Colors.white, width: 3)
                          : null,
                    ),
                  ),
                )),
            GestureDetector(
              onTap: () => onColorSelected(null),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  shape: BoxShape.circle,
                  border: selectedColor == null
                      ? Border.all(color: Colors.white, width: 3)
                      : null,
                ),
                child: const Icon(Icons.close, size: 20),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
