import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kg/models/enums.dart';
import 'package:kg/models/keuangan_model.dart';
import 'package:kg/models/party_role.dart';
import 'package:kg/pages/uang_keluar_form.dart';
import 'package:kg/pages/uang_masuk_form.dart';
import 'package:kg/providers/party_provider.dart';
import 'package:kg/ui/pihak/buildTransactionCard.dart';
import 'package:kg/utils/colors.dart';
import 'package:provider/provider.dart';

class DetailParty extends StatefulWidget {
  PartyModel party;
  DetailParty({super.key, required this.party});

  @override
  State<DetailParty> createState() => _DetailPartyState();
}

class _DetailPartyState extends State<DetailParty> {
  final _searchCtrl = TextEditingController();

  late List<TransactionModel> _transactions;

  @override
  void initState() {
    super.initState();
    _generateDummyTransactions();
  }

  void _generateDummyTransactions() {
    // Simulasi data transaksi terkait pihak ini
    _transactions = [
      TransactionModel(
        id: '1',
        trxNumber: '#2',
        time: DateTime.now().subtract(const Duration(minutes: 5)),
        typeTransaksi: trxType.INCOME_OTHER, // Uang Masuk
        totalAmount: 10000,
        paidAmount: 10000,
        partyId: widget.party.id,
        description: "Pelunasan Cicilan",
      ),
      TransactionModel(
        id: '2',
        trxNumber: '#2',
        time: DateTime.now().subtract(const Duration(minutes: 10)),
        typeTransaksi: trxType.PURCHASE, // Pembelian
        totalAmount: 10000,
        paidAmount: 0, // Belum dibayar
        partyId: widget.party.id,
      ),
      TransactionModel(
        id: '3',
        trxNumber: '#1',
        time: DateTime.now().subtract(const Duration(minutes: 15)),
        typeTransaksi: trxType.PURCHASE,
        totalAmount: 10000,
        paidAmount: 10000, // Lunas
        partyId: widget.party.id,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final partyProvider = Provider.of<PartyProvider>(context);
    // Ambil versi terbaru dari provider jika ada, fallback ke widget.party
    final PartyModel party = partyProvider.parties.firstWhere(
      (p) => p.id == widget.party.id,
      orElse: () => widget.party,
    );
    bool isDebt = widget.party.balance < 0;
    Color balanceColor = isDebt ? Colors.red : Colors.green;
    String balanceLabel = isDebt ? "Bayar" : "Terima";

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundAppBar,
        elevation: 0.5,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios_rounded, color: Colors.brown),
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.grey,
              child: Text(
                widget.party.name[0].toUpperCase(),
                style: const TextStyle(color: Colors.black),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.party.name,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.party.phone ?? "-",
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // IconButton(
          //   icon: const Icon(Icons.more_vert, color: Colors.black),
          //   onPressed: () {},
          // ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.party.balance.toString(),
                      style: TextStyle(
                        color: balanceColor,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {},
                      label: Text(
                        "Lihat Laporan",
                        style: TextStyle(color: Colors.black),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // 2. SEARCH & FILTER
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  color: Colors.white,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          decoration: InputDecoration(
                            hintText: "Cari catatan, jenis, tagih...",
                            prefixIcon: const Icon(
                              Icons.search,
                              color: Colors.grey,
                            ),
                            contentPadding: EdgeInsets.zero,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.filter_list,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                // 3. LIST TRANSAKSI
                Container(
                  height: 400,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _transactions.length,
                    itemBuilder: (context, index) {
                      return buildTransactionCard(_transactions[index]);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 10,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (c) => UangMasukForm(party: widget.party),
                    ),
                  );
                  await Provider.of<PartyProvider>(
                    context,
                    listen: false,
                  ).loadParties();
                  setState(() {});
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF27AE60),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  "Uang Masuk",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Tombol Plus Bulat
            InkWell(
              onTap: () {
                // Menu Tambahan
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Icon(Icons.add, color: Colors.black54),
              ),
            ),
            const SizedBox(width: 12),
            // Tombol Penjualan (Biru)
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddExpenseScreen(party: widget.party),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2F80ED),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  "Pengeluaran",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
