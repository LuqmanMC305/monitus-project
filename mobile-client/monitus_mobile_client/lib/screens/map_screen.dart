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
                    anchorPoint = _getPolygonCentroid(coords);
                  } else {
                    anchorPoint = LatLng(
                      double.tryParse(alert['latitude']?.toString() ?? '0.0') ?? 0.0, 
                      double.tryParse(alert['longitude']?.toString() ?? '0.0') ?? 0.0
                    );
                  }

                  //  Filter out corrupted or uninitialised boundary nodes gracefully
                  if (anchorPoint.latitude == 0.0 && anchorPoint.longitude == 0.0) {
                    return const Marker(
                      point: LatLng(0, 0), 
                      child: SizedBox.shrink()
                    );
                  }

                  return Marker(
                    point: anchorPoint,
                    width: 45,
                    height: 45,
                    child: GestureDetector(
                      onTap: () => _showAlertDetails(alert),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                          // border: Border.all(color: _getSeverityColor(alert['alert_type']), width: 2),
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
    showDialog(
      context: context,
      barrierDismissible: true, // Allows users to tap outside the card to close it
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), // Uniform rounded card styling
          ),
          icon: Text(
            alert['category_icon'] ?? '📢',
            style: const TextStyle(fontSize: 32),
          ),
          title: Text(
            alert['title'] ?? 'Incident Details',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Display Severity Label with matching badge color
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getSeverityColor(alert['alert_type']).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "Severity: ${(alert['alert_type'] ?? 'LOW').toString().toUpperCase()}",
                    style: TextStyle(
                      color: _getSeverityColor(alert['alert_type']),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Main Instruction Body
                Text(
                  alert['translated_body'] ?? alert['body'] ?? 'No details provided.',
                  style: const TextStyle(fontSize: 15, height: 1.4),
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 8),
                
                // Timestamp
                Text(
                  "Reported at: ${alert['received_at']}",
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                "Dismiss",
                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

    // Compute the centroid of a polygon alert 
    LatLng _getPolygonCentroid(List<LatLng> points) {
      if (points.isEmpty) return const LatLng(0, 0);

      double totalLat = 0.0;
      double totalLng = 0.0;

      for (var point in points) {
        totalLat += point.latitude;
        totalLng += point.longitude;
      }

      // Dividing by n (points.length) to find the average
      return LatLng(totalLat / points.length, totalLng / points.length);
    }

    // Refresh Map Data Method
    void _refreshMapData() {
    setState(() {
      _mapAlerts = DatabaseHelper.instance.getActiveAlerts();
    });
  }
}