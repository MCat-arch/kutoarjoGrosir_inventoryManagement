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
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as path;
// Import model Pihak dan Provider Cart Anda

class GenericTransactionForm extends StatefulWidget {
  final trxType type;
  final TransactionModel? editData;
  final PartyModel? preSelectedParty;

  const GenericTransactionForm({
    super.key,
    required this.type,
    required this.editData,
    this.preSelectedParty,
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
  String _trxNumber = "AUTO";
  DateTime _selectedDate = DateTime.now();
  String? _selectedPartyName; // Bisa nama Pihak atau Kategori Pengeluaran
  // File? _selectedImage;
  String? _selectedPartyId;
  String? _selectedCategoryId;
  File? _selectedImg;
  // String? _selectedEntityId;
  // String? _selectedEntityName;

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
      _selectedPartyId = data.partyId;
      _selectedPartyName = data.partyName;
      _descCtrl.text = data.description ?? "";

      // Isi Checkbox & Controller Bayar
      _paidAmountCtrl.text = data.paidAmount.toInt().toString();
      _isPaidCheckbox = data.isLunas;

      // Load Total Manual jika bukan barang
      // if (!_isItemTransaction) {
      //   _totalCtrl.text = currency.format(data.totalAmount);
      // }

      if (_isItemTransaction && data.items != null) {
        Future.microtask(
          () => context.read<TransactionProvider>().setCart(data.items!),
        );
      } else {
        _totalCtrl.text = data.totalAmount.toInt().toString();
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

  // --- BUILD METHOD ---
  @override
  Widget build(BuildContext context) {
    final trxProvider = context.watch<TransactionProvider>();
    final cartItems = trxProvider.cart;

    // --- THEME COLORS (Local Definition) ---
    const Color bgCream = Color(0xFFFFFEF7);
    const Color borderColor = Colors.black;
    const Color shadowColor = Colors.black;

    double totalBill = 0;
    if (_isItemTransaction) {
      totalBill = trxProvider.totalCartAmount;
    } else {
      totalBill =
          double.tryParse(_totalCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
          0;
    }

    // ignore: unused_local_variable
    double inputBayar =
        double.tryParse(
          _paidAmountCtrl.text.replaceAll(RegExp(r'[^0-9]'), ''),
        ) ??
        0;

    return Scaffold(
      backgroundColor: bgCream,
      appBar: AppBar(
        title: Text(
          _isEditMode
              ? "UBAH $_pageTitle".toUpperCase()
              : "TAMBAH $_pageTitle".toUpperCase(),
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900, // Extra Bold
            fontSize: 18,
            letterSpacing: 1,
          ),
        ),
        centerTitle: true,
        backgroundColor: bgCream,
        elevation: 0,
        // Garis Bawah AppBar Retro
        shape: const Border(bottom: BorderSide(color: borderColor, width: 2)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. HEADER (No Faktur & Tanggal)
                  Row(
                    children: [
                      Expanded(
                        child: _buildHeaderField("NO. FAKTUR", _trxNumber),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GestureDetector(
                          onTap: _pickDate,
                          child: _buildHeaderField(
                            "TANGGAL",
                            dateFormat.format(_selectedDate),
                            icon: Icons.calendar_today_outlined,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 2. CARD SELECTOR (Pihak / Kategori)
                  _buildSelectorCard(),

                  const SizedBox(height: 24),

                  // 3. KONTEN TENGAH
                  if (_isItemTransaction) ...[
                    // --- MODE BARANG ---
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _addProductToCart,
                        icon: const Icon(Icons.add, color: Colors.black),
                        label: const Text(
                          "TAMBAH BARANG",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        style:
                            ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: const BorderSide(
                                  color: borderColor,
                                  width: 2,
                                ),
                              ),
                            ).copyWith(
                              // Manual Shadow Effect via elevation hack or wrapping container usually,
                              // but keeping standard button for simplicity here or use Container
                              shadowColor: WidgetStateProperty.all(
                                Colors.transparent,
                              ),
                            ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 4. LIST ITEM (Cart)
                    if (cartItems.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "ITEM TAGIHAN (${cartItems.length})",
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ...cartItems.map((item) => _buildCartItemCard(item)),
                      const SizedBox(height: 20),
                      const Divider(thickness: 2, color: Colors.black),
                      const SizedBox(height: 20),
                    ],
                  ] else ...[
                    // --- MODE KEUANGAN ---
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _selectCategory,
                        icon: const Icon(Icons.add, color: Colors.black),
                        label: Text(
                          _selectedCategoryId == null
                              ? "PILIH KATEGORI"
                              : "GANTI KATEGORI",
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: const BorderSide(
                              color: borderColor,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    // Deskripsi Tambahan
                    Container(
                      decoration: BoxDecoration(
                        boxShadow: const [
                          BoxShadow(
                            color: shadowColor,
                            offset: Offset(4, 4),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _itemDescCtrl,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          hintText: "Deskripsi (Cth: Bayar Listrik)",
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: borderColor,
                              width: 2,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: borderColor,
                              width: 3,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // 4. TOTAL & CATATAN (Footer)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor, width: 2),
                      boxShadow: const [
                        BoxShadow(
                          color: shadowColor,
                          offset: Offset(4, 4),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              "TOTAL TAGIHAN",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const Spacer(),
                            SizedBox(
                              width: 180,
                              child: TextField(
                                controller: _totalCtrl,
                                textAlign: TextAlign.right,
                                keyboardType: TextInputType.number,
                                readOnly: _isItemTransaction,
                                onChanged: (v) => setState(() {}),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight:
                                      FontWeight.w900, // Angka Besar & Tebal
                                ),
                                decoration: const InputDecoration(
                                  prefixText: "Rp ",
                                  prefixStyle: TextStyle(
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  border: InputBorder.none,
                                  hintText: "0",
                                ),
                              ),
                            ),
                          ],
                        ),

                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(
                            color: Colors.black,
                            thickness: 1.5,
                          ), // Divider Hitam
                        ),

                        Row(
                          children: [
                            // Checkbox Retro
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isPaidCheckbox = !_isPaidCheckbox;
                                  _paidAmountCtrl.text = _isPaidCheckbox
                                      ? totalBill.toInt().toString()
                                      : "0";
                                });
                              },
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: _isPaidCheckbox
                                      ? Colors.black
                                      : Colors.white,
                                  border: Border.all(
                                    color: borderColor,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: _isPaidCheckbox
                                    ? const Icon(
                                        Icons.check,
                                        size: 18,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              "LUNAS",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),

                            const Spacer(),

                            SizedBox(
                              width: 140,
                              child: TextField(
                                controller: _paidAmountCtrl,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.right,
                                onChanged: (v) => setState(() {}),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  isDense: true,
                                  hintText: "0",
                                  fillColor: Colors.grey[100],
                                  filled: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 6. TOMBOL SIMPAN
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: bgCream,
              border: Border(top: BorderSide(color: borderColor, width: 2)),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () =>
                    _isFormValid() ? _saveTransaction(trxProvider) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black, // Hitam Solid
                  foregroundColor: Colors.white, // Teks Putih
                  disabledBackgroundColor: Colors.grey[400],
                  disabledForegroundColor: Colors.grey[700],
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    // Tetap beri border meskipun fill hitam agar konsisten
                    side: const BorderSide(color: borderColor, width: 2),
                  ),
                ),
                child: Text(
                  _isEditMode ? "PERBARUI DATA" : "SIMPAN TRANSAKSI",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET HELPER (RETRO STYLE) ---

  Widget _buildHeaderField(String label, String value, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black, width: 2), // Retro Border
        boxShadow: const [
          BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: Colors.grey[600],
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: Colors.black,
                ),
              ),
              if (icon != null) Icon(icon, size: 18, color: Colors.black),
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
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0),
        ],
      ),
      child: Row(
        children: [
          // Icon Avatar Bulat dengan Border
          Container(
            padding: const EdgeInsets.all(2), // Space antara border dan isi
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 2),
            ),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: _isItemTransaction
                  ? const Color(0xFF80D8FF)
                  : const Color(0xFFF9D423), // Biru/Kuning Retro
              child: Text(
                _selectedPartyName != null
                    ? _selectedPartyName![0].toUpperCase()
                    : "?",
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Nama & Label
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectorLabel.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _selectedPartyName ?? "Belum dipilih",
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Tombol Ubah (Pill Shape Black)
          InkWell(
            onTap: _selectPartyOrCategory,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                "UBAH",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItemCard(TransactioItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black, width: 2), // Boxy Border
        boxShadow: const [
          BoxShadow(color: Colors.black12, offset: Offset(2, 2), blurRadius: 0),
        ],
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
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "${item.qty} x ${currency.format(item.price)}",
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Subtotal di kanan atas
              Text(
                currency.format(item.price * item.qty),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Actions Row (Separated by line)
          Container(height: 1, color: Colors.grey[300]),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              InkWell(
                onTap: () {
                  /* Logic edit qty */
                },
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Row(
                    children: const [
                      Icon(Icons.edit, size: 16, color: Colors.black),
                      SizedBox(width: 4),
                      Text(
                        "Edit",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              InkWell(
                onTap: () => context.read<TransactionProvider>().removeFromCart(
                  item.variantId,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Row(
                    children: const [
                      Icon(Icons.delete, size: 16, color: Colors.red),
                      SizedBox(width: 4),
                      Text(
                        "Hapus",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
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
    if (image != null) {
      final Directory appDir = await getApplicationDocumentsDirectory();
      String fileName = path.basename(image.path);

      final String savedPath = path.join(appDir.path, fileName);

      final File localImage = await File(image.path).copy(savedPath);
      setState(() {
        _selectedImg = localImage;
      });
    }
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
    if (_isItemTransaction ||
        widget.type == trxType.UANG_MASUK ||
        widget.type == trxType.UANG_KELUAR) {
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
        _selectedPartyId = result.id;
        _selectedPartyName = result.name;
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
        _selectedCategoryId = result.id;
        _selectedPartyName = result.name;
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
    if (_selectedPartyId == null && _selectedCategoryId == null) return false;
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
      double total = _isItemTransaction
          ? provider.totalCartAmount
          : (double.tryParse(
                  _totalCtrl.text.replaceAll(RegExp(r'[^0-9]'), ''),
                ) ??
                0);
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
        partyId:
            (_isItemTransaction ||
                widget.type == trxType.UANG_MASUK ||
                widget.type == trxType.UANG_KELUAR)
            ? _selectedPartyId
            : _selectedCategoryId,
        partyName: _selectedPartyName,
        totalAmount: total,
        paidAmount: paid,
        description: _descCtrl.text.isEmpty
            ? _itemDescCtrl.text
            : _descCtrl.text,
        items: _isItemTransaction
            ? provider.cart
            : null, // Ambil dari Cart Provider
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
