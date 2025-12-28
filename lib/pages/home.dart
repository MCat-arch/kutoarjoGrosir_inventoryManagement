import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kg/pages/analysis_page.dart'; // Pastikan ada atau ganti dengan placeholder
import 'package:kg/providers/inventory_provider.dart';
import 'package:kg/providers/party_provider.dart';
import 'package:kg/providers/transaksi_provider.dart';
import 'package:kg/services/home_service.dart';
import 'package:kg/widgets/home_widget.dart'; // Kita akan buat ini di bawah
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late HomeService _homeService;

  // State Filter Grafik
  bool _isDailyChart = true; 

  // Warna Background Cream Retro
  final Color _bgCream = const Color(0xFFFFFEF7);

  @override
  void initState() {
    super.initState();
    _homeService = HomeService();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PartyProvider>(context, listen: false).loadParties();
      Provider.of<InventoryProvider>(context, listen: false).loadProducts();
      Provider.of<TransactionProvider>(context, listen: false).loadTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgCream,
      appBar: HomeWidget.buildAppBar(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. FINANCIAL SUMMARY (BENTO STYLE)
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

            const SizedBox(height: 24),

            // 2. MENU PINTASAN
            const Text(
              "AKSES CEPAT",
              style: TextStyle(
                fontWeight: FontWeight.w900, 
                fontSize: 14,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            HomeWidget.buildQuickActionsGrid(context),

            const SizedBox(height: 24),

            // 3. GRAFIK ANALISIS
             const Text(
              "ANALITIK KEUANGAN",
              style: TextStyle(
                fontWeight: FontWeight.w900, 
                fontSize: 14,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            Consumer<TransactionProvider>(
              builder: (context, transactionProvider, _) {
                final chartData = _isDailyChart
                    ? _homeService.generateChartData(transactionProvider.transactions)
                    : _homeService.generateMonthlyChartData(transactionProvider.transactions);
                    
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

            // 4. RINGKASAN GUDANG
             const Text(
              "STATUS GUDANG",
              style: TextStyle(
                fontWeight: FontWeight.w900, 
                fontSize: 14,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            // Asumsi InventoryAnalysisPage sudah ada/diimport
            const InventoryAnalysisPage(), 
          ],
        ),
      ),
    );
  }
}