import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/registration_provider.dart';
import 'screens/registration_screen.dart';

void main() {
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