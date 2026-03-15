import 'package:flutter/material.dart';
import 'pages/login_page.dart';

void main() {
  runApp(const LojaMaeApp());
}

class LojaMaeApp extends StatelessWidget {
  const LojaMaeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LojaMae',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const LoginPage(), // ✅ Sistema começa pelo Login agora
    );
  }
}