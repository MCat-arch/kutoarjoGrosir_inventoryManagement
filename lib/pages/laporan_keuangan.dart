import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:kg/models/transaction_model.dart';
import 'package:kg/services/pdf_report_service.dart';
// import 'package:kg/ui/transaction/buildTransactionCard.dart'; // Pastikan import ini sesuai kebutuhan
// import 'package:kg/utils/colors.dart'; // Kita gunakan local theme color
import 'package:kg/widgets/card_history_transaksi.dart';
import 'package:kg/widgets/transaction_menu_sheet.dart';
import 'package:kg/providers/transaksi_provider.dart';

class HistoryKeuangan extends StatefulWidget {
  const HistoryKeuangan({super.key});

  @override
  State<HistoryKeuangan> createState() => _HistoryKeuanganState();
}

class _HistoryKeuanganState extends State<HistoryKeuangan> {
  final dateFormat = DateFormat('dd MMM yyyy . HH:mm');
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = "";

  // ignore: unused_field
  List<String> period = ["Sepanjang tahun", "Harian", "Mingguan", "Bulanan"];
  // ignore: unused_field
  String _selectedPeriod = "Harian";

  // --- THEME COLORS (Retro Palette) ---
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

  List<TransactionModel> _applySearchFilter(List<TransactionModel> list) {
    if (_searchQuery.isEmpty) return list;
    final q = _searchQuery.toLowerCase();
    return list.where((trx) {
      final matchName = (trx.partyName ?? "").toLowerCase().contains(q);
      final matchNo = trx.trxNumber.toLowerCase().contains(q);
      final matchDesc = (trx.description ?? "").toLowerCase().contains(q);
      return matchName || matchNo || matchDesc;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final txnProvider = Provider.of<TransactionProvider>(context);
    final List<TransactionModel> allTransactions = txnProvider.transactions;
    final filtered = _applySearchFilter(allTransactions);

    return Scaffold(
      backgroundColor: _bgCream,
      appBar: AppBar(
        backgroundColor: _bgCream,
        elevation: 0,
        // Garis Bawah AppBar Retro
        shape: Border(bottom: BorderSide(color: _borderColor, width: 2)),
        centerTitle: true,
        title: const Text(
          "Riwayat Transaksi",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900, // Extra Bold
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: Column(
        children: [
          // --- SEARCH & ACTION BAR ---
          Container(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            decoration: BoxDecoration(
              color: _bgCream,
              // Opsional: Garis pemisah bawah tipis jika ingin memisahkan area header
              // border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              children: [
                // SEARCH FIELD
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: _shadowColor,
                          offset: const Offset(4, 4), // Hard Shadow
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (val) => setState(() {
                        _searchQuery = val;
                      }),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        hintText: "Cari nomor / nama...",
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.black,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                        // Retro Border Styling
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
                const SizedBox(width: 16),

                // PRINT BUTTON
                GestureDetector(
                  onTap: () {
                    PdfReportService().printTransactionReport(
                      allTransactions,
                      DateTime.now().subtract(const Duration(days: 30)),
                      DateTime.now(),
                    );
                  },
                  child: Container(
                    height: 50, // Samakan tinggi dengan TextField
                    width: 50,
                    decoration: BoxDecoration(
                      color: Colors.white, // Tombol Putih
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _borderColor, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: _shadowColor,
                          offset: const Offset(4, 4), // Hard Shadow
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.print_outlined,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- LIST BODY ---
          Expanded(
            child: txnProvider.isLoading && allTransactions.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.black),
                  )
                : filtered.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    color: Colors.black,
                    backgroundColor: Colors.white,
                    onRefresh: () => txnProvider.loadTransactions(),
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      itemCount: filtered.length,
                      separatorBuilder: (c, i) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        // Asumsi widget ini bisa menyesuaikan diri atau sudah di-style
                        // Jika belum, sebaiknya widget CardHistoryTransaksi juga diberi border/shadow
                        return HistoryTransactionCard(filtered[index], context);
                      },
                    ),
                  ),
          ),
        ],
      ),

      // --- FAB (ADD BUTTON) ---
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 10),
        height: 56,
        child: FloatingActionButton.extended(
          backgroundColor: Colors.black, // Hitam Solid
          foregroundColor: Colors.white, // Icon/Text Putih
          elevation: 10,
          highlightElevation: 0,
          // Border Button
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.black, width: 2),
          ),
          onPressed: () async {
            await showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => const TransactionMenuSheet(),
            );
            // ignore: use_build_context_synchronously
            await Provider.of<TransactionProvider>(
              context,
              listen: false,
            ).loadTransactions();
          },
          icon: const Icon(Icons.add, size: 28),
          label: const Text(
            "Transaksi",
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  // --- EMPTY STATE WIDGET ---
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon Retro Box
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: _borderColor, width: 2),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _shadowColor,
                  offset: const Offset(3, 3),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              size: 40,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "BELUM ADA TRANSAKSI",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w900,
              fontSize: 16,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Silakan buat transaksi baru\nmelalui tombol di bawah.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:provider/provider.dart';
// import 'package:kg/models/enums.dart';
// import 'package:kg/models/transaction_model.dart';
// import 'package:kg/services/pdf_report_service.dart';
// import 'package:kg/ui/transaction/buildTransactionCard.dart';
// import 'package:kg/utils/colors.dart';
// import 'package:kg/widgets/card_history_transaksi.dart';
// import 'package:kg/widgets/transaction_menu_sheet.dart';
// import 'package:kg/providers/transaksi_provider.dart';

// class HistoryKeuangan extends StatefulWidget {
//   const HistoryKeuangan({super.key});

//   @override
//   State<HistoryKeuangan> createState() => _HistoryKeuanganState();
// }

// class _HistoryKeuanganState extends State<HistoryKeuangan> {
//   final dateFormat = DateFormat('dd MMM yyyy . HH:mm');
//   final TextEditingController _searchCtrl = TextEditingController();
//   String _searchQuery = "";
//   List<String> period = ["Sepanjang tahun", "Harian", "Mingguan", "Bulanan"];
//   String _selectedPeriod = "Harian";

//   @override
//   void initState() {
//     super.initState();
//     // Load transactions once the first frame is rendered
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       Provider.of<TransactionProvider>(
//         context,
//         listen: false,
//       ).loadTransactions();
//     });
//   }

//   List<TransactionModel> _applySearchFilter(List<TransactionModel> list) {
//     if (_searchQuery.isEmpty) return list;
//     final q = _searchQuery.toLowerCase();
//     return list.where((trx) {
//       final matchName = (trx.partyName ?? "").toLowerCase().contains(q);
//       final matchNo = trx.trxNumber.toLowerCase().contains(q);
//       final matchDesc = (trx.description ?? "").toLowerCase().contains(q);
//       return matchName || matchNo || matchDesc;
//     }).toList();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final txnProvider = Provider.of<TransactionProvider>(context);
//     final List<TransactionModel> allTransactions = txnProvider.transactions;
//     final filtered = _applySearchFilter(allTransactions);

//     return Scaffold(
//       backgroundColor: backgroundColor,
//       appBar: AppBar(
//         backgroundColor: backgroundAppBar,
//         elevation: 0,
//         title: Center(
//           child: const Text(
//             "Riwayat Transaksi",
//             style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
//           ),
//         ),
//         actions: [
//           // IconButton(
//           //   icon: const Icon(Icons.tune, color: Colors.black),
//           //   onPressed: () {
//           //     // TODO: Show Filter BottomSheet (Jenis Transaksi, Status Lunas, dll)
//           //   },
//           // ),
//         ],
//       ),
//       body: Column(
//         children: [
//           Container(
//             color: container,
//             padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     controller: _searchCtrl,
//                     onChanged: (val) => setState(() {
//                       _searchQuery = val;
//                     }),
//                     decoration: InputDecoration(
//                       hintText: "Cari nomor / nama pihak...",
//                       prefixIcon: const Icon(Icons.search, color: Colors.grey),
//                       filled: true,
//                       fillColor: Colors.grey[100],
//                       contentPadding: EdgeInsets.zero,
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(10),
//                         borderSide: BorderSide.none,
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 10),
//                 Container(
//                   decoration: BoxDecoration(
//                     color: Colors.grey[100],
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   child: IconButton(
//                     icon: const Icon(Icons.print),
//                     onPressed: () {
//                       // Panggil Service PDF menggunakan data yang ada saat ini
//                       PdfReportService().printTransactionReport(
//                         allTransactions,
//                         DateTime.now().subtract(const Duration(days: 30)),
//                         DateTime.now(),
//                       );
//                     },
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           const SizedBox(height: 8),
//           // Body: loading / empty / list
//           Expanded(
//             child: txnProvider.isLoading && allTransactions.isEmpty
//                 ? const Center(child: CircularProgressIndicator())
//                 : filtered.isEmpty
//                 ? _buildEmptyState()
//                 : RefreshIndicator(
//                     onRefresh: () => txnProvider.loadTransactions(),
//                     child: ListView.builder(
//                       padding: const EdgeInsets.all(16),
//                       itemCount: filtered.length,
//                       itemBuilder: (context, index) {
//                         return HistoryTransactionCard(filtered[index], context);
//                       },
//                     ),
//                   ),
//           ),
//         ],
//       ),

//       floatingActionButton: FloatingActionButton(
//         backgroundColor: const Color(0xFF27AE60),
//         child: const Icon(Icons.add, color: Colors.white, size: 28),
//         onPressed: () async {
//           // Buka menu transaksi, lalu reload jika user menambah sesuatu
//           await showModalBottomSheet(
//             context: context,
//             isScrollControlled: true,
//             backgroundColor: Colors.transparent,
//             builder: (context) => const TransactionMenuSheet(),
//           );
//           // Setelah sheet ditutup, reload transaksi
//           await Provider.of<TransactionProvider>(
//             context,
//             listen: false,
//           ).loadTransactions();
//         },
//       ),
//     );
//   }

//   Widget _buildEmptyState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(Icons.history, size: 60, color: Colors.grey[300]),
//           const SizedBox(height: 10),
//           Text(
//             "Belum ada transaksi",
//             style: TextStyle(color: Colors.grey[500]),
//           ),
//         ],
//       ),
//     );
//   }
// }
