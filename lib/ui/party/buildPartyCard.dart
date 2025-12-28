import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kg/models/party_role.dart';
import 'package:kg/ui/party/detail_party.dart';
import 'package:kg/widgets/produk_detail.dart';
// import 'package:kg/utils/colors.dart'; // Kita pakai warna custom di sini biar match

Widget buildPartyCard(PartyModel party, BuildContext context) {
  bool hasDebt = party.balance < 0;
  String dateStr = DateFormat('dd MMM yyyy').format(party.lastTransactionDate!);
  bool hasImage = party.imagePath != null && party.imagePath!.isNotEmpty;

  // Warna retro palette
  const Color borderColor = Colors.black;
  const Color cardBg = Color(0xFFFFFEF7); // Creamy white
  const Color accentRed = Color(0xFFE57373);
  const Color accentGreen = Color(0xFF81C784);

  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => DetailParty(party: party)),
      );
    },
    child: Container(
      margin: const EdgeInsets.only(bottom: 16), // Jarak antar kartu lebih lega
      decoration: BoxDecoration(
        color: cardBg,
        // BORDER RETRO: Garis hitam tegas
        border: Border.all(color: borderColor, width: 2),
        borderRadius: BorderRadius.circular(12),
        // HARD SHADOW: Bayangan solid tanpa blur
        boxShadow: const [
          BoxShadow(
            color: borderColor,
            offset: Offset(4, 4), // Geser ke kanan bawah
            blurRadius: 0, // Tidak ada blur (Hard Shadow)
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            // AVATAR dengan Border
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: borderColor, width: 2),
              ),
              child: CircleAvatar(
                radius: 24,
                backgroundColor: Colors.grey[200],
                backgroundImage: hasImage ? FileImage(File(party.imagePath!)) : null,
                child: !hasImage
                    ? Text(
                        party.name.isNotEmpty
                            ? party.name.substring(0, 1).toUpperCase()
                            : "?",
                        style: const TextStyle(
                          fontWeight: FontWeight.w900, // Sangat Bold
                          color: borderColor,
                          fontSize: 20,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 16),
            
            // TEKS UTAMA
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    party.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800, // Bold Elegant
                      fontSize: 16,
                      color: borderColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    party.email ?? dateStr,
                    style: TextStyle(
                      color: Colors.grey[700], 
                      fontSize: 13,
                      fontWeight: FontWeight.w500
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // TRAILING / INFO SALDO (Gaya Outline Badge)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "${currency.format(party.balance)}",
                  // party.balance.toString(),
                  style: TextStyle(
                    color: party.balance == 0 ? borderColor : accentRed,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                // Badge Outline untuk Status
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: party.balance == 0 ? Colors.grey : borderColor,
                      width: 1.5
                    ),
                  ),
                  child: Text(
                    party.balance == 0 ? "Lunas" : "Bayar",
                    style: TextStyle(
                      color: party.balance == 0 ? Colors.grey[600] : borderColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700, // Bold text
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    ),
  );
}