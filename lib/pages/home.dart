import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // Wajib import untuk Grafik
import 'package:intl/intl.dart';
import 'package:kg/pages/analysis_page.dart';
import 'package:kg/pages/list_produk.dart';
import 'package:kg/providers/inventory_provider.dart';
import 'package:kg/providers/party_provider.dart';
import 'package:kg/providers/transaksi_provider.dart';
import 'package:kg/services/home_service.dart';
import 'package:kg/widgets/home_widget.dart';
import 'package:provider/provider.dart';
// import 'package:kg/models/product_model.dart'; // Jika ingin hitung stok real

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final currency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  late HomeService _homeService;

  // State Filter Grafik
  bool _isDailyChart = true; // true = Harian, false = Bulanan

  @override
  void initState() {
    super.initState();
    _homeService = HomeService();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PartyProvider>(context, listen: false).loadParties();
      Provider.of<InventoryProvider>(context, listen: false).loadProducts();
      Provider.of<TransactionProvider>(
        context,
        listen: false,
      ).loadTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: HomeWidget.buildAppBar(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Consumer<TransactionProvider>(
              builder: (context, transactionProvider, _) {
                final financial = _homeService.calculateFinancialSummary(
                  transactionProvider.transactions,
                );
                return HomeWidget.buildFinancialCard(
                  income: financial['income']!,
                  expense: financial['expense']!,
                  profit: financial['profit']!,
                );
              },
            ),

            SizedBox(height: 20),
            // 2. MENU PINTASAN (GRID)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const Text(
                "Akses Cepat",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const SizedBox(height: 10),
            HomeWidget.buildQuickActionsGrid(context),

            const SizedBox(height: 24),

            // 3. GRAFIK ANALISIS (CHART)
            Consumer<TransactionProvider>(
              builder: (context, transactionProvider, _) {
                final chartData = _isDailyChart
                    ? _homeService.generateChartData(
                        transactionProvider.transactions,
                      )
                    : _homeService.generateMonthlyChartData(
                        transactionProvider.transactions,
                      );
                return HomeWidget.buildChartSection(
                  chartData: chartData,
                  isDailyChart: _isDailyChart,
                  onToggle: (isDaily) {
                    setState(() {
                      _isDailyChart = isDaily;
                    });
                  },
                );
              },
            ),

            const SizedBox(height: 24),

            // 4. RINGKASAN GUDANG (INVENTORY)
            InventoryAnalysisPage(),
          ],
        ),
      ),
    );
  }
}
