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

  final TextEditingController _codigoController = TextEditingController();
  final FocusNode _codigoFocusNode = FocusNode();

  final TextEditingController _buscaController = TextEditingController();

  final TextEditingController _descontoController =
      TextEditingController(text: "0.00");

  double desconto = 0.0;
  bool carregando = true;

  @override
  void initState() {
    super.initState();
    carregarDados();

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
    try {
      setState(() => carregando = true);

      final resClientes = await http.get(Uri.parse("$urlBase/clientes"));
      final resProdutos = await http.get(Uri.parse("$urlBase/produtos"));

      setState(() {
        clientes = json.decode(resClientes.body);
        produtos = json.decode(resProdutos.body);
        produtosFiltrados = produtos;
        carregando = false;
      });
    } catch (e) {
      setState(() => carregando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Erro ao carregar dados: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void buscarPorCodigo(String codigo) {
    if (codigo.trim().isEmpty) return;

    final busca = codigo.trim().toLowerCase();

    dynamic produtoEncontrado;
    try {
      produtoEncontrado = produtos.firstWhere(
        (p) =>
            (p['codigoBarras'] != null &&
                p['codigoBarras'].toString().trim() == codigo.trim()) ||
            p['nome'].toString().toLowerCase().contains(busca),
      );
    } catch (_) {
      produtoEncontrado = null;
    }

    if (produtoEncontrado != null) {
      adicionarProduto(produtoEncontrado);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("✅ ${produtoEncontrado['nome']} adicionado!"),
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
    _codigoFocusNode.requestFocus();
  }

  void adicionarProduto(dynamic produto) {
    final int estoqueAtual = produto['estoque'] ?? 0;

    if (estoqueAtual <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ \"${produto['nome']}\" sem estoque!"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final int indexExistente =
        itensVenda.indexWhere((i) => i['produtoId'] == produto['id']);

    if (indexExistente >= 0) {
      final int qtdNoCarrinho = itensVenda[indexExistente]['quantidade'];

      if (qtdNoCarrinho >= estoqueAtual) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "⚠️ Estoque máximo de \"${produto['nome']}\" atingido! ($estoqueAtual disponível)",
            ),
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
          'precoUnitario': (produto['preco'] as num).toDouble(),
          'estoqueDisponivel': estoqueAtual,
        });
      });
    }
  }

  void removerItem(int index) {
    setState(() {
      itensVenda.removeAt(index);
    });
  }

  void aumentarQuantidade(int index) {
    final item = itensVenda[index];
    final estoqueDisponivel = item['estoqueDisponivel'] ?? 0;
    final quantidadeAtual = item['quantidade'] ?? 0;

    if (quantidadeAtual >= estoqueDisponivel) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "⚠️ Estoque máximo de \"${item['nome']}\" atingido! ($estoqueDisponivel disponível)",
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      itensVenda[index]['quantidade']++;
    });
  }

  void diminuirQuantidade(int index) {
    final quantidadeAtual = itensVenda[index]['quantidade'] ?? 1;

    setState(() {
      if (quantidadeAtual > 1) {
        itensVenda[index]['quantidade']--;
      } else {
        itensVenda.removeAt(index);
      }
    });
  }

  double calcularSubtotal() {
    return itensVenda.fold<double>(
      0,
      (sum, item) =>
          sum +
          ((item['precoUnitario'] as num).toDouble() *
              (item['quantidade'] as num).toDouble()),
    );
  }

  double calcularTotal() {
    return (calcularSubtotal() - desconto).clamp(0, double.infinity);
  }

  void mostrarModalDesconto() {
    _descontoController.text = desconto.toStringAsFixed(2);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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
                desconto = double.tryParse(
                      _descontoController.text.replaceAll(',', '.'),
                    ) ??
                    0.0;

                if (desconto > calcularSubtotal()) {
                  desconto = calcularSubtotal();
                }
              });

              Navigator.pop(context);
            },
            child: const Text("Aplicar"),
          ),
        ],
      ),
    );
  }

Future<void> finalizarFluxoVenda(String formaPagamento) async {
  if (mounted) Navigator.pop(context);

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(child: CircularProgressIndicator()),
  );

  try {
    final bodyAbrir = {
      'ClienteId': clienteSelecionado != null ? clienteSelecionado['id'] : 0,
    };

    final resAbrir = await http.post(
      Uri.parse("$urlBase/Vendas/abrir"),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(bodyAbrir),
    );

    if (resAbrir.statusCode < 200 || resAbrir.statusCode >= 300) {
      throw Exception("Erro ao abrir venda: ${resAbrir.body}");
    }

    final vendaId = json.decode(resAbrir.body)['vendaId'];

    for (var item in itensVenda) {
      final resItem = await http.post(
        Uri.parse("$urlBase/Vendas/$vendaId/itens"),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'ProdutoId': item['produtoId'],
          'Quantidade': item['quantidade'],
        }),
      );

      if (resItem.statusCode < 200 || resItem.statusCode >= 300) {
        throw Exception("Erro ao adicionar item: ${resItem.body}");
      }
    }

    if (desconto > 0) {
      final resDesconto = await http.post(
        Uri.parse("$urlBase/Vendas/$vendaId/desconto"),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'desconto': desconto}),
      );

      if (resDesconto.statusCode < 200 || resDesconto.statusCode >= 300) {
        throw Exception("Erro ao aplicar desconto: ${resDesconto.body}");
      }
    }

    final resFechar =
        await http.post(Uri.parse("$urlBase/Vendas/$vendaId/fechar"));

    if (resFechar.statusCode < 200 || resFechar.statusCode >= 300) {
      throw Exception("Erro ao fechar venda: ${resFechar.body}");
    }

    final resPagamento = await http.post(
      Uri.parse("$urlBase/Vendas/$vendaId/pagar"),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'valor': calcularTotal(),
        'forma': formaPagamento,
      }),
    );

    if (resPagamento.statusCode < 200 || resPagamento.statusCode >= 300) {
      throw Exception("Erro ao registrar pagamento: ${resPagamento.body}");
    }

    final itensParaRecibo = List.from(itensVenda);
    final totalParaRecibo = calcularTotal();
    final descontoParaRecibo = desconto;
    final clienteNome = clienteSelecionado != null
        ? clienteSelecionado['nome'].toString()
        : "NÃO INFORMADO";

    if (mounted) {
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Venda finalizada! Gerando recibo..."),
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

      _codigoController.clear();
      _codigoFocusNode.requestFocus();
    }

    await ReciboService.gerarRecibo(
      vendaId: vendaId,
      cliente: clienteNome,
      itens: itensParaRecibo,
      total: totalParaRecibo,
      formaPagamento: formaPagamento,
      desconto: descontoParaRecibo,
    );
  } catch (e) {
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Erro: $e"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

void mostrarModalPagamento() {
  if (itensVenda.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("⚠️ Adicione produtos antes de finalizar!"),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: const Text("Forma de Pagamento"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.money, color: Colors.green),
            title: const Text("Dinheiro"),
            onTap: () => finalizarFluxoVenda("Dinheiro"),
          ),
          ListTile(
            leading: const Icon(Icons.pix, color: Colors.blue),
            title: const Text("Pix"),
            onTap: () => finalizarFluxoVenda("Pix"),
          ),
          ListTile(
            leading: const Icon(Icons.credit_card, color: Colors.purple),
            title: const Text("Cartão"),
            onTap: () => finalizarFluxoVenda("Cartão"),
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
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.82,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _buscaController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: "Buscar Produto...",
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (val) {
                  setModalState(() {
                    produtosFiltrados = produtos.where((p) {
                      final nome = p['nome'].toString().toLowerCase();
                      final codigo = (p['codigoBarras'] ?? '').toString().toLowerCase();
                      final busca = val.toLowerCase();

                      return nome.contains(busca) || codigo.contains(busca);
                    }).toList();
                  });
                },
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: produtosFiltrados.length,
                  itemBuilder: (context, index) {
                    final produto = produtosFiltrados[index];
                    final estoque = produto['estoque'] ?? 0;
                    final semEstoque = estoque <= 0;

                    return Card(
                      elevation: 1,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(
                          produto['nome'],
                          style: TextStyle(
                            color: semEstoque ? Colors.grey : Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          "R\$ ${((produto['preco'] as num).toDouble()).toStringAsFixed(2)}",
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: semEstoque ? Colors.red[50] : Colors.green[50],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            semEstoque ? "Sem estoque" : "Estoque: $estoque",
                            style: TextStyle(
                              color: semEstoque ? Colors.red : Colors.green[800],
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        onTap: () {
                          adicionarProduto(produto);
                          if (!semEstoque) Navigator.pop(context);
                        },
                      ),
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

  Widget _buildCampoBusca() {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: TextField(
          controller: _codigoController,
          focusNode: _codigoFocusNode,
          decoration: InputDecoration(
            labelText: "Código de Barras ou Nome do Produto",
            hintText: "Bipe ou digite para buscar",
            prefixIcon: const Icon(Icons.qr_code_scanner),
            suffixIcon: IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => buscarPorCodigo(_codigoController.text),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.blue[50],
          ),
          onSubmitted: buscarPorCodigo,
        ),
      ),
    );
  }

  Widget _buildClienteCard() {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<dynamic>(
            hint: const Text("Selecionar cliente (opcional)"),
            value: clienteSelecionado,
            isExpanded: true,
            items: clientes
                .map(
                  (c) => DropdownMenuItem(
                    value: c,
                    child: Text(c['nome']),
                  ),
                )
                .toList(),
            onChanged: (val) => setState(() => clienteSelecionado = val),
          ),
        ),
      ),
    );
  }

  Widget _buildListaItens() {
    if (itensVenda.isEmpty) {
      return const Center(
        child: Text(
          "Nenhum produto adicionado.\nBipe o código ou clique em ADICIONAR PRODUTO.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      itemCount: itensVenda.length,
      itemBuilder: (context, index) {
        final item = itensVenda[index];
        final double totalItem =
            (item['precoUnitario'] as num).toDouble() *
                (item['quantidade'] as num).toDouble();

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => removerItem(index),
                  icon: const Icon(Icons.delete, color: Colors.red),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['nome'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Unitário: R\$ ${((item['precoUnitario'] as num).toDouble()).toStringAsFixed(2)}",
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => diminuirQuantidade(index),
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        Text(
                          "${item['quantidade']}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        IconButton(
                          onPressed: () => aumentarQuantidade(index),
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ],
                    ),
                    Text(
                      "R\$ ${totalItem.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

Widget _buildRodapeResumo() {
  return Container(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
    decoration: BoxDecoration(
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          blurRadius: 8,
          color: Colors.black.withOpacity(0.08),
          offset: const Offset(0, -2),
        ),
      ],
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
    ),
    child: SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Subtotal:",
                style: TextStyle(fontSize: 15, color: Colors.grey),
              ),
              Text(
                "R\$ ${calcularSubtotal().toStringAsFixed(2)}",
                style: const TextStyle(fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: mostrarModalDesconto,
                  icon: const Icon(Icons.discount, color: Colors.orange, size: 18),
                  label: Text(
                    desconto > 0
                        ? "Desconto: - R\$ ${desconto.toStringAsFixed(2)}"
                        : "Adicionar Desconto",
                    style: const TextStyle(color: Colors.orange),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              if (desconto > 0)
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red, size: 18),
                  onPressed: () => setState(() => desconto = 0.0),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // linha do total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Total:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                "R\$ ${calcularTotal().toStringAsFixed(2)}",
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // linha dos botões
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: mostrarBuscaProdutos,
                  icon: const Icon(Icons.add),
                  label: const Text("Adicionar Produto"),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: mostrarModalPagamento,
                  icon: const Icon(Icons.check_circle),
                  label: const Text("FINALIZAR"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nova Venda"),
        elevation: 0,
      ),
      drawer: const MenuLateral(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: mostrarBuscaProdutos,
        icon: const Icon(Icons.add),
        label: const Text("Adicionar Produto"),
      ),
      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildCampoBusca(),
                _buildClienteCard(),
                const SizedBox(height: 8),
                Expanded(child: _buildListaItens()),
                _buildRodapeResumo(),
              ],
            ),
    );
  }
}