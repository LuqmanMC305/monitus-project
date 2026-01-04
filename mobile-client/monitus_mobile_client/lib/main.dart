import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main(){
  runApp(MyApp());
}

class MyApp extends StatefulWidget{
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}
  
class _MyAppState extends State<MyApp>{
  String greet = "Hello";
  int value = 5;

  @override
    void initState(){
      super.initState();
      fetchGreeting();
    }

    Future<void> fetchGreeting() async{
      final res = await http.get(
        Uri.parse('http://10.0.2.2:8000/api/hello')
      );

      final data =jsonDecode(res.body);

      setState(() {
        greet = data['message'];
        value = data['value'];
      });
    }

  @override
  Widget build(BuildContext context){
    
    return MaterialApp(
      home:Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
            Text(greet),
            Text('$value'),
          ]),
        ),
      ),
    );
  }

}
  



