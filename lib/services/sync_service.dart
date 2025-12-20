import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart'; // Cek internet
import 'package:kg/services/database_helper.dart';

class SyncService {
  final _dbHelper = DatabaseHelper.instance;
  final _firestore = FirebaseFirestore.instance;

  // Nama Collection di Firestore
  final String _colTrx = 'transactions';
  final String _colParties = 'parties';
  final String _colProducts = 'products';
  final String _colVariants = 'variants';
  final String _colTransactionItems = 'transaction_items';
  final String _colStockHistory = 'stock_history';

  // Fungsi Utama yang akan dipanggil WorkManager
  Future<void> syncData() async {
    // 1. Cek Koneksi (Opsional, WorkManager biasanya sudah handle constraint ini)
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) return;

    print("🔄 Mulai Sinkronisasi Background...");

    await _syncTable('transactions', _colTrx);
    await _syncTable('parties', _colParties);
    await _syncTable('products', _colProducts);
    await _syncTable('variants', _colVariants);
    await _syncTable('transaction_items', _colTransactionItems);
    await _syncTable('stock_history', _colStockHistory);

    print("✅ Sinkronisasi Selesai.");
  }

  // Generic Sync Logic per Table
  Future<void> _syncTable(String tableName, String collectionName) async {
    final db = await _dbHelper.database;

    // Ambil data yang is_synced = 0
    final unsyncedRows = await db.query(
      tableName,
      where: 'is_synced = ?',
      whereArgs: [0],
    );

    if (unsyncedRows.isEmpty) return;

    final batch = _firestore.batch(); // Gunakan Batch Write agar hemat koneksi

    for (var row in unsyncedRows) {
      String docId = row['id'].toString();
      DocumentReference docRef = _firestore
          .collection(collectionName)
          .doc(docId);

      // Convert Map<String, Object?> ke Map<String, dynamic>
      Map<String, dynamic> data = Map<String, dynamic>.from(row);

      // Hapus kolom lokal yang tidak perlu di cloud (opsional)
      data.remove('is_synced');

      batch.set(docRef, data, SetOptions(merge: true));
    }

    // Eksekusi Upload
    try {
      await batch.commit();

      // Jika sukses, tandai lokal jadi is_synced = 1
      for (var row in unsyncedRows) {
        await db.update(
          tableName,
          {'is_synced': 1},
          where: 'id = ?',
          whereArgs: [row['id']],
        );
      }
      print("Uploaded ${unsyncedRows.length} items to $collectionName");
    } catch (e) {
      print("Error syncing $tableName: $e");
    }
  }
}
