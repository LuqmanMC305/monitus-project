import 'package:flutter/material.dart';
import 'package:monitus_mobile_client/screens/alert_history_screen.dart';
import 'package:provider/provider.dart';
import '../providers/registration_provider.dart';

class RegistrationScreen extends StatelessWidget {
  const RegistrationScreen({super.key});
  @override
  Widget build(BuildContext context) {
    // Access the "brain" (ViewModel)
    final provider = Provider.of<RegistrationProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text("Monitus Registration")),
      body: Center(
        child: provider.isLoading
            ? CircularProgressIndicator() // Show spinner if loading
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (provider.isSuccess)
                    Column(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 40),
                        const Text("Registered Successfuly", style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed:() {
                            // Navitage to new template screen
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const AlertHistoryScreen())
                            );
                          },
                         child: const Text("Alert History"))
                      ],
                    ),
                  if (provider.errorMessage != null) Text("Error: ${provider.errorMessage}"),
                  ElevatedButton(
                    onPressed: () => provider.handleRegistration(),
                    child: Text("Register Device"),
                  ),
                ],
              ),
      ),
    );
  }
}