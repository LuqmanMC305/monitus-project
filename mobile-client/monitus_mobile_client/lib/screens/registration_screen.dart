import 'package:flutter/material.dart';
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
                  if (provider.isSuccess) Text("Registered Successfully!"),
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