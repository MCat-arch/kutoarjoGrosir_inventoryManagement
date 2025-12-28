import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kg/pages/laporan_keuangan.dart';
import 'package:kg/pages/list_produk.dart';
import 'package:kg/pages/party_pages.dart';
import 'package:kg/services/sync_service.dart';
import 'package:kg/widgets/produk_detail.dart';

class HomeWidget {
  static final NumberFormat _currency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  // --- COLORS PALETTE ---
  static const Color colorBg = Color(0xFFFFFEF7);
  static const Color colorBorder = Colors.black;
  static const Color colorShadow = Colors.black;

  static const Color colorYellow = Color(0xFFF9D423); // Profit / Main
  static const Color colorGreen = Color(0xFF69F0AE); // Income
  static const Color colorRed = Color(0xFFFF8A80); // Expense
  static const Color colorBlue = Color(0xFF80D8FF); // Actions

  static AppBar buildAppBar(context) {
    return AppBar(
      backgroundColor: colorBg,
      elevation: 0,
      centerTitle: false,
      titleSpacing: 20,
      shape: const Border(bottom: BorderSide(color: colorBorder, width: 2)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorYellow,
              shape: BoxShape.circle,
              border: Border.all(color: colorBorder, width: 2),
            ),
            child: const Icon(Icons.storefront, color: Colors.black, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                "Halo, Owner 👋",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                "Kutoarjo Grosir",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.sync),
          onPressed: () async {
            final syncService = SyncService();
            await syncService.syncData();
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text("Sync Completed")));
          },
        ),
      ],
    );
  }

  // --- FINANCIAL CARD (BENTO GRID STYLE) ---
  static Widget buildFinancialCard({
    required double income,
    required double expense,
    required double profit,
  }) {
    return Column(
      children: [
        // 1. BIG PROFIT CARD
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colorYellow, // Warna Mencolok
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorBorder, width: 2),
            boxShadow: const [
              BoxShadow(
                color: colorShadow,
                offset: Offset(4, 4),
                blurRadius: 0,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.monetization_on, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "Total Keuntungan",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                currency.format(profit),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                  letterSpacing: -1,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 2. ROW INCOME & EXPENSE
        Row(
          children: [
            Expanded(
              child: _buildSmallStatCard(
                title: "Pemasukan",
                amount: income,
                color: colorGreen,
                icon: Icons.arrow_downward,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSmallStatCard(
                title: "Pengeluaran",
                amount: expense,
                color: colorRed,
                icon: Icons.arrow_upward,
              ),
            ),
          ],
        ),
      ],
    );
  }

  static Widget _buildSmallStatCard({
    required String title,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorBorder, width: 2),
        boxShadow: const [
          BoxShadow(color: colorShadow, offset: Offset(4, 4), blurRadius: 0),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Icon(icon, size: 14, color: Colors.black),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            currency.format(amount).replaceAll("Rp ", ""), // Hapus Rp biar muat
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  // --- QUICK ACTIONS GRID ---
  static Widget buildQuickActionsGrid(BuildContext context) {
    // Helper utk tombol navigasi
    Widget _btn(String label, IconData icon, Color bg, VoidCallback onTap) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorBorder, width: 2),
            boxShadow: const [
              BoxShadow(
                color: colorShadow,
                offset: Offset(3, 3),
                blurRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: bg,
                  shape: BoxShape.circle,
                  border: Border.all(color: colorBorder, width: 1.5),
                ),
                child: Icon(icon, color: Colors.black, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 0.85,
      children: [
        _btn("Produk", Icons.inventory_2_outlined, colorBlue, () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (c) => const InventoryScreen()),
          );
        }),
        _btn("Pihak", Icons.people_outline, colorYellow, () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (c) => const PartyPages()),
          );
        }),
        _btn("Transaksi", Icons.receipt_long, colorGreen, () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (c) => const HistoryKeuangan()),
          );
        }),
        _btn("Laporan", Icons.bar_chart_rounded, colorRed, () {
          // TODO: Navigasi ke Laporan
        }),
      ],
    );
  }

  // --- CHART SECTION ---
  static Widget buildChartSection({
    required List<FlSpot> chartData,
    required bool isDailyChart,
    required Function(bool) onToggle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorBorder, width: 2),
        boxShadow: const [
          BoxShadow(color: colorShadow, offset: Offset(4, 4), blurRadius: 0),
        ],
      ),
      child: Column(
        children: [
          // Header Chart
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Tren Arus Kas",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              // Toggle Switch Retro
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: colorBorder, width: 1.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    _chartToggleBtn(
                      "Harian",
                      isDailyChart,
                      () => onToggle(true),
                    ),
                    Container(width: 1.5, height: 25, color: colorBorder),
                    _chartToggleBtn(
                      "Bulanan",
                      !isDailyChart,
                      () => onToggle(false),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Chart
          AspectRatio(
            aspectRatio: 1.7,
            child: chartData.isEmpty
                ? Center(
                    child: Text(
                      "Belum ada data",
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.grey.withOpacity(0.2),
                          strokeWidth: 1,
                          dashArray: [5, 5], // Dotted line
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: chartData,
                          isCurved: true,
                          color: Colors.black, // Garis Grafik Hitam Tegas
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 4,
                                color: colorYellow, // Titik Kuning
                                strokeWidth: 2,
                                strokeColor: Colors.black, // Outline Hitam
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: colorYellow.withOpacity(
                              0.2,
                            ), // Shading bawah kuning
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  static Widget _chartToggleBtn(
    String text,
    bool isActive,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? Colors.black : Colors.transparent,
          borderRadius: isActive
              ? BorderRadius.circular(18)
              : BorderRadius.zero,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}
