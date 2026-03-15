import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../widgets/menu_lateral.dart';
import 'produtos_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  double totalVendasHoje = 0.0;
  int totalProdutosBaixoEstoque = 0;
  int totalClientes = 0;
  double faturamentoTotal = 0.0;
  List<dynamic> dadosGrafico = [];
  List<dynamic> produtosBaixoEstoque = []; // ✅ Lista completa para o modal
  bool carregando = true;
  String erroMensagem = "";
  int? touchedIndex; // ✅ Para tooltip do gráfico
  final String urlBase = "http://127.0.0.1:5012/api";

  @override
  void initState() {
    super.initState();
    carregarDados();
  }

  String get saudacao {
    final hora = DateTime.now().hour;
    if (hora < 12) return "Bom dia";
    if (hora < 18) return "Boa tarde";
    return "Boa noite";
  }

  Future<void> carregarDados() async {
    setState(() {
      carregando = true;
      erroMensagem = "";
    });

    try {
      final resultados = await Future.wait([
        http.get(Uri.parse("$urlBase/vendas/caixa/hoje")),
        http.get(Uri.parse("$urlBase/produtos")),
        http.get(Uri.parse("$urlBase/clientes")),
        http.get(Uri.parse("$urlBase/vendas/ultimos-dias?dias=7")),
      ]);

      if (mounted) {
        setState(() {
          // 1. Caixa Hoje
          try {
            final dadosCaixa = json.decode(resultados[0].body);
            totalVendasHoje = double.tryParse(
                    (dadosCaixa['totalDia'] ?? dadosCaixa['total'] ?? 0)
                        .toString()) ??
                0.0;
          } catch (_) {
            totalVendasHoje = 0.0;
          }

          // 2. Estoque Baixo
          try {
            final listaProdutos = json.decode(resultados[1].body) as List;
            produtosBaixoEstoque = listaProdutos
                .where((p) => (p['estoque'] ?? p['Estoque'] ?? 99) <= 3)
                .toList();
            totalProdutosBaixoEstoque = produtosBaixoEstoque.length;

            // ✅ Faturamento calculado localmente (soma de todas as vendas do gráfico)
            faturamentoTotal = 0.0; // será calculado no passo 4
          } catch (_) {
            totalProdutosBaixoEstoque = 0;
          }

          // 3. Clientes
          try {
            totalClientes = (json.decode(resultados[2].body) as List).length;
          } catch (_) {
            totalClientes = 0;
          }

          // 4. Gráfico + Faturamento Total (soma dos últimos 7 dias)
          try {
            dadosGrafico = json.decode(resultados[3].body);
            faturamentoTotal = dadosGrafico.fold(0.0, (sum, d) =>
                sum + (double.tryParse((d['total'] ?? 0).toString()) ?? 0.0));
          } catch (_) {
            dadosGrafico = [];
          }

          carregando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          erroMensagem =
              "Erro ao conectar com a API. Verifique se o backend está rodando.";
          carregando = false;
        });
      }
    }
  }

  double _getMaxY() {
    double max = 100;
    for (var d in dadosGrafico) {
      final val = double.tryParse((d['total'] ?? 0).toString()) ?? 0;
      if (val > max) max = val;
    }
    return max + (max * 0.2);
  }

  List<BarChartGroupData> _buildBarGroups() {
    return List.generate(dadosGrafico.length, (index) {
      final isTouched = index == touchedIndex;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: double.tryParse(
                    (dadosGrafico[index]['total'] ?? 0).toString()) ??
                0,
            gradient: LinearGradient(
              colors: isTouched
                  ? [Colors.orange, Colors.deepOrange] // ✅ Destaque ao tocar
                  : [Colors.blueAccent, Colors.lightBlue],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
            width: isTouched ? 22 : 18, // ✅ Cresce ao tocar
            borderRadius: BorderRadius.circular(4),
          )
        ],
      );
    });
  }

  // ✅ Modal de Estoque Baixo
  void _mostrarEstoqueBaixo() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("⚠️ Produtos com Estoque Baixo",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Divider(),
            produtosBaixoEstoque.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text("✅ Todos os produtos estão com estoque OK!",
                        style: TextStyle(color: Colors.green)),
                  )
                : SizedBox(
                    height: 250,
                    child: ListView.builder(
                      itemCount: produtosBaixoEstoque.length,
                      itemBuilder: (context, index) {
                        final p = produtosBaixoEstoque[index];
                        final estoque = p['estoque'] ?? 0;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: estoque <= 0
                                ? Colors.red
                                : Colors.orange,
                            child: Text(
                              "$estoque",
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(p['nome']),
                          subtitle: Text(estoque <= 0
                              ? "❌ Sem estoque!"
                              : "⚠️ Estoque crítico"),
                          trailing: TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const ProdutosPage()),
                              );
                            },
                            child: const Text("Repor"),
                          ),
                        );
                      },
                    ),
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
        title: const Text('3.L.A Variedades - Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: carregarDados,
            tooltip: "Atualizar",
          )
        ],
      ),
      drawer: const MenuLateral(),
      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : erroMensagem.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.wifi_off, size: 60, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(erroMensagem,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                          onPressed: carregarDados,
                          child: const Text("Tentar Novamente")),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: carregarDados,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Saudação
                      Text(
                        "$saudacao! 👋",
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const Text(
                        "Aqui está o resumo do seu negócio:",
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),

                      // Cards
                      const Text("Resumo do Dia 📊",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        childAspectRatio: 2.1,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        children: [
                          _buildSmallCard(
                              "Vendas Hoje",
                              "R\$ ${totalVendasHoje.toStringAsFixed(2)}",
                              Icons.today,
                              Colors.green),
                          _buildSmallCard(
                              "Últ. 7 dias",
                              "R\$ ${faturamentoTotal.toStringAsFixed(2)}",
                              Icons.account_balance_wallet,
                              Colors.teal),
                          // ✅ Card de estoque baixo clicável
                          GestureDetector(
                            onTap: _mostrarEstoqueBaixo,
                            child: _buildSmallCard(
                                "Estoque Baixo",
                                "$totalProdutosBaixoEstoque itens",
                                Icons.warning,
                                totalProdutosBaixoEstoque > 0
                                    ? Colors.orange
                                    : Colors.green),
                          ),
                          _buildSmallCard(
                              "Clientes",
                              "$totalClientes",
                              Icons.people,
                              Colors.purple),
                        ],
                      ),

                      const SizedBox(height: 25),

                      // Gráfico
                      const Text("Vendas nos últimos 7 dias 📈",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Container(
                        height: 220,
                        padding: const EdgeInsets.fromLTRB(10, 20, 20, 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 5)
                          ],
                        ),
                        child: dadosGrafico.isEmpty
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.bar_chart,
                                        size: 50, color: Colors.grey),
                                    SizedBox(height: 8),
                                    Text("Sem dados de vendas recentes",
                                        style: TextStyle(color: Colors.grey)),
                                  ],
                                ),
                              )
                            : BarChart(
                                BarChartData(
                                  alignment: BarChartAlignment.spaceAround,
                                  maxY: _getMaxY(),
                                  barGroups: _buildBarGroups(),
                                  gridData: const FlGridData(show: false),
                                  borderData: FlBorderData(show: false),
                                  // ✅ Tooltip ao tocar na barra
                                  barTouchData: BarTouchData(
                                    touchTooltipData: BarTouchTooltipData(
                                      getTooltipItem: (group, groupIndex,
                                          rod, rodIndex) {
                                        final valor = rod.toY;
                                        return BarTooltipItem(
                                          "R\$ ${valor.toStringAsFixed(2)}",
                                          const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold),
                                        );
                                      },
                                    ),
                                    touchCallback: (event, response) {
                                      setState(() {
                                        if (response == null ||
                                            response.spot == null) {
                                          touchedIndex = null;
                                        } else {
                                          touchedIndex = response
                                              .spot!.touchedBarGroupIndex;
                                        }
                                      });
                                    },
                                  ),
                                  titlesData: FlTitlesData(
                                    leftTitles: const AxisTitles(
                                        sideTitles:
                                            SideTitles(showTitles: false)),
                                    rightTitles: const AxisTitles(
                                        sideTitles:
                                            SideTitles(showTitles: false)),
                                    topTitles: const AxisTitles(
                                        sideTitles:
                                            SideTitles(showTitles: false)),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, meta) {
                                          if (value.toInt() >=
                                              dadosGrafico.length) {
                                            return const Text("");
                                          }
                                          DateTime data = DateTime.parse(
                                              dadosGrafico[value.toInt()]
                                                  ['dia']);
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                                top: 8.0),
                                            child: Text(
                                              DateFormat('dd/MM').format(data),
                                              style: const TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.grey),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                      ),

                      const SizedBox(height: 20),
                      const Text(
                        "🔄 Puxe para baixo ou clique em ↻ para atualizar",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                            fontSize: 12),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSmallCard(
      String titulo, String valor, IconData icone, Color cor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(color: cor.withOpacity(0.05), blurRadius: 4)
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Icon(icone, color: cor, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo,
                    style: const TextStyle(
                        fontSize: 11, color: Colors.black54),
                    overflow: TextOverflow.ellipsis),
                Text(valor,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: cor),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}