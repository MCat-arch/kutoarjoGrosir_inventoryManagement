import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kg/models/produk_model.dart';
import 'package:kg/models/variant_model.dart';
import 'package:kg/providers/inventory_provider.dart';
import 'package:provider/provider.dart';

class InventoryDetailPage extends StatelessWidget {
  final String filterType; // 'ASSET', 'LOW_STOCK', 'BEST_SELLER'

  const InventoryDetailPage({super.key, this.filterType = 'ASSET'});

  @override
  Widget build(BuildContext context) {
    // TEMA RETRO
    const Color bgCream = Color(0xFFFFFEF7);
    const Color borderColor = Colors.black;

    String title = "Detail Gudang";
    if (filterType == 'ASSET') title = "Valuasi Aset";
    if (filterType == 'LOW_STOCK') title = "Stok Menipis";
    if (filterType == 'BEST_SELLER') title = "Produk Terlaris";

    return Scaffold(
      backgroundColor: bgCream,
      appBar: AppBar(
        backgroundColor: bgCream,
        title: Text(
          title.toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        centerTitle: true,
        shape: const Border(bottom: BorderSide(color: borderColor, width: 2)),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Consumer<InventoryProvider>(
        builder: (context, provider, _) {
          List<ProductVariant> allVariants = [];

          // 1. Flatten semua varian dari semua produk
          for (var p in provider.products) {
            for (var v in p.variants) {
              // Kita clone/buat object wrapper simple jika perlu info nama produk
              // Disini asumsi ProductVariant cukup, atau modifikasi logic sesuai model
              allVariants.add(v);
            }
          }

          // 2. Filter Logic
          if (filterType == 'LOW_STOCK') {
            allVariants = allVariants
                .where((v) => v.warehouseData.physicalStock < 5)
                .toList();
            // Sort dari yang paling sedikit
            allVariants.sort(
              (a, b) => a.warehouseData.physicalStock.compareTo(
                b.warehouseData.physicalStock,
              ),
            );
          } else if (filterType == 'BEST_SELLER') {
            allVariants.sort(
              (a, b) => b.warehouseData.soldCount.compareTo(
                a.warehouseData.soldCount,
              ),
            );
          } else {
            // ASSET: Sort by Valuasi (Stok * Modal)
            allVariants.sort((a, b) {
              double valA =
                  a.warehouseData.physicalStock * a.warehouseData.cogs;
              double valB =
                  b.warehouseData.physicalStock * b.warehouseData.cogs;
              return valB.compareTo(valA);
            });
          }

          if (allVariants.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: allVariants.length,
            separatorBuilder: (c, i) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final variant = allVariants[index];
              return _buildDetailCard(variant, filterType);
            },
          );
        },
      ),
    );
  }

  Widget _buildDetailCard(ProductVariant variant, String type) {
    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    // Tentukan nilai yang dighlight di sebelah kanan berdasarkan tipe filter
    String rightLabel = "";
    String rightValue = "";
    Color highlightColor = Colors.black;

    if (type == 'ASSET') {
      double assetVal =
          variant.warehouseData.physicalStock * variant.warehouseData.cogs;
      rightLabel = "Total Aset";
      rightValue = currency.format(assetVal);
      highlightColor = Colors.blue[800]!;
    } else if (type == 'LOW_STOCK') {
      rightLabel = "Sisa Stok";
      rightValue = "${variant.warehouseData.physicalStock}";
      highlightColor = Colors.red[800]!;
    } else {
      rightLabel = "Terjual";
      rightValue = "${variant.warehouseData.soldCount}";
      highlightColor = Colors.purple[800]!;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0),
        ],
      ),
      child: Row(
        children: [
          // Avatar Inisial
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: highlightColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.black, width: 1.5),
            ),
            child: Center(
              child: Text(
                variant.name.isNotEmpty ? variant.name[0].toUpperCase() : "?",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  color: highlightColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Info Utama
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  variant.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    "SKU: ${variant.sku}",
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Highlight Value
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                rightLabel.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                rightValue,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: highlightColor,
                ),
              ),
            ],
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
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black,
                  offset: Offset(3, 3),
                  blurRadius: 0,
                ),
              ],
            ),
            child: const Icon(
              Icons.inbox_outlined,
              size: 40,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Tidak ada data ditemukan",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:kg/services/database_helper.dart';

// class InventoryDetailPage extends StatefulWidget {
//   final String filterType; // 'ALL', 'LOW_STOCK', 'ASSET'

//   const InventoryDetailPage({super.key, this.filterType = 'ALL'});

//   @override
//   State<InventoryDetailPage> createState() => _InventoryDetailPageState();
// }

// class _InventoryDetailPageState extends State<InventoryDetailPage> {
//   final _currency = NumberFormat.currency(
//     locale: 'id_ID',
//     symbol: 'Rp ',
//     decimalDigits: 0,
//   );
//   List<Map<String, dynamic>> _items = [];
//   bool _isLoading = true;

//   // Variabel untuk ringkasan header
//   double _totalAssetValue = 0;
//   int _totalItems = 0;

//   final Color _primaryColor = const Color(0xFF27AE60);

//   @override
//   void initState() {
//     super.initState();
//     _loadInventory();
//   }

//   Future<void> _loadInventory() async {
//     final db = await DatabaseHelper.instance.database;
//     String query = '''
//       SELECT v.*, p.name as product_name 
//       FROM variants v 
//       JOIN products p ON v.product_id = p.id
//     ''';

//     if (widget.filterType == 'LOW_STOCK') {
//       query += ' WHERE v.stock <= v.safety_stock OR v.stock <= 5';
//     }

//     // Sort logic
//     if (widget.filterType == 'ASSET') {
//       query += ' ORDER BY (v.stock * v.cogs) DESC';
//     } else {
//       query += ' ORDER BY p.name ASC';
//     }

//     final res = await db.rawQuery(query);

//     // Hitung ringkasan manual
//     double tempAsset = 0;
//     for (var item in res) {
//       final int stok = (item['stock'] ?? 0) as int;
//       final int cogs = (item['cogs'] ?? 0) as int;
//       tempAsset += stok + cogs;
//     }

//     if (mounted) {
//       setState(() {
//         _items = res;
//         _totalItems = res.length;
//         _totalAssetValue = tempAsset;
//         _isLoading = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[50], // Background nyaman
//       appBar: AppBar(
//         title: Text(
//           _getTitle(),
//           style: const TextStyle(
//             fontWeight: FontWeight.w600,
//             color: Colors.black87,
//           ),
//         ),
//         centerTitle: true,
//         backgroundColor: Colors.white,
//         foregroundColor: Colors.black,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () => Navigator.pop(context),
//         ),
//         bottom: PreferredSize(
//           preferredSize: const Size.fromHeight(1),
//           child: Container(color: Colors.grey[200], height: 1),
//         ),
//       ),
//       body: _isLoading
//           ? Center(child: CircularProgressIndicator(color: _primaryColor))
//           : Column(
//               children: [
//                 // 1. HEADER SUMMARY
//                 _buildSummaryHeader(),

//                 // 2. LIST ITEMS
//                 Expanded(
//                   child: _items.isEmpty
//                       ? _buildEmptyState()
//                       : ListView.separated(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 16,
//                             vertical: 20,
//                           ),
//                           itemCount: _items.length,
//                           separatorBuilder: (c, i) =>
//                               const SizedBox(height: 12),
//                           itemBuilder: (context, index) {
//                             return _buildInventoryCard(_items[index]);
//                           },
//                         ),
//                 ),
//               ],
//             ),
//     );
//   }

//   // --- WIDGETS ---

//   Widget _buildSummaryHeader() {
//     String label = "Total Item";
//     String value = "$_totalItems Varian";
//     Color bgColor = Colors.blue[50]!;
//     Color textColor = Colors.blue[800]!;

//     if (widget.filterType == 'ASSET') {
//       label = "Total Valuasi Aset";
//       value = _currency.format(_totalAssetValue);
//       bgColor = Colors.green[50]!;
//       textColor = Colors.green[800]!;
//     } else if (widget.filterType == 'LOW_STOCK') {
//       label = "Perlu Restock";
//       value = "$_totalItems Varian";
//       bgColor = Colors.red[50]!;
//       textColor = Colors.red[800]!;
//     }

//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(20),
//       color: Colors.white,
//       child: Container(
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: bgColor,
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(color: textColor.withOpacity(0.1)),
//         ),
//         child: Column(
//           children: [
//             Text(
//               label,
//               style: TextStyle(
//                 color: textColor.withOpacity(0.8),
//                 fontSize: 13,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//             const SizedBox(height: 4),
//             Text(
//               value,
//               style: TextStyle(
//                 color: textColor,
//                 fontSize: 22,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildInventoryCard(Map<String, dynamic> item) {
//     double assetVal = (item['stock'] * item['cogs']).toDouble();
//     bool isLow = item['stock'] <= (item['safety_stock'] ?? 5);

//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.grey[200]!),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.03),
//             blurRadius: 6,
//             offset: const Offset(0, 3),
//           ),
//         ],
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Icon Inisial Produk
//           Container(
//             width: 44,
//             height: 44,
//             decoration: BoxDecoration(
//               color: isLow ? Colors.red[50] : Colors.grey[100],
//               borderRadius: BorderRadius.circular(10),
//             ),
//             child: Center(
//               child: Text(
//                 item['product_name'] != null
//                     ? item['product_name'][0].toUpperCase()
//                     : '?',
//                 style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                   fontSize: 18,
//                   color: isLow ? Colors.red : Colors.grey[600],
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(width: 14),

//           // Info Produk (Tengah)
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   item['product_name'] ?? 'Tanpa Nama',
//                   style: const TextStyle(
//                     fontWeight: FontWeight.bold,
//                     fontSize: 15,
//                     color: Colors.black87,
//                   ),
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//                 const SizedBox(height: 2),
//                 Text(
//                   "Varian: ${item['name']}",
//                   style: TextStyle(fontSize: 13, color: Colors.grey[600]),
//                 ),
//                 const SizedBox(height: 6),
//                 Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 8,
//                     vertical: 2,
//                   ),
//                   decoration: BoxDecoration(
//                     color: Colors.grey[100],
//                     borderRadius: BorderRadius.circular(4),
//                   ),
//                   child: Text(
//                     "HPP: ${_currency.format(item['cogs'])}",
//                     style: TextStyle(fontSize: 11, color: Colors.grey[700]),
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           // Info Stok & Aset (Kanan)
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.end,
//             children: [
//               Container(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 10,
//                   vertical: 4,
//                 ),
//                 decoration: BoxDecoration(
//                   color: isLow ? Colors.red : _primaryColor,
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 child: Text(
//                   "${item['stock']} Unit",
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontWeight: FontWeight.bold,
//                     fontSize: 12,
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 "Aset",
//                 style: TextStyle(fontSize: 10, color: Colors.grey[400]),
//               ),
//               Text(
//                 _currency.format(assetVal),
//                 style: TextStyle(
//                   fontSize: 13,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.grey[800],
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildEmptyState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(Icons.inventory_2_outlined, size: 60, color: Colors.grey[300]),
//           const SizedBox(height: 16),
//           Text(
//             "Tidak ada data ditemukan",
//             style: TextStyle(color: Colors.grey[500], fontSize: 16),
//           ),
//         ],
//       ),
//     );
//   }

//   String _getTitle() {
//     if (widget.filterType == 'LOW_STOCK') return "Stok Menipis";
//     if (widget.filterType == 'ASSET') return "Valuasi Aset";
//     return "Detail Gudang";
//   }
// }

// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:kg/services/database_helper.dart';

// class InventoryDetailPage extends StatefulWidget {
//   final String filterType; // 'ALL', 'LOW_STOCK', 'ASSET'

//   const InventoryDetailPage({super.key, this.filterType = 'ALL'});

//   @override
//   State<InventoryDetailPage> createState() => _InventoryDetailPageState();
// }

// class _InventoryDetailPageState extends State<InventoryDetailPage> {
//   final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
//   List<Map<String, dynamic>> _items = [];
//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _loadInventory();
//   }

//   Future<void> _loadInventory() async {
//     final db = await DatabaseHelper.instance.database;
//     String query = '''
//       SELECT v.*, p.name as product_name 
//       FROM variants v 
//       JOIN products p ON v.product_id = p.id
//     ''';

//     if (widget.filterType == 'LOW_STOCK') {
//       query += ' WHERE v.stock <= v.safety_stock OR v.stock <= 5';
//     }
    
//     // Sort berdasarkan aset tertinggi jika filter ASSET
//     if (widget.filterType == 'ASSET') {
//       query += ' ORDER BY (v.stock * v.cogs) DESC';
//     } else {
//       query += ' ORDER BY p.name ASC';
//     }

//     final res = await db.rawQuery(query);
//     setState(() {
//       _items = res;
//       _isLoading = false;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(_getTitle()),
//         backgroundColor: Colors.white,
//         foregroundColor: Colors.black,
//         elevation: 0,
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : ListView.separated(
//               padding: const EdgeInsets.all(16),
//               itemCount: _items.length,
//               separatorBuilder: (c, i) => const Divider(),
//               itemBuilder: (context, index) {
//                 final item = _items[index];
//                 double assetVal = (item['stock'] * item['cogs']).toDouble();
//                 bool isLow = item['stock'] <= (item['safety_stock'] ?? 5);

//                 return ListTile(
//                   contentPadding: EdgeInsets.zero,
//                   title: Text(
//                     "${item['product_name']} (${item['name']})",
//                     style: const TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                   subtitle: Text("HPP: ${_currency.format(item['cogs'])}"),
//                   trailing: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     crossAxisAlignment: CrossAxisAlignment.end,
//                     children: [
//                       Text(
//                         "${item['stock']} Unit",
//                         style: TextStyle(
//                           color: isLow ? Colors.red : Colors.black,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       Text(
//                         "Aset: ${_currency.format(assetVal)}",
//                         style: const TextStyle(fontSize: 11, color: Colors.grey),
//                       ),
//                     ],
//                   ),
//                 );
//               },
//             ),
//     );
//   }

//   String _getTitle() {
//     if (widget.filterType == 'LOW_STOCK') return "Stok Menipis";
//     if (widget.filterType == 'ASSET') return "Valuasi Aset";
//     return "Detail Gudang";
//   }
// }