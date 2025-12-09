import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kg/models/enums.dart';
import 'package:kg/models/keuangan_model.dart';


// --- WIDGET ITEM TRANSAKSI ---
  Widget buildTransactionCard(TransactionModel trx) {
    // Logic Judul & Warna
    String title = "";
    Color amountColor = Colors.black;

    switch (trx.typeTransaksi) {
      case trxType.INCOME_OTHER:
      case trxType.SALE:
        title = "Uang Masuk ${trx.trxNumber}";
        amountColor = Colors.green;
        break;
      case trxType.PURCHASE:
        title = "Pembelian ${trx.trxNumber}";
        amountColor = Colors.black;
        break;
      case trxType.EXPENSE:
        title = "Pengeluaran ${trx.trxNumber}";
        amountColor = Colors.red;
        break;
      default:
        title = "Transaksi ${trx.trxNumber}";
    }

    bool isLunas = trx.isLunas;
    String statusText = isLunas ? "Dibayar" : "Belum Dibayar";
    Color statusBg = isLunas ? Colors.green[50]! : Colors.pink[50]!;
    Color statusColor = isLunas ? Colors.green : Colors.pink;

    // Untuk Saldo di card (jika hutang belum lunas)
    String saldoText = isLunas
        ? "Saldo: Rp 0"
        : "Saldo: ${trx.remainingDebt}";
    Color saldoBg = isLunas ? Colors.grey[100]! : Colors.pink[50]!;
    Color saldoColor = isLunas ? Colors.grey : Colors.pink;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd MMM yyyy • HH:mm').format(trx.time),
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
              Text(
               trx.totalAmount.toString(),
                style: TextStyle(
                  color: amountColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Badges Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Badge Saldo
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: saldoBg,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  saldoText,
                  style: TextStyle(
                    color: saldoColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Badge Status Lunas/Belum
              if (!isLunas) // Jika lunas biasanya tidak perlu badge merah besar, atau bisa pakai "Dibayar" hijau
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    "Dibayar",
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
