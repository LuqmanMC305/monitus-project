import 'package:flutter/material.dart';
//import 'package:monitus_mobile_client/screens/alert_history_screen.dart';
import 'package:monitus_mobile_client/screens/main_wrapper_screen.dart';
//import 'package:monitus_mobile_client/screens/map_screen.dart';
import 'package:provider/provider.dart';
import '../providers/registration_provider.dart';
import '../providers/community_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

    @override
    State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen>{
  bool _isLoginMode = false;

  // Controllers to capture user imput
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose(){
    // Clean up controllers when the screen is destroyed
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Access the "brain" (ViewModel)
    final provider = Provider.of<RegistrationProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text(_isLoginMode ? "Login" : "Registration")),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          child: provider.isLoading
            ? const CircularProgressIndicator() // Show spinner if loading
            : SingleChildScrollView(
              child : Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    if (provider.isSuccess) _buildSuccessUI(context),
                    if(!provider.isSuccess) ...[
                      // Full Name text field appears only during registration
                      if (!_isLoginMode) ...[
                        _buildTextField(_nameController, "Full Name", Icons.person),
                        const SizedBox(height: 15),
                        ],

                        // These fields stay for BOTH modes
                        _buildTextField(_emailController, "Email Address", Icons.email),
                        const SizedBox(height: 15),
                        _buildTextField(_passwordController, "Password", Icons.lock, obscure: true),
                        const SizedBox(height: 30),

                        if(provider.errorMessage != null) 
                          Text("Error: ${provider.errorMessage}", style: const TextStyle(color: Colors.red)),

                        ElevatedButton(
                          style: ElevatedButton.styleFrom(minimumSize: const Size(70, 50)),
                          onPressed:() {
                            // Select the correct action based on the mode
                            if(_isLoginMode){
                              // Pass captured login data to provider
                              provider.handleLogin(
                                email: _emailController.text.trim(),
                                 password: _passwordController.text.trim(),
                              );
                            } else {
                              // Pass captured registration data to provider
                              provider.handleRegistration(
                              name: _nameController.text.trim(), 
                              email: _emailController.text.trim(), 
                              password: _passwordController.text.trim(),
                            );
                            }
                          },
                          child: Text(_isLoginMode ? "Login" : "Register Account & Device"),
                        ),

                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isLoginMode = !_isLoginMode;
                              provider.reset(); // Clear any existing errors when switching modes
                            });
                          },
                          child: Text(_isLoginMode 
                            ? "New here? Create an account" 
                            : "Already have an account? Login"),
                        ),
                    ],    
                  ],                  
                ),
            ),      
        ),
      );
  }

  // Helper widget for a clean UI
  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool obscure = false}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildSuccessUI(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, // Vertical centering
        crossAxisAlignment: CrossAxisAlignment.center, // Horizontal child alignment
         children: [
           // Add top padding so it's not glued to the AppBar
          const SizedBox(height: 100),
          
          const Icon(Icons.check_circle, color: Colors.green, size: 60),
          Text( _isLoginMode ? "Login Successful" : "Registered Successfully", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {

              //Fetch the newly saved dynamic ID straight out of SharedPreferences
              final prefs = await SharedPreferences.getInstance();
              final String? newId = prefs.getString('saved_user_id');

              //  Inject the true active ID straight into CommunityProvider
              if (newId != null && context.mounted) {
                Provider.of<CommunityProvider>(context, listen: false).setCurrentUser(int.parse(newId));
              }

              if (context.mounted){
                // Navigate to the Dashboard
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const MainWrapper()),
                );
              }
            },
            child: const Text("Enter Dashboard", style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
