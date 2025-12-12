import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:kg/models/enums.dart';
import 'package:kg/models/keuangan_model.dart';
import 'package:kg/services/pdf_report_service.dart';
import 'package:kg/ui/pihak/buildTransactionCard.dart';
import 'package:kg/utils/colors.dart';
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
  List<String> period = ["Sepanjang tahun", "Harian", "Mingguan", "Bulanan"];
  String _selectedPeriod = "Harian";

  @override
  void initState() {
    super.initState();
    // Load transactions once the first frame is rendered
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
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundAppBar,
        elevation: 0,
        title: const Text(
          "Riwayat Transaksi",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: Colors.black),
            onPressed: () {
              // TODO: Show Filter BottomSheet (Jenis Transaksi, Status Lunas, dll)
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: container,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (val) => setState(() {
                      _searchQuery = val;
                    }),
                    decoration: InputDecoration(
                      hintText: "Cari nomor / nama pihak...",
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.print),
                    onPressed: () {
                      // Panggil Service PDF menggunakan data yang ada saat ini
                      PdfReportService().printTransactionReport(
                        allTransactions,
                        DateTime.now().subtract(const Duration(days: 30)),
                        DateTime.now(),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_month_outlined,
                      size: 20,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _selectedPeriod,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    // TODO: Ubah periode filter
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF27AE60),
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    "Ubah",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Body: loading / empty / list
          Expanded(
            child: txnProvider.isLoading && allTransactions.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: () => txnProvider.loadTransactions(),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        return HistoryTransactionCard(filtered[index]);
                      },
                    ),
                  ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF27AE60),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
        onPressed: () async {
          // Buka menu transaksi, lalu reload jika user menambah sesuatu
          await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const TransactionMenuSheet(),
          );
          // Setelah sheet ditutup, reload transaksi
          await Provider.of<TransactionProvider>(
            context,
            listen: false,
          ).loadTransactions();
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 10),
          Text(
            "Belum ada transaksi",
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
