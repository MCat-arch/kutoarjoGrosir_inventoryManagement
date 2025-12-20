import 'package:kg/models/party_role.dart';
import 'package:kg/services/database_helper.dart';
import 'package:sqflite/sqflite.dart';

class PartyService {
  // --- CRUD METHODS KHUSUS PARTY ---

  Future<Database> get _db async => await DatabaseHelper.instance.database;

  // 1. Create
  Future<int> createParty(PartyModel party) async {
    final db = await _db;
    // toMap harus mengubah Enum role ke String
    return await db.insert('parties', party.toMap());
  }

  // 2. Read All
  Future<List<PartyModel>> getAllParties() async {
    final db = await _db;
    final result = await db.query('parties', orderBy: 'name ASC');

    return result.map((json) => PartyModel.fromMap(json)).toList();
  }

  // 3. Update
  Future<int> updateParty(PartyModel party) async {
    final db = await _db;
    return db.update(
      'parties',
      {
        'is_synced':0,
        ...party.toMap()},
      where: 'id = ?',
      whereArgs: [party.id],
    );
  }

  // 4. Delete
  Future<int> deleteParty(String id) async {
    final db = await _db;
    return await db.delete('parties', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateBalance(String id, double amount, bool isAdd) async {
    final db = await _db;

    var result = await db.query(
      'parties',
      columns: ['balance'],
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isNotEmpty) {
      double oldBalance = (result.first['balance'] as num).toDouble();
      double newBalance;
      if (isAdd) {
        newBalance = oldBalance + amount;
      } else {
        newBalance = oldBalance - amount;
      }

      await db.update(
        'parties',
        {'balance': newBalance},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }
}
