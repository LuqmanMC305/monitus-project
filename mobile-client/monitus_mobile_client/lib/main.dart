import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/registration_provider.dart';
import 'screens/registration_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';


void main() async{
  // Ensure the initialisation of Flutter bindings
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise Firebase
  try{
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
  } catch (e){
    debugPrint("Firebase initialisation failed! $e");
  }
  

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RegistrationProvider()),
      ],
      child: const MonitusApp(),
    ),
  );
}

class MonitusApp extends StatelessWidget {
  const MonitusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Monitus',
      home: RegistrationScreen(),
    );
  }
}