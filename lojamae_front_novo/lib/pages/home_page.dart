import 'package:flutter/material.dart';
import 'nova_venda_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: Row(
        children: [
          Container(
            width: 240,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          image: const DecorationImage(
                            image: AssetImage('assets/images/3la_logo.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          '3.L.A\nVariedades',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111827),
                            height: 1.1,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 36),

                  _menuItem(
                    Icons.dashboard_rounded,
                    'Dashboard',
                    selected: true,
                    onTap: () {},
                  ),
                  _menuItem(
                    Icons.point_of_sale_rounded,
                    'Nova Venda',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NovaVendaPage(),
                        ),
                      );
                    },
                  ),
                  _menuItem(Icons.people_alt_rounded, 'Clientes'),
                  _menuItem(Icons.inventory_2_rounded, 'Produtos'),
                  _menuItem(Icons.account_balance_wallet_rounded, 'Caixa'),
                  _menuItem(Icons.receipt_long_rounded, 'Fiado'),
                  _menuItem(Icons.bar_chart_rounded, 'Relatórios'),

                  const SizedBox(height: 24),

                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: Color(0xFFE5E7EB),
                          child: Icon(
                            Icons.person,
                            color: Color(0xFF374151),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Administrador',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF374151),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Olá, André 👋',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Dashboard da Loja',
                              style: TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF111827),
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Acompanhe o resumo geral da loja hoje.',
                              style: TextStyle(
                                fontSize: 15,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NovaVendaPage(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Nova Venda'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 18,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  Row(
                    children: [
                      Expanded(
                        child: _buildCard(
                          titulo: 'Vendas Hoje',
                          valor: 'R\$ 0,00',
                          icone: Icons.shopping_cart_rounded,
                          cor: const Color(0xFF3B82F6),
                          subtitulo: 'Total vendido no dia',
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: _buildCard(
                          titulo: 'Caixa Atual',
                          valor: 'R\$ 0,00',
                          icone: Icons.account_balance_wallet_rounded,
                          cor: const Color(0xFF22C55E),
                          subtitulo: 'Saldo disponível agora',
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: _buildCard(
                          titulo: 'Clientes Devendo',
                          valor: '0',
                          icone: Icons.people_alt_rounded,
                          cor: const Color(0xFFF59E0B),
                          subtitulo: 'Pendências em aberto',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildSectionCard(
                          title: 'Resumo do Dia',
                          child: Column(
                            children: [
                              _buildResumoItem(
                                'Total de vendas',
                                '0',
                                Icons.receipt_long_rounded,
                              ),
                              const Divider(height: 28),
                              _buildResumoItem(
                                'Itens vendidos',
                                '0',
                                Icons.inventory_2_rounded,
                              ),
                              const Divider(height: 28),
                              _buildResumoItem(
                                'Pagamentos recebidos',
                                'R\$ 0,00',
                                Icons.payments_rounded,
                              ),
                              const Divider(height: 28),
                              _buildResumoItem(
                                'Saldo em aberto',
                                'R\$ 0,00',
                                Icons.warning_amber_rounded,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        flex: 3,
                        child: _buildSectionCard(
                          title: 'Últimas Movimentações',
                          child: Column(
                            children: [
                              _buildMovimentacaoItem(
                                cliente: 'Maria Souza',
                                descricao: 'Compra finalizada',
                                valor: 'R\$ 120,00',
                                cor: const Color(0xFF22C55E),
                              ),
                              const Divider(height: 28),
                              _buildMovimentacaoItem(
                                cliente: 'João Pedro',
                                descricao: 'Pagamento parcial',
                                valor: 'R\$ 50,00',
                                cor: const Color(0xFF3B82F6),
                              ),
                              const Divider(height: 28),
                              _buildMovimentacaoItem(
                                cliente: 'Ana Clara',
                                descricao: 'Venda no fiado',
                                valor: 'R\$ 85,00',
                                cor: const Color(0xFFF59E0B),
                              ),
                              const Divider(height: 28),
                              _buildMovimentacaoItem(
                                cliente: 'Carlos Lima',
                                descricao: 'Compra finalizada',
                                valor: 'R\$ 210,00',
                                cor: const Color(0xFF22C55E),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuItem(
    IconData icon,
    String title, {
    bool selected = false,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEEF4FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 6,
          ),
          leading: Icon(
            icon,
            color: selected ? const Color(0xFF2563EB) : const Color(0xFF374151),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color:
                  selected ? const Color(0xFF2563EB) : const Color(0xFF374151),
            ),
          ),
          onTap: onTap,
        ),
      ),
    );
  }

  Widget _buildCard({
    required String titulo,
    required String valor,
    required IconData icone,
    required Color cor,
    required String subtitulo,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
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
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Color.fromRGBO(cor.red, cor.green, cor.blue, 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              icone,
              color: cor,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  valor,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitulo,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 22),
          child,
        ],
      ),
    );
  }

  Widget _buildResumoItem(
    String titulo,
    String valor,
    IconData icone,
  ) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icone,
            color: const Color(0xFF4B5563),
            size: 22,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            titulo,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF4B5563),
            ),
          ),
        ),
        Text(
          valor,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
      ],
    );
  }

  Widget _buildMovimentacaoItem({
    required String cliente,
    required String descricao,
    required String valor,
    required Color cor,
  }) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Color.fromRGBO(cor.red, cor.green, cor.blue, 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            Icons.person,
            color: cor,
            size: 22,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                cliente,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                descricao,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
        Text(
          valor,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: cor,
          ),
        ),
      ],
    );
  }
}