import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong2.dart';
import '../controllers/incident_notifier.dart';
import '../controllers/alert_notifier.dart';

class InteractiveMapScreen extends ConsumerStatefulWidget {
  const InteractiveMapScreen({super.key});

  @override
  ConsumerState<InteractiveMapScreen> createState() => _InteractiveMapScreenState();
}

class _InteractiveMapScreenState extends ConsumerState<InteractiveMapScreen> {
  final MapController _mapController = MapController();
  
  // Default map center set to Nigeria (close to Abuja)
  final LatLng _initialCenter = const LatLng(9.0820, 8.6753); 

  @override
  void initState() {
    super.initState();
    // Fetch fresh reports on load
    Future.microtask(() {
      ref.read(incidentProvider.notifier).fetchIncidents();
      ref.read(alertProvider.notifier).fetchAlerts();
    });
  }

  void _showReportBottomSheet(BuildContext context, Map<String, dynamic> report, bool isAlert) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final title = isAlert ? report['title'] : 'Verified Incident: ${report['type'].toString().replaceAll('_', ' ').toUpperCase()}';
        final description = isAlert ? report['message'] : report['description'];
        final String urgency = (isAlert ? report['type'] : report['urgency_level'] ?? 'medium').toString().toUpperCase();
        final credibility = isAlert ? 100 : report['credibility_score'] ?? 50;
        final status = isAlert ? 'ACTIVE WARNING' : report['status'].toString().toUpperCase();

        Color urgencyColor;
        switch (urgency.toLowerCase()) {
          case 'critical':
          case 'danger':
            urgencyColor = Colors.red.shade800; break;
          case 'high': urgencyColor = Colors.orange.shade800; break;
          case 'medium': urgencyColor = Colors.amber.shade800; break;
          default: urgencyColor = Colors.green.shade800;
        }

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bottom sheet handler
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

              // Title and Urgency Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: urgencyColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      urgency,
                      style: TextStyle(color: urgencyColor, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Meta description Info
              Row(
                children: [
                  Icon(Icons.shield_outlined, color: Colors.blue.shade700, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Status: $status',
                    style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const Spacer(),
                  Icon(Icons.star_half_rounded, color: Colors.amber.shade700, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    'Credibility: $credibility%',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ],
              ),
              const Divider(height: 24, thickness: 1.2),

              // Description Text
              const Text(
                'Description & Observations:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 6),
              Text(
                description,
                style: const TextStyle(fontSize: 15, height: 1.4, color: Colors.black87),
              ),
              const SizedBox(height: 28),

              // Navigation Actions button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
                  label: const Text('Acknowledge and Monitor', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
    final incidentState = ref.watch(incidentProvider);
    final alertState = ref.watch(alertProvider);

    final List<Marker> markers = [];
    final List<CircleMarker> circles = [];

    // Parse Incidents to Map Markers
    for (var incident in incidentState.incidents) {
      final double? lat = double.tryParse(incident['latitude'].toString());
      final double? lng = double.tryParse(incident['longitude'].toString());

      if (lat != null && lng != null) {
        final String urgency = (incident['urgency_level'] ?? 'medium').toString();
        Color markerColor;
        IconData markerIcon;

        switch (urgency.toLowerCase()) {
          case 'critical':
            markerColor = Colors.red.shade900;
            markerIcon = Icons.report_problem;
            break;
          case 'high':
            markerColor = Colors.red.shade600;
            markerIcon = Icons.warning_rounded;
            break;
          case 'medium':
            markerColor = Colors.orange;
            markerIcon = Icons.info_outline;
            break;
          default:
            markerColor = Colors.green;
            markerIcon = Icons.check_circle_outline;
        }

        markers.add(
          Marker(
            point: LatLng(lat, lng),
            width: 44,
            height: 44,
            child: GestureDetector(
              onTap: () => _showReportBottomSheet(context, incident, false),
              child: Container(
                decoration: BoxDecoration(
                  color: markerColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: markerColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: markerColor.withOpacity(0.4),
                          blurRadius: 6,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(markerIcon, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }

    // Parse Alerts to Map Geo-Fences & Pins
    for (var alert in alertState.alerts) {
      final double? lat = double.tryParse(alert['latitude'].toString());
      final double? lng = double.tryParse(alert['longitude'].toString());
      final double radiusKm = double.tryParse(alert['radius_km'].toString()) ?? 5.0;

      if (lat != null && lng != null) {
        final alertLatLng = LatLng(lat, lng);
        final String type = (alert['type'] ?? 'general').toString();
        Color alertColor = Colors.red;
        if (type == 'weather') alertColor = Colors.blue;
        if (type == 'health') alertColor = Colors.purple;

        // Danger zone radius geofence
        circles.add(
          CircleMarker(
            point: alertLatLng,
            color: alertColor.withOpacity(0.12),
            borderStrokeWidth: 1.5,
            borderColor: alertColor.withOpacity(0.6),
            useRadiusInMeter: true,
            radius: radiusKm * 1000, 
          ),
        );

        markers.add(
          Marker(
            point: alertLatLng,
            width: 48,
            height: 48,
            child: GestureDetector(
              onTap: () => _showReportBottomSheet(context, alert, true),
              child: Icon(
                Icons.radio_button_checked_rounded,
                color: alertColor,
                size: 26,
              ),
            ),
          ),
        );
      }
    }

    final isMapLoading = incidentState.status == IncidentStatus.loading || alertState.status == AlertStatus.loading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Interactive Safety Map', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(incidentProvider.notifier).fetchIncidents();
              ref.read(alertProvider.notifier).fetchAlerts();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialCenter,
              initialZoom: 6.5,
              maxZoom: 18,
              minZoom: 4,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'shineeye_app',
              ),
              CircleLayer(circles: circles),
              MarkerLayer(markers: markers),
            ],
          ),

          // Loading indicator overlay
          if (isMapLoading)
            const Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Card(
                  elevation: 4,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0F4C5C)),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Updating danger zones...',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Legend Card
          Positioned(
            bottom: 24,
            left: 20,
            right: 20,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildLegendItem(Colors.red.shade900, 'Critical Incident'),
                    _buildLegendItem(Colors.red.shade500, 'High Urgency'),
                    _buildLegendItem(Colors.orange, 'Warning'),
                    _buildLegendItem(Colors.blue, 'Evacuation Area'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
