import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kg/models/enums.dart';
import 'package:kg/models/transaction_model.dart';
import 'package:kg/providers/transaksi_provider.dart';
import 'package:kg/ui/transaction/generic_transaction_form.dart';
import 'package:kg/widgets/produk_detail.dart';
import 'package:provider/provider.dart';

Widget HistoryTransactionCard(TransactionModel trx, context) {
  // Logic Tampilan berdasarkan Tipe
  String typeLabel = "";
  Color typeColor = Colors.black;
  IconData typeIcon = Icons.help;
  Color amountColor = Colors.black;
  bool isMoneyIn = false;

  switch (trx.typeTransaksi) {
    case trxType.SALE:
      typeLabel = "Penjualan";
      typeColor = Colors.blue[700]!;
      typeIcon = Icons.sell;
      amountColor = Colors.green;
      isMoneyIn = true;
      break;
    case trxType.UANG_MASUK:
      typeLabel = "Uang Masuk";
      typeColor = Colors.green[700]!;
      typeIcon = Icons.arrow_downward;
      amountColor = Colors.green;
      isMoneyIn = true;
      break;
    case trxType.INCOME_OTHER:
      typeLabel = "Pemasukan Lain";
      typeColor = Colors.green[700]!;
      typeIcon = Icons.arrow_downward;
      amountColor = Colors.green;
      isMoneyIn = true;
      break;
    case trxType.PURCHASE:
      typeLabel = "Pembelian";
      typeColor = Colors.orange[800]!;
      typeIcon = Icons.shopping_bag;
      amountColor = Colors.black;
      break;
    case trxType.UANG_KELUAR:
      typeLabel = "Uang Keluar";
      typeColor = Colors.red[700]!;
      typeIcon = Icons.arrow_upward;
      amountColor = Colors.black; // Uang keluar biasanya hitam/merah
      break;
    case trxType.EXPENSE:
      typeLabel = "Pengeluaran";
      typeColor = Colors.red[700]!;
      typeIcon = Icons.arrow_upward;
      amountColor = Colors.black;
      break;
    default:
      typeLabel = "Transaksi";
  }

  bool isLunas = trx.isLunas;

  return Container(
    margin: EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      // Shadow halus agar card terlihat mengambang
      boxShadow: [
        BoxShadow(
          color: Colors.grey.shade100,
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          // 1. Ambil Provider
          final provider = Provider.of<TransactionProvider>(
            context,
            listen: false,
          );

          if (trx.id == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('ID transaksi tidak valid')),
            );
            return;
          }

          // 2. Load detail items dari database (Pastikan fungsi ini ada di Provider)

          List<TransactioItem>? details = await provider.getTransactionItems(
            trx.id,
          );

          // 3. Gabungkan detail ke object TransactionModel agar lengkap
          TransactionModel fullTrx = TransactionModel(
            id: trx.id,
            trxNumber: trx.trxNumber,
            time: trx.time ?? DateTime.now(),
            typeTransaksi: trx.typeTransaksi ?? trxType.SALE,
            partyId: trx.partyId,
            partyName: trx.partyName,
            totalAmount: trx.totalAmount ?? 0,
            paidAmount: trx.paidAmount ?? 0,
            description: trx.description ?? '',
            proofImage: trx.proofImage ?? '',
            items: details ?? null,
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (ctx) => GenericTransactionForm(
                type: fullTrx.typeTransaksi,
                editData: fullTrx, // Pass data untuk edit
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER CARD: Tipe & Nominal
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Tipe Transaksi
                  Row(
                    children: [
                      Text(
                        typeLabel,
                        style: TextStyle(
                          color: typeColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        " ${trx.trxNumber}",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  // Nominal
                  Text(
                    "${isMoneyIn ? '+' : '-'} ${currency.format(trx.totalAmount)}",
                    style: TextStyle(
                      color: amountColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),
              const Divider(height: 1, color: Color(0xFFEEEEEE)),
              const SizedBox(height: 8),

              // BODY CARD: Nama Pihak & Tanggal
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trx.partyName ?? "Umum",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Text(
                          DateFormat().format(trx.time),
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),

                  // STATUS BADGE (Jika Belum Lunas)
                  if (!isLunas)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        "Belum Dibayar",
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    // Opsional: Tampilkan badge lunas atau kosongkan saja agar bersih
                    const Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Colors.green,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
