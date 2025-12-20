import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kg/services/smart_analysis_service.dart';
import 'package:kg/ui/analysis/inventory_analysis_detail.dart';
import 'package:kg/ui/analysis/smart_restock_screen.dart';

class InventoryAnalysisPage extends StatefulWidget {
  const InventoryAnalysisPage({super.key});

  @override
  State<InventoryAnalysisPage> createState() => _InventoryAnalysisPageState();
}

class _InventoryAnalysisPageState extends State<InventoryAnalysisPage> {
  final _currency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  late Future<Map<String, dynamic>> _dashboardData;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _dashboardData = SmartAnalysisService().getDashboardStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _dashboardData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final data =
            snapshot.data ??
            {
              'totalAsset': 0.0,
              'lowStockCount': 0,
              'bestSellerName': '-',
              'smartAlertCount': 0,
            };

        return Column(
          children: [
            // 1. BAGIAN ATAS: SMART ANALYSIS (Gabungan K-Means & MA)
            _buildSmartAnalysisBanner(data['smartAlertCount']),

            // 2. BAGIAN BAWAH: INVENTORY SUMMARY (Statis jadi Dinamis)
            _buildInventorySummaryList(data),
          ],
        );
      },
    );
  }

  Widget _buildSmartAnalysisBanner(int alertCount) {
    bool hasAlert = alertCount > 0;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hasAlert
              ? [const Color(0xFFE5F9E0), const Color(0xFFF0FFF4)] // Hijau Muda
              : [Colors.grey.shade50, Colors.grey.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasAlert
              ? const Color(0xFF27AE60).withOpacity(0.3)
              : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5),
              ],
            ),
            child: Icon(
              hasAlert ? Icons.auto_graph : Icons.check_circle,
              color: hasAlert ? const Color(0xFF27AE60) : Colors.grey,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Smart Stock Analisis",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                SizedBox(height: 4),
                Text(
                  hasAlert
                      ? "$alertCount Barang Prioritas perlu restock segera!"
                      : "Analisis aman. Stok dalam kondisi optimal.",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SmartRestockScreen()),
              );
              _refreshData();
            },
            child: Text(
              "Selengkapnya",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventorySummaryList(Map<String, dynamic> data) {
    return SizedBox(
      height: 120,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 15),
        children: [
          // CARD 1: TOTAL ASET
          _inventoryCard(
            title: "Total Aset",
            value: _currency.format(data['totalAsset']),
            bgColor: Colors.blue[50]!,
            accentColor: Colors.blue,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (c) =>
                      const InventoryDetailPage(filterType: 'ASSET'),
                ),
              );
            },
          ),
          const SizedBox(width: 12),

          // CARD 2: STOK MENIPIS
          _inventoryCard(
            title: "Stok Menipis",
            value: "${data['lowStockCount']} Item",
            bgColor: Colors.orange[50]!,
            accentColor: Colors.orange,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (c) =>
                      const InventoryDetailPage(filterType: 'LOW_STOCK'),
                ),
              );
            },
          ),
          const SizedBox(width: 12),

          //CARD 3 produk terlaris
          _inventoryCard(
            title: "Produk Terlaris",
            value: data['bestSellerName'],
            bgColor: Colors.purple[50]!,
            accentColor: Colors.purple,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => InventoryDetailPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _inventoryCard({
    required String title,
    required String value,
    required Color bgColor,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                color: accentColor.withOpacity(0.8),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: accentColor,
                fontSize:
                    15, // Sedikit dikecilkan agar muat jika nominal panjang
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
