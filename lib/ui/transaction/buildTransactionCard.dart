import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kg/models/enums.dart';
import 'package:kg/models/transaction_model.dart';

Widget buildTransactionCard(TransactionModel trx, BuildContext context) {
  // --- THEME CONSTANTS ---
  const Color borderColor = Colors.black;
  const Color shadowColor = Colors.black;
  
  // Logic Judul, Warna & Ikon
  String title = "";
  Color iconColor = Colors.black;
  IconData iconData = Icons.receipt;
  Color amountColor = Colors.black;

  // Format Currency (Optional, agar lebih rapi)
  final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  switch (trx.typeTransaksi) {
    case trxType.INCOME_OTHER:
    case trxType.SALE:
    case trxType.UANG_MASUK:
      title = "Pemasukan";
      amountColor = const Color(0xFF27AE60); // Green Retro
      iconColor = const Color(0xFFB9F6CA); // Light Green bg
      iconData = Icons.arrow_downward_rounded; // Uang Masuk
      break;
    case trxType.PURCHASE:
      title = "Pembelian";
      amountColor = Colors.black;
      iconColor = const Color(0xFFFFF59D); // Yellow bg
      iconData = Icons.shopping_bag_outlined;
      break;
    case trxType.EXPENSE:
    case trxType.UANG_KELUAR:
      title = "Pengeluaran";
      amountColor = const Color(0xFFC62828); // Red Retro
      iconColor = const Color(0xFFFFCDD2); // Pink bg
      iconData = Icons.arrow_upward_rounded; // Uang Keluar
      break;
    default:
      title = "Transaksi";
      amountColor = Colors.black;
      iconColor = Colors.grey[200]!;
      iconData = Icons.swap_horiz;
  }

  bool isLunas = trx.isLunas;
  
  // Logic Badge Status
  String statusText = isLunas ? "LUNAS" : "BELUM LUNAS";
  Color statusBg = isLunas ? Colors.black : Colors.white;
  Color statusFg = isLunas ? Colors.white : Colors.black;

  // Logic Badge Saldo (Sisa Hutang)
  String saldoText = isLunas
      ? "Selesai"
      : "Sisa: ${currencyFormatter.format(trx.remainingDebt)}";

  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: borderColor, width: 2), // Border Tebal
      boxShadow: const [
        BoxShadow(
          color: shadowColor,
          offset: Offset(4, 4), // Hard Shadow
          blurRadius: 0,
        ),
      ],
    ),
    child: Column(
      children: [
        // --- BAGIAN ATAS: INFO UTAMA ---
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Icon Box
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: iconColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor, width: 2),
                ),
                child: Icon(iconData, color: Colors.black, size: 24),
              ),
              const SizedBox(width: 12),
              
              // 2. Title & Date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "$title #${trx.trxNumber}",
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('dd MMM yyyy • HH:mm').format(trx.time),
                      style: TextStyle(
                        color: Colors.grey[600], 
                        fontSize: 12,
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Amount
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    currencyFormatter.format(trx.totalAmount),
                    style: TextStyle(
                      color: amountColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Garis Pemisah Hitam
        Container(height: 2, color: borderColor),

        // --- BAGIAN BAWAH: STATUS & BADGE ---
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            color: Color(0xFFF9FAFB), // Sedikit abu untuk footer
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Badge Status (Hitam/Putih Box)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: borderColor, width: 1.5),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusFg,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              // Info Saldo / Sisa
              Row(
                children: [
                  if (!isLunas) 
                    const Icon(Icons.warning_amber_rounded, size: 14, color: Colors.red),
                  if (!isLunas) const SizedBox(width: 4),
                  Text(
                    saldoText,
                    style: TextStyle(
                      color: isLunas ? Colors.grey : Colors.red[800],
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      fontStyle: isLunas ? FontStyle.normal : FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:kg/models/enums.dart';
// import 'package:kg/models/transaction_model.dart';


// // --- WIDGET ITEM TRANSAKSI ---
//   Widget buildTransactionCard(TransactionModel trx) {
//     // Logic Judul & Warna
//     String title = "";
//     Color amountColor = Colors.black;

//     switch (trx.typeTransaksi) {
//       case trxType.INCOME_OTHER:
//       case trxType.SALE:
//         title = "Uang Masuk ${trx.trxNumber}";
//         amountColor = Colors.green;
//         break;
//       case trxType.PURCHASE:
//         title = "Pembelian ${trx.trxNumber}";
//         amountColor = Colors.black;
//         break;
//       case trxType.EXPENSE:
//         title = "Pengeluaran ${trx.trxNumber}";
//         amountColor = Colors.red;
//         break;
//       default:
//         title = "Transaksi ${trx.trxNumber}";
//     }

//     bool isLunas = trx.isLunas;
//     String statusText = isLunas ? "Dibayar" : "Belum Dibayar";
//     Color statusBg = isLunas ? Colors.green[50]! : Colors.pink[50]!;
//     Color statusColor = isLunas ? Colors.green : Colors.pink;

//     // Untuk Saldo di card (jika hutang belum lunas)
//     String saldoText = isLunas
//         ? "Saldo: Rp 0"
//         : "Saldo: ${trx.remainingDebt}";
//     Color saldoBg = isLunas ? Colors.grey[100]! : Colors.pink[50]!;
//     Color saldoColor = isLunas ? Colors.grey : Colors.pink;

//     return Container(
//       margin: const EdgeInsets.only(bottom: 10),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.grey.shade100),
//       ),
//       child: Column(
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     title,
//                     style: const TextStyle(
//                       fontWeight: FontWeight.bold,
//                       fontSize: 16,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     DateFormat('dd MMM yyyy • HH:mm').format(trx.time),
//                     style: const TextStyle(color: Colors.grey, fontSize: 12),
//                   ),
//                 ],
//               ),
//               Text(
//                trx.totalAmount.toString(),
//                 style: TextStyle(
//                   color: amountColor,
//                   fontWeight: FontWeight.bold,
//                   fontSize: 16,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 12),
//           // Badges Status
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               // Badge Saldo
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                 decoration: BoxDecoration(
//                   color: saldoBg,
//                   borderRadius: BorderRadius.circular(4),
//                 ),
//                 child: Text(
//                   saldoText,
//                   style: TextStyle(
//                     color: saldoColor,
//                     fontSize: 12,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//               // Badge Status Lunas/Belum
//               if (!isLunas) // Jika lunas biasanya tidak perlu badge merah besar, atau bisa pakai "Dibayar" hijau
//                 Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 8,
//                     vertical: 4,
//                   ),
//                   decoration: BoxDecoration(
//                     color: statusBg,
//                     borderRadius: BorderRadius.circular(4),
//                   ),
//                   child: Text(
//                     statusText,
//                     style: TextStyle(
//                       color: statusColor,
//                       fontSize: 12,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 )
//               else
//                 Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 8,
//                     vertical: 4,
//                   ),
//                   decoration: BoxDecoration(
//                     color: Colors.green[50],
//                     borderRadius: BorderRadius.circular(4),
//                   ),
//                   child: const Text(
//                     "Dibayar",
//                     style: TextStyle(
//                       color: Colors.green,
//                       fontSize: 12,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
