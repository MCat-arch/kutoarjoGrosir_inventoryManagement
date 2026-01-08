import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:kg/models/enums.dart';
import 'package:kg/models/transaction_model.dart';
import 'package:kg/models/party_role.dart';
import 'package:kg/providers/party_provider.dart';
import 'package:kg/providers/transaksi_provider.dart';
import 'package:kg/ui/transaction/generic_transaction_form.dart';
import 'package:kg/ui/transaction/buildTransactionCard.dart'; // Pastikan path benar
// import 'package:kg/utils/colors.dart'; // Kita pakai local theme colors

class DetailParty extends StatefulWidget {
  final PartyModel party;
  const DetailParty({super.key, required this.party});

  @override
  State<DetailParty> createState() => _DetailPartyState();
}

class _DetailPartyState extends State<DetailParty> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = "";

  // --- THEME COLORS ---
  final Color _bgCream = const Color(0xFFFFFEF7);
  final Color _borderColor = Colors.black;
  final Color _shadowColor = Colors.black;

  @override
  void initState() {
    super.initState();
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

    // Ambil versi terbaru dari provider
    final PartyModel party = partyProvider.parties.firstWhere(
      (p) => p.id == widget.party.id,
      orElse: () => widget.party,
    );

    bool isDebt = party.balance < 0;
    // Warna Retro untuk Balance
    Color balanceColor = isDebt ? const Color(0xFFC62828) : const Color(0xFF2E7D32);

    return Scaffold(
      backgroundColor: _bgCream,
      appBar: AppBar(
        backgroundColor: _bgCream,
        elevation: 0,
        // Garis Bawah AppBar Retro
        shape: Border(bottom: BorderSide(color: _borderColor, width: 2)),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.black),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            // Avatar Retro
            Container(
              width: 40, 
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: _borderColor, width: 1.5),
              ),
              child: Center(
                child: Text(
                  party.name.isNotEmpty ? party.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                    fontSize: 18,
                  ),
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
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  party.phone ?? "-",
                  style: TextStyle(
                    color: Colors.grey[700], 
                    fontSize: 12,
                    fontWeight: FontWeight.w600
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // 1. INFO CARD (SALDO)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _bgCream,
              border: Border(bottom: BorderSide(color: _borderColor, width: 2)),
            ),
            child: Column(
              children: [
                // Container Saldo Retro
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _borderColor, width: 2),
                    boxShadow: [
                       BoxShadow(color: _shadowColor, offset: const Offset(4, 4), blurRadius: 0)
                    ]
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SISA SALDO',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(party.balance.abs()),
                            style: TextStyle(
                              color: balanceColor,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDebt ? const Color(0xFFFFCDD2) : const Color(0xFFC8E6C9),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: _borderColor, width: 1),
                            ),
                            child: Text(
                              isDebt ? "PIHAK BERHUTANG" : "ANDA BERHUTANG",
                              style: TextStyle(
                                fontSize: 10, 
                                fontWeight: FontWeight.bold,
                                color: Colors.black
                              ),
                            ),
                          )
                        ],
                      ),
                      // Tombol Laporan Kecil
                      InkWell(
                        onTap: () {
                          // TODO: Navigate to report
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.print_outlined, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Search Bar Retro
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                             BoxShadow(color: _shadowColor, offset: const Offset(3, 3), blurRadius: 0)
                          ]
                        ),
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: (val) => setState(() => _searchQuery = val),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            hintText: "Cari riwayat...",
                            hintStyle: TextStyle(color: Colors.grey[500]),
                            filled: true,
                            fillColor: Colors.white,
                            prefixIcon: const Icon(Icons.search, color: Colors.black),
                            contentPadding: EdgeInsets.zero,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: _borderColor, width: 2),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: _borderColor, width: 2),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: _borderColor, width: 3),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Filter Icon
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _borderColor, width: 2),
                        boxShadow: [
                           BoxShadow(color: _shadowColor, offset: const Offset(3, 3), blurRadius: 0)
                        ]
                      ),
                      child: const Icon(Icons.filter_list, color: Colors.black),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 2. TRANSACTION LIST
          Expanded(
            child: Consumer<TransactionProvider>(
              builder: (context, transactionProvider, _) {
                final filtered = _filterTransactionsByParty(
                  transactionProvider.transactions,
                );

                if (transactionProvider.isLoading && filtered.isEmpty) {
                  return const Center(child: CircularProgressIndicator(color: Colors.black));
                }

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 60, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          'BELUM ADA TRANSAKSI',
                          style: TextStyle(
                            color: Colors.grey[500], 
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    return buildTransactionCard(filtered[index], context);
                  },
                );
              },
            ),
          ),
        ],
      ),

      // 3. BOTTOM BAR ACTIONS
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: _borderColor, width: 2)),
        ),
        child: Row(
          children: [
            // TOMBOL UANG MASUK
            Expanded(
              child: _buildActionButton(
                "Terima Uang",
                const Color(0xFF27AE60), // Hijau
                () => _navigateToTransaction(trxType.UANG_MASUK, party),
              ),
            ),
            const SizedBox(width: 12),

            // TOMBOL MENU (ADD)
            InkWell(
              onTap: () => _showTransactionMenu(context, party),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: _borderColor, width: 2),
                  boxShadow: [
                     BoxShadow(color: _shadowColor, offset: const Offset(2, 2), blurRadius: 0)
                  ]
                ),
                child: const Icon(Icons.add, color: Colors.black, size: 28),
              ),
            ),
            const SizedBox(width: 12),

            // TOMBOL UANG KELUAR
            Expanded(
              child: _buildActionButton(
                "Bayar Uang",
                const Color(0xFFC62828), // Merah
                () => _navigateToTransaction(trxType.UANG_KELUAR, party),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildActionButton(String label, Color color, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Colors.black, width: 2),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ).copyWith(
        // Efek tekan manual shadow bisa ditambahkan di sini jika mau
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
      ),
    );
  }

  void _showTransactionMenu(BuildContext context, PartyModel party) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFFFFFEF7),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: Colors.black, width: 2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                "BUAT TRANSAKSI",
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1),
              ),
            ),
            const SizedBox(height: 24),
            _buildMenuItem(Icons.shopping_cart, "Penjualan", Colors.blue, 
              () => _navigateToTransaction(trxType.SALE, party)),
            const SizedBox(height: 12),
            _buildMenuItem(Icons.shopping_bag, "Pembelian", Colors.orange, 
              () => _navigateToTransaction(trxType.PURCHASE, party)),
            const SizedBox(height: 12),
            _buildMenuItem(Icons.undo, "Retur Penjualan", Colors.purple, 
              () => _navigateToTransaction(trxType.SALE_RETURN, party)),
            const SizedBox(height: 12),
            _buildMenuItem(Icons.redo, "Retur Pembelian", Colors.red, 
              () => _navigateToTransaction(trxType.PURCHASE_RETURN, party)),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black, width: 2),
          boxShadow: const [
             BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0)
          ]
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 16),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // --- NAVIGATION LOGIC WITH AUTO-FILL PARTY ---
  Future<void> _navigateToTransaction(trxType type, PartyModel party) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (c) => GenericTransactionForm(
          type: type, 
          editData: null,
          preSelectedParty: party, 
        ),
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

// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:provider/provider.dart';
// import 'package:kg/models/enums.dart';
// import 'package:kg/models/transaction_model.dart';
// import 'package:kg/models/party_role.dart';
// import 'package:kg/providers/party_provider.dart';
// import 'package:kg/providers/transaksi_provider.dart';
// import 'package:kg/ui/transaction/generic_transaction_form.dart';
// import 'package:kg/ui/transaction/buildTransactionCard.dart';
// import 'package:kg/utils/colors.dart';

// class DetailParty extends StatefulWidget {
//   final PartyModel party;
//   const DetailParty({super.key, required this.party});

//   @override
//   State<DetailParty> createState() => _DetailPartyState();
// }
// // 
// class _DetailPartyState extends State<DetailParty> {
//   final _searchCtrl = TextEditingController();
//   String _searchQuery = "";

//   @override
//   void initState() {
//     super.initState();
//     // Load transactions after frame
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       Provider.of<TransactionProvider>(
//         context,
//         listen: false,
//       ).loadTransactions();
//     });
//   }

//   List<TransactionModel> _filterTransactionsByParty(
//     List<TransactionModel> allTransactions,
//   ) {
//     return allTransactions
//         .where(
//           (trx) =>
//               trx.partyId == widget.party.id &&
//               ((trx.partyName?.toLowerCase() ?? '').contains(
//                     _searchQuery.toLowerCase(),
//                   ) ||
//                   trx.trxNumber.toLowerCase().contains(
//                     _searchQuery.toLowerCase(),
//                   ) ||
//                   (trx.description ?? '').toLowerCase().contains(
//                     _searchQuery.toLowerCase(),
//                   )),
//         )
//         .toList();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final partyProvider = Provider.of<PartyProvider>(context);

//     // Ambil versi terbaru dari provider jika ada, fallback ke widget.party
//     final PartyModel party = partyProvider.parties.firstWhere(
//       (p) => p.id == widget.party.id,
//       orElse: () => widget.party,
//     );

//     bool isDebt = party.balance < 0;
//     Color balanceColor = isDebt ? Colors.red : Colors.green;

//     return Scaffold(
//       backgroundColor: backgroundColor,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0.5,
//         leading: IconButton(
//           onPressed: () => Navigator.pop(context),
//           icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.black),
//         ),
//         title: Row(
//           children: [
//             CircleAvatar(
//               backgroundColor: Colors.grey[200],
//               child: Text(
//                 party.name.isNotEmpty ? party.name[0].toUpperCase() : '?',
//                 style: const TextStyle(
//                   fontWeight: FontWeight.bold,
//                   color: Colors.black,
//                 ),
//               ),
//             ),
//             const SizedBox(width: 12),
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   party.name,
//                   style: const TextStyle(
//                     color: Colors.black,
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 Text(
//                   party.phone ?? "-",
//                   style: const TextStyle(color: Colors.grey, fontSize: 12),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//       body: Column(
//         children: [
//           // Header: Balance & Report
//           Container(
//             color: Colors.white,
//             padding: const EdgeInsets.all(20),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           'Saldo',
//                           style: TextStyle(
//                             color: Colors.grey[600],
//                             fontSize: 12,
//                           ),
//                         ),
//                         const SizedBox(height: 4),
//                         Text(
//                           'Rp ${party.balance.abs().toStringAsFixed(0)}',
//                           style: TextStyle(
//                             color: balanceColor,
//                             fontSize: 28,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ],
//                     ),
//                     OutlinedButton.icon(
//                       onPressed: () {
//                         // TODO: Navigate to report
//                       },
//                       icon: const Icon(Icons.assessment),
//                       label: const Text("Laporan"),
//                       style: OutlinedButton.styleFrom(
//                         side: BorderSide(color: Colors.grey.shade300),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 16),
//                 // Search & Filter
//                 Row(
//                   children: [
//                     Expanded(
//                       child: TextField(
//                         controller: _searchCtrl,
//                         onChanged: (val) => setState(() => _searchQuery = val),
//                         decoration: InputDecoration(
//                           hintText: "Cari transaksi...",
//                           prefixIcon: const Icon(
//                             Icons.search,
//                             color: Colors.grey,
//                           ),
//                           contentPadding: EdgeInsets.zero,
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(8),
//                             borderSide: BorderSide(color: Colors.grey.shade300),
//                           ),
//                           enabledBorder: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(8),
//                             borderSide: BorderSide(color: Colors.grey.shade300),
//                           ),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 10),
//                     Container(
//                       padding: const EdgeInsets.all(12),
//                       decoration: BoxDecoration(
//                         border: Border.all(color: Colors.grey.shade300),
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: const Icon(
//                         Icons.filter_list,
//                         color: Colors.black54,
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),

//           // Transaction List
//           Expanded(
//             child: Consumer<TransactionProvider>(
//               builder: (context, transactionProvider, _) {
//                 final filtered = _filterTransactionsByParty(
//                   transactionProvider.transactions,
//                 );

//                 if (transactionProvider.isLoading && filtered.isEmpty) {
//                   return const Center(child: CircularProgressIndicator());
//                 }

//                 if (filtered.isEmpty) {
//                   return Center(
//                     child: Text(
//                       'Belum ada transaksi',
//                       style: TextStyle(color: Colors.grey[500]),
//                     ),
//                   );
//                 }

//                 return ListView.builder(
//                   padding: const EdgeInsets.all(16),
//                   itemCount: filtered.length,
//                   itemBuilder: (context, index) {
//                     return buildTransactionCard(filtered[index], context);
//                   },
//                 );
//               },
//             ),
//           ),
//         ],
//       ),

//       bottomNavigationBar: Container(
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           boxShadow: [
//             BoxShadow(
//               color: Colors.grey.shade200,
//               blurRadius: 10,
//               offset: const Offset(0, -5),
//             ),
//           ],
//         ),
//         child: Row(
//           children: [
//             // Uang Masuk Button
//             Expanded(
//               child: ElevatedButton(
//                 onPressed: () async {
//                   await Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (c) => GenericTransactionForm(
//                         type: trxType.UANG_MASUK,
//                         editData: null,
//                       ),
//                     ),
//                   );
//                   // Reload setelah kembali
//                   if (mounted) {
//                     await Provider.of<PartyProvider>(
//                       context,
//                       listen: false,
//                     ).loadParties();
//                     await Provider.of<TransactionProvider>(
//                       context,
//                       listen: false,
//                     ).loadTransactions();
//                     setState(() {});
//                   }
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFF27AE60),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(25),
//                   ),
//                   padding: const EdgeInsets.symmetric(vertical: 14),
//                 ),
//                 child: const Text(
//                   "Uang Masuk",
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             ),
//             const SizedBox(width: 12),

//             // Menu Button
//             InkWell(
//               onTap: () {
//                 _showTransactionMenu(context, party);
//               },
//               child: Container(
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   border: Border.all(color: Colors.grey.shade300),
//                 ),
//                 child: const Icon(Icons.add, color: Colors.black54),
//               ),
//             ),
//             const SizedBox(width: 12),

//             // Transaksi Button
//             Expanded(
//               child: ElevatedButton(
//                 onPressed: () async {
//                   await Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (c) => GenericTransactionForm(
//                         type: trxType.UANG_KELUAR,
//                         editData: null,
//                       ),
//                     ),
//                   );
//                   // Reload setelah kembali
//                   if (mounted) {
//                     await Provider.of<PartyProvider>(
//                       context,
//                       listen: false,
//                     ).loadParties();
//                     await Provider.of<TransactionProvider>(
//                       context,
//                       listen: false,
//                     ).loadTransactions();
//                     setState(() {});
//                   }
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFF2F80ED),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(25),
//                   ),
//                   padding: const EdgeInsets.symmetric(vertical: 14),
//                 ),
//                 child: const Text(
//                   "Uang Keluar",
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _showTransactionMenu(BuildContext context, PartyModel party) {
//     showModalBottomSheet(
//       context: context,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (ctx) => Container(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             ListTile(
//               leading: const Icon(Icons.shopping_cart, color: Colors.blue),
//               title: const Text("Penjualan"),
//               onTap: () {
//                 Navigator.pop(ctx);
//                 _navigateToTransaction(trxType.SALE);
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.shopping_bag, color: Colors.orange),
//               title: const Text("Pembelian"),
//               onTap: () {
//                 Navigator.pop(ctx);
//                 _navigateToTransaction(trxType.PURCHASE);
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.undo, color: Colors.purple),
//               title: const Text("Retur Penjualan"),
//               onTap: () {
//                 Navigator.pop(ctx);
//                 _navigateToTransaction(trxType.SALE_RETURN);
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.redo, color: Colors.red),
//               title: const Text("Retur Pembelian"),
//               onTap: () {
//                 Navigator.pop(ctx);
//                 _navigateToTransaction(trxType.PURCHASE_RETURN);
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Future<void> _navigateToTransaction(trxType type) async {
//     await Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (c) => GenericTransactionForm(type: type, editData: null),
//       ),
//     );
//     // Reload setelah kembali
//     if (mounted) {
//       await Provider.of<PartyProvider>(context, listen: false).loadParties();
//       await Provider.of<TransactionProvider>(
//         context,
//         listen: false,
//       ).loadTransactions();
//       setState(() {});
//     }
//   }

//   @override
//   void dispose() {
//     _searchCtrl.dispose();
//     super.dispose();
//   }
// }
