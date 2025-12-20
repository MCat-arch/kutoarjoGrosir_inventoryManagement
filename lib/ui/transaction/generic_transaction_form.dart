import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kg/models/account_category_model.dart';
import 'package:kg/models/enums.dart';
import 'package:kg/models/transaction_model.dart';
import 'package:kg/models/party_role.dart';
import 'package:kg/providers/transaksi_provider.dart';
import 'package:kg/widgets/account_picker.dart';
import 'package:kg/widgets/party_picker.dart';
import 'package:kg/widgets/product_picker.dart';
import 'package:provider/provider.dart';
// Import model Pihak dan Provider Cart Anda

class GenericTransactionForm extends StatefulWidget {
  final trxType type;
  final TransactionModel? editData;

  const GenericTransactionForm({
    super.key,
    required this.type,
    required this.editData,
  });

  @override
  State<GenericTransactionForm> createState() => _GenericTransactionFormState();
}

class _GenericTransactionFormState extends State<GenericTransactionForm> {
  // Format Currency & Date
  final currency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  final dateFormat = DateFormat('dd MMM yyyy');

  bool _isPaidCheckbox = false; // Checkbox "Lunas/Bayar Penuh"

  bool get _isEditMode => widget.editData != null;

  // Controllers
  final _totalCtrl = TextEditingController();
  final _paidAmountCtrl = TextEditingController();
  final _descCtrl = TextEditingController(); // Catatan umum (bawah)
  final _itemDescCtrl =
      TextEditingController(); // Deskripsi khusus pengeluaran (atas total)

  // State
  String _trxNumber = "AUTO-001";
  DateTime _selectedDate = DateTime.now();
  // String? _selectedPartyName; // Bisa nama Pihak atau Kategori Pengeluaran
  // // File? _selectedImage;
  // String? _selectedPartyId;
  // String? _selectedCategoryId;
  XFile? _selectedImg;
  String? _selectedEntityId; 
  String? _selectedEntityName;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    if (_isEditMode) {
      final data = widget.editData!;
      _trxNumber = data.trxNumber;
      _selectedDate = data.time;
      _selectedEntityId = data.partyId;
      _selectedEntityName = data.partyName;
      _descCtrl.text = data.description ?? "";

      // Isi Checkbox & Controller Bayar
      _paidAmountCtrl.text = data.paidAmount.toInt().toString();
      _isPaidCheckbox = data.isLunas;

      // Load Total Manual jika bukan barang
      if (!_isItemTransaction) {
        _totalCtrl.text = currency.format(data.totalAmount);
      }

      if (_isItemTransaction && data.items != null) {
        Future.microtask(
          () => context.read<TransactionProvider>().setCart(data.items!),
        );
      } else {
        Future.microtask(() => context.read<TransactionProvider>().clearCart());
      }
    } else {
      _generateTrxNumber();
      // FIX: Reset Cart agar sisa transaksi sebelumnya hilang
      Future.microtask(
        () => Provider.of<TransactionProvider>(
          context,
          listen: false,
        ).clearCart(),
      );
    }
  }

  void _generateTrxNumber() {
    _trxNumber =
        "${_getTypePrefix(widget.type)}-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}";
  }

  String _getTypePrefix(trxType type) {
    switch (type) {
      case trxType.SALE:
        return "JL";
      case trxType.SALE_RETURN:
        return "RJ";
      case trxType.PURCHASE:
        return "BL";
      case trxType.PURCHASE_RETURN:
        return "RB";
      case trxType.UANG_MASUK:
        return "UM";
      case trxType.UANG_KELUAR:
        return "UK";
      case trxType.EXPENSE:
        return "EX";
      case trxType.INCOME_OTHER:
        return "IN";
      default:
        return "TRX";
    }
  }

  // Logic: Apakah ini transaksi barang (Jual/Beli) atau murni uang (Biaya)?
  bool get _isItemTransaction =>
      widget.type == trxType.SALE ||
      widget.type == trxType.PURCHASE ||
      widget.type == trxType.SALE_RETURN ||
      widget.type == trxType.PURCHASE_RETURN;

  // Logic: Judul Halaman
  String get _pageTitle {
    switch (widget.type) {
      case trxType.SALE:
        return "Tambah Penjualan";
      case trxType.SALE_RETURN:
        return "Tambah Retur Penjualan";
      case trxType.UANG_MASUK:
        return "Tambah Uang Masuk";
      case trxType.PURCHASE:
        return "Tambah Pembelian";
      case trxType.PURCHASE_RETURN:
        return "Tambah Retur Pembelian";
      case trxType.UANG_KELUAR:
        return "Tambah Uang Keluar";
      case trxType.EXPENSE:
        return "Tambah Pengeluaran";
      case trxType.INCOME_OTHER:
        return "Tambah Pemasukan";
      default:
        return "Transaksi Baru";
    }
  }

  // Logic: Label Selector (Pihak vs Kategori)
  String get _selectorLabel {
    if (_isItemTransaction ||
        widget.type == trxType.UANG_MASUK ||
        widget.type == trxType.UANG_KELUAR)
      return "Pihak (Pelanggan/Supplier)";
    if (widget.type == trxType.EXPENSE || widget.type == trxType.INCOME_OTHER)
      return "Kategori "; // Misal: Listrik, Gaji
    return "Sumber Dana"; // Misal: Bank, Kas
  }

  double get _currentTotal {
    if (_isItemTransaction) {
      return context.read<TransactionProvider>().totalCartAmount;
    } else {
      return double.tryParse(
            _totalCtrl.text.replaceAll(RegExp(r'[^0-9]'), ''),
          ) ??
          0;
    }
  }

  @override
  void dispose() {
    _totalCtrl.dispose();
    _paidAmountCtrl.dispose();
    _descCtrl.dispose();
    _itemDescCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trxProvider = context.watch<TransactionProvider>();
    final cartItems = trxProvider.cart;

    double totalBill = 0;
    if (_isItemTransaction) {
      totalBill = trxProvider.totalCartAmount;
    } else {
      // Parse manual dari controller jika Keuangan
      totalBill =
          double.tryParse(_totalCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
          0;
    }

    double inputBayar =
        double.tryParse(
          _paidAmountCtrl.text.replaceAll(RegExp(r'[^0-9]'), ''),
        ) ??
        0;
    double remaining = totalBill - inputBayar;

    return Scaffold(
      backgroundColor: Colors.grey[50], // Background abu sangat muda
      appBar: AppBar(
        title: Text(
          _isEditMode ? "Ubah $_pageTitle" : "Tambah $_pageTitle",
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. HEADER (No Faktur & Tanggal)
                  Row(
                    children: [
                      Expanded(
                        child: _buildHeaderField("Nomor Faktur", _trxNumber),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: _pickDate,
                          child: _buildHeaderField(
                            "Tanggal",
                            dateFormat.format(_selectedDate),
                            icon: Icons.calendar_today,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 2. CARD SELECTOR (Pihak / Kategori)
                  _buildSelectorCard(),

                  const SizedBox(height: 16),

                  // 3. KONTEN TENGAH (BEDA ANTARA JUAL/BELI vs BIAYA)
                  if (_isItemTransaction) ...[
                    // --- MODE BARANG (Jual/Beli) ---
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _addProductToCart,
                        icon: const Icon(
                          Icons.add_circle,
                          color: Color(0xFF27AE60),
                        ),
                        label: const Text(
                          "Tambah Barang",
                          style: TextStyle(
                            color: Color(0xFF27AE60),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Color(0xFF27AE60)),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 4. LIST ITEM (Cart)
                    if (cartItems.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Item Tagihan (${cartItems.length})",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Icon(
                            Icons.remove,
                            size: 16,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ...cartItems.map((item) => _buildCartItemCard(item)),
                      const Divider(height: 30),
                    ],

                    // Consumer<TransactionProvider>(
                    //   builder: (context, provider, child) {
                    //     if (provider.cart.isEmpty) {
                    //       return Center(
                    //         child: Padding(
                    //           padding: const EdgeInsets.all(20),
                    //           child: Text(
                    //             "Belum ada barang",
                    //             style: TextStyle(color: Colors.grey[500]),
                    //           ),
                    //         ),
                    //       );
                    //     }
                    //     return Column(
                    //       children: provider.cart.map((item) {
                    //         return Card(
                    //           margin: const EdgeInsets.only(bottom: 8),
                    //           child: ListTile(
                    //             title: Text(item.name),
                    //             subtitle: Text(
                    //               "${item.qty} x ${currency.format(item.price)}",
                    //             ),
                    //             trailing: IconButton(
                    //               icon: const Icon(Icons.close, size: 20),
                    //               onPressed: () {
                    //                 context
                    //                     .read<TransactionProvider>()
                    //                     .removeFromCart(item.variantId);
                    //               },
                    //             ),
                    //           ),
                    //         );
                    //       }).toList(),
                    //     );
                    //   },
                    // ),
                  ] else ...[
                    // --- MODE KEUANGAN (Biaya/Masuk) ---
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _selectCategory,
                        icon: const Icon(
                          Icons.add_circle,
                          color: Color(0xFF27AE60),
                        ),
                        label: Text(
                          _selectedEntityId == null
                              ? "Tambah Item Pengeluaran"
                              : "Tambah Sumber",
                          style: const TextStyle(
                            color: Color(0xFF27AE60),
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Color(0xFF27AE60)),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    Checkbox(
                      value: _isPaidCheckbox,
                      activeColor: const Color(0xFF27AE60),
                      onChanged: (val) {
                        setState(() {
                          _isPaidCheckbox = val!;
                          if (_isPaidCheckbox) {
                            _paidAmountCtrl.text = totalBill.toInt().toString();
                          } else {
                            _paidAmountCtrl.text = "0";
                          }
                        });
                      },
                    ),
                    const Text("Lunas / Jumlah Dibayar"),
                    const Spacer(),
                    SizedBox(
                      width: 120,
                      child: TextField(
                        controller: _paidAmountCtrl,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.right,
                        onChanged: (val) =>
                            setState(() {}), // Refresh UI hitung sisa
                        decoration: const InputDecoration(
                          prefixText: "Rp ",
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                          border: UnderlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Deskripsi Tambahan (Hanya di mode Keuangan sesuai request)
                    TextField(
                      controller: _itemDescCtrl,
                      decoration: InputDecoration(
                        hintText: "Deskripsi (Misal: Bayar Listrik Bulan Ini)",
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // 4. TOTAL & CATATAN (Footer Umum)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Text(
                              "Total",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            // Jika mode barang, total read-only dari Cart Provider.
                            // Jika mode keuangan, total bisa diedit manual.
                            SizedBox(
                              width: 150,
                              child: TextField(
                                controller: _totalCtrl,
                                textAlign: TextAlign.right,
                                keyboardType: TextInputType.number,
                                // ReadOnly jika ini transaksi barang (karena total dihitung otomatis)
                                readOnly: _isItemTransaction,
                                onChanged: (v) => setState(() {}),
                                decoration: const InputDecoration(
                                  prefixText: "Rp ",
                                  border: InputBorder.none,
                                  hintText: "0",
                                ),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(),

                        // TextField(
                        //   controller: _descCtrl,
                        //   maxLines: 2,
                        //   decoration: const InputDecoration(
                        //     hintText: "Catatan atau Keterangan",
                        //     border: InputBorder.none,
                        //     hintStyle: TextStyle(
                        //       fontSize: 14,
                        //       color: Colors.grey,
                        //     ),
                        //   ),
                        // ),
                        Row(
                          children: [
                            Checkbox(
                              value: _isPaidCheckbox,
                              onChanged: (val) => setState(() {
                                _isPaidCheckbox = val!;
                                _paidAmountCtrl.text = _isPaidCheckbox
                                    ? totalBill.toInt().toString()
                                    : "0";
                              }),
                            ),
                            Text("Lunas"),
                            Spacer(),
                            SizedBox(
                              width: 120,
                              child: TextField(
                                controller: _paidAmountCtrl,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.right,
                                onChanged: (v) => setState(() {}),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 5. GAMBAR
                  InkWell(
                    onTap: _pickImage,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.add_photo_alternate_outlined,
                          color: Color(0xFF27AE60),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _selectedImg == null
                              ? "Tambahkan Gambar"
                              : "Ubah Gambar",
                          style: const TextStyle(
                            color: Color(0xFF27AE60),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 5),
                      ],
                    ),
                  ),
                  if (_selectedImg != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(_selectedImg!.path),
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // 6. TOMBOL SIMPAN
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () =>
                    _isFormValid() ? _saveTransaction(trxProvider) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors
                      .grey[200], // Default disable color (ubah ke Hijau jika valid)
                  foregroundColor: _isFormValid()
                      ? Colors.white
                      : Colors.black54,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  _isEditMode ? "Perbarui" : "Simpan",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET HELPER ---

  Widget _buildHeaderField(String label, String value, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              if (icon != null) Icon(icon, size: 18, color: Colors.grey),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Icon Avatar Bulat
          CircleAvatar(
            backgroundColor: _isItemTransaction
                ? Colors.blue[50]
                : Colors.teal[50],
            child: Text(
              _selectedEntityName != null
                  ? _selectedEntityName![0].toUpperCase()
                  : "?",
              style: TextStyle(
                color: _isItemTransaction ? Colors.blue : Colors.teal,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Nama & Label
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedEntityName ?? _selectorLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (_selectedEntityName !=
                    null) // Jika sudah pilih, tampilkan label kecil
                  Text(
                    _selectorLabel,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
          ),
          // Tombol Ubah
          OutlinedButton.icon(
            onPressed: _selectPartyOrCategory,
            icon: const Icon(Icons.cached, size: 16, color: Color(0xFF27AE60)),
            label: const Text(
              "Ubah",
              style: TextStyle(color: Color(0xFF27AE60)),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF27AE60)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItemCard(TransactioItem item) {
    // Tampilan Item sesuai screenshot
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${item.qty} UNIT x ${currency.format(item.price)}",
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Text(
                    currency.format(item.price * item.qty),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  // Tombol Edit Kecil
                  InkWell(
                    onTap: () {
                      // Logic edit qty (bisa pakai dialog sederhana)
                    },
                    child: const Icon(Icons.edit, size: 18, color: Colors.grey),
                  ),
                  const SizedBox(width: 8),
                  // Tombol Hapus Merah
                  InkWell(
                    onTap: () => context
                        .read<TransactionProvider>()
                        .removeFromCart(item.variantId),
                    child: const Icon(
                      Icons.delete,
                      size: 18,
                      color: Colors.redAccent,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Subtotal", style: TextStyle(color: Colors.grey)),
              Text(
                currency.format(item.price * item.qty),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- LOGIC FUNCTIONS ---

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _selectedImg = image);
  }

  Future<void> _addProductToCart() async {
    final result = await showModalBottomSheet<ProductSelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (c) => const ProductPickerSheet(),
    );

    if (result != null && mounted) {
      final item = TransactioItem(
        productId: result.product.id,
        variantId: result.variant.id,
        name: "${result.product.name} (${result.variant.name})",
        qty: 1,
        price: result.variant.warehouseData.offlinePrice,
        cogs: result.variant.warehouseData.cogs,
      );
      context.read<TransactionProvider>().addToCart(item);
      _updateTotalFromCart();
    }
  }

  Future<void> _selectPartyOrCategory() async {
    if (_isItemTransaction) {
      await _selectParty();
    } else {
      await _selectCategory();
    }
  }

  Future<void> _selectParty() async {
    final result = await showModalBottomSheet<PartyModel>(
      context: context,
      isScrollControlled: true,
      builder: (c) => const PartyPickerSheet(),
    );

    if (result != null && mounted) {
      setState(() {
        _selectedEntityId = result.id;
        _selectedEntityName = result.name;
      });
    }
  }

  Future<void> _selectCategory() async {
    String type =
        (widget.type == trxType.EXPENSE || widget.type == trxType.UANG_KELUAR)
        ? 'EXPENSE'
        : 'INCOME';

    final result = await showModalBottomSheet<AccountCategoryModel>(
      context: context,
      isScrollControlled: true,
      builder: (c) => CategoryAccountPicker(type: type),
    );

    if (result != null && mounted) {
      setState(() {
        _selectedEntityId = result.id;
        _selectedEntityName = result.name;
      });
    }
  }

  void _updateTotalFromCart() {
    if (_isItemTransaction) {
      setState(() {
        _totalCtrl.text = currency.format(_currentTotal);
      });
    }
  }

  bool _isFormValid() {
    // Validasi dasar
    if (_selectedEntityId == null) return false;
    if (_currentTotal <= 0) return false;
    return true;
  }

  Future<void> _saveTransaction(TransactionProvider provider) async {
    if (!_isFormValid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Mohon lengkapi semua field")),
      );
      return;
    }

    try {
      double total = provider.totalCartAmount;
      double paid = double.tryParse(_paidAmountCtrl.text) ?? 0;

      // Construct Model
      final trx = TransactionModel(
        id: _isEditMode
            ? widget.editData!.id
            : DateTime.now().millisecondsSinceEpoch
                  .toString(), // ID Baru atau ID Lama
        trxNumber: _trxNumber,
        time: _selectedDate,
        typeTransaksi: widget.type,
        partyId: _selectedEntityId,
        partyName: _selectedEntityName,
        totalAmount: total,
        paidAmount: paid,
        description: _descCtrl.text,
        items: provider.cart, // Ambil dari Cart Provider
      );

      bool success;
      if (_isEditMode) {
        success = await provider.updateTransaction(trx);
      } else {
        success = await provider.saveTransaction(trx);
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Transaksi berhasil disimpan")),
        );
        Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal menyimpan transaksi")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }
}
