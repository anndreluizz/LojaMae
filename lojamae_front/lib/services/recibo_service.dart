import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class ReciboService {
  static Future<void> gerarRecibo({
    required int vendaId,
    required String cliente,
    required List itens,
    required double total,
    required String formaPagamento,
    double desconto = 0.0,
  }) async {
    final pdf = pw.Document();
    final dataHora = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    final subtotal = itens.fold<double>(
      0,
      (previousValue, item) =>
          previousValue +
          ((item['precoUnitario'] as num).toDouble() *
              (item['quantidade'] as num).toDouble()),
    );

    String moeda(double valor) => 'R\$ ${valor.toStringAsFixed(2)}';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(12),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Cabeçalho
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      '3.L.A VARIEDADES',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Fone: (97) 98120-2980',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 6),
              pw.Divider(),

              pw.Center(
                child: pw.Text(
                  'RECIBO DE VENDA',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),

              pw.SizedBox(height: 6),

              pw.Text('Venda: #$vendaId', style: const pw.TextStyle(fontSize: 10)),
              pw.Text('Data: $dataHora', style: const pw.TextStyle(fontSize: 10)),
              pw.Text(
                'Cliente: ${cliente.trim().isEmpty ? "NÃO INFORMADO" : cliente}',
                style: const pw.TextStyle(fontSize: 10),
              ),

              pw.SizedBox(height: 6),
              pw.Divider(),

              // Cabeçalho da tabela
              pw.Row(
                children: [
                  pw.Expanded(
                    flex: 5,
                    child: pw.Text(
                      'Item',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      'Qtd',
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.Expanded(
                    flex: 3,
                    child: pw.Text(
                      'Total',
                      textAlign: pw.TextAlign.right,
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 4),

              // Itens
              ...itens.map((item) {
                final nome = (item['nome'] ?? '').toString();
                final quantidade = (item['quantidade'] as num).toDouble();
                final precoUnitario = (item['precoUnitario'] as num).toDouble();
                final totalItem = quantidade * precoUnitario;

                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        flex: 5,
                        child: pw.Text(
                          nome,
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          quantidade.toInt().toString(),
                          textAlign: pw.TextAlign.center,
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ),
                      pw.Expanded(
                        flex: 3,
                        child: pw.Text(
                          moeda(totalItem),
                          textAlign: pw.TextAlign.right,
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              pw.Divider(),

              // Resumo
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Subtotal:', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text(moeda(subtotal), style: const pw.TextStyle(fontSize: 10)),
                ],
              ),

              if (desconto > 0) ...[
                pw.SizedBox(height: 2),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Desconto:',
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.red,
                      ),
                    ),
                    pw.Text(
                      '- ${moeda(desconto)}',
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.red,
                      ),
                    ),
                  ],
                ),
              ],

              pw.SizedBox(height: 4),
              pw.Divider(thickness: 1.2),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'TOTAL:',
                    style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    moeda(total),
                    style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 8),

              pw.Text(
                'Pagamento: $formaPagamento',
                style: const pw.TextStyle(fontSize: 10),
              ),

              pw.SizedBox(height: 18),

              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'Obrigado pela preferência!',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontStyle: pw.FontStyle.italic,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Volte sempre :)',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}