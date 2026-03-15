import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../widgets/menu_lateral.dart';

class ClientesPage extends StatefulWidget {
  const ClientesPage({super.key});

  @override
  State<ClientesPage> createState() => _ClientesPageState();
}

class _ClientesPageState extends State<ClientesPage> {
  List clientes = [];
  bool carregando = true;
  final String baseUrl = "http://127.0.0.1:5012/api/clientes";

  @override
  void initState() {
    super.initState();
    buscarClientes();
  }

  Future<void> buscarClientes() async {
    setState(() => carregando = true);
    final response = await http.get(Uri.parse(baseUrl));
    if (response.statusCode == 200) {
      setState(() {
        clientes = json.decode(response.body);
        carregando = false;
      });
    } else {
      setState(() => carregando = false);
    }
  }

  void _abrirFormularioCadastro() {
    final nomeCtrl = TextEditingController();
    final telefoneCtrl = TextEditingController();
    final cidadeCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Novo Cliente'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nomeCtrl, decoration: const InputDecoration(labelText: 'Nome')),
            TextField(controller: telefoneCtrl, decoration: const InputDecoration(labelText: 'Telefone')),
            TextField(controller: cidadeCtrl, decoration: const InputDecoration(labelText: 'Cidade')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final body = json.encode({
                'nome': nomeCtrl.text,
                'telefone': telefoneCtrl.text,
                'cidade': cidadeCtrl.text,
              });
              final response = await http.post(
                Uri.parse(baseUrl),
                headers: {'Content-Type': 'application/json'},
                body: body,
              );
              if (response.statusCode == 201) {
                Navigator.pop(context);
                buscarClientes();
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clientes')),
      drawer: const MenuLateral(),
      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : clientes.isEmpty
              ? const Center(child: Text('Nenhum cliente cadastrado.'))
              : ListView.builder(
                  itemCount: clientes.length,
                  itemBuilder: (context, index) {
                    final cliente = clientes[index];
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(cliente['nome']),
                      subtitle: Text("${cliente['telefone']} - ${cliente['cidade']}"),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _abrirFormularioCadastro,
        child: const Icon(Icons.add),
      ),
    );
  }
}