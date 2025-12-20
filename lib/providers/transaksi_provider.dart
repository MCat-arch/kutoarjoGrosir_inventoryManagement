import 'package:flutter/material.dart';
import 'package:kg/models/transaction_model.dart';
import 'package:kg/models/enums.dart'; // Import TrxType
import 'package:kg/services/transaction_service.dart';

class TransactionProvider with ChangeNotifier {
  final TransactionService _service = TransactionService();

  // State List History Transaksi
  List<TransactionModel> _transactions = [];
  List<TransactionModel> get transactions => _transactions;

  // State KERANJANG BELANJA (Untuk POS)
  final List<TransactioItem> _cart = [];
  List<TransactioItem> get cart => _cart;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // --- 1. LOGIC CART (POS) ---

  void addToCart(TransactioItem item) {
    // Cek duplikasi, jika ada update qty
    int index = _cart.indexWhere(
      (element) => element.variantId == item.variantId,
    );
    if (index != -1) {
      // Update item logic (buat object baru karena final)
      TransactioItem old = _cart[index];
      _cart[index] = TransactioItem(
        productId: old.productId,
        variantId: old.variantId,
        name: old.name,
        qty: old.qty + item.qty,
        price: old.price,
        cogs: old.cogs,
      );
    } else {
      _cart.add(item);
    }
    notifyListeners();
  }

  void removeFromCart(String variantId) {
    _cart.removeWhere((item) => item.variantId == variantId);
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }

  double get totalCartAmount =>
      _cart.fold(0, (sum, item) => sum + (item.price * item.qty));

  // --- 2. LOGIC TRANSAKSI ---

  Future<void> loadTransactions() async {
    _isLoading = true;
    notifyListeners();
    try {
      _transactions = await _service.getAllTransactions();
    } catch (e) {
      print("Error load transactions: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // UPDATE TRANSACTION
  Future<bool> updateTransaction(TransactionModel trx) async {
    _isLoading = true;
    notifyListeners();
    try {
      // Logic Item: Jika di UI form update, items mungkin sudah diedit di Cart atau di object trx sendiri
      // Pastikan object 'trx' yang dikirim sudah berisi list item terbaru

      await _service.updateTransaction(trx);

      await loadTransactions(); // Refresh UI
      return true;
    } catch (e) {
      print("Error updating transaction: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fungsi Checkout / Simpan Transaksi
  Future<bool> saveTransaction(TransactionModel trx) async {
    _isLoading = true;
    notifyListeners();
    try {
      // Pastikan item diambil dari Cart jika list item kosong
      List<TransactioItem>? finalItems = trx.items;
      if ((finalItems == null || finalItems.isEmpty) && _cart.isNotEmpty) {
        finalItems = List.from(_cart);
      }

      double paid = trx.paidAmount;

      // Reconstruct model dengan items yang benar
      TransactionModel finalTrx = TransactionModel(
        id: trx.id,
        trxNumber: trx.trxNumber,
        time: trx.time,
        typeTransaksi: trx.typeTransaksi,
        partyId: trx.partyId,
        partyName: trx.partyName,
        totalAmount: trx.totalAmount,
        paidAmount: paid,
        description: trx.description,
        items: finalItems,
      );

      await _service.createTransaction(finalTrx);

      // Jika sukses
      clearCart();
      await loadTransactions(); // Refresh list history
      return true;
    } catch (e) {
      print("Error saving transaction: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setCart(List<TransactioItem> items) {
    _cart.clear();
    _cart.addAll(items);
    notifyListeners();
  }
}
