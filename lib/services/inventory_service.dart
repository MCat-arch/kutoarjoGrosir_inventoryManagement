import 'package:kg/models/produk_model.dart';
import 'package:kg/models/variant_model.dart';
import 'package:kg/models/stock_history.dart';
import 'package:sqflite/sqflite.dart';
import 'package:kg/services/database_helper.dart';
import 'package:kg/models/enums.dart'; // Import StatusProduk, ShopeeItemStatus

class InventoryService {
  Future<Database> get _db async => await DatabaseHelper.instance.database;

  // ==============================================================================
  // 1. CREATE PRODUCT (Header + Variants)
  // ==============================================================================
  Future<void> createProduct(ProductModel product) async {
    final db = await _db;

    // Gunakan Transaction agar jika insert variant gagal, insert product juga dibatalkan
    await db.transaction((txn) async {
      // A. Insert Header Produk
      await txn.insert('products', {
        'id': product.id,
        'name': product.name,
        'description': product.description,
        'image_url': product.mainImageUrl,
        'category': product.categoryName,
        'shopee_item_id': product.shopeeItemId,
        'supplier_id': product.supplierId,
        // 'shopee_status': product.shopeeStatus.toString() // Jika ada kolom status di header
      });

      // B. Insert Variants
      for (var variant in product.variants) {
        await txn.insert('variants', _mapVariantToDb(variant, product.id));
      }
    });
  }

  // ==============================================================================
  // 2. READ ALL PRODUCTS (JOIN QUERY)
  // ==============================================================================
  Future<List<ProductModel>> getAllProducts() async {
    final db = await _db;

    // Kita ambil semua produk dulu
    final productRows = await db.rawQuery('''
  SELECT p.*, pt.name as supplier_name
  FROM products p
  LEFT JOIN parties pt ON p.supplier_id = pt.id
''');

    List<ProductModel> results = [];

    for (var pRow in productRows) {
      String productId = pRow['id'] as String;

      // Ambil Varian untuk produk ini
      final variantRows = await db.query(
        'variants',
        where: 'product_id = ?',
        whereArgs: [productId],
      );

      // Convert Rows Varian -> List<ProductVariant>
      List<ProductVariant> variantsList = variantRows.map((vRow) {
        return _mapDbToVariant(vRow);
      }).toList();

      // Susun kembali ProductModel
      results.add(
        ProductModel(
          id: productId,
          name: pRow['name'] as String,
          description: pRow['description'] as String? ?? '',
          mainImageUrl: pRow['image_url'] as String?,
          categoryName: pRow['category'] as String? ?? 'Umum',
          supplierId:
              pRow['supplier_id'] as String? ??
              'Unknown', // Mapping supplier_id ke name
          supplierName: pRow['supplier_name'] as String,
          shopeeItemId: pRow['shopee_item_id'] as int?,
          shopeeStatus: ShopeeItemStatus
              .NORMAL, // Default, atau ambil dari DB jika kolomnya ditambah
          variants: variantsList,
          lastUpdated:
              DateTime.now(), // Atau ambil dari DB jika ada kolom updated_at
        ),
      );
    }

    return results;
  }

  
  // ==============================================================================
  // 4. DELETE PRODUCT
  // ==============================================================================
  Future<void> deleteProduct(String id) async {
    final db = await _db;
    // Karena ON DELETE CASCADE diatur di SQL, hapus produk otomatis hapus varian
    await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  // ==============================================================================
  // HELPER MAPPING (PENTING: Menjembatani Model vs Tabel)
  // ==============================================================================

  // Model -> Database Row
  Map<String, dynamic> _mapVariantToDb(
    ProductVariant variant,
    String productId,
  ) {
    return {
      'id': variant.id,
      'product_id': productId,
      'name': variant.name,
      'sku': variant.sku,

      // Data Warehouse
      'stock': variant.warehouseData.physicalStock,
      'cogs': variant.warehouseData.cogs,
      'price': variant.warehouseData.offlinePrice,

      'safety_stock': variant.warehouseData.safetyStock,
      'harga_produksi': variant.warehouseData.hargaProduksi,
      'sold_count': variant.warehouseData.soldCount,
      'status': variant.warehouseData.status.toString(),

      // Data Shopee (Mapping seadanya sesuai tabel)
      'shopee_model_id': variant.shopeeData?.id,
      'is_synced': 0,

      // KOLOM TAMBAHAN UNTUK SMART ANALYSIS (Default value karena model belum punya)
      'abc_category': 'Unknown', // Default kategori ABC
      'daily_burn_rate': 0.0, // Default burn rate
      'recommended_stock': 0, // Default rekomendasi stok
      'last_analyzed': null, // Default null (belum dianalisis)
    };
  }

  // Database Row -> Model
  ProductVariant _mapDbToVariant(Map<String, dynamic> row) {
    return ProductVariant(
      id: row['id'],
      sku: row['sku'],
      name: row['name'],
      // Reconstruct Warehouse Data
      warehouseData: WarehouseVariantData(
        physicalStock: row['stock'] ?? 0,
        cogs: (row['cogs'] ?? 0).toDouble(),
        offlinePrice: (row['price'] ?? 0).toDouble(),

        // Data yang mungkin belum ada di tabel variants saat ini (Default Value)
        safetyStock: row['safety_stock'] ?? 0,
        hargaProduksi: (row['harga_produksi'] ?? 0).toDouble(),
        status: StatusProduk.values.firstWhere(
          (e) => e.toString().split('.').last == (row['status'] ?? 'NORMAL'),
          orElse: () => StatusProduk.NORMAL,
        ),
        soldCount: row['sold_count'] ?? 0,
      ),
      // Reconstruct Shopee Data (Nullable)
      shopeeData: row['shopee_model_id'] != null
          ? ShopeeVariantData(
              id: row['shopee_model_id'],
              allocatedStock:
                  0, // Data Shopee lain biasanya dari API, bukan DB lokal
              originalPrice: 0,
              currentPrice: 0,
              status: 'NORMAL',
            )
          : null,
    );
  }

  Future<void> updateProductWithHistory(
    ProductModel oldproduct,
    ProductModel newproduct,
  ) async {
    final db = await _db;

    await db.transaction((txn) async {
      await txn.update(
        'products',
        {
          'name': newproduct.name,
          'description': newproduct.description,
          'image_url': newproduct.mainImageUrl,
          'category': newproduct.categoryName,
          'supplier_id': newproduct.supplierId,
          'is_synced': 0,
        },
        where: 'id = ?',
        whereArgs: [newproduct.id],
      );

      for (var newVar in newproduct.variants) {
        var oldVar = oldproduct.variants.firstWhere(
          (v) => v.id == newVar.id,
          orElse: () => newVar,
        );

        if (oldVar.id == newVar.id &&
            oldVar.warehouseData.physicalStock !=
                newVar.warehouseData.physicalStock) {
          int oldQty = oldVar.warehouseData.physicalStock;
          int newQty = newVar.warehouseData.physicalStock;

          int diff = newQty - oldQty;

          // Catat History
          await txn.insert('stock_history', {
            'id': DateTime.now().millisecondsSinceEpoch.toString() + newVar.id,
            'variant_id': newVar.id,
            'product_name': newproduct.name,
            'variant_name': newVar.name,
            'previous_stock': oldQty,
            'current_stock': newQty,
            'change_amount': diff,
            'type': 'MANUAL_EDIT',
            'description': 'Perubahan stok manual via Edit Produk',
            'created_at': DateTime.now().toIso8601String(),
          });
        }
      }

      //update variants
      await txn.delete(
        'variants',
        where: 'product_id = ?',
        whereArgs: [newproduct.id],
      );
      for (var variant in newproduct.variants) {
        await txn.insert('variants', _mapVariantToDb(variant, newproduct.id));
      }
    });
  }

  //method read history
  Future<List<StockHistoryModel>> getStockHistory(String productId) async {
    final db = await _db;

    final variants = await db.query(
      'variants',
      columns: ['id'],
      where: 'product_id = ?',
      whereArgs: [productId],
    );

    if (variants.isEmpty) return [];

    final variantIds = variants.map((v) => v['id']).toList();

    final placeholders = List.filled(variantIds.length, '?').join(',');
    final result = await db.query(
      'stock_history',
      where: 'variant_id IN ($placeholders)',
      whereArgs: variantIds,
      orderBy: 'created_at DESC',
    );

    return result.map((e) => StockHistoryModel.fromMap(e)).toList();
  }
}
