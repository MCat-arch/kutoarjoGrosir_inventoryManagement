import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // Wajib import untuk Grafik
import 'package:intl/intl.dart';
// import 'package:kg/models/product_model.dart'; // Jika ingin hitung stok real

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  // State Filter Grafik
  bool _isDailyChart = true; // true = Harian, false = Bulanan

  // --- DUMMY DATA SUMMARY (Nanti dari Firebase) ---
  double totalIncome = 5000000;
  double totalExpense = 1200000;
  double totalAssetValue = 15000000; // Nilai Aset Gudang
  int lowStockCount = 3; // Peringatan Stok Menipis

  @override
  Widget build(BuildContext context) {
    double netProfit = totalIncome - totalExpense;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. FINANCIAL OVERVIEW CARD
            _buildFinancialCard(netProfit),

            const SizedBox(height: 20),

            // 2. MENU PINTASAN (GRID)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const Text("Akses Cepat", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const SizedBox(height: 10),
            _buildQuickActionsGrid(),

            const SizedBox(height: 24),

            // 3. GRAFIK ANALISIS (CHART)
            _buildChartSection(),

            const SizedBox(height: 24),

            // 4. RINGKASAN GUDANG (INVENTORY)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Ringkasan Gudang", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  TextButton(onPressed: (){}, child: const Text("Lihat Semua"))
                ],
              ),
            ),
            _buildInventorySummary(),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS COMPONENTS ---

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text("Halo, Owner 👋", style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.normal)),
          Text("Toko Baju Berkah", style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none, color: Colors.black),
          onPressed: () {},
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildFinancialCard(double profit) {
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
          BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Keuntungan Bersih Bulan Ini", style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          Text(
            currency.format(profit),
            style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildMiniStat(Icons.arrow_downward, "Pemasukan", totalIncome, Colors.white),
              Container(width: 1, height: 30, color: Colors.white24, margin: const EdgeInsets.symmetric(horizontal: 20)),
              _buildMiniStat(Icons.arrow_upward, "Pengeluaran", totalExpense, Colors.redAccent.shade100),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String label, double amount, Color valueColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
            Text(currency.format(amount), style: TextStyle(color: valueColor, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        )
      ],
    );
  }

  Widget _buildQuickActionsGrid() {
    final actions = [
      {'icon': Icons.add_shopping_cart, 'label': 'Penjualan', 'color': Colors.blue},
      {'icon': Icons.shopping_bag_outlined, 'label': 'Pembelian', 'color': Colors.orange},
      {'icon': Icons.attach_money, 'label': 'Biaya', 'color': Colors.red},
      {'icon': Icons.inventory_2_outlined, 'label': 'Tambah Stok', 'color': Colors.purple},
    ];

    return SizedBox(
      height: 90, // Tinggi fixed agar tidak overflow
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: actions.length,
        separatorBuilder: (c, i) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final item = actions[index];
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (item['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(item['icon'] as IconData, color: item['color'] as Color),
              ),
              const SizedBox(height: 8),
              Text(item['label'] as String, style: const TextStyle(fontSize: 12)),
            ],
          );
        },
      ),
    );
  }

  // --- CHART SECTION (GRAFIK) ---
  Widget _buildChartSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
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
              const Text("Arus Kas", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              // Toggle Harian / Bulanan
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: [
                    _chartToggleBtn("Harian", true),
                    _chartToggleBtn("Bulanan", false),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 20),
          AspectRatio(
            aspectRatio: 1.5,
            child: BarChart(
              BarChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        // Label X-Axis
                        const days = ['Sn', 'Sl', 'Rb', 'Km', 'Jm', 'Sb', 'Mg'];
                        if (value.toInt() < days.length) {
                           return Text(days[value.toInt()], style: const TextStyle(color: Colors.grey, fontSize: 10));
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: _generateChartData(), // Data Grafik
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Legenda Grafik
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _chartLegend(Colors.green, "Masuk"),
              const SizedBox(width: 16),
              _chartLegend(Colors.redAccent, "Keluar"),
            ],
          )
        ],
      ),
    );
  }

  Widget _chartToggleBtn(String label, bool isDaily) {
    bool isActive = _isDailyChart == isDaily;
    return GestureDetector(
      onTap: () => setState(() => _isDailyChart = isDaily),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isActive ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : null,
        ),
        child: Text(
          label, 
          style: TextStyle(
            fontSize: 12, 
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? Colors.black : Colors.grey
          )
        ),
      ),
    );
  }

  Widget _chartLegend(Color color, String label) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  List<BarChartGroupData> _generateChartData() {
    // DUMMY DATA: Nanti diganti dengan logic grouping TransactionModel berdasarkan tanggal
    // Index 0 = Senin, 1 = Selasa, dst.
    return [
      _makeGroupData(0, 5, 2),  // Senin: Masuk 5jt, Keluar 2jt
      _makeGroupData(1, 2, 1),
      _makeGroupData(2, 6, 4),
      _makeGroupData(3, 3, 3),
      _makeGroupData(4, 8, 2),
      _makeGroupData(5, 4, 1),
      _makeGroupData(6, 10, 5), // Minggu
    ];
  }

  BarChartGroupData _makeGroupData(int x, double y1, double y2) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(toY: y1, color: Colors.green, width: 8, borderRadius: BorderRadius.circular(2)),
        BarChartRodData(toY: y2, color: Colors.redAccent, width: 8, borderRadius: BorderRadius.circular(2)),
      ],
    );
  }

  // --- INVENTORY SUMMARY ---
  Widget _buildInventorySummary() {
    return Container(
      height: 120,
      margin: const EdgeInsets.only(top: 10),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _inventoryCard("Total Aset", currency.format(totalAssetValue), Colors.blue[50]!, Colors.blue),
          const SizedBox(width: 12),
          _inventoryCard("Stok Menipis", "$lowStockCount Item", Colors.orange[50]!, Colors.orange),
          const SizedBox(width: 12),
          _inventoryCard("Produk Terlaris", "Kemeja Flanel", Colors.purple[50]!, Colors.purple),
        ],
      ),
    );
  }

  Widget _inventoryCard(String title, String value, Color bgColor, Color accentColor) {
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
          Text(title, style: TextStyle(color: accentColor.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: accentColor, fontSize: 16, fontWeight: FontWeight.bold), maxLines: 2),
        ],
      ),
    );
  }
}