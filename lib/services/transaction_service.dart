import 'package:kg/models/transaction_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:kg/services/database_helper.dart';
import 'package:kg/models/enums.dart';

class TransactionService {
  Future<Database> get _db async => await DatabaseHelper.instance.database;

  // 1. CREATE TRANSACTION (Atomic: Simpan Trx + Simpan Items + Update Stok + Update Saldo Pihak)
  Future<void> createTransaction(TransactionModel trx) async {
    final db = await _db;
    await db.transaction((txn) async {
      // Insert header
      await txn.insert('transactions', trx.toMap());

      // Apply effects (insert items, update stok, dll.)
      await _applyTransactionEffects(txn, trx, isUpdate: false);
    });
  }

  // 2. READ ALL TRANSACTIONS (Dengan Join ke Parties)
  Future<List<TransactionModel>> getAllTransactions() async {
    final db = await _db;

    // Kita lakukan LEFT JOIN agar bisa dapat nama Party langsung
    final result = await db.rawQuery('''
        SELECT t.*, p.name as party_name
        FROM transactions t
        LEFT JOIN parties p ON t.party_id = p.id
        ORDER BY t.created_at DESC
      ''');

    return result.map((json) => TransactionModel.fromMap(json)).toList();
  }

  // 3. READ DETAIL (Termasuk Items dan Nama Produk)
  Future<List<TransactioItem>> getTransactionItems(String trxId) async {
    final db = await _db;

    // Join ke Variants & Products untuk dapat Nama Barang
    final result = await db.rawQuery(
      '''
        SELECT ti.*, v.id as variant_id, p.id as product_id,
               p.name || ' (' || v.name || ')' as full_name
        FROM transaction_items ti
        JOIN variants v ON ti.variant_id = v.id
        JOIN products p ON v.product_id = p.id
        WHERE ti.transaction_id = ?
      ''',
      [trxId],
    );

    return result.map((map) => TransactioItem.fromMap(map)).toList();
  }

  // 4. UPDATE TRANSACTION
  Future<void> updateTransaction(
    TransactionModel newTrx, {
    bool allowTypeChange = false,
  }) async {
    final db = await _db;

    await db.transaction((txn) async {
      // Ambil data trx lama
      List<Map> oldTrxRaw = await txn.query(
        'transactions',
        where: 'id=?',
        whereArgs: [newTrx.id],
      );
      if (oldTrxRaw.isEmpty) throw Exception("Transaksi Tidak ditemukan");

      // Ambil items lama dengan JOIN
      List<Map> oldItemsRaw = await txn.rawQuery(
        '''
        SELECT ti.*, v.id as variant_id, p.id as product_id, p.name
        FROM transaction_items ti
        JOIN variants v ON ti.variant_id = v.id
        JOIN products p ON v.product_id = p.id
        WHERE ti.transaction_id = ?
        ''',
        [newTrx.id],
      );

      // Revert efek trx lama
      await _revertStockAndBalance(txn, oldTrxRaw.first, oldItemsRaw);

      // Delete items dan financial lama
      await txn.delete(
        'transaction_items',
        where: 'transaction_id = ?',
        whereArgs: [newTrx.id],
      );
      await txn.delete(
        'financial_records',
        where: 'transaction_id = ?',
        whereArgs: [newTrx.id],
      );

      // Update header dengan is_synced = 0
      await txn.update(
        'transactions',
        {...newTrx.toMap(), 'is_synced': 0},
        where: 'id = ?',
        whereArgs: [newTrx.id],
      );

      // Apply efek trx baru
      await _applyTransactionEffects(txn, newTrx, isUpdate: true);
    });
  }

  // Helper: Apply effects (insert items, update stok, financial, saldo)
  Future<void> _applyTransactionEffects(Transaction txn, TransactionModel trx, {required bool isUpdate}) async {
    await _insertTransactionItems(txn, trx);
    await _updateStockForItems(txn, trx, isUpdate: isUpdate);
    await _insertFinancialRecords(txn, trx);
    await _updatePartyBalance(txn, trx, isUpdate: isUpdate);
  }

  // Helper: Insert transaction items
  Future<void> _insertTransactionItems(Transaction txn, TransactionModel trx) async {
    if (trx.items != null) {
      for (var item in trx.items!) {
        await txn.insert('transaction_items', item.toMapForDb(trx.id));
      }
    }
  }

  // Helper: Update stok berdasarkan items
  Future<void> _updateStockForItems(Transaction txn, TransactionModel trx, {required bool isUpdate}) async {
    if (trx.items != null) {
      for (var item in trx.items!) {
        bool decreaseStock = trx.typeTransaksi == trxType.SALE || trx.typeTransaksi == trxType.PURCHASE_RETURN;
        bool increaseStock = trx.typeTransaksi == trxType.PURCHASE || trx.typeTransaksi == trxType.SALE_RETURN;

        if (decreaseStock || increaseStock) {
          List<Map> res = await txn.query(
            'variants',
            columns: ['stock'],
            where: 'id = ?',
            whereArgs: [item.variantId],
          );

          if (res.isNotEmpty) {
            int currentStock = res.first['stock'] as int;
            int newStock = currentStock;

            if (decreaseStock) {
              if (currentStock < item.qty) throw Exception("Stok tidak cukup untuk ${item.name}");
              newStock -= item.qty;
            } else if (increaseStock) {
              newStock += item.qty;
            }

            await txn.update(
              'variants',
              {'stock': newStock, 'is_synced': 0},  // Reset sync
              where: 'id = ?',
              whereArgs: [item.variantId],
            );
          }
        }
      }
    }
  }

  // Helper: Insert financial records
  Future<void> _insertFinancialRecords(Transaction txn, TransactionModel trx) async {
    if (trx.paidAmount > 0) {
      bool isIncome = trx.typeTransaksi == trxType.SALE || trx.typeTransaksi == trxType.INCOME_OTHER || trx.typeTransaksi == trxType.PURCHASE_RETURN || trx.typeTransaksi == trxType.UANG_MASUK;

      await txn.insert('financial_records', {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'transaction_id': trx.id,
        'type': isIncome ? 'INCOME' : 'EXPENSE',
        'category': trx.typeTransaksi.toString().split('.').last,
        'amount': trx.paidAmount,
        'description': trx.description ?? "${isIncome ? 'Masuk' : 'Keluar'} # ${trx.trxNumber}",
        'created_at': DateTime.now().toIso8601String(),
        'is_synced': 0,  // Tambah ini jika tabel punya kolom
      });
    }
  }

  // Helper: Update saldo party
  Future<void> _updatePartyBalance(Transaction txn, TransactionModel trx, {required bool isUpdate}) async {
    if (trx.partyId != null) {
      double debtChange = trx.totalAmount - trx.paidAmount;
      if (debtChange != 0 || trx.typeTransaksi == trxType.INCOME_OTHER || trx.typeTransaksi == trxType.EXPENSE) {
        List<Map> partyRes = await txn.query(
          'parties',
          columns: ['balance'],
          where: 'id = ?',
          whereArgs: [trx.partyId],
        );

        if (partyRes.isNotEmpty) {
          double currentBalance = (partyRes.first['balance'] as num).toDouble();
          double newBalance = currentBalance;

          if (trx.typeTransaksi == trxType.SALE) {
            newBalance += debtChange;
          } else if (trx.typeTransaksi == trxType.PURCHASE) {
            newBalance -= debtChange;
          } else if (trx.typeTransaksi == trxType.INCOME_OTHER) {
            newBalance -= trx.paidAmount;
          } else if (trx.typeTransaksi == trxType.EXPENSE) {
            newBalance += trx.paidAmount;
          } else if (trx.typeTransaksi == trxType.UANG_MASUK) {
            newBalance += trx.paidAmount;
          } else if (trx.typeTransaksi == trxType.UANG_KELUAR) {
            newBalance -= trx.paidAmount;
          }

          await txn.update(
            'parties',
            {'balance': newBalance, 'last_transaction_date': DateTime.now().toIso8601String(), 'is_synced': 0},
            where: 'id = ?',
            whereArgs: [trx.partyId],
          );
        }
      }
    }
  }

  // Helper: Revert stok dan saldo dari trx lama
  Future<void> _revertStockAndBalance(Transaction txn, Map oldTrx, List<Map> oldItems) async {
    trxType oldType = trxType.values.firstWhere(
      (e) => e.toString().split('.').last == oldTrx['type'],
    );
    double oldTotal = (oldTrx['total_amount'] as num).toDouble();
    double oldPaid = (oldTrx['paid_amount'] as num).toDouble();
    double debtChange = oldTotal - oldPaid;
    String? partyId = oldTrx['party_id'] as String?;

    // Revert stok untuk setiap item
    for (var item in oldItems) {
      String variantId = item['variant_id'];  // Perbaiki dari 'variant_Id' ke 'variant_id'
      int qty = item['qty'] as int;
      bool wasDecrease = oldType == trxType.SALE || oldType == trxType.PURCHASE_RETURN;
      bool wasIncrease = oldType == trxType.PURCHASE || oldType == trxType.SALE_RETURN;

      List<Map> varRes = await txn.query(
        'variants',
        columns: ['stock'],
        where: 'id = ?',
        whereArgs: [variantId],
      );

      if (varRes.isNotEmpty) {
        int currentStock = varRes.first['stock'] as int;
        int revertedStock = currentStock;

        if (wasDecrease) {
          revertedStock += qty;  // Balik decrease -> increase
        } else if (wasIncrease) {
          revertedStock -= qty;  // Balik increase -> decrease
        }

        await txn.update(
          'variants',
          {'stock': revertedStock},
          where: 'id = ?',
          whereArgs: [variantId],
        );
      }
    }

    // Revert saldo party
    if (partyId != null && debtChange != 0) {
      List<Map> partyRes = await txn.query(
        'parties',
        columns: ['balance'],
        where: 'id = ?',
        whereArgs: [partyId],
      );

      if (partyRes.isNotEmpty) {
        double currentBalance = (partyRes.first['balance'] as num).toDouble();
        double revertedBalance = currentBalance;

        if (oldType == trxType.SALE) {
          revertedBalance -= debtChange;  // Balik + -> -
        } else if (oldType == trxType.PURCHASE) {
          revertedBalance += debtChange;  // Balik - -> +
        } else if (oldType == trxType.INCOME_OTHER) {
          revertedBalance += oldPaid;  // Balik - -> +
        } else if (oldType == trxType.EXPENSE) {
          revertedBalance -= oldPaid;  // Balik + -> -
        } else if (oldType == trxType.UANG_MASUK) {
          revertedBalance -= oldPaid;  // Balik + -> -
        } else if (oldType == trxType.UANG_KELUAR) {
          revertedBalance += oldPaid;  // Balik - -> +
        }

        await txn.update(
          'parties',
          {'balance': revertedBalance},
          where: 'id = ?',
          whereArgs: [partyId],
        );
      }
    }
  }
}