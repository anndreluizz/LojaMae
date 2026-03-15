import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../widgets/menu_lateral.dart';
import '../services/recibo_service.dart';

class VendasPage extends StatefulWidget {
  const VendasPage({super.key});

  @override
  State<VendasPage> createState() => _VendasPageState();
}

class _VendasPageState extends State<VendasPage> {
  List clientes = [];
  List produtos = [];
  List produtosFiltrados = [];
  List itensVenda = [];
  dynamic clienteSelecionado;
  final String urlBase = "http://127.0.0.1:5012/api";

  // ✅ Busca por código de barras (sempre visível no topo)
  final TextEditingController _codigoController = TextEditingController();
  final FocusNode _codigoFocusNode = FocusNode();

  // ✅ Busca no modal
  final TextEditingController _buscaController = TextEditingController();

  // ✅ Desconto
  final TextEditingController _descontoController = TextEditingController(text: "0.00");
  double desconto = 0.0;

  @override
  void initState() {
    super.initState();
    carregarDados();
    // Foca no campo de código de barras ao abrir a tela
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _codigoFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _codigoFocusNode.dispose();
    _buscaController.dispose();
    _descontoController.dispose();
    super.dispose();
  }

  Future<void> carregarDados() async {
    final resClientes = await http.get(Uri.parse("$urlBase/clientes"));
    final resProdutos = await http.get(Uri.parse("$urlBase/produtos"));
    setState(() {
      clientes = json.decode(resClientes.body);
      produtos = json.decode(resProdutos.body);
      produtosFiltrados = produtos;
    });
  }

  // ✅ Busca por código de barras (leitor físico ou digitado)
  void buscarPorCodigo(String codigo) {
    if (codigo.trim().isEmpty) return;

    final produto = produtos.firstWhere(
      (p) =>
          (p['codigoBarras'] != null &&
              p['codigoBarras'].toString() == codigo.trim()) ||
          p['nome'].toString().toLowerCase().contains(codigo.toLowerCase()),
      orElse: () => null,
    );

    if (produto != null) {
      adicionarProduto(produto);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("✅ ${produto['nome']} adicionado!"),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Produto \"$codigo\" não encontrado."),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    _codigoController.clear();
    _codigoFocusNode.requestFocus(); // Mantém o foco para o próximo produto
  }

  void adicionarProduto(dynamic produto) {
    int estoqueAtual = produto['estoque'] ?? 0;

    if (estoqueAtual <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ \"${produto['nome']}\" sem estoque!"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    int indexExistente =
        itensVenda.indexWhere((i) => i['produtoId'] == produto['id']);

    if (indexExistente >= 0) {
      int qtdNoCarrinho = itensVenda[indexExistente]['quantidade'];
      if (qtdNoCarrinho >= estoqueAtual) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                "⚠️ Estoque máximo de \"${produto['nome']}\" atingido! ($estoqueAtual disponível)"),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      setState(() {
        itensVenda[indexExistente]['quantidade']++;
      });
    } else {
      setState(() {
        itensVenda.add({
          'produtoId': produto['id'],
          'nome': produto['nome'],
          'quantidade': 1,
          'precoUnitario': produto['preco'],
          'estoqueDisponivel': estoqueAtual,
        });
      });
    }
  }

  double calcularSubtotal() => itensVenda.fold(
      0, (sum, item) => sum + (item['precoUnitario'] * item['quantidade']));

  double calcularTotal() => (calcularSubtotal() - desconto).clamp(0, double.infinity);

  // ✅ Modal de Desconto
  void mostrarModalDesconto() {
    _descontoController.text = desconto.toStringAsFixed(2);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Aplicar Desconto"),
        content: TextField(
          controller: _descontoController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: "Valor do Desconto (R\$)",
            prefixText: "R\$ ",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                desconto = double.tryParse(_descontoController.text.replaceAll(',', '.')) ?? 0.0;
                if (desconto > calcularSubtotal()) desconto = calcularSubtotal();
              });
              Navigator.pop(context);
            },
            child: const Text("Aplicar"),
          ),
        ],
      ),
    );
  }

  Future<void> finalizarFluxoVenda(int formaPagamento) async {
    if (mounted) Navigator.pop(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 1. Abrir Venda
      final resAbrir = await http.post(
        Uri.parse("$urlBase/Vendas/abrir"),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'ClienteId': clienteSelecionado['id']}),
      );
      final vendaId = json.decode(resAbrir.body)['vendaId'];

      // 2. Adicionar Itens
      for (var item in itensVenda) {
        await http.post(
          Uri.parse("$urlBase/Vendas/$vendaId/itens"),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'ProdutoId': item['produtoId'],
            'Quantidade': item['quantidade']
          }),
        );
      }

      // ✅ 3. Aplicar Desconto (se houver)
      if (desconto > 0) {
        await http.post(
          Uri.parse("$urlBase/Vendas/$vendaId/desconto"),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'desconto': desconto}),
        );
      }

      // 4. Registrar Pagamento
      await http.post(
        Uri.parse("$urlBase/Vendas/$vendaId/pagar"),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'Valor': calcularTotal(), 'Forma': formaPagamento}),
      );

      // 5. Fechar Venda
      await http.post(Uri.parse("$urlBase/Vendas/$vendaId/fechar"));

      // 6. Gerar Recibo
      String formaTxt = formaPagamento == 0
          ? "Dinheiro"
          : formaPagamento == 1
              ? "Pix"
              : "Cartão";

      final itensParaRecibo = List.from(itensVenda);
      final totalParaRecibo = calcularTotal();
      final clienteNome = clienteSelecionado['nome'];

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Venda Finalizada! Gerando recibo..."),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() {
          itensVenda.clear();
          clienteSelecionado = null;
          desconto = 0.0;
          _descontoController.text = "0.00";
        });
        _codigoFocusNode.requestFocus();
      }

      await ReciboService.gerarRecibo(
        vendaId: vendaId,
        cliente: clienteNome,
        itens: itensParaRecibo,
        total: totalParaRecibo,
        formaPagamento: formaTxt,
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Erro: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  void mostrarModalPagamento() {
    if (clienteSelecionado == null || itensVenda.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠️ Selecione um cliente e adicione produtos!"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Forma de Pagamento"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.money, color: Colors.green),
              title: const Text("Dinheiro"),
              onTap: () => finalizarFluxoVenda(0),
            ),
            ListTile(
              leading: const Icon(Icons.pix, color: Colors.blue),
              title: const Text("Pix"),
              onTap: () => finalizarFluxoVenda(1),
            ),
            ListTile(
              leading: const Icon(Icons.credit_card, color: Colors.purple),
              title: const Text("Cartão"),
              onTap: () => finalizarFluxoVenda(2),
            ),
          ],
        ),
      ),
    );
  }

  void mostrarBuscaProdutos() {
    _buscaController.clear();
    produtosFiltrados = produtos;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _buscaController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: "Buscar Produto...",
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) {
                  setModalState(() {
                    produtosFiltrados = produtos
                        .where((p) => p['nome']
                            .toString()
                            .toLowerCase()
                            .contains(val.toLowerCase()))
                        .toList();
                  });
                },
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: produtosFiltrados.length,
                  itemBuilder: (context, index) {
                    final produto = produtosFiltrados[index];
                    final estoque = produto['estoque'] ?? 0;
                    final semEstoque = estoque <= 0;
                    return ListTile(
                      title: Text(produto['nome'],
                          style: TextStyle(
                              color: semEstoque ? Colors.grey : Colors.black)),
                      subtitle: Text("R\$ ${produto['preco']}"),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: semEstoque
                              ? Colors.red[100]
                              : Colors.green[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          semEstoque ? "Sem estoque" : "Estoque: $estoque",
                          style: TextStyle(
                              color: semEstoque ? Colors.red : Colors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      onTap: () {
                        adicionarProduto(produto);
                        if (!semEstoque) Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nova Venda')),
      drawer: const MenuLateral(),
      body: Column(
        children: [
          // ✅ Campo de Código de Barras (sempre visível no topo)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: TextField(
              controller: _codigoController,
              focusNode: _codigoFocusNode,
              decoration: InputDecoration(
                labelText: "🔎 Código de Barras ou Nome do Produto",
                hintText: "Bipe o produto ou digite o nome...",
                prefixIcon: const Icon(Icons.qr_code_scanner),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => buscarPorCodigo(_codigoController.text),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: Colors.blue[50],
              ),
              onSubmitted: buscarPorCodigo, // ✅ Enter ou leitura do leitor físico
            ),
          ),

          // Seleção de Cliente
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<dynamic>(
              hint: const Text("Selecione o Cliente"),
              value: clienteSelecionado,
              isExpanded: true,
              items: clientes
                  .map((c) =>
                      DropdownMenuItem(value: c, child: Text(c['nome'])))
                  .toList(),
              onChanged: (val) => setState(() => clienteSelecionado = val),
            ),
          ),

          const Divider(),

          // Lista de Itens
          Expanded(
            child: itensVenda.isEmpty
                ? const Center(
                    child: Text(
                      "Nenhum produto adicionado.\nBipe o código ou clique em + ADICIONAR PRODUTO",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: itensVenda.length,
                    itemBuilder: (context, index) => ListTile(
                      title: Text(itensVenda[index]['nome']),
                      subtitle: Text("Qtd: ${itensVenda[index]['quantidade']}"),
                      trailing: Text(
                        "R\$ ${(itensVenda[index]['precoUnitario'] * itensVenda[index]['quantidade']).toStringAsFixed(2)}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      leading: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () =>
                            setState(() => itensVenda.removeAt(index)),
                      ),
                    ),
                  ),
          ),

          // Botão Adicionar Produto
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: ElevatedButton.icon(
              onPressed: mostrarBuscaProdutos,
              icon: const Icon(Icons.add),
              label: const Text("ADICIONAR PRODUTO"),
            ),
          ),

          // ✅ Rodapé com Subtotal, Desconto e Total
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.blueGrey[50],
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Subtotal:", style: TextStyle(fontSize: 14, color: Colors.grey)),
                    Text("R\$ ${calcularSubtotal().toStringAsFixed(2)}", style: const TextStyle(fontSize: 14)),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: mostrarModalDesconto,
                      icon: const Icon(Icons.discount, color: Colors.orange, size: 18),
                      label: Text(
                        desconto > 0 ? "Desconto: - R\$ ${desconto.toStringAsFixed(2)}" : "Adicionar Desconto",
                        style: const TextStyle(color: Colors.orange),
                      ),
                    ),
                    if (desconto > 0)
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red, size: 18),
                        onPressed: () => setState(() => desconto = 0.0),
                      ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Total: R\$ ${calcularTotal().toStringAsFixed(2)}",
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    ElevatedButton(
                      onPressed: mostrarModalPagamento,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      ),
                      child: const Text("FINALIZAR", style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}