import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/survival_notifier.dart';

class SurvivalAcademyScreen extends ConsumerStatefulWidget {
  const SurvivalAcademyScreen({super.key});

  @override
  ConsumerState<SurvivalAcademyScreen> createState() => _SurvivalAcademyScreenState();
}

class _SurvivalAcademyScreenState extends ConsumerState<SurvivalAcademyScreen> {
  String _currentLanguage = 'en';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(survivalProvider.notifier).fetchGuides(lang: _currentLanguage);
    });
  }

  void _showGuideDetail(BuildContext context, Map<String, dynamic> guide) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final category = guide['category'].toString().toUpperCase();
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F4C5C).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  category,
                  style: const TextStyle(
                    color: Color(0xFF0F4C5C),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                guide['title'],
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, height: 1.3),
              ),
              const Divider(height: 28),
              const Text(
                'INSTRUCTIONS & PROTOCOLS',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey, letterSpacing: 0.8),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.45,
                ),
                child: SingleChildScrollView(
                  child: Text(
                    guide['content'],
                    style: const TextStyle(fontSize: 15, height: 1.6, color: Colors.black87),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.check_rounded, color: Colors.white),
                  label: const Text('I Understand', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F4C5C),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final survivalState = ref.watch(survivalProvider);
    final isGuidesLoading = survivalState.status == SurvivalStatus.loading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Survival Academy', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _currentLanguage,
                dropdownColor: const Color(0xFF0F4C5C),
                icon: const Icon(Icons.language_rounded, color: Colors.white),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                items: const [
                  DropdownMenuItem(value: 'en', child: Text('English ')),
                  DropdownMenuItem(value: 'ha', child: Text('Hausa ')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _currentLanguage = val);
                    ref.read(survivalProvider.notifier).changeLanguage(val);
                  }
                },
              ),
            ),
          )
        ],
      ),
      body: isGuidesLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F4C5C)))
          : survivalState.guides.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Text(
                      'No offline survival guides found for this language preset.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: survivalState.guides.length,
                  itemBuilder: (context, index) {
                    final guide = survivalState.guides[index];
                    final category = guide['category'].toString();
                    
                    IconData catIcon;
                    Color catColor;
                    switch (category.toLowerCase()) {
                      case 'first_aid':
                        catIcon = Icons.medical_services_outlined;
                        catColor = Colors.red.shade700;
                        break;
                      case 'disaster':
                        catIcon = Icons.storm;
                        catColor = Colors.blue.shade700;
                        break;
                      default:
                        catIcon = Icons.security;
                        catColor = Colors.indigo.shade700;
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      child: InkWell(
                        onTap: () => _showGuideDetail(context, guide),
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: catColor.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(catIcon, color: catColor, size: 28),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      category.toUpperCase().replaceAll('_', ' '),
                                      style: TextStyle(
                                        color: catColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      guide['title'],
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Offline available • 3 min read',
                                      style: TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
