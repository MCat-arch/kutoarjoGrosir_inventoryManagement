import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kg/models/enums.dart';
import 'package:kg/models/keuangan_model.dart';
import 'package:kg/ui/pihak/buildTransactionCard.dart';
import 'package:kg/utils/colors.dart';
import 'package:kg/widgets/card_history_transaksi.dart';
import 'package:kg/widgets/transaction_menu_sheet.dart';

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

  late List<TransactionModel> _allTransactions;
  @override
  void initState() {
    super.initState();
    _generateDummyData();
  }

  void _generateDummyData() {
    _allTransactions = [
      TransactionModel(
        id: '1',
        trxNumber: '#INV-005',
        time: DateTime.now().subtract(const Duration(hours: 1)),
        typeTransaksi: trxType.SALE, // Penjualan
        partyName: 'Budi Santoso',
        totalAmount: 150000,
        paidAmount: 150000,
      ),
      TransactionModel(
        id: '2',
        trxNumber: '#EXP-003',
        time: DateTime.now().subtract(const Duration(hours: 5)),
        typeTransaksi: trxType.EXPENSE, // Pengeluaran
        partyName: 'PLN (Listrik)',
        totalAmount: 350000,
        paidAmount: 350000,
      ),
      TransactionModel(
        id: '3',
        trxNumber: '#PUR-002',
        time: DateTime.now().subtract(const Duration(days: 1)),
        typeTransaksi: trxType.PURCHASE, // Pembelian Stok
        partyName: 'Toko Kain Abadi',
        totalAmount: 2000000,
        paidAmount: 0, // Belum Lunas
      ),
      TransactionModel(
        id: '4',
        trxNumber: '#INC-001',
        time: DateTime.now().subtract(const Duration(days: 2)),
        typeTransaksi: trxType.INCOME_OTHER, // Uang Masuk Lain
        partyName: 'Budi Santoso',
        totalAmount: 50000,
        paidAmount: 50000,
      ),
    ];
  }

  List<TransactionModel> get filteredTransaction {
    if (_searchQuery.isEmpty) return _allTransactions;
    return _allTransactions.where((trx) {
      final query = _searchQuery.toLowerCase();
      final matchName = (trx.partyName ?? "").toLowerCase().contains(query);
      final matchNo = trx.trxNumber.toLowerCase().contains(query);
      return matchName || matchNo;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
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
            icon: const Icon(
              Icons.tune,
              color: Colors.black,
            ), // Icon Filter Advanced
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
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                // Tombol Download Laporan
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.download_rounded,
                      color: Colors.black54,
                    ),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ),

          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      _selectedPeriod!,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF27AE60),
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    "Ubah",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8),
          Expanded(
            child: filteredTransaction.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: filteredTransaction.length,
                    itemBuilder: (context, index) {
                      return HistoryTransactionCard(filteredTransaction[index]);
                    },
                  ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF27AE60), // Hijau utama
        child: const Icon(Icons.add, color: Colors.white, size: 28),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true, // Supaya bisa tinggi
            backgroundColor: Colors.transparent, // Agar rounded corner terlihat
            builder: (context) => const TransactionMenuSheet(),
          );
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
