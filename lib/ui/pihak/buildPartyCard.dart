import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kg/models/party_role.dart';
import 'package:kg/ui/party/detail_party.dart';
import 'package:kg/utils/colors.dart';

Widget buildPartyCard(PartyModel party, context) {
  bool hasDebt = party.balance < 0;
  String dateStr = DateFormat('dd MMM yyyy').format(party.lastTransactionDate!);
  bool hasImage = party.imagePath != null && party.imagePath!.isNotEmpty;

  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => DetailParty(party: party)),
      );
    },
    child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: Colors.grey[100],
          backgroundImage: hasImage ? FileImage(File(party.imagePath!)) : null,
          child: !hasImage
              ? Text(
                  party.name.isNotEmpty
                      ? party.name.substring(0, 1).toUpperCase()
                      : "?",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                )
              : null,
        ),
        title: Text(
          party.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Padding(
          padding: EdgeInsets.only(top: 4),
          child: Text(
            party.email ?? dateStr,
            style: TextStyle(color: listTileText, fontSize: 13),
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              party.balance.toString(),
              style: TextStyle(
                color: party.balance == 0 ? Colors.black : Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              party.balance == 0 ? "Telah Diselesaikan" : "Bayar",
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        onTap: () {},
      ),
    ),
  );
}
