import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart'; // Cek internet
import 'package:kg/services/auth_service.dart';
import 'package:kg/utils/database_helper.dart';

class SyncService {
  final _dbHelper = DatabaseHelper.instance;
  final _firestore = FirebaseFirestore.instance;
  final _authService = AuthService();

  // Nama Collection di Firestore
  final String _colTrx = 'transactions';
  final String _colParties = 'parties';
  final String _colProducts = 'products';
  final String _colVariants = 'variants';
  final String _colTransactionItems = 'transaction_items';
  final String _colStockHistory = 'stock_history';

  // Fungsi Utama yang akan dipanggil WorkManager
  Future<bool> syncData() async {
    try {
      // 1. Cek Koneksi (Opsional, WorkManager biasanya sudah handle constraint ini)
      // var connectivityResult = await (Connectivity().checkConnectivity());
      // if (connectivityResult == ConnectivityResult.none) {
      //     print("No internet connection");
      //     return false;
      //   }

      print("🔄 Mulai Sinkronisasi Background...");

      // Get user ID
      String? userId = await _authService.getUserId();
      if (userId == null) return false;

      await _syncTable(userId, 'transactions', _colTrx);
      await _syncTable(userId, 'parties', _colParties);
      await _syncTable(userId, 'products', _colProducts);
      await _syncTable(userId, 'variants', _colVariants);
      await _syncTable(userId, 'transaction_items', _colTransactionItems);
      await _syncTable(userId, 'stock_history', _colStockHistory);

      print("✅ Sinkronisasi Selesai.");
      return true;
    } catch (e) {
      print("Sync failed: $e");
      return false;
    }
  }

  // Generic Sync Logic per Table
  Future<void> _syncTable(
    String userId,
    String tableName,
    String collectionName,
  ) async {
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
          .collection('users')
          .doc(userId)
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
      throw e;
    }
  }
}
