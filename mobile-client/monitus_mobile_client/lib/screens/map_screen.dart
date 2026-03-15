import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/database_helper.dart';
import 'package:geolocator/geolocator.dart';
import '../services/registration_service.dart';


class AlertMapScreen extends StatefulWidget {
  const AlertMapScreen({super.key});

  @override
  State<AlertMapScreen> createState() => _AlertMapScreenState();
}

class _AlertMapScreenState extends State<AlertMapScreen> {
  final MapController _mapController = MapController();
  late Future<List<Map<String, dynamic>>> _mapAlerts;

  @override
  void initState() {
    super.initState();
    // Fetch all alerts from SQLite
    _mapAlerts = DatabaseHelper.instance.getActiveAlerts(); 
  }

  // Sync current mobile user location using determinePosition inside registration_service file
  Future<void> _syncMapToUser() async {
    try {
      // Use the static method from your service
      Position position = await RegistrationService.determinePosition(); 

      _mapController.move(
        LatLng(position.latitude, position.longitude), 
        14.0
      );
    } catch (e) {
      debugPrint("Location error: $e"); 
    }
  }

  @override
  Widget build(BuildContext context) {
    // Wrap the FutureBuilder in a Scaffold so we can add the FloatingActionButton
    return Scaffold(
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _mapAlerts,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          // ... Your existing logic for alertsWithGeo and debugPrints ...
          final alertsWithGeo = snapshot.data!.where((alert) => 
            (alert['latitude'] ?? 0.0) != 0.0 && (alert['longitude'] ?? 0.0) != 0.0
          ).toList();

          return FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(5.3767, 100.3036),
              initialZoom: 13.0,
              onMapReady: () => _syncMapToUser(),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.monitus.app',
              ),
              CircleLayer(
                circles: alertsWithGeo.map((alert) {
                  return CircleMarker(
                    point: LatLng(alert['latitude'], alert['longitude']),
                    radius: alert['radius'] ?? 500.0,
                    useRadiusInMeter: true,
                    color: _getSeverityColor(alert['alert_type']).withValues(alpha: 0.2),
                    borderColor: _getSeverityColor(alert['alert_type']),
                    borderStrokeWidth: 2,
                  );
                }).toList(),
              ),
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
      ),
      
      // Refresh Button
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.redAccent,
        onPressed: () {
          setState(() {
            // IMPORTANT: Re-assign the future to trigger a fresh database query
            _mapAlerts = DatabaseHelper.instance.getActiveAlerts(); 
          });
          
          // Show a tiny feedback message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Fetching latest alerts..."),
              duration: Duration(milliseconds: 800),
            ),
          );
        },
        child: const Icon(Icons.sync, color: Colors.white),
      ),
    );
  }

  // Helper method to get severity colour for alerts
  Color _getSeverityColor(String? type) {
    switch (type?.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.yellow;
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

    // Refresh Map Data Method
    void _refreshMapData() {
    setState(() {
      _mapAlerts = DatabaseHelper.instance.getActiveAlerts();
    });
  }
}