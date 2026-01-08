import 'package:kg/models/performance_variants_model.dart';
import 'package:kg/services/algorithms/k_means_produk.dart';
import 'package:kg/services/algorithms/moving_avg_produk.dart';
import 'package:kg/utils/database_helper.dart';
import 'package:sqflite/sqflite.dart';

class SmartAnalysisService {
  Future<Database> get _db async => await DatabaseHelper.instance.database;

  Future<void> runSmartRestockAnalysis() async {
    List<VariantPerformance> dataPoints = await _fetchPerformanceData(days: 30);
    if (dataPoints.isEmpty) return;

    // run k-means untuk labelling
    KMeansProduk(k: 3, maxIterations: 100).execute(dataPoints);

    // run mva forecasting
    for (var item in dataPoints) {
      if (item.category == 'C') {
        item.suggestedStock = 0;
        item.dailyBurnRate = 0;
        continue; // Skip C
      }

      List<int> dailySales = await _fetchDailySales(item.variantId, 30);

      double burnRate = ForecastEngineMVA.calculateSimpleMovingAverage(
        dailySales,
        30,
      );
      item.dailyBurnRate = burnRate;

      // Hitung Saran Restock
      item.suggestedStock = ForecastEngineMVA.calculateRestockSuggestion(
        dailyBurnRate: burnRate,
        currentStock: item.currentStock,
        priority: item.category,
      );
    }

    await _saveAnalysisResults(dataPoints);
  }

  Future<List<VariantPerformance>> _fetchPerformanceData({
    required int days,
  }) async {
    final db = await _db;
    final dateThreshold = DateTime.now()
        .subtract(Duration(days: days))
        .toIso8601String();

    //AND HERE WE GO THE QUERY
    final result = await db.rawQuery(
      '''
    SELECT
    v.id as variant_id,
    p.name as p_name,
    v.name as v_name,
    v.stock as current_stock,
    COALESCE(SUM(ti.qty), 0) as total_qty,
    COALESCE(SUM(ti.price_at_moment * ti.qty), 0) as total_revenue
  FROM variants v
  JOIN products p ON v.product_id = p.id
  LEFT JOIN transaction_items ti ON v.id = ti.variant_id
  LEFT JOIN transactions t ON ti.transaction_id = t.id
  WHERE t.created_at >= ? AND t.type = 'SALE' OR t.type = 'PURCHASE_RETURN'
  GROUP BY v.id
''',
      [dateThreshold],
    );

    return result
        .map(
          (row) => VariantPerformance(
            variantId: row['variant_id'] as String,
            productName: row['p_name'] as String,
            variantName: row['v_name'] as String,
            totalQtySold: (row['total_qty'] as num).toInt(),
            totalRevenue: (row['total_revenue'] as num).toDouble(),
            currentStock: (row['current_stock'] as num).toInt(),
          ),
        )
        .toList();
  }

  Future<void> _saveAnalysisResults(List<VariantPerformance> items) async {
    final db = await _db;
    final batch = db.batch();

    for (var item in items) {
      batch.update(
        'variants',
        {
          'abc_category': item.category,
          'daily_burn_rate': item.dailyBurnRate,
          'recommended_stock': item.suggestedStock,
          'last_analyzed': DateTime.now().toIso8601String(),
          'is_synced': 0,
        },
        where: 'id = ?',
        whereArgs: [item.variantId],
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<int>> _fetchDailySales(String variantId, int days) async {
    final db = await _db;
    final dateThreshold = DateTime.now().subtract(Duration(days: days));

    //QUERY mengelompokkan penjualan per tanggal
    final result = await db.rawQuery(
      '''
  SELECT
    DATE(t.created_at) as sale_date,
    SUM(ti.qty) as qty
  FROM transaction_items ti
  JOIN transactions t ON ti.transaction_id = t.id
  WHERE ti.variant_id = ?
    AND t.created_at >= ?
    AND t.type = 'SALE'
  GROUP BY DATE(t.created_at)
  ORDER BY sale_date ASC
''',
      [variantId, dateThreshold.toIso8601String()],
    );

    List<int> salesStream = [];

    for (var row in result) {
      salesStream.add((row['qty'] as num).toInt());
    }

    return salesStream;
  }

  // class analysis dashboard
  Future<Map<String, dynamic>> getDashboardStats() async {
    final db = await _db;

    final assetsRes = await db.rawQuery(
      'SELECT SUM(stock * cogs) as total_asset FROM variants',
    );
    double totalAsset =
        (assetsRes.first['total_asset'] as num?)?.toDouble() ?? 0;

    //hitung stok kurang
    final lowStock = await db.rawQuery(
      'SELECT COUNT(*) as count FROM variants WHERE stock <= safety_stock OR stock <= 5',
    );
    int lowStockCount = (lowStock.first['count'] as num?)?.toInt() ?? 0;

    // produk terlaris by qty sold
    final bestSellerRes = await db.rawQuery('''
    SELECT p.name, v.name as variant_name, SUM(ti.qty) as total_sold
    FROM transaction_items ti
    JOIN variants v ON ti.variant_id = v.id
    JOIN products p ON v.product_id = p.id
    GROUP BY ti.variant_id
    ORDER BY total_sold DESC
    LIMIT 1
''');

    String bestSellerName = "-";
    if (bestSellerRes.isNotEmpty) {
      bestSellerName = "${bestSellerRes.first['name']}";
    }

    //jumlah rekomendasi stok
    final smartRes = await db.rawQuery(
      'SELECT COUNT(*) as count FROM variants WHERE recommended_stock > 0',
    );
    int smartAlertCount = (smartRes.first['count'] as num?)?.toInt() ?? 0;

    return {
      'totalAsset': totalAsset,
      'lowStockCount': lowStockCount,
      'bestSellerName': bestSellerName,
      'smartAlertCount': smartAlertCount,
    };
  }
}
