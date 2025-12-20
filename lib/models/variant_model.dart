// Class pembantu untuk data khusus Shopee (Online)
import 'package:kg/models/enums.dart';
import 'package:kg/models/produk_model.dart';

class ShopeeVariantData {
  final int? id; // Model ID dari Shopee
  final int allocatedStock; // Stok yang "jatahnya" Shopee
  final double originalPrice;
  final double currentPrice; // Harga jual di Shopee
  final String status; // Status varian di Shopee

  ShopeeVariantData({
    this.id,
    required this.allocatedStock,
    required this.originalPrice,
    required this.currentPrice,
    required this.status,
  });

  factory ShopeeVariantData.fromJson(Map<String, dynamic> map) {
    return ShopeeVariantData(
      id: map['id'],
      allocatedStock: map['allocatedStock'],
      originalPrice: map['originalPrice'],
      currentPrice: map['currentPrice'],
      status: map['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'allocatedStock': allocatedStock,
      'originalPrice': originalPrice,
      'currentPrice': currentPrice,
      'status': status,
    };
  }

  ShopeeVariantData copyWith({
    int? id,
    int? allocatedStock,
    double? originalPrice,
    double? currentPrice,
    String? status,
  }) {
    return ShopeeVariantData(
      id: id ?? this.id,
      allocatedStock: allocatedStock ?? this.allocatedStock,
      originalPrice: originalPrice ?? this.originalPrice,
      currentPrice: currentPrice ?? this.currentPrice,
      status: status ?? this.status,
    );
  }
}

// Class pembantu untuk data Gudang (Offline/Master)
class WarehouseVariantData {
  final int physicalStock; // Stok NYATA di rak (Editable by Admin)
  final int
  safetyStock; // Batas aman (misal: sisakan 2 pcs jangan dijual online)
  final double hargaProduksi;
  final double
  cogs; // Cost of Goods Sold (Harga Modal/HPP) - Shopee tidak tahu ini
  final double offlinePrice; // Harga jual kalau orang beli ke toko langsung
  final StatusProduk status;
  final int soldCount;
  WarehouseVariantData({
    required this.physicalStock,
    this.safetyStock = 0,
    required this.hargaProduksi,
    required this.cogs,
    required this.offlinePrice,
    required this.status,
    required this.soldCount,
  });

  // Hitung stok yang BISA dijual ke Shopee
  // Logic: Stok Nyata - Safety Stock
  int get sellableOnlineStock {
    final int stock = physicalStock - safetyStock;
    return stock > 0 ? stock : 0;
  }

  double get profitPerItem => offlinePrice - cogs;

  // toMap & fromMap...

  factory WarehouseVariantData.fromJson(Map<String, dynamic> map) {
    return WarehouseVariantData(
      physicalStock: map['physical_stock'] ?? 0,
      safetyStock: map['safety_stock'] ?? 0,
      hargaProduksi: (map['harga_produksi'] ?? 0).toDouble(),
      cogs: (map['cogs'] ?? 0).toDouble(),
      offlinePrice: (map['offline_price'] ?? 0).toDouble(),
      // Konversi String ke Enum StatusProduk
      status: StatusProduk.values.firstWhere(
        (e) => e.toString() == 'StatusProduk.${map['status']}',
        orElse: () => StatusProduk.NORMAL,
      ),
      soldCount: map['sold_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'physical_stock': physicalStock,
      'safety_stock': safetyStock,
      'harga_produksi': hargaProduksi,
      'cogs': cogs,
      'offline_price': offlinePrice,
      'status': status.toString().split('.').last, // Simpan string enum
      'sold_count': soldCount,
    };
  }

  WarehouseVariantData copyWith({
    int? physicalStock,
    int? safetyStock,
    double? hargaProduksi,
    double? cogs,
    double? offlinePrice,
    StatusProduk? status,
    int? soldCount,
  }) {
    return WarehouseVariantData(
      physicalStock: physicalStock ?? this.physicalStock,
      safetyStock: safetyStock ?? this.safetyStock,
      hargaProduksi: hargaProduksi ?? this.hargaProduksi,
      cogs: cogs ?? this.cogs,
      offlinePrice: offlinePrice ?? this.offlinePrice,
      status: status ?? this.status,
      soldCount: soldCount ?? this.soldCount,
    );
  }
}

class ProductVariant {
  final String id; // Internal UUID
  final String sku; // Link abadi Offline-Online
  final String name;

  // HYBRID DATA
  final ShopeeVariantData?
  shopeeData; // Nullable (bisa jadi barang ini cuma ada di gudang, gak di Shopee)
  final WarehouseVariantData warehouseData; // Wajib ada

  ProductVariant({
    required this.id,
    required this.sku,
    required this.name,
    this.shopeeData,
    required this.warehouseData,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> map) {
    return ProductVariant(
      id: map['id'],
      sku: map['sku'],
      name: map['name'],
      shopeeData: map['shopee_data'] != null
          ? ShopeeVariantData.fromJson(map['shopee_data'])
          : null,
      warehouseData: WarehouseVariantData.fromJson(map['warehouse_data']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sku': sku,
      'name': name,
      'shopee_data': shopeeData?.toJson(),
      'warehouse_data': warehouseData.toJson(),
    };
  }
}
