// file: lib/models/product_model.dart

import 'package:kg/models/enums.dart'; // Enum ShopeeItemStatus
import 'package:kg/models/produk.dart';

class ProductModel {
  final String id; // Firestore Doc ID

  // Data Tampilan Utama
  final String name;
  final String description;
  final String? mainImageUrl; // Foto Utama (Untuk Thumbnail List)

  // Data Bisnis (Dipindahkan dari variant agar tidak duplikat)
  final String categoryName; // "Kemeja", "Celana"
  final String supplierName; // "Pak Budi Tailor"

  // Data Shopee (Parent Level)
  final int? shopeeItemId;
  final ShopeeItemStatus shopeeStatus;

  // List Varian
  final List<ProductVariant> variants;
  final DateTime lastUpdated;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    this.mainImageUrl,
    required this.categoryName,
    required this.supplierName,
    this.shopeeItemId,
    required this.shopeeStatus,
    required this.variants,
    required this.lastUpdated,
  });

  // --- HELPER UNTUK UI GRID VIEW ---
  // Menjumlahkan stok dari semua varian untuk ditampilkan di Card Depan
  int get totalStock =>
      variants.fold(0, (sum, v) => sum + v.warehouseData.physicalStock);

  // Mengambil range harga (jika varian harganya beda-beda)
  double get minPrice {
    if (variants.isEmpty) return 0;
    return variants
        .map((v) => v.warehouseData.offlinePrice)
        .reduce((a, b) => a < b ? a : b);
  }

  // Menghitung Total Keuntungan Produk ini (Akumulasi semua varian)
  double get totalProfitAccrued {
    return variants.fold(0.0, (sum, v) {
      // (Harga Jual - COGS) * Jumlah Terjual
      double profitPerUnit =
          v.warehouseData.offlinePrice - v.warehouseData.cogs;
      return sum + (profitPerUnit * v.warehouseData.soldCount);
    });
  }

  // Mengambil total barang terjual
  int get totalSoldCount =>
      variants.fold(0, (sum, v) => sum + v.warehouseData.soldCount);

  factory ProductModel.fromJson(Map<String, dynamic> map, String docId) {
    return ProductModel(
      id: docId,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      mainImageUrl: map['main_image_url'],
      categoryName: map['category_name'] ?? 'Umum',
      supplierName: map['supplier_name'] ?? 'Unknown',
      shopeeItemId: map['shopee_item_id'],

      // Enum Parsing
      shopeeStatus: ShopeeItemStatus.values.firstWhere(
        (e) => e.toString() == 'ShopeeItemStatus.${map['shopee_status']}',
        orElse: () => ShopeeItemStatus.NORMAL,
      ),

      variants: List<ProductVariant>.from(
        (map['variants'] ?? []).map((x) => ProductVariant.fromJson(x)),
      ),

      lastUpdated: (map['last_updated']).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'main_image_url': mainImageUrl,
      'category_name': categoryName,
      'supplier_name': supplierName,
      'shopee_item_id': shopeeItemId,
      'shopee_status': shopeeStatus.toString().split('.').last,
      'variants': variants.map((x) => x.toJson()).toList(),
      'last_updated': lastUpdated,
    };
  }

  ProductModel copyWith({
    String? id,
    String? name,
    String? description,
    String? mainImageUrl,
    String? categoryName,
    String? supplierName,
    int? shoppeItemId,
    ShopeeItemStatus? shopeeStatus,
    List<ProductVariant>? variants,
    DateTime? lastUpdated,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      mainImageUrl: mainImageUrl ?? this.mainImageUrl,
      categoryName: categoryName ?? this.categoryName,
      supplierName: supplierName ?? this.supplierName,
      shopeeStatus: shopeeStatus ?? this.shopeeStatus,
      variants: variants ?? this.variants,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
