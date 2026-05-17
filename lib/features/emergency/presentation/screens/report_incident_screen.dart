import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../controllers/incident_notifier.dart';

class ReportIncidentScreen extends ConsumerStatefulWidget {
  const ReportIncidentScreen({super.key});

  @override
  ConsumerState<ReportIncidentScreen> createState() => _ReportIncidentScreenState();
}

class _ReportIncidentScreenState extends ConsumerState<ReportIncidentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  
  String _selectedType = 'insecurity';
  String _selectedUrgency = 'low';
  bool _isAnonymous = false;
  
  // Location selections
  String _selectedLocationPreset = 'Abuja';
  double _latitude = 9.0764785;
  double _longitude = 7.3985740;

  final Map<String, List<double>> _locationPresets = {
    'Abuja': [9.0764785, 7.3985740],
    'Lagos (Third Mainland)': [6.514432, 3.393433],
    'Kaduna (Rijana)': [9.948212, 7.324231],
    'Lokoja (Confluence)': [7.802311, 6.733321],
  };

  final List<Map<String, String>> _categories = [
    {'value': 'insecurity', 'label': 'Armed Insecurity / Banditry'},
    {'value': 'suspicious_activity', 'label': 'Suspicious Activity'},
    {'value': 'accident', 'label': 'Road Accident / Collision'},
    {'value': 'kidnapping', 'label': 'Kidnapping Threat'},
    {'value': 'mob_violence', 'label': 'Mob Violence / Riot'},
    {'value': 'health_outbreak', 'label': 'Health Outbreak / Disease'},
    {'value': 'disaster', 'label': 'Natural Disaster / Flood'},
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _onLocationPresetChanged(String? val) {
    if (val != null) {
      setState(() {
        _selectedLocationPreset = val;
        _latitude = _locationPresets[val]![0];
        _longitude = _locationPresets[val]![1];
      });
    }
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(incidentProvider.notifier).reportIncident(
      type: _selectedType,
      description: _descriptionController.text,
      latitude: _latitude,
      longitude: _longitude,
      urgencyLevel: _selectedUrgency,
      isAnonymous: _isAnonymous,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Incident reported successfully! Verifiers notified.'),
            backgroundColor: Color(0xFF0F4C5C),
          ),
        );
        context.pop();
      } else {
        final error = ref.read(incidentProvider).errorMessage ?? 'Submission failed';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $error'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(incidentProvider);
    final isLoading = state.status == IncidentStatus.loading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Incident', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F4C5C).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF0F4C5C).withOpacity(0.2)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.gavel_rounded, color: Color(0xFF0F4C5C), size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Reports are verified by trusted local responders. Falsifying emergency reports is punishable under state cyber safety regulations.',
                        style: TextStyle(color: Color(0xFF0F4C5C), fontSize: 13, height: 1.4, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Category Selector
              const Text('Incident Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.category_outlined, color: Color(0xFF0F4C5C)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
                items: _categories.map((cat) {
                  return DropdownMenuItem(value: cat['value']!, child: Text(cat['label']!));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedType = val);
                },
              ),
              const SizedBox(height: 20),

              // Urgency Level Selector
              const Text('Urgency level', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: ['low', 'medium', 'high', 'critical'].map((level) {
                  final isSelected = _selectedUrgency == level;
                  Color btnColor;
                  switch (level) {
                    case 'critical': btnColor = Colors.red.shade700; break;
                    case 'high': btnColor = Colors.orange.shade700; break;
                    case 'medium': btnColor = Colors.amber.shade700; break;
                    default: btnColor = Colors.green.shade700;
                  }

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: InkWell(
                        onTap: () => setState(() => _selectedUrgency = level),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? btnColor : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? btnColor : Colors.grey.shade300,
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              level.toUpperCase(),
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Incident Details
              const Text('Describe What Happened', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Enter as much detail as possible (e.g. number of people involved, vehicles, directions...)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter incident details';
                  }
                  if (val.trim().length < 10) {
                    return 'Please provide a more detailed description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Simulated Location Picker
              const Text('Incident Location (Geospatial Coordinates)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedLocationPreset,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.my_location, color: Color(0xFF0F4C5C)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
                items: _locationPresets.keys.map((presetName) {
                  return DropdownMenuItem(value: presetName, child: Text(presetName));
                }).toList(),
                onChanged: _onLocationPresetChanged,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Lat: ${_latitude.toStringAsFixed(6)}',
                      style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Long: ${_longitude.toStringAsFixed(6)}',
                      style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Anonymous Toggle
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.security, color: Color(0xFF0F4C5C)),
                title: const Text('Report Anonymously', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Hide your name and avatar from responders and nearby safety feeds.'),
                value: _isAnonymous,
                activeColor: const Color(0xFF0F4C5C),
                onChanged: (val) => setState(() => _isAnonymous = val),
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _submitReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F4C5C),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 2,
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Submit Urgent Report',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
