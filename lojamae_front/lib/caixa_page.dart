import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CaixaPage extends StatefulWidget {
  const CaixaPage({super.key});

  @override
  State<CaixaPage> createState() => _CaixaPageState();
}

class _CaixaPageState extends State<CaixaPage> {
  // ✅ URL HTTP da sua API (igual no dotnet run)
final String baseUrl = "http://127.0.0.1:5812";

  bool loading = false;
  String? error;
  Map<String, dynamic>? caixa;

  Future<void> carregar() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final res = await http.get(Uri.parse("$baseUrl/api/caixa/aberto"));

      if (res.statusCode == 200) {
        setState(() => caixa = jsonDecode(res.body) as Map<String, dynamic>);
      } else if (res.statusCode == 404) {
        setState(() => caixa = null);
      } else {
        setState(() => error = "Status ${res.statusCode}: ${res.body}");
      }
    } catch (e) {
      setState(() => error = "Falha: $e");
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    carregar();
  }

  String v(String key) => (caixa?[key] ?? "-").toString();

  @override
  Widget build(BuildContext context) {
    final temCaixa = caixa != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text("LojaMae - Caixa (Dev)"),
        actions: [
          IconButton(
            onPressed: loading ? null : carregar,
            icon: const Icon(Icons.refresh),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      color: Colors.red.withOpacity(0.15),
                      child: Text(
                        error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: temCaixa
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "✅ Caixa ABERTO",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text("Id: ${v("id")}"),
                                Text("Status: ${v("status")}"),
                                Text("Valor inicial: ${v("valorInicial")}"),
                                Text("Saldo caixa: ${v("saldoCaixa")}"),
                              ],
                            )
                          : const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "❌ Nenhum caixa aberto",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text("Abra um caixa no backend ou implemente botão depois."),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}