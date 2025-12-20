import 'package:flutter/material.dart';
import 'package:kg/models/produk_model.dart';
import 'package:kg/models/variant_model.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:kg/providers/inventory_provider.dart';

// Class return value custom untuk dikirim balik
class ProductSelection {
  final ProductModel product;
  final ProductVariant variant;
  ProductSelection(this.product, this.variant);
}

class ProductPickerSheet extends StatefulWidget {
  const ProductPickerSheet({super.key});

  @override
  State<ProductPickerSheet> createState() => _ProductPickerSheetState();
}

class _ProductPickerSheetState extends State<ProductPickerSheet> {
  final currency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    // Load data saat sheet dibuka
    Future.microtask(
      () =>
          Provider.of<InventoryProvider>(context, listen: false).loadProducts(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85, // 85% layar
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Pilih Barang",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(),
          // Search Bar (Bisa dihubungkan ke Provider filter)
          TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: "Cari nama produk...",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (val) {
              context.read<InventoryProvider>().setSearchQuery(val);
            },
          ),
          const SizedBox(height: 10),

          //list produk
          Expanded(
            child: Consumer<InventoryProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading)
                  return const Center(child: CircularProgressIndicator());
                if (provider.filteredProducts.isEmpty)
                  return const Center(child: Text("Produk tidak ditemukan"));
                return ListView.builder(
                  itemCount: provider.filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = provider.filteredProducts[index];
                    return _buildProductItem(product);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductItem(ProductModel product) {
    return Card(
      elevation: 0,
      color: Colors.grey[50],
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ExpansionTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.inventory_2_outlined, color: Colors.blue),
        ),
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text("Total Stok: ${product.totalStock}"),
        children: product.variants.map((variant) {
          bool isOutOfStock = variant.warehouseData.physicalStock <= 0;
          return ListTile(
            contentPadding: const EdgeInsets.only(left: 32, right: 16),
            title: Text(variant.name), // Nama Varian (S, M, L)
            subtitle: Text(currency.format(variant.warehouseData.offlinePrice)),
            trailing: isOutOfStock
                ? const Text(
                    "HABIS",
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  )
                : Text(
                    "Stok: ${variant.warehouseData.physicalStock}",
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
            onTap: isOutOfStock
                ? null
                : () {
                    // Return Selection
                    Navigator.pop(context, ProductSelection(product, variant));
                  },
          );
        }).toList(),
      ),
    );
  }
}
