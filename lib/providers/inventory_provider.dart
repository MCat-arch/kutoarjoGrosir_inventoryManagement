import 'package:flutter/material.dart';
import 'package:kg/models/produk_model.dart';
import 'package:kg/services/inventory_service.dart';

class InventoryProvider with ChangeNotifier {
  final InventoryService _service = InventoryService();

  // State
  List<ProductModel> _products = [];
  List<ProductModel> get products => _products;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Filter State
  String _searchQuery = "";
  String? _filterCategory;

  // --- ACTIONS ---

  // 1. Load Data
  Future<void> loadProducts() async {
    _isLoading = true;
    notifyListeners();

    try {
      _products = await _service.getAllProducts();
    } catch (e) {
      print("Error loading inventory: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 2. Tambah Produk
  Future<void> addProduct(ProductModel product) async {
    await _service.createProduct(product);
    await loadProducts(); // Reload untuk memastikan data sinkron
  }

  // // 3. Update Produk
  Future<void> updateProduct(
    ProductModel productOld,
    ProductModel productNew,
  ) async {
    await _service.updateProductWithHistory(productOld, productNew);

    // Optimistic Update (Update lokal dulu biar cepat)
    int index = _products.indexWhere((p) => p.id == productOld.id);
    if (index != -1) {
      _products[index] = productNew;
      notifyListeners();
    } else {
      await loadProducts();
    }
  }

  // 4. Delete Produk
  Future<void> deleteProduct(String id) async {
    await _service.deleteProduct(id);
    _products.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  // --- GETTERS UNTUK UI (FILTERING) ---

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCategoryFilter(String? category) {
    _filterCategory = category;
    notifyListeners();
  }

  // Mengambil list produk yang sudah difilter Search & Kategori
  List<ProductModel> get filteredProducts {
    return _products.where((p) {
      bool matchName = p.name.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      bool matchCategory =
          _filterCategory == null ||
          _filterCategory == "Semua" ||
          p.categoryName == _filterCategory;
      return matchName && matchCategory;
    }).toList();
  }
}
