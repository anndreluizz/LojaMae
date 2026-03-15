import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'widgets/menu_lateral.dart';

class CaixaPage extends StatefulWidget {
  const CaixaPage({super.key});

  @override
  State<CaixaPage> createState() => _CaixaPageState();
}

class _CaixaPageState extends State<CaixaPage> {
  Map<String, dynamic>? caixa;
  bool carregando = true;
  final String baseUrl = "http://127.0.0.1:5012/api/caixa/aberto";

  @override
  void initState() {
    super.initState();
    buscarStatusCaixa();
  }

  Future<void> buscarStatusCaixa() async {
    setState(() => carregando = true);
    try {
      final response = await http.get(Uri.parse(baseUrl));
      if (response.statusCode == 200) {
        setState(() {
          caixa = json.decode(response.body);
          carregando = false;
        });
      } else {
        setState(() {
          caixa = null;
          carregando = false;
        });
      }
    } catch (e) {
      setState(() => carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LojaMae - Caixa (Dev)'),
        actions: [
          IconButton(onPressed: buscarStatusCaixa, icon: const Icon(Icons.refresh))
        ],
      ),
      drawer: const MenuLateral(), // <-- ISSO FAZ O MENU APARECER
      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: caixa == null
                  ? const Card(
                      child: ListTile(
                        leading: Icon(Icons.error, color: Colors.red),
                        title: Text('Nenhum caixa aberto'),
                        subtitle: Text('Abra um caixa no backend ou implemente o botão depois.'),
                      ),
                    )
                  : Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.check_box, color: Colors.green),
                                SizedBox(width: 10),
                                Text('Caixa ABERTO', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const Divider(),
                            Text('Id: ${caixa!['id']}'),
                            Text('Status: ${caixa!['status']}'),
                            Text('Valor inicial: ${caixa!['valorInicial']}'),
                            Text('Saldo caixa: ${caixa!['saldoCaixa']}'),
                          ],
                        ),
                      ),
                    ),
            ),
    );
  }
}