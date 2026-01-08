import 'package:flutter/material.dart';
import 'package:kg/models/account_category_model.dart';
import 'package:kg/utils/database_helper.dart';

class CategoryProvider with ChangeNotifier {
  List<AccountCategoryModel> _categories = [];
  List<AccountCategoryModel> get categories => _categories;

  Future<void> loadCategories(String type) async {
    final db = await DatabaseHelper.instance.database;
    final res = await db.query(
      'account_categories', 
      where: 'type = ?', 
      whereArgs: [type],
      orderBy: 'name ASC'
    );
    _categories = res.map((e) => AccountCategoryModel.fromMap(e)).toList();
    notifyListeners();
  }

  Future<void> addCategory(String name, String type) async {
    final db = await DatabaseHelper.instance.database;
    final newCat = AccountCategoryModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      type: type,
    );
    await db.insert('account_categories', newCat.toMap());
    await loadCategories(type); // Refresh
  }
}