import 'package:kg/models/keuangan_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:kg/services/database_helper.dart';
import 'package:kg/models/enums.dart';

class TransactionService {
  Future<Database> get _db async => await DatabaseHelper.instance.database;

  // 1. CREATE TRANSACTION (Atomic: Simpan Trx + Simpan Items + Update Stok + Update Saldo Pihak)
  Future<void> createTransaction(TransactionModel trx) async {
    final db = await _db;

    await db.transaction((txn) async {
      // A. Insert Header Transaksi
      await txn.insert('transactions', trx.toMap());

      // B. Handle Items & Update Inventory
      if (trx.items != null && trx.items!.isNotEmpty) {
        for (var item in trx.items!) {
          // 1. Insert Item ke Tabel transaction_items
          await txn.insert('transaction_items', item.toMapForDb(trx.id));

          // 2. Logic Update Stok (Cek tipe transaksi)
          bool decreaseStock =
              trx.typeTransaksi == trxType.SALE ||
              trx.typeTransaksi == trxType.PURCHASE_RETURN;
          bool increaseStock =
              trx.typeTransaksi == trxType.PURCHASE ||
              trx.typeTransaksi == trxType.SALE_RETURN;

          if (decreaseStock || increaseStock) {
            // Ambil stok saat ini
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
                if (currentStock < item.qty) {
                  throw Exception("Stok tidak cukup untuk ${item.name}");
                }
                newStock -= item.qty;
              } else if (increaseStock) {
                newStock += item.qty;
              }

              // Update Stok di DB
              await txn.update(
                'variants',
                {'stock': newStock},
                where: 'id = ?',
                whereArgs: [item.variantId],
              );
            }
          }
        }
      }

      if (trx.paidAmount > 0) {
        bool isIncome =
            trx.typeTransaksi == trxType.SALE ||
            trx.typeTransaksi == trxType.INCOME_OTHER ||
            trx.typeTransaksi == trxType.PURCHASE_RETURN ||
            trx.typeTransaksi == trxType.UANG_MASUK;

        await txn.insert('financial_records', {
          'id': DateTime.now().millisecondsSinceEpoch.toString(), // ID unik
          'transaction_id': trx.id,
          'type': isIncome ? 'INCOME' : 'EXPENSE', // Map ke Enum String
          'category': trx.typeTransaksi
              .toString()
              .split('.')
              .last, // Kategori sesuai tipe trx
          'amount': trx.paidAmount,
          'description':
              trx.description ??
              "${isIncome ? 'Masuk' : 'Keluar'} # ${trx.trxNumber}",
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      // C. Update Saldo Pihak (Hutang/Piutang)
      if (trx.partyId != null) {
        double debtChange = trx.totalAmount - trx.paidAmount;

        // Jika lunas (debtChange == 0), tidak perlu update saldo
        if (debtChange != 0 ||
            trx.typeTransaksi == trxType.INCOME_OTHER ||
            trx.typeTransaksi == trxType.EXPENSE) {
          List<Map> partyRes = await txn.query(
            'parties',
            columns: ['balance'],
            where: 'id = ?',
            whereArgs: [trx.partyId],
          );

          if (partyRes.isNotEmpty) {
            double currentBalance = (partyRes.first['balance'] as num)
                .toDouble();
            double newBalance = currentBalance;

            // Logic:
            // JUAL Belum Lunas = Balance Naik (Piutang positif)
            // BELI Belum Lunas = Balance Turun (Hutang negatif)
            // Uang Masuk (Bayar Hutang Pelanggan) = Balance Turun
            // Uang Keluar (Bayar Hutang Supplier) = Balance Naik

            if (trx.typeTransaksi == trxType.SALE) {
              newBalance += debtChange;
            } else if (trx.typeTransaksi == trxType.PURCHASE) {
              newBalance -= debtChange;
            } else if (trx.typeTransaksi == trxType.INCOME_OTHER) {
              // Asumsi ini pelunasan piutang pelanggan
              newBalance -= trx.paidAmount;
            } else if (trx.typeTransaksi == trxType.EXPENSE) {
              // Asumsi ini pelunasan hutang ke supplier
              newBalance += trx.paidAmount;
            } else if (trx.typeTransaksi == trxType.UANG_MASUK) {
              newBalance += trx.paidAmount;
            } else if (trx.typeTransaksi == trxType.UANG_KELUAR) {
              newBalance -= trx.paidAmount;
            }

            await txn.update(
              'parties',
              {
                'balance': newBalance,
                'last_transaction_date': DateTime.now().toIso8601String(),
              },
              where: 'id = ?',
              whereArgs: [trx.partyId],
            );
          }
        }
      }
    });
  }

  // 2. READ ALL TRANSACTIONS (Dengan Join ke Parties)
  Future<List<TransactionModel>> getAllTransactions() async {
    final db = await _db;

    // Kita lakukan LEFT JOIN agar bisa dapat nama Party langsung
    // membaca all transaction
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
}
