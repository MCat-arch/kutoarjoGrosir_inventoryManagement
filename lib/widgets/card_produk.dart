import 'package:flutter/material.dart';
import 'package:kg/pages/list_produk.dart';
import 'package:kg/models/produk_model.dart';
import 'package:kg/widgets/produk_detail.dart';

// WIDGET CARD PRODUK (GRID ITEM)
Widget buildProductCard(ProductModel product, context) {
  bool isOutOfStock = product.totalStock <= 0;

  // var currency;
  return GestureDetector(
    onTap: () => showProductDetail(product, context),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 5,
            offset: const Offset(0, 5),
          ),
        ],
        border: isOutOfStock ? Border.all(color: Colors.red.shade200) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Gambar / Placeholder
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isOutOfStock ? Colors.red[50] : Colors.blue[50],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.shopping_bag_outlined,
                size: 40,
                color: isOutOfStock ? Colors.red[300] : Colors.blue[300],
              ),
            ),
          ),

          // 2. Informasi Utama
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nama
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),

                // Harga Jual (Besar)
                Text(
                  "${product.minPrice}",
                  style: TextStyle(
                    color: Colors.blue[800],
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),

                // HPP (Kecil/Grey)
                Text(
                  "HPP: ${product.totalProfitAccrued}",
                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                ),

                const SizedBox(height: 8),

                // Stok Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isOutOfStock ? Colors.red : Colors.green,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isOutOfStock ? "HABIS" : "Stok: ${product.totalStock}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
