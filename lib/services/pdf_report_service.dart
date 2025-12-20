import 'package:kg/models/transaction_model.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:kg/models/enums.dart';

class PdfReportService {
  final currency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  // Fungsi Utama
  Future<void> printTransactionReport(
    List<TransactionModel> transactions,
    DateTime start,
    DateTime end,
  ) async {
    final doc = pw.Document();
    final font = await PdfGoogleFonts.openSansRegular();
    final fontBold = await PdfGoogleFonts.openSansBold();

    // Hitung Total
    double totalIncome = 0;
    double totalExpense = 0;

    // Data untuk Tabel
    final List<List<String>> tableData = transactions.map((trx) {
      bool isIncome =
          trx.typeTransaksi == trxType.SALE ||
          trx.typeTransaksi == trxType.INCOME_OTHER ||
          trx.typeTransaksi == trxType.UANG_MASUK ||
          trx.typeTransaksi == trxType.PURCHASE_RETURN;
      if (isIncome)
        totalIncome += trx.totalAmount;
      else
        totalExpense += trx.totalAmount;

      return [
        dateFormat.format(trx.time), // Tanggal
        trx.trxNumber, // No Bukti
        trx.typeTransaksi.toString().split('.').last, // Tipe
        trx.partyName ?? "-", // Pihak
        isIncome ? currency.format(trx.totalAmount) : "-", // Masuk
        !isIncome ? currency.format(trx.totalAmount) : "-", // Keluar
      ];
    }).toList();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        build: (pw.Context context) {
          return [
            // HEADER LAPORAN
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Laporan Transaksi',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Toko KutoarjoGrosir'),
                      pw.Text(
                        'Periode: ${DateFormat('dd/MM').format(start)} - ${DateFormat('dd/MM/yyyy').format(end)}',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // TABEL DATA
            pw.TableHelper.fromTextArray(
              context: context,
              headers: [
                'Tanggal',
                'No. Bukti',
                'Tipe',
                'Pihak',
                'Masuk',
                'Keluar',
              ],
              data: tableData,
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.teal),
              rowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
              cellAlignment: pw.Alignment.centerLeft,
              cellAlignments: {
                4: pw.Alignment.centerRight, // Kolom Masuk Rata Kanan
                5: pw.Alignment.centerRight, // Kolom Keluar Rata Kanan
              },
            ),

            pw.SizedBox(height: 20),
            pw.Divider(),

            // FOOTER TOTAL
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      "Total Pemasukan: ${currency.format(totalIncome)}",
                      style: const pw.TextStyle(color: PdfColors.green),
                    ),
                    pw.Text(
                      "Total Pengeluaran: ${currency.format(totalExpense)}",
                      style: const pw.TextStyle(color: PdfColors.red),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      "Laba Bersih: ${currency.format(totalIncome - totalExpense)}",
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    // Buka Preview Print
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
    );
  }
}
