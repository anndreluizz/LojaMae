import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../widgets/menu_lateral.dart';

class ProdutosPage extends StatefulWidget {
  const ProdutosPage({super.key});

  @override
  State<ProdutosPage> createState() => _ProdutosPageState();
}

class _ProdutosPageState extends State<ProdutosPage> {
  List produtos = [];
  bool carregando = true;
  final String baseUrl = "http://127.0.0.1:5012/api/produtos";

  @override
  void initState() {
    super.initState();
    buscarProdutos();
  }

  Future<void> buscarProdutos() async {
    setState(() => carregando = true);
    try {
      final response = await http.get(Uri.parse(baseUrl));
      if (response.statusCode == 200) {
        setState(() {
          produtos = json.decode(response.body);
          carregando = false;
        });
      } else {
        setState(() => carregando = false);
      }
    } catch (e) {
      setState(() => carregando = false);
    }
  }

  void _abrirFormularioProduto({dynamic produtoExistente}) {
    // ✅ Limpa o preço para edição (remove R$ se vier do banco)
    String precoInicial = produtoExistente?['preco']?.toString() ?? '';
    
    final nomeCtrl = TextEditingController(text: produtoExistente?['nome'] ?? '');
    final precoCtrl = TextEditingController(text: precoInicial);
    final estoqueCtrl = TextEditingController(text: produtoExistente?['estoque']?.toString() ?? '');
    final codigoCtrl = TextEditingController(text: produtoExistente?['codigoBarras'] ?? '');
    final codigoFocus = FocusNode();

    final bool editando = produtoExistente != null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(editando ? 'Editar Produto' : 'Novo Produto'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codigoCtrl,
                focusNode: codigoFocus,
                decoration: const InputDecoration(
                  labelText: 'Código de Barras',
                  prefixIcon: Icon(Icons.qr_code_scanner),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: nomeCtrl,
                decoration: const InputDecoration(labelText: 'Nome do Produto', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: precoCtrl,
                decoration: const InputDecoration(
                  labelText: 'Preço', 
                  prefixText: 'R\$ ', 
                  hintText: '0.00',
                  border: OutlineInputBorder()
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: estoqueCtrl,
                decoration: const InputDecoration(labelText: 'Estoque Inicial', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              // ✅ LIMPEZA DOS DADOS ANTES DE ENVIAR
              String precoLimpo = precoCtrl.text
                  .replaceAll('R\$', '')
                  .replaceAll(' ', '')
                  .replaceAll(',', '.');

              final body = json.encode({
                'id': produtoExistente?['id'] ?? 0, // Importante para o Put
                'nome': nomeCtrl.text,
                'preco': double.tryParse(precoLimpo) ?? 0.0,
                'estoque': int.tryParse(estoqueCtrl.text) ?? 0,
                'codigoBarras': codigoCtrl.text.trim().isEmpty ? null : codigoCtrl.text.trim(),
              });

              http.Response response;
              if (editando) {
                response = await http.put(
                  Uri.parse("$baseUrl/${produtoExistente['id']}"),
                  headers: {'Content-Type': 'application/json'},
                  body: body,
                );
              } else {
                response = await http.post(
                  Uri.parse(baseUrl),
                  headers: {'Content-Type': 'application/json'},
                  body: body,
                );
              }

              if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204) {
                if (mounted) Navigator.pop(context);
                buscarProdutos();
              } else {
                // Mostra erro se falhar
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Erro: ${response.body}"), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: Text(editando ? 'Atualizar' : 'Salvar'),
          ),
        ],
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => codigoFocus.requestFocus());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Produtos')),
      drawer: const MenuLateral(),
      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : produtos.isEmpty
              ? const Center(child: Text('Nenhum produto cadastrado.'))
              : ListView.builder(
                  itemCount: produtos.length,
                  itemBuilder: (context, index) {
                    final produto = produtos[index];
                    return ListTile(
                      leading: const Icon(Icons.inventory_2),
                      title: Text(produto['nome']),
                      subtitle: Text("Estoque: ${produto['estoque']} | 🔖 ${produto['codigoBarras'] ?? 'Sem código'}"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("R\$ ${produto['preco']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _abrirFormularioProduto(produtoExistente: produto),
                          ),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirFormularioProduto(),
        child: const Icon(Icons.add),
      ),
    );
  }
}