import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HomeWidget {
  static final NumberFormat _currency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static AppBar buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            "Halo, Owner 👋",
            style: TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.normal,
            ),
          ),
          Text(
            "Toko KutoarjoGrosir",
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [],
    );
  }

  static Widget buildFinancialCard({
    required double income,
    required double expense,
    required double profit,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade800, Colors.green.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const Text(
            "Keuntungan Bersih Bulan Ini",
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Text(
            _currency.format(profit),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildMiniStat(
                Icons.arrow_downward,
                "Pemasukan",
                income,
                Colors.white,
              ),
              Container(
                width: 1,
                height: 30,
                color: Colors.white24,
                margin: const EdgeInsets.symmetric(horizontal: 20),
              ),
              _buildMiniStat(
                Icons.arrow_upward,
                "Pengeluaran",
                expense,
                Colors.redAccent.shade100,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _buildMiniStat(
    IconData icon,
    String label,
    double amount,
    Color valueColor,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 10),
            ),
            Text(
              _currency.format(amount),
              style: TextStyle(
                color: valueColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ],
    );
  }

  static Widget buildQuickActionsGrid(BuildContext context) {
    final actions = [
      {
        'icon': Icons.add_shopping_cart,
        'label': 'Penjualan',
        'color': Colors.blue,
        'route': '/transaction',
      },
      {
        'icon': Icons.shopping_bag_outlined,
        'label': 'Pembelian',
        'color': Colors.orange,
        'route': '/transaction',
      },
      {
        'icon': Icons.attach_money,
        'label': 'Biaya',
        'color': Colors.red,
        'route': '/transaction',
      },
      {
        'icon': Icons.inventory_2_outlined,
        'label': 'Tambah Stok',
        'color': Colors.purple,
        'route': '/add-product',
      },
    ];

    return SizedBox(
      height: 90,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final item = actions[index];
          return GestureDetector(
            onTap: () {
              // Navigator.pushNamed(context, item['route']);
              Navigator.pushNamed(context, "${item['route']}");
            },
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (item['color'] as Color).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    item['icon'] as IconData,
                    color: item['color'] as Color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item['label'] as String,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          );
        },
        separatorBuilder: (c, i) => SizedBox(width: 16),
        itemCount: actions.length,
      ),
    );
  }

  static Widget buildChartSection({
    required List<BarChartGroupData> chartData,
    required bool isDailyChart,
    required Function(bool) onToggle,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Arus Kas",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    _chartToggleBtn(
                      "Harian",
                      isDailyChart,
                      () => onToggle(true),
                    ),
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
          const SizedBox(height: 20),
          AspectRatio(
            aspectRatio: 1.5,
            child: BarChart(
              BarChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = ['Sn', 'Sl', 'Rb', 'Km', 'Jm', 'Sb', 'Mg'];
                        if (isDailyChart && value.toInt() < days.length) {
                          return Text(
                            days[value.toInt()],
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 10,
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: chartData,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _chartLegend(Colors.green, "Masuk"),
              const SizedBox(width: 16),
              _chartLegend(Colors.redAccent, "Keluar"),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _chartToggleBtn(
    String label,
    bool isActive,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? Colors.black : Colors.grey,
          ),
        ),
      ),
    );
  }

  static Widget _chartLegend(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  static Widget buildInventorySummary({
    required double assetValue,
    required int lowStockCount,
  }) {
    return Container(
      height: 120,
      margin: const EdgeInsets.only(top: 10),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _inventoryCard(
            "Total Aset",
            _currency.format(assetValue),
            Colors.blue[50]!,
            Colors.blue,
          ),
          const SizedBox(width: 12),
          _inventoryCard(
            "Stok Menipis",
            "$lowStockCount Item",
            Colors.orange[50]!,
            Colors.orange,
          ),
          const SizedBox(width: 12),
          _inventoryCard(
            "Produk Terlaris",
            "Kemeja Flanel",
            Colors.purple[50]!,
            Colors.purple,
          ),
        ],
      ),
    );
  }

  static Widget _inventoryCard(
    String title,
    String value,
    Color bgColor,
    Color accentColor,
  ) {
    return Container(
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
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}
