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

  // --- THEME COLORS ---
  final Color _bgCream = const Color(0xFFFFFEF7);
  final Color _borderColor = Colors.black;
  final Color _shadowColor = Colors.black;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _runAnalysis() async {
    setState(() {
      _isloading = true;
    });
    // Simulasi delay agar terlihat prosesnya (optional)
    await Future.delayed(const Duration(milliseconds: 800));
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
      backgroundColor: _bgCream,
      appBar: AppBar(
        title: const Text(
          "SMART RESTOCK",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
            fontSize: 18,
            letterSpacing: 1,
          ),
        ),
        centerTitle: true,
        backgroundColor: _bgCream,
        elevation: 0,
        shape: Border(bottom: BorderSide(color: _borderColor, width: 2)),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
              onPressed: _runAnalysis,
              icon: const Icon(Icons.refresh, color: Colors.black),
              tooltip: "Hitung ulang analisis",
            ),
          ),
        ],
      ),

      body: _isloading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.black),
                  const SizedBox(height: 16),
                  Text(
                    "MENGANALISIS DATA...",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            )
          : _recommendations.isEmpty
          ? _buildEmptyState()
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: _recommendations.length,
              separatorBuilder: (c, i) => const SizedBox(height: 20),
              itemBuilder: (context, index) {
                final item = _recommendations[index];
                return _buildRestockCard(item);
              },
            ),
    );
  }

  // --- WIDGET: CARD REKOMENDASI ---
  Widget _buildRestockCard(Map<String, dynamic> item) {
    final String category = item['abc_category'];
    final int recStock = item['recommended_stock'];
    final double burnRate = item['daily_burn_rate'];
    final int currentStock =
        item['stock']; // Pastikan field di DB namanya 'stock' atau 'physical_stock'

    // Logic Warna & Badge
    Color badgeColor;
    String badgeText;

    if (category == 'A') {
      badgeColor = const Color(0xFFF9D423); // Kuning Retro
      badgeText = "WINNING PRODUCT";
    } else if (category == 'B') {
      badgeColor = const Color(0xFF80D8FF); // Biru Retro
      badgeText = "REGULAR";
    } else {
      badgeColor = Colors.grey[300]!;
      badgeText = "SLOW MOVER";
    }

    // Estimasi Habis
    int daysLeft = burnRate > 0 ? (currentStock / burnRate).floor() : 99;
    String daysLeftText = daysLeft <= 0 ? "HABIS" : "$daysLeft HARI";

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: _shadowColor,
            offset: const Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER: Badge & Nama Produk
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: _borderColor, width: 2)),
              color: Colors.grey[50],
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Box
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: _borderColor, width: 1.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.inventory_2_outlined, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge Kategori
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: badgeColor,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: _borderColor, width: 1.5),
                        ),
                        child: Text(
                          badgeText,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "${item['product_name']}",
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          height: 1.1,
                        ),
                      ),
                      Text(
                        "Varian: ${item['name']}",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // BODY: Stats Grid
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildStatItem("Sisa Stok", "$currentStock pcs", false),
                    Container(width: 1, height: 30, color: Colors.grey[300]),
                    _buildStatItem(
                      "Terjual/Hari",
                      burnRate.toStringAsFixed(1),
                      false,
                    ),
                    Container(width: 1, height: 30, color: Colors.grey[300]),
                    _buildStatItem(
                      "Estimasi Habis",
                      daysLeftText,
                      daysLeft <= 2,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ACTION BOX: REKOMENDASI
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2F1), // Mint
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _borderColor, width: 1.5),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        offset: Offset(2, 2),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.shopping_cart_checkout,
                        color: Colors.black,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "SARAN PEMBELIAN",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              "+ $recStock Pcs",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),
                Text(
                  "Alasan: Produk ${category == 'A' ? 'Sangat Laris' : 'Standard'} dengan stok menipis.",
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, bool isAlert) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: isAlert ? Colors.red : Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: _borderColor, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black,
                  offset: Offset(4, 4),
                  blurRadius: 0,
                ),
              ],
            ),
            child: const Icon(
              Icons.check_circle_outline,
              size: 50,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "GUDANG AMAN!",
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Belum ada saran belanja saat ini.",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: _runAnalysis,
            style: TextButton.styleFrom(
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: _borderColor, width: 2),
              ),
            ),
            child: const Text(
              "CEK LAGI",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:kg/services/database_helper.dart';
// import 'package:kg/services/smart_analysis_service.dart';

// class SmartRestockScreen extends StatefulWidget {
//   const SmartRestockScreen({super.key});

//   @override
//   State<SmartRestockScreen> createState() => _SmartRestockScreenState();
// }

// class _SmartRestockScreenState extends State<SmartRestockScreen> {
//   List<Map<String, dynamic>> _recommendations = [];
//   bool _isloading = false;

//   @override
//   void initState() {
//     super.initState();
//     _loadData();
//   }

//   Future<void> _runAnalysis() async {
//     setState(() {
//       _isloading = true;
//     });
//     await SmartAnalysisService().runSmartRestockAnalysis();
//     await _loadData();
//     setState(() {
//       _isloading = false;
//     });
//   }

//   Future<void> _loadData() async {
//     final db = await DatabaseHelper.instance.database;

//     final res = await db.rawQuery('''
//   SELECT v.*, p.name as product_name
//   FROM variants v
//   JOIN products p ON v.product_id = p.id
//   WHERE v.recommended_stock > 0
//   ORDER BY v.abc_category ASC, v.recommended_stock DESC
//   ''');

//     setState(() {
//       _recommendations = res;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Smart Analysis"),
//         backgroundColor: Colors.lightBlueAccent,
//         elevation: 0,
//         actions: [
//           IconButton(
//             onPressed: _runAnalysis,
//             icon: Icon(Icons.refresh),
//             tooltip: "Hitung ulang analysis",
//           ),
//         ],
//       ),

//       body: _isloading
//           ? Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   CircularProgressIndicator(),
//                   SizedBox(height: 16),
//                   Text("Sedang menganalisis performa produk"),
//                 ],
//               ),
//             )
//           : _recommendations.isEmpty
//           ? Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   const Icon(
//                     Icons.check_circle_outline,
//                     size: 60,
//                     color: Colors.green,
//                   ),
//                   const SizedBox(height: 16),
//                   const Text("Stok Aman! Belum ada saran belanja."),
//                   TextButton(
//                     onPressed: _runAnalysis,
//                     child: const Text("Analisis Sekarang"),
//                   ),
//                 ],
//               ),
//             )
//           : ListView.builder(
//               padding: EdgeInsets.all(16),
//               itemCount: _recommendations.length,
//               itemBuilder: (context, index) {
//                 final item = _recommendations[index];
//                 final String category = item['abc_category'];
//                 final int recStock = item['recommended_stock'];
//                 final double burnRate = item['daily_burn_rate'];
//                 final int currentStock = item['stock'];

//                 // Warna Badge
//                 Color badgeColor = category == 'A' ? Colors.green : Colors.blue;
//                 String badgeText = category == 'A'
//                     ? "WINNING PRODUCT"
//                     : "STANDARD";

//                 // Estimasi habis
//                 int daysLeft = burnRate > 0
//                     ? (currentStock / burnRate).floor()
//                     : 99;

//                 return Card(
//                   elevation: 2,
//                   margin: EdgeInsets.only(bottom: 12),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Padding(
//                     padding: EdgeInsets.all(16),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Row(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Container(
//                               padding: EdgeInsets.symmetric(
//                                 horizontal: 8,
//                                 vertical: 4,
//                               ),
//                               decoration: BoxDecoration(
//                                 color: badgeColor.withOpacity(0.1),
//                                 borderRadius: BorderRadius.circular(8),
//                                 border: Border.all(color: badgeColor),
//                               ),
//                               child: Text(
//                                 badgeText,
//                                 style: TextStyle(
//                                   color: badgeColor,
//                                   fontWeight: FontWeight.bold,
//                                   fontSize: 10,
//                                 ),
//                               ),
//                             ),
//                             SizedBox(width: 12),
//                             Expanded(
//                               child: Text(
//                                 "${item['product_name']} (${item['name']})",
//                                 style: const TextStyle(
//                                   fontWeight: FontWeight.bold,
//                                   fontSize: 16,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                         SizedBox(height: 12),
//                         Container(
//                           padding: EdgeInsets.all(12),
//                           decoration: BoxDecoration(
//                             color: Colors.orange[50],
//                             borderRadius: BorderRadius.circular(8),
//                             border: Border.all(color: Colors.orange.shade200),
//                           ),
//                           child: Row(
//                             children: [
//                               const Icon(
//                                 Icons.shopping_cart,
//                                 color: Colors.orange,
//                               ),
//                               const SizedBox(width: 12),
//                               Expanded(
//                                 child: Text.rich(
//                                   TextSpan(
//                                     children: [
//                                       const TextSpan(text: "Saran: Beli "),
//                                       TextSpan(
//                                         text: "$recStock pcs",
//                                         style: const TextStyle(
//                                           fontWeight: FontWeight.bold,
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                         SizedBox(height: 12),
//                         // Alasan (Explanation)
//                         Text(
//                           "Alasan: Produk ini laris (Kategori $category) dan diprediksi habis dalam ${daysLeft <= 0 ? 'hari ini' : '$daysLeft hari'} berdasarkan rata-rata penjualan ${burnRate.toStringAsFixed(1)}/hari.",
//                           style: TextStyle(
//                             color: Colors.grey[600],
//                             fontSize: 12,
//                             fontStyle: FontStyle.italic,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 );
//               },
//             ),
//     );
//   }
// }
