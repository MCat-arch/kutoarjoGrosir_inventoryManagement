import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kg/models/stock_history.dart';
import 'package:kg/services/inventory_service.dart';

class StockHistoryScreen extends StatelessWidget {
  final String productId;
  final String productName;

  const StockHistoryScreen({
    super.key,
    required this.productId,
    required this.productName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Riwayat Stok: $productName"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: FutureBuilder<List<StockHistoryModel>>(
        future: InventoryService().getStockHistory(productId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text("Belum ada riwayat perubahan stok."),
            );
          }

          final historyList = snapshot.data!;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: historyList.length,
            separatorBuilder: (c, i) => const Divider(),
            itemBuilder: (context, index) {
              final item = historyList[index];
              final isPositive = item.changeAmount > 0;
              final color = isPositive ? Colors.green : Colors.red;
              final icon = isPositive
                  ? Icons.arrow_upward
                  : Icons.arrow_downward;

              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: color.withOpacity(0.1),
                  child: Icon(icon, color: color, size: 20),
                ),
                title: Text(
                  "${item.type.replaceAll('_', ' ')} (${item.variantName})", // Misal: MANUAL EDIT (Merah-S)
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  DateFormat('dd MMM yyyy • HH:mm').format(item.createdAt),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "${isPositive ? '+' : ''}${item.changeAmount}",
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      "${item.previousStock} ➔ ${item.currentStock}",
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
