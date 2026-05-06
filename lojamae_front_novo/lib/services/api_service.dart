import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:5012/api';

  // 🔓 ABRIR VENDA
  static Future<int?> abrirVenda() async {
    final response = await http.post(
      Uri.parse('$baseUrl/vendas/abrir'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"clienteId": null}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data['id'];
    }

    return null;
  }

  // ➕ ADICIONAR ITEM
  static Future<bool> adicionarItem(
      int vendaId, String nome, int quantidade) async {
    final response = await http.post(
      Uri.parse('$baseUrl/vendas/$vendaId/itens'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "produtoNome": nome,
        "quantidade": quantidade
      }),
    );

    return response.statusCode == 200 || response.statusCode == 201;
  }

  // 💰 PAGAMENTO
  static Future<bool> pagar(
      int vendaId, double valor, String forma) async {
    final response = await http.post(
      Uri.parse('$baseUrl/vendas/$vendaId/pagar'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "valor": valor,
        "formaPagamento": forma
      }),
    );

    return response.statusCode == 200 || response.statusCode == 201;
  }

  // ✅ FECHAR VENDA
  static Future<bool> fecharVenda(int vendaId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/vendas/$vendaId/fechar'),
    );

    return response.statusCode == 200 || response.statusCode == 201;
  }
}