import 'package:flutter/material.dart';
import 'alert_history_screen.dart';
import 'community_list_screen.dart';
import 'map_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'registration_screen.dart'; 
import 'package:provider/provider.dart';
import '../providers/registration_provider.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _selectedIndex = 0;
  String _userName = "User"; // Default mobile user name

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  // The list of screens to toggle between
  final List<Widget> _screens = [
    const AlertHistoryScreen(), // Index 0 -> History
    const CommunityListScreen(), // Index 1 -> New Community Discovery Screen
    const AlertMapScreen(), // Index 2 -> Map
  ];

  Future<void> _handleLogout() async{
    final prefs = await SharedPreferences.getInstance();

    // Clear identity from storage
    await prefs.remove('saved_user_id');
    await prefs.remove('last_activity'); // Timeout logic

    if(!mounted) return;
    // RESET PROVIDER STATE
    Provider.of<RegistrationProvider>(context, listen: false).reset();

    // Redirect to Registration and clear navigation stack
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const RegistrationScreen()),
      (route) => false,
    );
    
    debugPrint("Identity Cleared: User logged out.");
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // Fetch the name we saved earlier
      _userName = prefs.getString('user_name') ?? "User";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Monitus'),
            const SizedBox(width: 8),
            Text(
              '| $_userName', 
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            )
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: (){
              _showLogoutConfirmation();
            },
          ),
        ],
      ),
      
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ), // Display the selected screen

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
            label: 'Alert List',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Communities',
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