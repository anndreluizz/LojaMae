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
  List<dynamic> formasPagamento = [];
  bool carregando = true;

  final String baseUrl = "http://127.0.0.1:5012/api/caixa";

  final TextEditingController _valorInicialController = TextEditingController(
    text: "0.00",
  );

  final TextEditingController _valorFinalController = TextEditingController();

  @override
  void initState() {
    super.initState();
    carregarDadosCaixa();
  }

  @override
  void dispose() {
    _valorInicialController.dispose();
    _valorFinalController.dispose();
    super.dispose();
  }

  Future<void> carregarDadosCaixa() async {
    setState(() => carregando = true);

    try {
      await buscarStatusCaixa();
      await buscarFormasPagamento();
    } finally {
      if (mounted) {
        setState(() => carregando = false);
      }
    }
  }

  Future<void> buscarStatusCaixa() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/aberto"));

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          caixa = json.decode(response.body);
        });
      } else {
        setState(() {
          caixa = null;
          formasPagamento = [];
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        caixa = null;
        formasPagamento = [];
      });
    }
  }

  Future<void> buscarFormasPagamento() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/formas-pagamento"));

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          formasPagamento = json.decode(response.body);
        });
      } else {
        setState(() {
          formasPagamento = [];
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        formasPagamento = [];
      });
    }
  }

  Future<void> abrirCaixa() async {
    final valorInicial = double.tryParse(
          _valorInicialController.text.replaceAll(',', '.'),
        ) ??
        0.0;

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/abrir"),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'valorInicial': valorInicial,
        }),
      );

      if (!mounted) return;

      Navigator.pop(context);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Caixa aberto com sucesso."),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        await carregarDadosCaixa();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Erro ao abrir caixa: ${response.body}"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Erro ao abrir caixa: $e"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> fecharCaixa() async {
    final saldoEsperado = ((caixa?['saldoCaixa'] ?? 0) as num).toDouble();

    final texto = _valorFinalController.text.trim();

    final valorFinal = texto.isEmpty
        ? saldoEsperado
        : (double.tryParse(texto.replaceAll(',', '.')) ?? saldoEsperado);

    final diferenca = valorFinal - saldoEsperado;

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/fechar"),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'valorFinal': valorFinal,
          'diferenca': diferenca,
        }),
      );

      if (!mounted) return;

      Navigator.pop(context);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Caixa fechado com sucesso."),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _valorFinalController.clear();
        await carregarDadosCaixa();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Erro ao fechar caixa: ${response.body}"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Erro ao fechar caixa: $e"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void mostrarModalAbrirCaixa() {
    _valorInicialController.text = "0.00";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Abrir Caixa"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        content: TextField(
          controller: _valorInicialController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: "Valor Inicial",
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
            onPressed: abrirCaixa,
            child: const Text("Abrir"),
          ),
        ],
      ),
    );
  }

  void mostrarModalFecharCaixa() {
    _valorFinalController.clear();

    showDialog(
      context: context,
      builder: (context) {
        final double saldoEsperado =
            ((caixa?['saldoCaixa'] ?? 0) as num).toDouble();

        double diferenca = 0;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Fechar Caixa"),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Saldo esperado: R\$ ${saldoEsperado.toStringAsFixed(2)}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _valorFinalController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: "Valor contado",
                      prefixText: "R\$ ",
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      final valor =
                          double.tryParse(value.replaceAll(',', '.')) ?? 0;

                      setStateDialog(() {
                        diferenca = valor - saldoEsperado;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Diferença: R\$ ${diferenca.toStringAsFixed(2)}",
                    style: TextStyle(
                      color: diferenca == 0
                          ? Colors.green
                          : (diferenca > 0 ? Colors.blue : Colors.red),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancelar"),
                ),
                ElevatedButton(
                  onPressed: fecharCaixa,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Confirmar Fechamento"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String formatarMoeda(dynamic valor) {
    if (valor == null) return "R\$ 0,00";
    final numero = (valor as num).toDouble();
    return "R\$ ${numero.toStringAsFixed(2)}";
  }

  String formatarData(dynamic data) {
    if (data == null) return "-";
    return data.toString();
  }

  IconData obterIconeFormaPagamento(String forma) {
    switch (forma.toLowerCase()) {
      case 'dinheiro':
        return Icons.attach_money;
      case 'pix':
        return Icons.pix;
      case 'cartão':
      case 'cartao':
        return Icons.credit_card;
      default:
        return Icons.payments;
    }
  }

  Color obterCorFormaPagamento(String forma) {
    switch (forma.toLowerCase()) {
      case 'dinheiro':
        return Colors.green;
      case 'pix':
        return Colors.blue;
      case 'cartão':
      case 'cartao':
        return Colors.deepPurple;
      default:
        return Colors.grey;
    }
  }

  Widget _buildSemCaixa() {
    return Center(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.point_of_sale, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              const Text(
                'Nenhum caixa aberto',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Abra um caixa para começar as vendas do dia.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: mostrarModalAbrirCaixa,
                icon: const Icon(Icons.lock_open),
                label: const Text("Abrir Caixa"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormasPagamento() {
    if (formasPagamento.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: const Padding(
          padding: EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Formas de pagamento',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Nenhum pagamento registrado neste caixa.',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Formas de pagamento',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...formasPagamento.map((item) {
              final forma = item['formaPagamento']?.toString() ?? 'Não informado';
              final total = item['total'];
              final cor = obterCorFormaPagamento(forma);
              final icone = obterIconeFormaPagamento(forma);

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: cor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cor.withOpacity(0.25)),
                ),
                child: Row(
                  children: [
                    Icon(icone, color: cor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        forma,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      formatarMoeda(total),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: cor,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCaixaAberto() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 28),
                      SizedBox(width: 10),
                      Text(
                        'Caixa Aberto',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Text('ID: ${caixa!['id']}'),
                  const SizedBox(height: 6),
                  Text('Status: ${caixa!['status']}'),
                  const SizedBox(height: 6),
                  Text('Abertura: ${formatarData(caixa!['dataAbertura'])}'),
                  const SizedBox(height: 6),
                  Text('Valor inicial: ${formatarMoeda(caixa!['valorInicial'])}'),
                  const SizedBox(height: 6),
                  Text(
                    'Total pagamentos: ${formatarMoeda(caixa!['totalPagamentos'])}',
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Saldo do caixa: ${formatarMoeda(caixa!['saldoCaixa'])}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildFormasPagamento(),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: mostrarModalFecharCaixa,
              icon: const Icon(Icons.lock),
              label: const Text("Fechar Caixa"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Controle de Caixa'),
        actions: [
          IconButton(
            onPressed: carregarDadosCaixa,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      drawer: const MenuLateral(),
      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : caixa == null
              ? _buildSemCaixa()
              : _buildCaixaAberto(),
    );
  }
}