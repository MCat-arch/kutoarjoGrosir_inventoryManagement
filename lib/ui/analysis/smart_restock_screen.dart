import 'package:flutter/material.dart';
import 'package:kg/services/database_helper.dart';
import 'package:kg/services/smart_analysis_service.dart';

class SmartRestockScreen extends StatefulWidget {
  const SmartRestockScreen({super.key});

  @override
  State<SmartRestockScreen> createState() => _SmartRestockScreenState();
}

class _SmartRestockScreenState extends State<SmartRestockScreen> {
  List<Map<String, dynamic>> _recommendations = [];
  bool _isloading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _runAnalysis() async {
    setState(() {
      _isloading = true;
    });
    await SmartAnalysisService().runSmartRestockAnalysis();
    await _loadData();
    setState(() {
      _isloading = false;
    });
  }

  Future<void> _loadData() async {
    final db = await DatabaseHelper.instance.database;

    final res = await db.rawQuery('''
  SELECT v.*, p.name as product_name
  FROM variants v
  JOIN products p ON v.product_id = p.id
  WHERE v.recommended_stock > 0
  ORDER BY v.abc_category ASC, v.recommended_stock DESC
  ''');

    setState(() {
      _recommendations = res;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Smart Analysis"),
        backgroundColor: Colors.lightBlueAccent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _runAnalysis,
            icon: Icon(Icons.refresh),
            tooltip: "Hitung ulang analysis",
          ),
        ],
      ),

      body: _isloading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Sedang menganalisis performa produk"),
                ],
              ),
            )
          : _recommendations.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 60,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 16),
                  const Text("Stok Aman! Belum ada saran belanja."),
                  TextButton(
                    onPressed: _runAnalysis,
                    child: const Text("Analisis Sekarang"),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: _recommendations.length,
              itemBuilder: (context, index) {
                final item = _recommendations[index];
                final String category = item['abc_category'];
                final int recStock = item['recommended_stock'];
                final double burnRate = item['daily_burn_rate'];
                final int currentStock = item['stock'];

                // Warna Badge
                Color badgeColor = category == 'A' ? Colors.green : Colors.blue;
                String badgeText = category == 'A'
                    ? "WINNING PRODUCT"
                    : "STANDARD";

                // Estimasi habis
                int daysLeft = burnRate > 0
                    ? (currentStock / burnRate).floor()
                    : 99;

                return Card(
                  elevation: 2,
                  margin: EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: badgeColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: badgeColor),
                              ),
                              child: Text(
                                badgeText,
                                style: TextStyle(
                                  color: badgeColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "${item['product_name']} (${item['name']})",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.shopping_cart,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text.rich(
                                  TextSpan(
                                    children: [
                                      const TextSpan(text: "Saran: Beli "),
                                      TextSpan(
                                        text: "$recStock pcs",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 12),
                        // Alasan (Explanation)
                        Text(
                          "Alasan: Produk ini laris (Kategori $category) dan diprediksi habis dalam ${daysLeft <= 0 ? 'hari ini' : '$daysLeft hari'} berdasarkan rata-rata penjualan ${burnRate.toStringAsFixed(1)}/hari.",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
