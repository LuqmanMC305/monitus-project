import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For formatting the date
import '../services/database_helper.dart';
import '../services/translation_service.dart';
import '../services/alert_notifier.dart';

class AlertHistoryScreen extends StatefulWidget {
  const AlertHistoryScreen({super.key});

  @override
  State<AlertHistoryScreen> createState() => _AlertHistoryScreenState();

}

  class _AlertHistoryScreenState extends State<AlertHistoryScreen>{
      // Future variable to hold data
      late Future<List<Map<String, dynamic>>> _alertFuture;

       // Define a map for language code
      final Map<String, String> languageLabels = {
        'ms': 'Malay',
        'zh': 'Chinese',
        'ta': 'Tamil',
        'en': 'English',
      };

      @override
      void initState() {
        super.initState();
        _alertFuture = _refreshData();  // Initialise by calling the combined cleanup and fetch logic
        AlertNotifier.refreshTrigger.addListener(_loadAlerts);
      }

        // Helper function to handle expired alerts (NEW MASTER FUNCTION FOR ALERT REFRESH)
      Future<List<Map<String, dynamic>>> _refreshData() async{
        // Silent Cleanup (14-day auto-delete logic)
        await DatabaseHelper.instance.deleteOldAlerts();

        // Fetch the fresh list and return it directly
        return DatabaseHelper.instance.getActiveAlerts();
      }

      @override
      void dispose() {
        AlertNotifier.refreshTrigger.removeListener(_loadAlerts);
        super.dispose();
      }

    // Manual Refresh _refreshData
    Future<void> _loadAlerts() async {
      print("RELOADING ALERTS");

      setState(() {
        _alertFuture = _refreshData();
      });

      // Wait for the future to finish so the RefreshIndicator spinner hides at the right time
      await _alertFuture;
    }

    @override
    Widget build(BuildContext context) {
      print("BUILD TRIGGERED");

      return FutureBuilder<List<Map<String, dynamic>>>(
        future: _alertFuture, 
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Handle the case where no alerts are found
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return RefreshIndicator(
              onRefresh: _handlePullToRefresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(), // Ensures pull-to-refresh works when empty
                children: const [
                  SizedBox(height: 200),
                  Center(child: Text("No alerts found.")),
                ],
              ),
            );
          }

          final alerts = snapshot.data!;

          // Handle the active alert list
          return RefreshIndicator(
            onRefresh: _handlePullToRefresh,
            color: Colors.blueAccent,
            child: ListView.separated(
              // AlwaysScrollableScrollPhysics ensures the gesture works even for short lists
              physics: const AlwaysScrollableScrollPhysics(), 
              itemCount: alerts.length,
              separatorBuilder: (context, index) => const Divider(height: 1, thickness: 1),
              itemBuilder: (context, index) {
                final alert = alerts[index];

                String displayBody = (alert['translated_body'] != null && alert['translated_body'].isNotEmpty)
                    ? alert['translated_body']
                    : (alert['body'] ?? 'No message content');

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: _getAlertIcon(alert['alert_type']),
                  title: Text(
                    alert['title'],
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(displayBody, style: const TextStyle(fontSize: 13, color: Colors.black87)),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMMM d, yyyy h:mm a').format(DateTime.parse(alert['received_at'])),
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      )
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    icon: const Icon(Icons.translate, color: Colors.blue),
                    onSelected: (String languageCode) async {
                      String newTranslation = await TranslationService().translateAlert(
                        alert['body'], 
                        targetLanguageCode: languageCode
                      );

                      await DatabaseHelper.instance.updateAlertTranslation(
                        alert['id'], 
                        newTranslation, 
                        languageCode
                      );

                      _loadAlerts(); 
                      
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Translated to ${languageLabels[languageCode] ?? languageCode}")),
                        );
                      }
                    },
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(value: 'en', child: Text('Original (English)')),
                      const PopupMenuItem<String>(value: 'ms', child: Text('Malay')),
                      const PopupMenuItem<String>(value: 'zh', child: Text('Chinese')),
                      const PopupMenuItem<String>(value: 'ta', child: Text('Tamil')),
                    ],
                  ),
                );
              },
            ),
          );
        },
      );
    }

    // Explicit UI trigger for the pull-to-refresh gesture
    Future<void> _handlePullToRefresh() async {
      print("USER PULLED DOWN TO REFRESH");

      setState(() {
        // Re-assigning the future tells the FutureBuilder to show the loader and update
        _alertFuture = _refreshData();
      });

      // Keep the loading spinner active until the database operations finish
      await _alertFuture;
    }
  }
  
  // Helper function to pick the icon based on 'alert_type' (WILL CUSTOMISE ALERTS LATER)
  Widget _getAlertIcon(String? type) {
    IconData iconData;
    switch (type) {
      case 'flood_warning':
        iconData = Icons.water_drop; // Currently using Material Icons
        break;
      case 'emergency':
        iconData = Icons.warning;
        break;
      default:
        iconData = Icons.notifications;
    }
    return CircleAvatar(
      backgroundColor: Colors.black,
      child: Icon(iconData, color: Colors.white),
    );
  }

   





