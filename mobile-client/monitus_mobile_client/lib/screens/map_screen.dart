import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/database_helper.dart';

class AlertMapScreen extends StatefulWidget {
  const AlertMapScreen({super.key});

  @override
  State<AlertMapScreen> createState() => _AlertMapScreenState();
}

class _AlertMapScreenState extends State<AlertMapScreen> {
  late Future<List<Map<String, dynamic>>> _mapAlerts;

  @override
  void initState() {
    super.initState();
    // Fetch all alerts from SQLite
    _mapAlerts = DatabaseHelper.instance.getActiveAlerts(); 
  }

  @override
  Widget build(BuildContext context) {
      return FutureBuilder<List<Map<String, dynamic>>>(
        future: _mapAlerts,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          // 1. Filter out alerts that don't have GPS data (0,0)
          final alertsWithGeo = snapshot.data!.where((alert) => 
            (alert['latitude'] ?? 0.0) != 0.0 && (alert['longitude'] ?? 0.0) != 0.0
          ).toList();

          return FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(3.1390, 101.6869), // Default to KL center
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.monitus.app',
              ),
              // 2. Draw the impact radius circles
              CircleLayer(
                circles: alertsWithGeo.map((alert) {
                  return CircleMarker(
                    point: LatLng(alert['latitude'], alert['longitude']),
                    radius: alert['radius'] ?? 500.0,
                    useRadiusInMeter: true,
                    color: Colors.red.withValues(alpha: 0.3), // alpha is opacity
                    borderColor: _getSeverityColor(alert['alert_type']),
                    borderStrokeWidth: 2,
                  );
                }).toList(),
              ),
              // Step 3: Draw the center icons
              MarkerLayer(
                markers: alertsWithGeo.map((alert) {
                  return Marker(
                    point: LatLng(alert['latitude'], alert['longitude']),
                    width: 40,
                    height: 40,
                    child: GestureDetector(
                      onTap: () => _showAlertDetails(alert),
                      child: Icon(
                        alert['alert_type'] == 'emergency' ? Icons.warning : Icons.info, 
                        color: _getSeverityColor(alert['alert_type']), 
                        size: 30
                      ),
                    )
                  );
                }).toList(),
              ),
            ],
          );
        },
      );
  }

  // Helper method to get severity colour for alerts
  Color _getSeverityColor(String? type) {
    switch (type?.toLowerCase()) {
      case 'emergency':
      case 'danger':
        return Colors.red;
      case 'warning':
      case 'alert':
        return Colors.orange;
      case 'info':
      case 'notice':
        return Colors.blue;
      default:
        return Colors.grey; // Fallback for unknown types
    }
  }

  // Method to show alert details
  void _showAlertDetails(Map<String, dynamic> alert) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                alert['title'] ?? 'Incident Details',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(alert['translated_body'] ?? alert['body'] ?? 'No details provided.'),
              const SizedBox(height: 20),
              Text("Reported at: ${alert['received_at']}", 
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        );
      },
    );
  }
}