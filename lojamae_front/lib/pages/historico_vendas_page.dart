import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../widgets/menu_lateral.dart';

class HistoricoVendasPage extends StatefulWidget {
  const HistoricoVendasPage({super.key});

  @override
  State<HistoricoVendasPage> createState() => _HistoricoVendasPageState();
}

class _HistoricoVendasPageState extends State<HistoricoVendasPage> {
  List vendas = [];
  bool carregando = true;
  final String urlBase = "http://127.0.0.1:5012/api";

  @override
  void initState() {
    super.initState();
    carregarVendas();
  }

  Future<void> carregarVendas() async {
    setState(() => carregando = true);
    try {
      final response = await http.get(Uri.parse("$urlBase/Vendas"));
      if (response.statusCode == 200) {
        setState(() {
          vendas = json.decode(response.body);
          carregando = false;
        });
      }
    } catch (e) {
      print("Erro: $e");
      setState(() => carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Vendas'),
        actions: [IconButton(onPressed: carregarVendas, icon: const Icon(Icons.refresh))],
      ),
      drawer: const MenuLateral(),
      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : vendas.isEmpty
              ? const Center(child: Text("Nenhuma venda encontrada."))
              : RefreshIndicator(
                  onRefresh: carregarVendas,
                  child: ListView.builder(
                    itemCount: vendas.length,
                    itemBuilder: (context, index) {
                      final venda = vendas[index];
                      // Pega a data e corta apenas o dia/mês/ano se vier com hora
                      String dataOriginal = (venda['dataVenda'] ?? venda['DataVenda'] ?? "Sem data").toString();
                      String dataFormatada = dataOriginal.length > 10 ? dataOriginal.substring(0, 10) : dataOriginal;
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        elevation: 3,
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.blue,
                            child: Icon(Icons.shopping_cart, color: Colors.white),
                          ),
                          title: Text(
                            "Venda #${venda['id']} - ${venda['clienteNome'] ?? venda['ClienteNome'] ?? 'Consumidor'}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text("Data: $dataFormatada"),
                          trailing: Text(
                            "R\$ ${venda['total'] ?? venda['Total']}",
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}