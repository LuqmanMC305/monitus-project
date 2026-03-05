import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For formatting the date
import '../services/database_helper.dart';

class AlertHistoryScreen extends StatefulWidget {
  const AlertHistoryScreen({super.key});

  @override
  State<AlertHistoryScreen> createState() => _AlertHistoryScreenState();

}

  class _AlertHistoryScreenState extends State<AlertHistoryScreen>{
      // Future variable to hold data
      late Future<List<Map<String, dynamic>>> _alertFuture;

      @override
      void initState() {
        super.initState();
        _loadAlerts(); // Load data on startup
      }

    // Manual Refresh Function
    void _loadAlerts() {
      setState(() {
        _alertFuture = DatabaseHelper.instance.getActiveAlerts(); 
      });
    }

    Widget build(BuildContext context){
      return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.grey[400], // Matches the grey header in your image
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text('ALERTS', 
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _loadAlerts, 
            icon: const Icon(Icons.refresh, color: Colors.black)),
            IconButton(onPressed: () {}, icon: const Icon(Icons.settings, color: Colors.black)),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future:_alertFuture, // Points to the state-managed  Alert Future
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No alerts found."));
          }

          final alerts = snapshot.data!;

          return ListView.separated(
            itemCount: alerts.length,
            separatorBuilder: (context, index) => const Divider(height: 1, thickness: 1),
            itemBuilder: (context, index) {
              final alert = alerts[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: _getAlertIcon(alert['alert_type']), // Custom icon logic
                title: Text(
                  alert['title'],
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: Text(
                  // Format the timestamp to match your design
                  DateFormat('MMMM d, yyyy h:mm a').format(DateTime.parse(alert['received_at'])),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.grey[400], // Matches the grey footer in your image
        child: const Text(
          'Alerts will be automatically cleared after 14 days',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
    );
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



