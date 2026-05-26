import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/database_helper.dart';
import 'package:geolocator/geolocator.dart';
import '../services/registration_service.dart';
import '../services/alert_notifier.dart';
import 'dart:convert';


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
    
    // Listen for background updates to clear resolved markers
    AlertNotifier.refreshTrigger.addListener(_refreshMapData);
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

  // Helper method to decode the JSON array safely
  List<LatLng> _parsePolygon(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) return [];
    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.map((point) => LatLng(
        double.parse(point[0].toString()), 
        double.parse(point[1].toString())
      )).toList();
    } catch (e) {
      debugPrint("Error parsing polygon: $e");
      return [];
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

              // MODE A: CIRCLE RENDERER
             CircleLayer(
                circles: snapshot.data!.where((alert) => alert['area_type'] == 'radius').map((alert) {
                  return CircleMarker(
                    point: LatLng(alert['latitude'] ?? 0.0, alert['longitude'] ?? 0.0),
                    radius: alert['radius'] ?? 500.0,
                    useRadiusInMeter: true,
                    color: _getSeverityColor(alert['alert_type']).withValues(alpha: 0.2),
                    borderColor: _getSeverityColor(alert['alert_type']),
                    borderStrokeWidth: 2,
                  );
                }).toList(),
              ),

              // MODE B: POLYGON RENDERER
              PolygonLayer(
                polygons: snapshot.data!.where((alert) => alert['area_type'] == 'polygon').map((alert) {
                  List<LatLng> coords = _parsePolygon(alert['danger_zone_coordinates']);
                  return Polygon(
                    points: coords,
                    color: _getSeverityColor(alert['alert_type']).withValues(alpha: 0.2),
                    borderColor: _getSeverityColor(alert['alert_type']),
                    borderStrokeWidth: 3,
                  );
                }).toList(),
              ),

              MarkerLayer(
                markers: snapshot.data!.map((alert) {

                  // Determine marker location based on geometry type
                  LatLng anchorPoint;
                  if (alert['area_type'] == 'polygon') {
                    List<LatLng> coords = _parsePolygon(alert['danger_zone_coordinates']);
                    anchorPoint = coords.isNotEmpty ? coords.first : LatLng(0, 0);
                  } else {
                    anchorPoint = LatLng(alert['latitude'] ?? 0.0, alert['longitude'] ?? 0.0);
                  }

                  // Only draw if we have a valid point
                  if (anchorPoint.latitude == 0 && anchorPoint.longitude == 0) 
                    return Marker(point: LatLng(0,0), child: SizedBox());

                  return Marker(
                    point: LatLng(alert['latitude'], alert['longitude']),
                    width: 45,
                    height: 45,
                    child: GestureDetector(
                      onTap: () => _showAlertDetails(alert),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _getSeverityColor(alert['alert_type']).withValues(alpha: 0.2),
                          //shape: BoxShape.circle,
                          //border: Border.all(color: _getSeverityColor(alert['alert_type']), width: 2),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          alert['category_icon'] ?? '📢',
                          style: const TextStyle(fontSize: 22),
                        )
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
        return Color(0xFFF9A825); // Amber
      case 'low':
        return Color(0xFF90EE90); // Light Green
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