import 'package:flutter/material.dart';
import 'pages/home_page.dart';

void main() {
  runApp(const LojaMaeApp());
}

class LojaMaeApp extends StatelessWidget {
  const LojaMaeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Loja Mãe',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
      ),
      home: const HomePage(),
    );
  }
}