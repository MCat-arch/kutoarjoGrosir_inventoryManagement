import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Opsional: Jika ingin format mata uang rapi
import 'package:kg/models/produk_model.dart';
import 'package:kg/widgets/produk_detail.dart';

Widget buildProductCard(ProductModel product, BuildContext context) {
  bool isOutOfStock = product.totalStock <= 0;

  // Format currency sederhana (Opsional)
  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  return GestureDetector(
    onTap: () {
      // Pastikan fungsi showProductDetail sudah diimport dengan benar
      showProductDetail(product, context);
    },
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
        // Border merah jika stok habis
        border: isOutOfStock ? Border.all(color: Colors.red.shade200) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. BAGIAN GAMBAR
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: isOutOfStock ? Colors.red[50] : Colors.blue[50],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              // ClipRRect digunakan agar gambar mengikuti lekukan rounded corners card
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: _buildProductImage(product.mainImageUrl),
              ),
            ),
          ),

          // 2. INFORMASI PRODUK
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nama Produk
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

                // Harga Jual
                Text(
                  currencyFormatter.format(
                    product.minPrice,
                  ), // Menggunakan formatter
                  style: TextStyle(
                    color: Colors.blue[800],
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),

                // HPP (Info Tambahan)
                Text(
                  "HPP: ${currencyFormatter.format(product.totalProfitAccrued)}",
                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                ),

                const SizedBox(height: 8),

                // Badge Stok
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

// Fungsi Helper untuk Menangani Gambar
Widget _buildProductImage(String? imagePath) {
  // 1. Cek apakah path ada dan tidak kosong
  if (imagePath != null && imagePath.isNotEmpty) {
    // 2. Cek apakah file benar-benar ada di storage HP
    File imageFile = File(imagePath);
    if (imageFile.existsSync()) {
      return Image.file(
        imageFile,
        fit: BoxFit.cover, // Agar gambar memenuhi kotak tanpa gepeng
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          // Jika file ada tapi rusak (corrupt)
          return const Center(
            child: Icon(Icons.broken_image, color: Colors.grey),
          );
        },
      );
    }
  }

  // 3. Fallback jika tidak ada gambar (Tampilkan Icon)
  return const Center(
    child: Icon(
      Icons.image_not_supported_outlined,
      color: Colors.grey,
      size: 40,
    ),
  );
}

// import 'package:flutter/material.dart';
// import 'package:kg/pages/list_produk.dart';
// import 'package:kg/models/produk_model.dart';
// import 'package:kg/widgets/produk_detail.dart';

// // WIDGET CARD PRODUK (GRID ITEM)
// Widget buildProductCard(ProductModel product, context) {
//   bool isOutOfStock = product.totalStock <= 0;

//   // var currency;
//   return GestureDetector(
//     onTap: () => showProductDetail(product, context),
//     child: Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.shade200,
//             blurRadius: 5,
//             offset: const Offset(0, 5),
//           ),
//         ],
//         border: isOutOfStock ? Border.all(color: Colors.red.shade200) : null,
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // 1. Gambar / Placeholder
//           Expanded(
//             child: Container(
//               decoration: BoxDecoration(
//                 color: isOutOfStock ? Colors.red[50] : Colors.blue[50],
//                 borderRadius: const BorderRadius.vertical(
//                   top: Radius.circular(16),
//                 ),
//               ),
//               alignment: Alignment.center,
//               child: Icon(
//                 Icons.shopping_bag_outlined,
//                 size: 40,
//                 color: isOutOfStock ? Colors.red[300] : Colors.blue[300],
//               ),
//             ),
//           ),

//           // 2. Informasi Utama
//           Padding(
//             padding: const EdgeInsets.all(12),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Nama
//                 Text(
//                   product.name,
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                   style: const TextStyle(
//                     fontWeight: FontWeight.bold,
//                     fontSize: 14,
//                   ),
//                 ),
//                 const SizedBox(height: 8),

//                 // Harga Jual (Besar)
//                 Text(
//                   "${product.minPrice}",
//                   style: TextStyle(
//                     color: Colors.blue[800],
//                     fontWeight: FontWeight.bold,
//                     fontSize: 14,
//                   ),
//                 ),

//                 // HPP (Kecil/Grey)
//                 Text(
//                   "HPP: ${product.totalProfitAccrued}",
//                   style: const TextStyle(color: Colors.grey, fontSize: 10),
//                 ),

//                 const SizedBox(height: 8),

//                 // Stok Badge
//                 Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 8,
//                     vertical: 4,
//                   ),
//                   decoration: BoxDecoration(
//                     color: isOutOfStock ? Colors.red : Colors.green,
//                     borderRadius: BorderRadius.circular(4),
//                   ),
//                   child: Text(
//                     isOutOfStock ? "HABIS" : "Stok: ${product.totalStock}",
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontSize: 10,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     ),
//   );
// }
