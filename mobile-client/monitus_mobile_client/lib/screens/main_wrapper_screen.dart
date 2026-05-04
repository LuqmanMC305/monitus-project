import 'package:flutter/material.dart';
import 'alert_history_screen.dart';
import 'map_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'registration_screen.dart'; 

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _selectedIndex = 0;

  // The list of screens to toggle between
  final List<Widget> _screens = [
    const AlertHistoryScreen(),
    const AlertMapScreen(),
  ];

  Future<void> _handleLogout() async{
    final prefs = await SharedPreferences.getInstance();

    // Clear identity from storage
    await prefs.remove('saved_user_id');
    await prefs.remove('last_activity'); // Timeout logic

    if(!mounted) return;

    // Redirect to Registration and clear navigation stack
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const RegistrationScreen()),
      (route) => false,
    );
    
    debugPrint("Identity Cleared: User logged out.");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitus'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: (){
              _showLogoutConfirmation();
            },
          ),
        ],
      ),
      body: _screens[_selectedIndex], // Display the selected screen
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
        ],
      ),
    );
  }

  // Quick confirmation dialogue for logout
  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(onPressed: () => _handleLogout(), child: const Text("Logout", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}