import 'package:flutter/material.dart';
import '../caixa_page.dart';
import '../pages/clientes_page.dart';
import '../pages/produtos_page.dart';
import '../pages/vendas_page.dart';
import '../pages/dashboard_page.dart';
import '../pages/login_page.dart';
import '../pages/historico_vendas_page.dart'; // ✅ Novo import
import '../sessao.dart';

class MenuLateral extends StatelessWidget {
  const MenuLateral({super.key});

  @override
  Widget build(BuildContext context) {
    bool isAdmin = Sessao.perfil == 'admin';

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.blue),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.store, color: Colors.white, size: 40),
                const SizedBox(height: 10),
                Text(
                  'Olá, ${Sessao.nome ?? "Usuário"}',
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
                Text(
                  isAdmin ? 'Administrador' : 'Funcionário',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),

          // ✅ SÓ ADMIN VÊ O DASHBOARD
          if (isAdmin)
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Painel de Controle'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DashboardPage()));
              },
            ),

          // ✅ SÓ ADMIN VÊ O CAIXA
          if (isAdmin)
            ListTile(
              leading: const Icon(Icons.account_balance_wallet),
              title: const Text('Caixa'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const CaixaPage()));
              },
            ),

          // ✅ SÓ ADMIN VÊ O HISTÓRICO
          if (isAdmin)
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Histórico de Vendas'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HistoricoVendasPage()));
              },
            ),

          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Clientes'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ClientesPage()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.inventory_2),
            title: const Text('Produtos'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ProdutosPage()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.shopping_cart),
            title: const Text('Nova Venda'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const VendasPage()));
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sair', style: TextStyle(color: Colors.red)),
            onTap: () {
              Sessao.limpar();
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()));
            },
          ),
        ],
      ),
    );
  }
}