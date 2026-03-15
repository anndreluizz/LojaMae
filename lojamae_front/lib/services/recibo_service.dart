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
    double desconto = 0.0, // ✅ Desconto opcional
  }) async {
    final pdf = pw.Document();
    final dataHora = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    // Corrigido: calcula subtotal somando os itens, não usando total + desconto
    final subtotal = itens.fold<double>(
      0,
      (previousValue, item) => previousValue + (item['precoUnitario'] * item['quantidade']),
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  "3.L.A VARIEDADES",
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Center(child: pw.Text("Fone: (97) 98120-2980")),
              pw.Divider(),
              pw.Text("RECIBO DE VENDA #$vendaId"),
              pw.Text("Data: $dataHora"),
              pw.Text("Cliente: $cliente"),
              pw.Divider(),

              // Tabela de itens
              pw.Table(
                children: [
                  pw.TableRow(children: [
                    pw.Text("Item", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text("Qtd", textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text("Total", textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ]),
                  ...itens.map((item) => pw.TableRow(children: [
                    pw.Text(item['nome']),
                    pw.Text(item['quantidade'].toString(), textAlign: pw.TextAlign.center),
                    pw.Text(
                      "R\$ ${(item['precoUnitario'] * item['quantidade']).toStringAsFixed(2)}",
                      textAlign: pw.TextAlign.right,
                    ),
                  ])),
                ],
              ),
              pw.Divider(),

              // ✅ Subtotal
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Subtotal:"),
                  pw.Text("R\$ ${subtotal.toStringAsFixed(2)}"),
                ],
              ),

              // ✅ Desconto (só aparece se houver)
              if (desconto > 0)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("Desconto:", style: pw.TextStyle(color: PdfColors.red)),
                    pw.Text(
                      "- R\$ ${desconto.toStringAsFixed(2)}",
                      style: pw.TextStyle(color: PdfColors.red),
                    ),
                  ],
                ),

              pw.Divider(),

              // Total final
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("TOTAL:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                  pw.Text(
                    "R\$ ${total.toStringAsFixed(2)}",
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),

              pw.SizedBox(height: 5),
              pw.Text("Pagamento: $formaPagamento"),
              pw.SizedBox(height: 20),
              pw.Center(
                child: pw.Text(
                  "Obrigado pela preferência!",
                  style: pw.TextStyle(fontStyle: pw.FontStyle.italic),
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }
}