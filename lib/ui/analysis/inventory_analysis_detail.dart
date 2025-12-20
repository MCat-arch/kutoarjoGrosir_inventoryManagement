import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kg/services/database_helper.dart';

class InventoryDetailPage extends StatefulWidget {
  final String filterType; // 'ALL', 'LOW_STOCK', 'ASSET'

  const InventoryDetailPage({super.key, this.filterType = 'ALL'});

  @override
  State<InventoryDetailPage> createState() => _InventoryDetailPageState();
}

class _InventoryDetailPageState extends State<InventoryDetailPage> {
  final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  Future<void> _loadInventory() async {
    final db = await DatabaseHelper.instance.database;
    String query = '''
      SELECT v.*, p.name as product_name 
      FROM variants v 
      JOIN products p ON v.product_id = p.id
    ''';

    if (widget.filterType == 'LOW_STOCK') {
      query += ' WHERE v.stock <= v.safety_stock OR v.stock <= 5';
    }
    
    // Sort berdasarkan aset tertinggi jika filter ASSET
    if (widget.filterType == 'ASSET') {
      query += ' ORDER BY (v.stock * v.cogs) DESC';
    } else {
      query += ' ORDER BY p.name ASC';
    }

    final res = await db.rawQuery(query);
    setState(() {
      _items = res;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              separatorBuilder: (c, i) => const Divider(),
              itemBuilder: (context, index) {
                final item = _items[index];
                double assetVal = (item['stock'] * item['cogs']).toDouble();
                bool isLow = item['stock'] <= (item['safety_stock'] ?? 5);

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    "${item['product_name']} (${item['name']})",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text("HPP: ${_currency.format(item['cogs'])}"),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "${item['stock']} Unit",
                        style: TextStyle(
                          color: isLow ? Colors.red : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Aset: ${_currency.format(assetVal)}",
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  String _getTitle() {
    if (widget.filterType == 'LOW_STOCK') return "Stok Menipis";
    if (widget.filterType == 'ASSET') return "Valuasi Aset";
    return "Detail Gudang";
  }
}