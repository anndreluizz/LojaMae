import 'package:flutter/material.dart';
import '../services/api_service.dart';

class NovaVendaPage extends StatefulWidget {
  const NovaVendaPage({super.key});

  @override
  State<NovaVendaPage> createState() => _NovaVendaPageState();
}

class _NovaVendaPageState extends State<NovaVendaPage> {
  final TextEditingController clienteController =
      TextEditingController(text: 'andre');
  final TextEditingController produtoController = TextEditingController();
  final TextEditingController quantidadeController =
      TextEditingController(text: '1');
  final TextEditingController valorController =
      TextEditingController(text: '25,00');

  String formaPagamento = 'Cartão';

  int? vendaId;
  bool carregando = false;

  final List<Map<String, dynamic>> itens = [];

  // 🔓 INICIAR VENDA
  @override
  void initState() {
    super.initState();
    iniciarVenda();
  }

  Future<void> iniciarVenda() async {
    vendaId = await ApiService.abrirVenda();

    if (vendaId != null) {
      print('Venda iniciada: $vendaId');
    } else {
      print('Erro ao iniciar venda');
    }
  }

  // ➕ ADICIONAR PRODUTO
  void adicionarProduto() {
    final nome = produtoController.text.trim();
    final quantidadeTexto = quantidadeController.text.trim();
    final valorTexto = valorController.text.trim().replaceAll(',', '.');

    if (nome.isEmpty || quantidadeTexto.isEmpty || valorTexto.isEmpty) return;

    final quantidade = int.tryParse(quantidadeTexto);
    final valor = double.tryParse(valorTexto);

    if (quantidade == null || quantidade <= 0 || valor == null || valor <= 0) {
      return;
    }

    setState(() {
      itens.add({
        'nome': nome,
        'quantidade': quantidade,
        'valor': valor,
      });
    });

    produtoController.clear();
    quantidadeController.text = '1';
    valorController.text = '25,00';
  }

  void removerProduto(int index) {
    setState(() {
      itens.removeAt(index);
    });
  }

  double get subtotal {
    double total = 0;
    for (final item in itens) {
      total += (item['quantidade'] as int) * (item['valor'] as double);
    }
    return total;
  }

  int get totalItens {
    int total = 0;
    for (final item in itens) {
      total += item['quantidade'] as int;
    }
    return total;
  }

  String formatarValor(double valor) {
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  // 🚀 FINALIZAR VENDA (API REAL)
  Future<void> finalizarVenda() async {
    if (vendaId == null) {
      print('Venda não iniciada');
      return;
    }

    setState(() => carregando = true);

    try {
      // ➕ Enviar itens
      for (var item in itens) {
        await ApiService.adicionarItem(
          vendaId!,
          item['nome'],
          item['quantidade'],
        );
      }

      // 💰 Pagamento
      await ApiService.pagar(
        vendaId!,
        subtotal,
        formaPagamento,
      );

      // ✅ Fechar venda
      await ApiService.fecharVenda(vendaId!);

      print('Venda finalizada com sucesso');

      // 🔄 Reset
      setState(() {
        itens.clear();
        vendaId = null;
      });

      await iniciarVenda();
    } catch (e) {
      print('Erro ao finalizar venda: $e');
    }

    setState(() => carregando = false);
  }

  @override
  void dispose() {
    clienteController.dispose();
    produtoController.dispose();
    quantidadeController.dispose();
    valorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: Padding(
        padding: const EdgeInsets.all(28),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ESQUERDA
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 18,
                      color: Color(0x14000000),
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nova Venda',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 20),

                    TextField(
                      controller: clienteController,
                      decoration: const InputDecoration(
                        labelText: 'Cliente',
                      ),
                    ),

                    const SizedBox(height: 20),

                    TextField(
                      controller: produtoController,
                      onSubmitted: (_) => adicionarProduto(),
                      decoration: InputDecoration(
                        labelText: 'Produto',
                        suffixIcon: IconButton(
                          onPressed: adicionarProduto,
                          icon: const Icon(Icons.add),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: quantidadeController,
                            keyboardType: TextInputType.number,
                            decoration:
                                const InputDecoration(labelText: 'Qtd'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: valorController,
                            decoration:
                                const InputDecoration(labelText: 'Valor'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    Expanded(
                      child: ListView.builder(
                        itemCount: itens.length,
                        itemBuilder: (context, index) {
                          final item = itens[index];
                          return ListTile(
                            title: Text(item['nome']),
                            subtitle: Text(
                                '${item['quantidade']}x - ${formatarValor(item['valor'])}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => removerProduto(index),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 24),

            // DIREITA
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Subtotal: ${formatarValor(subtotal)}'),
                    Text('Itens: $totalItens'),

                    const SizedBox(height: 20),

                    DropdownButton<String>(
                      value: formaPagamento,
                      items: const [
                        DropdownMenuItem(
                            value: 'Dinheiro', child: Text('Dinheiro')),
                        DropdownMenuItem(value: 'Pix', child: Text('Pix')),
                        DropdownMenuItem(
                            value: 'Cartão', child: Text('Cartão')),
                        DropdownMenuItem(
                            value: 'Fiado', child: Text('Fiado')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => formaPagamento = value);
                        }
                      },
                    ),

                    const Spacer(),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: carregando ? null : finalizarVenda,
                        child: carregando
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text('Finalizar Venda'),
                      ),
                    ),
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