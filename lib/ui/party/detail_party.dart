import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:kg/models/enums.dart';
import 'package:kg/models/transaction_model.dart';
import 'package:kg/models/party_role.dart';
import 'package:kg/providers/party_provider.dart';
import 'package:kg/providers/transaksi_provider.dart';
import 'package:kg/ui/transaction/generic_transaction_form.dart';
import 'package:kg/ui/pihak/buildTransactionCard.dart';
import 'package:kg/utils/colors.dart';

class DetailParty extends StatefulWidget {
  final PartyModel party;
  const DetailParty({super.key, required this.party});

  @override
  State<DetailParty> createState() => _DetailPartyState();
}

class _DetailPartyState extends State<DetailParty> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    // Load transactions after frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TransactionProvider>(
        context,
        listen: false,
      ).loadTransactions();
    });
  }

  List<TransactionModel> _filterTransactionsByParty(
    List<TransactionModel> allTransactions,
  ) {
    return allTransactions
        .where(
          (trx) =>
              trx.partyId == widget.party.id &&
              ((trx.partyName?.toLowerCase() ?? '').contains(
                    _searchQuery.toLowerCase(),
                  ) ||
                  trx.trxNumber.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ) ||
                  (trx.description ?? '').toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  )),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final partyProvider = Provider.of<PartyProvider>(context);

    // Ambil versi terbaru dari provider jika ada, fallback ke widget.party
    final PartyModel party = partyProvider.parties.firstWhere(
      (p) => p.id == widget.party.id,
      orElse: () => widget.party,
    );

    bool isDebt = party.balance < 0;
    Color balanceColor = isDebt ? Colors.red : Colors.green;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.black),
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.grey[200],
              child: Text(
                party.name.isNotEmpty ? party.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  party.name,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  party.phone ?? "-",
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Header: Balance & Report
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Saldo',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Rp ${party.balance.abs().toStringAsFixed(0)}',
                          style: TextStyle(
                            color: balanceColor,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        // TODO: Navigate to report
                      },
                      icon: const Icon(Icons.assessment),
                      label: const Text("Laporan"),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Search & Filter
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (val) => setState(() => _searchQuery = val),
                        decoration: InputDecoration(
                          hintText: "Cari transaksi...",
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.grey,
                          ),
                          contentPadding: EdgeInsets.zero,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
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
              ],
            ),
          ),

          // Transaction List
          Expanded(
            child: Consumer<TransactionProvider>(
              builder: (context, transactionProvider, _) {
                final filtered = _filterTransactionsByParty(
                  transactionProvider.transactions,
                );

                if (transactionProvider.isLoading && filtered.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      'Belum ada transaksi',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    return buildTransactionCard(filtered[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),

      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            // Uang Masuk Button
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (c) => GenericTransactionForm(
                        type: trxType.UANG_MASUK,
                        editData: null,
                      ),
                    ),
                  );
                  // Reload setelah kembali
                  if (mounted) {
                    await Provider.of<PartyProvider>(
                      context,
                      listen: false,
                    ).loadParties();
                    await Provider.of<TransactionProvider>(
                      context,
                      listen: false,
                    ).loadTransactions();
                    setState(() {});
                  }
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

            // Menu Button
            InkWell(
              onTap: () {
                _showTransactionMenu(context, party);
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

            // Transaksi Button
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (c) => GenericTransactionForm(
                        type: trxType.UANG_KELUAR,
                        editData: null,
                      ),
                    ),
                  );
                  // Reload setelah kembali
                  if (mounted) {
                    await Provider.of<PartyProvider>(
                      context,
                      listen: false,
                    ).loadParties();
                    await Provider.of<TransactionProvider>(
                      context,
                      listen: false,
                    ).loadTransactions();
                    setState(() {});
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2F80ED),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  "Uang Keluar",
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

  void _showTransactionMenu(BuildContext context, PartyModel party) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.shopping_cart, color: Colors.blue),
              title: const Text("Penjualan"),
              onTap: () {
                Navigator.pop(ctx);
                _navigateToTransaction(trxType.SALE);
              },
            ),
            ListTile(
              leading: const Icon(Icons.shopping_bag, color: Colors.orange),
              title: const Text("Pembelian"),
              onTap: () {
                Navigator.pop(ctx);
                _navigateToTransaction(trxType.PURCHASE);
              },
            ),
            ListTile(
              leading: const Icon(Icons.undo, color: Colors.purple),
              title: const Text("Retur Penjualan"),
              onTap: () {
                Navigator.pop(ctx);
                _navigateToTransaction(trxType.SALE_RETURN);
              },
            ),
            ListTile(
              leading: const Icon(Icons.redo, color: Colors.red),
              title: const Text("Retur Pembelian"),
              onTap: () {
                Navigator.pop(ctx);
                _navigateToTransaction(trxType.PURCHASE_RETURN);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToTransaction(trxType type) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (c) => GenericTransactionForm(type: type, editData: null),
      ),
    );
    // Reload setelah kembali
    if (mounted) {
      await Provider.of<PartyProvider>(context, listen: false).loadParties();
      await Provider.of<TransactionProvider>(
        context,
        listen: false,
      ).loadTransactions();
      setState(() {});
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }
}
