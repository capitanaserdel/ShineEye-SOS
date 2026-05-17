import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/profile_notifier.dart';

class IceProfileScreen extends ConsumerStatefulWidget {
  const IceProfileScreen({super.key});

  @override
  ConsumerState<IceProfileScreen> createState() => _IceProfileScreenState();
}

class _IceProfileScreenState extends ConsumerState<IceProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _bloodGroupController;
  late TextEditingController _conditionsController;
  
  List<Map<String, String>> _contacts = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _bloodGroupController = TextEditingController();
    _conditionsController = TextEditingController();

    // Populate initial data from provider
    Future.microtask(() async {
      await ref.read(profileProvider.notifier).fetchProfile();
      final currentProfile = ref.read(profileProvider).profile;
      if (currentProfile != null) {
        _populateFields(currentProfile);
      }
    });
  }

  void _populateFields(Map<String, dynamic> profile) {
    setState(() {
      _nameController.text = profile['name'] ?? '';
      _phoneController.text = profile['phone'] ?? '';
      _bloodGroupController.text = profile['blood_group'] ?? '';
      _conditionsController.text = profile['medical_conditions'] ?? '';
      
      final rawContacts = profile['emergency_contacts'];
      if (rawContacts is List) {
        _contacts = rawContacts.map((contact) {
          return {
            'name': contact['name']?.toString() ?? '',
            'phone': contact['phone']?.toString() ?? '',
          };
        }).toList();
      } else {
        _contacts = [];
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _bloodGroupController.dispose();
    _conditionsController.dispose();
    super.dispose();
  }

  void _addContactField() {
    setState(() {
      _contacts.add({'name': '', 'phone': ''});
    });
  }

  void _removeContactField(int index) {
    setState(() {
      _contacts.removeAt(index);
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(profileProvider.notifier).updateProfile(
      name: _nameController.text,
      phone: _phoneController.text,
      bloodGroup: _bloodGroupController.text,
      medicalConditions: _conditionsController.text,
      emergencyContacts: _contacts,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('In Case of Emergency (ICE) Profile updated!'),
            backgroundColor: Color(0xFF0F4C5C),
          ),
        );
      } else {
        final error = ref.read(profileProvider).errorMessage ?? 'Update failed';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $error'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);
    final isLoading = profileState.status == ProfileStatus.loading;

    // Listen to profile updates to auto-populate fields when loaded
    ref.listen(profileProvider, (previous, next) {
      if (previous?.profile == null && next.profile != null) {
        _populateFields(next.profile!);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('ICE Settings', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: isLoading && profileState.profile == null
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F4C5C)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Banner explaining ICE
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.purple.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.health_and_safety, color: Colors.purple, size: 28),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'ICE (In Case of Emergency) information is securely shared with health officials and emergency dispatchers in highly critical situations.',
                              style: TextStyle(color: Colors.purple, fontSize: 13, height: 1.4, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // SECTION 1: Personal Info
                    const Text('Primary Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 12),
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Full Name',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              validator: (val) => val == null || val.isEmpty ? 'Name cannot be empty' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _phoneController,
                              decoration: const InputDecoration(
                                labelText: 'Phone Number',
                                prefixIcon: Icon(Icons.phone_outlined),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // SECTION 2: Medical Info Card
                    const Text('Medical Profiling', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 12),
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _bloodGroupController,
                              decoration: const InputDecoration(
                                labelText: 'Blood Group (e.g. O+, A-)',
                                prefixIcon: Icon(Icons.bloodtype_outlined),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _conditionsController,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                labelText: 'Critical Medical Conditions / Allergies',
                                alignLabelWithHint: true,
                                prefixIcon: Padding(
                                  padding: EdgeInsets.only(bottom: 40),
                                  child: Icon(Icons.description_outlined),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // SECTION 3: Emergency Contacts List
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Emergency Contacts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        TextButton.icon(
                          onPressed: _addContactField,
                          icon: const Icon(Icons.add, color: Color(0xFF0F4C5C)),
                          label: const Text('Add Contact', style: TextStyle(color: Color(0xFF0F4C5C), fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (_contacts.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Text(
                            'No emergency contacts declared yet.',
                            style: TextStyle(color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _contacts.length,
                        itemBuilder: (context, index) {
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      children: [
                                        TextFormField(
                                          initialValue: _contacts[index]['name'],
                                          decoration: const InputDecoration(
                                            labelText: 'Contact Name / Relationship',
                                            isDense: true,
                                            border: InputBorder.none,
                                          ),
                                          onChanged: (val) {
                                            _contacts[index]['name'] = val;
                                          },
                                          validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                                        ),
                                        const Divider(height: 1),
                                        TextFormField(
                                          initialValue: _contacts[index]['phone'],
                                          decoration: const InputDecoration(
                                            labelText: 'Phone Number',
                                            isDense: true,
                                            border: InputBorder.none,
                                          ),
                                          onChanged: (val) {
                                            _contacts[index]['phone'] = val;
                                          },
                                          validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () => _removeContactField(index),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    
                    const SizedBox(height: 32),

                    // SECTION 4: Save Action
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F4C5C),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'Save Profile',
                                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}
