import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/database_helper.dart';
import 'package:geolocator/geolocator.dart';
import '../services/registration_service.dart';
import '../services/alert_notifier.dart';
import '../services/report_service.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io'; 
import 'package:image_picker/image_picker.dart'; 
import '../config/storage_keys.dart';

class AlertMapScreen extends StatefulWidget {
  const AlertMapScreen({super.key});

  @override
  State<AlertMapScreen> createState() => _AlertMapScreenState();
}

class _AlertMapScreenState extends State<AlertMapScreen> {
  final MapController _mapController = MapController();
  late Future<List<Map<String, dynamic>>> _mapAlerts;

  // 🟢 Crowdsourcing Flow State Variables
  bool _isReportingMode = false;
  File? _selectedImage;
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _mapAlerts = DatabaseHelper.instance.getActiveAlerts(); 
    AlertNotifier.refreshTrigger.addListener(_refreshMapData);
  }

  Future<void> _syncMapToUser() async {
    try {
      Position position = await RegistrationService.determinePosition(); 
      _mapController.move(LatLng(position.latitude, position.longitude), 14.0);
    } catch (e) {
      debugPrint("Location error: $e"); 
    }
  }

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
    return Scaffold(
      // 🟢 Dynamic Top Header Bar to warn users they are in placement mode
      appBar: _isReportingMode 
        ? AppBar(
            backgroundColor: Colors.orangeAccent,
            title: const Text('Pan Map to Place Incident Pin', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.black),
              onPressed: () => setState(() => _isReportingMode = false),
            ),
          )
        : null,

      body: Stack(
        children: [
          FutureBuilder<List<Map<String, dynamic>>>(
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

                  // MODE A: CIRCLE RENDERER (Remains visible!)
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

                  // MODE B: POLYGON RENDERER (Remains visible!)
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

                      if (anchorPoint.latitude == 0.0 && anchorPoint.longitude == 0.0) {
                        return const Marker(point: LatLng(0, 0), child: SizedBox.shrink());
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

          // 🟢 FIXED CROSSHAIR PIN: Drops directly over map center when toggle is true
          if (_isReportingMode)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 40.0), // Counters icon layout anchor offset
                child: Icon(Icons.location_pin, color: Colors.redAccent, size: 50),
              ),
            ),
        ],
      ),
      
      // 🟢 DYNAMIC FLOATING ACTION BUTTON SYSTEM
      floatingActionButton: _isReportingMode 
        ? FloatingActionButton.extended(
            backgroundColor: Colors.green,
            onPressed: () {
              // Capture exact location currently centered underneath crosshairs
              final targetPosition = _mapController.camera.center;
              _openReportSubmissionSheet(context, targetPosition);
            },
            label: const Text("Confirm Location Here", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            icon: const Icon(Icons.check, color: Colors.white),
          )
        : Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Community Reporting Trigger Button
              FloatingActionButton(
                heroTag: "reportBtn",
                backgroundColor: Colors.orange,
                onPressed: () => setState(() => _isReportingMode = true),
                child: const Icon(Icons.report_problem, color: Colors.white),
              ),
              const SizedBox(height: 10),
              // Standard Sync Refresh Button
              FloatingActionButton(
                heroTag: "syncBtn",
                backgroundColor: Colors.redAccent,
                onPressed: () {
                  setState(() {
                    _mapAlerts = DatabaseHelper.instance.getActiveAlerts(); 
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Fetching latest alerts..."), duration: Duration(milliseconds: 800)),
                  );
                },
                child: const Icon(Icons.sync, color: Colors.white),
              ),
            ],
          ),
    );
  }

  // 🟢 CROWDSOURCING MODAL SUBMISSION 
  void _openReportSubmissionSheet(BuildContext context, LatLng coordinates) {
    showDialog(
      context: context,
      barrierDismissible: true, // Allows tapping outside to dismiss the form safely
      builder: (BuildContext bc) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding: const EdgeInsets.all(20), // Standard margin around the dialog box
          child: Container(
            // Limits the dialog width on web/desktop view displays so it doesn't stretch out fully
            constraints: const BoxConstraints(maxWidth: 500), 
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Report Community Incident', 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Coordinates: ${coordinates.latitude.toStringAsFixed(4)}, ${coordinates.longitude.toStringAsFixed(4)}', 
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 15),
                  
                  TextField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Incident Details',
                      hintText: 'Describe flash floods, structural damage, fallen roadblocks...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Embedded Image Preview box frame
                  _selectedImage != null 
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(_selectedImage!, height: 150, fit: BoxFit.cover),
                        )
                      : Container(
                          height: 120, 
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300), 
                            borderRadius: BorderRadius.circular(10), 
                            color: Colors.grey.shade50,
                          ), 
                          alignment: Alignment.center, 
                          child: const Text('No Evidence Photo Attached', style: TextStyle(color: Colors.grey)),
                        ),
                  const SizedBox(height: 8),
                  
                  TextButton.icon(
                    onPressed: () async {
                      final picker = ImagePicker();
                      final pickedFile = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
                      if (pickedFile != null) {
                        // 💡 NOTE: Since showDialog doesn't need an outer StatefulBuilder layout context anymore,
                        // we can call the standard dialog controller state updates cleanly!
                        (bc as Element).markNeedsBuild(); 
                        _selectedImage = File(pickedFile.path);
                      }
                    },
                    icon: const Icon(Icons.camera_alt, color: Colors.blue),
                    label: const Text('Capture Live Camera Evidence', style: TextStyle(color: Colors.blue)),
                  ),
                  const SizedBox(height: 15),

                  ElevatedButton(
                    onPressed: () async {
                      // 1. Validate user text input field
                      if (_descriptionController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Please write a small description"))
                        );
                        return;
                      }

                      // 2. Display an un-dismissible loading spinner overlay dialog
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => const Center(
                          child: CircularProgressIndicator(color: Colors.redAccent),
                        ),
                      );

                      // 3. Read the dynamic user ID from SharedPreferences
                      final SharedPreferences prefs = await SharedPreferences.getInstance();
                      final String? savedAppUserId = prefs.getString(StorageKeys.appUserId);
                      final int parsedUserId = int.tryParse(savedAppUserId ?? '') ?? 1; 
                      
                      try {
                        // 4. Trigger your Dio network submission handler
                        bool isSuccess = await ReportService().submitIncidentReport(
                          appUserId: parsedUserId, 
                          description: _descriptionController.text.trim(),
                          location: coordinates, 
                          imageFile: _selectedImage,
                        );

                        // 5. Pop the loading spinner immediately after API responds
                        if (context.mounted) Navigator.pop(context);

                        if (isSuccess) {
                          // 6. Reset elements and completely dismiss the custom form box dialog drawer frame
                          _selectedImage = null;
                          _descriptionController.clear();
                          
                          if (context.mounted) Navigator.pop(bc); // Closes the dialog safely
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Report forwarded to automated AI triage desk."), 
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Submission failed. Check backend server connection."), 
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        if (context.mounted) {
                          Navigator.pop(context); // Pops spinner out
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("An unexpected error occurred: $e"), backgroundColor: Colors.redAccent),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent, 
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text(
                      'Submit Emergency Request', 
                      style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getSeverityColor(String? type) {
    switch (type?.toLowerCase()) {
      case 'high': return Colors.red;
      case 'medium': return const Color(0xFFF9A825);
      case 'low': return const Color(0xFF90EE90);
      default: return Colors.grey;
    }
  }

  void _showAlertDetails(Map<String, dynamic> alert) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          icon: Text(alert['category_icon'] ?? '📢', style: const TextStyle(fontSize: 32)),
          title: Text(alert['title'] ?? 'Incident Details', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: _getSeverityColor(alert['alert_type']).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                  child: Text("Severity: ${(alert['alert_type'] ?? 'LOW').toString().toUpperCase()}", style: TextStyle(color: _getSeverityColor(alert['alert_type']), fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                const SizedBox(height: 12),
                Text(alert['translated_body'] ?? alert['body'] ?? 'No details provided.', style: const TextStyle(fontSize: 15, height: 1.4)),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 8),
                Text("Reported at: ${alert['received_at']}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Dismiss", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))),
          ],
        );
      },
    );
  }

  LatLng _getPolygonCentroid(List<LatLng> points) {
    if (points.isEmpty) return const LatLng(0, 0);
    double totalLat = 0.0;
    double totalLng = 0.0;
    for (var point in points) {
      totalLat += point.latitude;
      totalLng += point.longitude;
    }
    return LatLng(totalLat / points.length, totalLng / points.length);
  }

  void _refreshMapData() {
    setState(() {
      _mapAlerts = DatabaseHelper.instance.getActiveAlerts();
    });
  }
}