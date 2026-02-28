import 'package:flutter/material.dart';
import 'caixa_page.dart';

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
      theme: ThemeData(useMaterial3: true),
      home: const CaixaPage(),
    );
  }
}