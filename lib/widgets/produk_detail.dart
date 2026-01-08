import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Wajib import ini
import 'package:kg/models/produk_model.dart';
import 'package:kg/ui/inventory/edit_produk.dart';
import 'package:kg/ui/inventory/stock_history.dart';

// Helper Format Rupiah
final currency = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp ',
  decimalDigits: 0,
);

showProductDetail(ProductModel product, BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true, // Supaya sheet bisa tinggi menyesuaikan konten
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      // Kita bungkus dengan DraggableScrollableSheet agar bisa di-swipe ke atas (opsional)
      // Tapi untuk sekarang pakai SingleChildScrollView saja biar simpel
      return Container(
        padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
        // Batasi tinggi maksimal agar tidak menutupi seluruh layar (opsional)
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Handle (Garis Abu di tengah atas)
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              // 2. GAMBAR PRODUK (Logic: Cek null/empty)
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                  image:
                      (product.mainImageUrl != null &&
                          product.mainImageUrl!.isNotEmpty)
                      ? DecorationImage(
                          image: NetworkImage(product.mainImageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child:
                    (product.mainImageUrl == null ||
                        product.mainImageUrl!.isEmpty)
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_not_supported_outlined,
                            size: 50,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Tidak ada gambar",
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ],
                      )
                    : null,
              ),
              const SizedBox(height: 20),

              // 3. Judul & Status
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(
                        255,
                        240,
                        240,
                        240,
                      ), // Sedikit lebih terang biar bagus
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: () {
                        //go to riwayat stok
                        // NAVIGASI KE RIWAYAT
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (c) => StockHistoryScreen(
                              productId: product.id,
                              productName: product.name,
                            ),
                          ),
                        );
                      },
                      icon: Icon(Icons.history_toggle_off, color: Colors.black87),
                      tooltip: "Riwayat Stok",
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Container(
                  //   padding: const EdgeInsets.symmetric(
                  //     horizontal: 10,
                  //     vertical: 5,
                  //   ),
                  //   decoration: BoxDecoration(
                  //     color:
                  //         product.shopeeStatus.toString() ==
                  //             'ShopeeItemStatus.NORMAL'
                  //         ? Colors.green[100]
                  //         : Colors.red[100],
                  //     borderRadius: BorderRadius.circular(20),
                  //   ),
                  //   child: Text(
                  //     product.shopeeStatus
                  //         .toString()
                  //         .split('.')
                  //         .last, // Ambil kata setelah titik
                  //     style: TextStyle(
                  //       color:
                  //           product.shopeeStatus.toString() ==
                  //               'ShopeeItemStatus.NORMAL'
                  //           ? Colors.green[800]
                  //           : Colors.red[800],
                  //       fontWeight: FontWeight.bold,
                  //       fontSize: 12,
                  //     ),
                  //   ),
                  // ),
                ],
              ),
              const SizedBox(height: 20),

              // 4. Grid Info (Keuangan & Stok)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    _detailRow(
                      "Stok Total (Semua Varian)",
                      "${product.totalStock} pcs",
                      isBold: true,
                    ),
                    _detailRow(
                      "Total Terjual",
                      "${product.totalSoldCount} pcs",
                    ),
                    const Divider(height: 24),

                    // Harga Jual (Menggunakan getter minPrice)
                    _detailRow(
                      "Harga Jual (Mulai)",
                      currency.format(product.minPrice),
                    ),

                    // HPP (Karena HPP ada di varian, kita ambil HPP varian pertama sebagai estimasi)
                    _detailRow(
                      "Estimasi HPP/Modal",
                      product.variants.isNotEmpty
                          ? currency.format(
                              product.variants.first.warehouseData.cogs,
                            )
                          : "Rp 0",
                    ),

                    const Divider(height: 24),

                    // Keuntungan Total (Getter totalProfitAccrued)
                    _detailRow(
                      "Total Keuntungan",
                      currency.format(product.totalProfitAccrued),
                      color: Colors.green,
                      isBold: true,
                    ),
                  ],
                ),
              ),

              // 5. Informasi Varian (Opsional tapi Bagus: List Varian Singkat)
              const SizedBox(height: 20),
              const Text(
                "Rincian Varian",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ...product.variants.map(
                (v) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "• ${v.name}",
                        style: const TextStyle(color: Colors.grey),
                      ),
                      Text(
                        "Sisa: ${v.warehouseData.physicalStock}",
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 6. Info Supplier
              const Text(
                "Informasi Tambahan",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _buildInfoTile(
                Icons.store,
                product.supplierName!,
                "Penjahit / Supplier",
              ),
              _buildInfoTile(
                Icons.category,
                product.categoryName,
                "Kategori Produk",
              ),

              const SizedBox(height: 30),

              // 7. Tombol Edit
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context); // Tutup sheet dulu
                    // TODO: Navigasi ke Halaman Edit
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (c) => EditProduk(produk: product),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text("EDIT DATA PRODUK"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blue[900],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

// Helper Widget untuk Baris Detail Angka
Widget _detailRow(
  String label,
  String value, {
  bool isBold = false,
  Color? color,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color ?? Colors.black87,
            fontSize: 16,
          ),
        ),
      ],
    ),
  );
}

// Helper Widget untuk Info Tambahan (Icon + Text)
Widget _buildInfoTile(IconData icon, String title, String subtitle) {
  return ListTile(
    contentPadding: EdgeInsets.zero,
    dense: true,
    leading: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 20, color: Colors.blue[800]),
    ),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
    subtitle: Text(subtitle),
  );
}


