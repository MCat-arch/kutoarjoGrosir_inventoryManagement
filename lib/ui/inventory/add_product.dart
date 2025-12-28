import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kg/models/enums.dart';
import 'package:kg/models/produk_model.dart';
import 'package:kg/models/variant_model.dart';
import 'package:kg/providers/inventory_provider.dart';
import 'package:kg/providers/party_provider.dart';
import 'package:kg/utils/colors.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as path;

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _categoryCtrl = TextEditingController();

  String? selectedSupplier;

  final List<ProductVariant> _variants = [];

  bool _isLoading = false;
  String _skuNumber = "";
  File? imgCtrl;
  int _skuCounter = 1;

  // --- THEME COLORS (Retro Palette) ---
  final Color _bgCream = const Color(0xFFFFFEF7);
  final Color _borderColor = Colors.black;
  final Color _shadowColor = Colors.black;

  @override
  void initState() {
    super.initState();
    _generateSKU();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _categoryCtrl.dispose();
    super.dispose();
  }

  String _generateSKU() {
    String random = Random().nextInt(999).toString().padLeft(3, '0');
    String time = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
    return "VR-$time-$random-$_skuCounter";
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      final Directory appDir = await getApplicationDocumentsDirectory();
      String fileName = path.basename(pickedFile.path);
      final String savedPath = path.join(appDir.path, fileName);
      final File localImage = await File(pickedFile.path).copy(savedPath);
      setState(() {
        imgCtrl = localImage;
      });
    }
  }

  Future<void> _showAddVariantDialog({
    ProductVariant? edit,
    int? editIndex,
  }) async {
    final skuCtrl = _skuNumber;
    final nameCtrl = TextEditingController(text: edit?.name ?? '');
    final stockCtrl = TextEditingController(
      text: edit?.warehouseData.physicalStock.toString() ?? '0',
    );
    final priceCtrl = TextEditingController(
      text: edit?.warehouseData.offlinePrice.toStringAsFixed(0) ?? '0',
    );
    final cogsCtrl = TextEditingController(
      text: edit?.warehouseData.cogs.toStringAsFixed(0) ?? '0',
    );

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(edit == null ? "Tambah Varian" : "Edit Varian"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "SKU : ${_skuNumber}",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nama Varian'),
              ),
              TextField(
                controller: stockCtrl,
                decoration: const InputDecoration(labelText: 'Stok Fisik'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: priceCtrl,
                decoration: const InputDecoration(
                  labelText: 'Harga Jual (offline)',
                ),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: cogsCtrl,
                decoration: const InputDecoration(labelText: 'HPP / COGS'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text("Batal")),
          ElevatedButton(
            onPressed: () {
              final sku = skuCtrl;
              final name = nameCtrl.text.trim();
              final stock = int.tryParse(stockCtrl.text.trim()) ?? 0;
              final price = double.tryParse(priceCtrl.text.trim()) ?? 0;
              final cogs = double.tryParse(cogsCtrl.text.trim()) ?? 0;

              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nama varian wajib diisi')),
                );
                return;
              }
              final variant = ProductVariant(
                id:
                    edit?.id ??
                    DateTime.now().millisecondsSinceEpoch.toString(),
                sku: sku.isNotEmpty
                    ? sku
                    : DateTime.now().millisecondsSinceEpoch.toString(),
                name: name,
                shopeeData: edit?.shopeeData,
                warehouseData: WarehouseVariantData(
                  physicalStock: stock,
                  safetyStock: 0,
                  hargaProduksi: (cogs > 0) ? cogs * 0.8 : 0,
                  cogs: cogs,
                  offlinePrice: price,
                  status: StatusProduk.NORMAL,
                  soldCount: edit?.warehouseData.soldCount ?? 0,
                ),
              );

              setState(() {
                if (editIndex != null) {
                  _variants[editIndex] = variant;
                } else {
                  _variants.add(variant);
                }
                _skuCounter++;
              });

              Navigator.pop(ctx);
            },
            child: Text("Simpan"),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_variants.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Tambahkan minimal 1 variant")));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final product = ProductModel(
      id: id,
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      mainImageUrl: imgCtrl?.path,
      categoryName: _categoryCtrl.text.trim().isEmpty
          ? 'Umum'
          : _categoryCtrl.text.trim(),
      supplierId: selectedSupplier ?? '',
      supplierName: null,
      shopeeItemId: null,
      shopeeStatus: ShopeeItemStatus.NORMAL,
      variants: List<ProductVariant>.from(_variants),
      lastUpdated: DateTime.now(),
    );

    try {
      await Provider.of<InventoryProvider>(
        context,
        listen: false,
      ).addProduct(product);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Produk berhasil ditambahkan')));
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menyimpan produk: $e')));
    } finally {
      if (mounted)
        setState(() {
          _isLoading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgCream,
      appBar: AppBar(
        backgroundColor: _bgCream,
        elevation: 0,
        centerTitle: true,
        // Garis Bawah AppBar Retro
        shape: Border(bottom: BorderSide(color: _borderColor, width: 2)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Tambah Produk",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader("Informasi Utama"),
                    _buildRetroTextField(_nameCtrl, "Nama Produk"),
                    const SizedBox(height: 20),
                    _buildRetroTextField(_descCtrl, "Deskripsi", maxLines: 3),
                    const SizedBox(height: 20),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildRetroTextField(
                            _categoryCtrl,
                            "Kategori",
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(child: _buildRetroSupplierDropdown()),
                      ],
                    ),

                    const SizedBox(height: 32),
                    _buildSectionHeader("Media"),
                    _buildRetroImagePicker(),

                    const SizedBox(height: 32),

                    // HEADER VARIAN
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSectionHeader("Varian & Stok", bottomMargin: 0),
                        // Tombol Tambah Varian (Outline Style)
                        InkWell(
                          onTap: () => _showEditVariantDialog(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: _borderColor, width: 2),
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.white,
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black,
                                  offset: Offset(2, 2),
                                  blurRadius: 0,
                                ),
                              ],
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.add, size: 16, color: Colors.black),
                                SizedBox(width: 4),
                                Text(
                                  "Tambah",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // LIST VARIAN
                    if (_variants.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white,
                        ),
                        child: const Center(
                          child: Text(
                            "Belum ada varian",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        itemCount: _variants.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        separatorBuilder: (c, i) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          return _buildRetroVariantCard(
                            _variants[index],
                            index,
                          );
                        },
                      ),

                    const SizedBox(height: 40),

                    // SAVE BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _saveProduct,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          elevation: 10,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(
                              color: Colors.black,
                              width: 2,
                            ),
                          ),
                        ),
                        child: const Text(
                          "Tambah Produk",
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  // --- WIDGET COMPONENTS (RETRO STYLE) ---

  Widget _buildSectionHeader(String title, {double bottomMargin = 12}) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomMargin),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w900,
          color: Colors.black,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildRetroTextField(
    TextEditingController ctrl,
    String hint, {
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: const [
          BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0),
        ],
      ),
      child: TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        style: const TextStyle(fontWeight: FontWeight.w600),
        validator: (v) => v!.isEmpty ? "Wajib diisi" : null,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400]),
          contentPadding: const EdgeInsets.all(16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: _borderColor, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: _borderColor, width: 2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: _borderColor, width: 3),
          ),
        ),
      ),
    );
  }

  Widget _buildRetroSupplierDropdown() {
    return Consumer<PartyProvider>(
      builder: (context, partyProvider, _) {
        final suppliers = partyProvider.parties
            .where((p) => p.role == PartyRole.SUPPLIER)
            .toList();

        return Container(
          decoration: BoxDecoration(
            boxShadow: const [
              BoxShadow(
                color: Colors.black,
                offset: Offset(4, 4),
                blurRadius: 0,
              ),
            ],
          ),
          child: DropdownButtonFormField<String>(
            value: selectedSupplier,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              hintText: "Supplier",
              hintStyle: TextStyle(color: Colors.grey[400]),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: _borderColor, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: _borderColor, width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: _borderColor, width: 3),
              ),
            ),
            items: suppliers
                .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name)))
                .toList(),
            onChanged: (val) => setState(() => selectedSupplier = val),
            validator: (value) => value == null ? 'Pilih Supplier' : null,
          ),
        );
      },
    );
  }

  Widget _buildRetroImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _borderColor, width: 2),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0),
          ],
          image: imgCtrl != null
              ? DecorationImage(image: FileImage(imgCtrl!), fit: BoxFit.cover)
              : null,
        ),
        child: imgCtrl == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Upload Foto",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )
            : Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.edit, color: Colors.white, size: 18),
                ),
              ),
      ),
    );
  }

  Widget _buildRetroVariantCard(ProductVariant variant, int index) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor, width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0),
        ],
      ),
      child: Column(
        children: [
          // Header Card (Nama & SKU)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: _borderColor, width: 2)),
              color: Colors.grey[50], // Sedikit beda warna header
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(10),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        variant.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        "SKU: ${variant.sku}",
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                // Action Buttons (Icon Only)
                Row(
                  children: [
                    InkWell(
                      onTap: () => _showEditVariantDialog(
                        editData: variant,
                        index: index,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          border: Border.all(color: _borderColor, width: 1.5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.edit, size: 16),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => setState(() => _variants.removeAt(index)),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF8A80), // Red retro
                          border: Border.all(color: _borderColor, width: 1.5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.delete,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Body Card (Info Stok & Harga)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildVariantInfo(
                  "Stok",
                  "${variant.warehouseData.physicalStock}",
                ),
                _buildVariantInfo(
                  "Harga",
                  "Rp ${variant.warehouseData.offlinePrice.toStringAsFixed(0)}",
                ),
                _buildVariantInfo(
                  "Modal",
                  "Rp ${variant.warehouseData.cogs.toStringAsFixed(0)}",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVariantInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
        ),
      ],
    );
  }

  // --- DIALOG EDIT VARIAN (Styled) ---
  Future<void> _showEditVariantDialog({
    ProductVariant? editData,
    int? index,
  }) async {
    final String sku = editData?.sku ?? _generateSKU();
    final nameCtrl = TextEditingController(text: editData?.name ?? '');
    final stockCtrl = TextEditingController(
      text: editData?.warehouseData.physicalStock.toString() ?? '0',
    );
    final priceCtrl = TextEditingController(
      text: editData?.warehouseData.offlinePrice.toStringAsFixed(0) ?? '0',
    );
    final cogsCtrl = TextEditingController(
      text: editData?.warehouseData.cogs.toStringAsFixed(0) ?? '0',
    );

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _bgCream,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: _borderColor, width: 2),
        ),
        title: Text(
          editData == null ? "TAMBAH VARIAN" : "EDIT VARIAN",
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "SKU : $sku",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildRetroTextField(nameCtrl, "Nama Varian"),
              const SizedBox(height: 12),
              Text("stok"),
              _buildRetroTextField(stockCtrl, "Stok Fisik"),
              const SizedBox(height: 12),
              Text("Harga jual"),
              _buildRetroTextField(priceCtrl, "Harga Jual"),
              const SizedBox(height: 12),
              Text("HPP"),
              _buildRetroTextField(cogsCtrl, "HPP / Modal"),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              "BATAL",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              final name = nameCtrl.text.trim();
              final stock = int.tryParse(stockCtrl.text.trim()) ?? 0;
              final price = double.tryParse(priceCtrl.text.trim()) ?? 0;
              final cogs = double.tryParse(cogsCtrl.text.trim()) ?? 0;

              if (name.isEmpty) return;

              final String variantId =
                  editData?.id ??
                  (DateTime.now().millisecondsSinceEpoch.toString() +
                      Random().nextInt(99).toString());

              final newVariant = ProductVariant(
                id: variantId,
                sku: sku,
                name: name,
                shopeeData: editData?.shopeeData,
                warehouseData: WarehouseVariantData(
                  physicalStock: stock,
                  safetyStock: editData?.warehouseData.safetyStock ?? 0,
                  hargaProduksi: (cogs > 0) ? cogs : 0,
                  cogs: cogs,
                  offlinePrice: price,
                  status: StatusProduk.NORMAL,
                  soldCount: editData?.warehouseData.soldCount ?? 0,
                ),
              );

              setState(() {
                if (index != null) {
                  _variants[index] = newVariant;
                } else {
                  _variants.add(newVariant);
                  _skuCounter++;
                }
              });
              Navigator.pop(ctx);
            },
            child: const Text(
              "Tambah",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}


  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     backgroundColor: Colors.white, // Background bersih
  //      appBar: AppBar(
  //       backgroundColor: _bgCream,
  //       elevation: 0,
  //       centerTitle: true,
  //       // Garis Bawah AppBar Retro
  //       shape: Border(bottom: BorderSide(color: _borderColor, width: 2)),
  //       leading: IconButton(
  //         icon: const Icon(Icons.arrow_back, color: Colors.black),
  //         onPressed: () => Navigator.pop(context),
  //       ),
  //       title: const Text(
  //         "Tambah Produk",
  //         style: TextStyle(
  //           color: Colors.black,
  //           fontWeight: FontWeight.w900,
  //           fontSize: 20,
  //         ),
  //       ),
  //     ),
  //     body: SafeArea(
  //       child: Form(
  //         key: _formKey,
  //         child: SingleChildScrollView(
  //           padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               // --- SECTION: INFORMASI DASAR ---
  //               Text(
  //                 "Informasi Dasar",
  //                 style: TextStyle(
  //                   fontSize: 16,
  //                   fontWeight: FontWeight.bold,
  //                   color: Colors.grey[800],
  //                 ),
  //               ),
  //               const SizedBox(height: 16),

  //               TextFormField(
  //                 controller: _nameCtrl,
  //                 decoration: _inputDecoration(
  //                   label: 'Nama Produk',
  //                   hint: 'Misal: Kopi Arabika 200g',
  //                 ),
  //                 validator: (v) => (v == null || v.trim().isEmpty)
  //                     ? 'Nama produk wajib diisi'
  //                     : null,
  //               ),
  //               const SizedBox(height: 16),

  //               TextFormField(
  //                 controller: _descCtrl,
  //                 decoration: _inputDecoration(
  //                   label: 'Deskripsi',
  //                   hint: 'Jelaskan detail produk...',
  //                 ),
  //                 maxLines: 4,
  //                 minLines: 2,
  //               ),
  //               const SizedBox(height: 16),

  //               Row(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   Expanded(
  //                     child: TextFormField(
  //                       controller: _categoryCtrl,
  //                       decoration: _inputDecoration(label: 'Kategori'),
  //                     ),
  //                   ),
  //                   const SizedBox(width: 16),
  //                   // Pastikan Dropdown Anda juga menggunakan decoration serupa jika memungkinkan
  //                   Expanded(child: _buildSupplierDropdownWrapper()),
  //                 ],
  //               ),

  //               const SizedBox(height: 32),

  //               // --- SECTION: MEDIA ---
  //               Text(
  //                 "Media Produk",
  //                 style: TextStyle(
  //                   fontSize: 16,
  //                   fontWeight: FontWeight.bold,
  //                   color: Colors.grey[800],
  //                 ),
  //               ),
  //               const SizedBox(height: 12),

  //               _buildImagePickerArea(),

  //               const SizedBox(height: 32),

  //               // --- SECTION: VARIAN ---
  //               Row(
  //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                 children: [
  //                   Text(
  //                     "Varian Produk",
  //                     style: TextStyle(
  //                       fontSize: 16,
  //                       fontWeight: FontWeight.bold,
  //                       color: Colors.grey[800],
  //                     ),
  //                   ),

  //                   // Tombol Tambah Varian dibuat Outlined agar tidak bersaing dengan tombol Simpan Utama
  //                   OutlinedButton.icon(
  //                     onPressed: () => _showAddVariantDialog(),
  //                     icon: Icon(Icons.add, size: 18, color: _primaryColor),
  //                     label: Text(
  //                       'Tambah Varian',
  //                       style: TextStyle(color: _primaryColor),
  //                     ),
  //                     style: OutlinedButton.styleFrom(
  //                       side: BorderSide(color: _primaryColor),
  //                       shape: RoundedRectangleBorder(
  //                         borderRadius: BorderRadius.circular(8),
  //                       ),
  //                       padding: const EdgeInsets.symmetric(
  //                         horizontal: 16,
  //                         vertical: 8,
  //                       ),
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //               const SizedBox(height: 12),

  //               if (_variants.isEmpty)
  //                 _buildEmptyVariantState()
  //               else
  //                 ListView.separated(
  //                   // Gunakan separated agar lebih rapi
  //                   shrinkWrap: true,
  //                   physics: const NeverScrollableScrollPhysics(),
  //                   itemCount: _variants.length,
  //                   separatorBuilder: (c, i) => const SizedBox(height: 12),
  //                   itemBuilder: (c, i) => _buildVariantTile(_variants[i], i),
  //                 ),

  //               const SizedBox(height: 40),

  //               // --- TOMBOL SIMPAN ---
  //               SizedBox(
  //                 width: double.infinity,
  //                 height: 52, // Tinggi tombol yang nyaman (Comfortable)
  //                 child: ElevatedButton(
  //                   onPressed: _isSaving ? null : _saveProduct,
  //                   style: ElevatedButton.styleFrom(
  //                     backgroundColor: _primaryColor,
  //                     foregroundColor: Colors.white,
  //                     elevation: 2, // Shadow halus
  //                     shape: RoundedRectangleBorder(
  //                       borderRadius: BorderRadius.circular(12),
  //                     ),
  //                   ),
  //                   child: _isSaving
  //                       ? const SizedBox(
  //                           height: 24,
  //                           width: 24,
  //                           child: CircularProgressIndicator(
  //                             color: Colors.white,
  //                             strokeWidth: 2,
  //                           ),
  //                         )
  //                       : const Text(
  //                           'Simpan Produk',
  //                           style: TextStyle(
  //                             fontSize: 16,
  //                             fontWeight: FontWeight.bold,
  //                             letterSpacing: 0.5,
  //                           ),
  //                         ),
  //                 ),
  //               ),
  //               const SizedBox(height: 20),
  //             ],
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  // --- WIDGET COMPONENTS ---

  // Widget _buildSupplierDropdownWrapper() {
  //   // Wrapper ini memastikan Dropdown terlihat seragam dengan TextFormField
  //   return Theme(
  //     data: Theme.of(context).copyWith(
  //       inputDecorationTheme: InputDecorationTheme(
  //         filled: true,
  //         fillColor: Colors.grey[50],
  //         border: OutlineInputBorder(
  //           borderRadius: BorderRadius.circular(12),
  //           borderSide: BorderSide.none,
  //         ),
  //         enabledBorder: OutlineInputBorder(
  //           borderRadius: BorderRadius.circular(12),
  //           borderSide: BorderSide(color: Colors.grey[300]!),
  //         ),
  //         contentPadding: const EdgeInsets.symmetric(
  //           horizontal: 16,
  //           vertical: 16,
  //         ),
  //       ),
  //     ),
  //     child: _buildSupplierDropdown(), // Memanggil widget dropdown asli Anda
  //   );
  // }

  // Widget _buildImagePickerArea() {
  //   return InkWell(
  //     onTap: _pickImage,
  //     borderRadius: BorderRadius.circular(12),
  //     child: Container(
  //       width: double.infinity,
  //       height: 160,
  //       decoration: BoxDecoration(
  //         color: Colors.grey[50],
  //         borderRadius: BorderRadius.circular(12),
  //         border: Border.all(
  //           color: imgCtrl != null ? Colors.transparent : Colors.grey[300]!,
  //           width: 1.5,
  //         ),
  //         image: imgCtrl != null
  //             ? DecorationImage(
  //                 image: FileImage(File(imgCtrl!)),
  //                 fit: BoxFit.cover,
  //               )
  //             : null,
  //       ),
  //       child: imgCtrl == null
  //           ? Column(
  //               mainAxisAlignment: MainAxisAlignment.center,
  //               children: [
  //                 Icon(
  //                   Icons.add_photo_alternate_outlined,
  //                   size: 40,
  //                   color: Colors.grey[400],
  //                 ),
  //                 const SizedBox(height: 8),
  //                 Text(
  //                   "Upload Gambar Produk",
  //                   style: TextStyle(
  //                     color: Colors.grey[600],
  //                     fontWeight: FontWeight.w500,
  //                   ),
  //                 ),
  //               ],
  //             )
  //           : Stack(
  //               children: [
  //                 Positioned(
  //                   right: 8,
  //                   top: 8,
  //                   child: Container(
  //                     padding: const EdgeInsets.all(4),
  //                     decoration: BoxDecoration(
  //                       color: Colors.white.withOpacity(0.9),
  //                       shape: BoxShape.circle,
  //                     ),
  //                     child: Icon(Icons.edit, size: 20, color: _primaryColor),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //     ),
  //   );
  // }

  // Widget _buildEmptyVariantState() {
  //   return Container(
  //     padding: const EdgeInsets.symmetric(vertical: 30),
  //     width: double.infinity,
  //     decoration: BoxDecoration(
  //       color: Colors.grey[50],
  //       borderRadius: BorderRadius.circular(12),
  //       border: Border.all(
  //         color: Colors.grey[200]!,
  //       ), // Dashed border idealnya, tapi solid grey cukup rapi
  //     ),
  //     child: Column(
  //       children: [
  //         Icon(Icons.style_outlined, size: 40, color: Colors.grey[300]),
  //         const SizedBox(height: 8),
  //         Text(
  //           'Belum ada varian produk',
  //           style: TextStyle(color: Colors.grey[500], fontSize: 14),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildVariantTile(dynamic v, int idx) {
  //   // Pastikan 'v' sesuai model Anda
  //   return Container(
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(12),
  //       border: Border.all(color: Colors.grey[200]!),
  //       boxShadow: [
  //         BoxShadow(
  //           color: Colors.black.withOpacity(0.03),
  //           blurRadius: 4,
  //           offset: const Offset(0, 2),
  //         ),
  //       ],
  //     ),
  //     child: ListTile(
  //       contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  //       title: Text(
  //         v.name,
  //         style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
  //       ),
  //       subtitle: Padding(
  //         padding: const EdgeInsets.only(top: 4),
  //         child: Text(
  //           'SKU: ${v.sku}  •  Stok: ${v.warehouseData.physicalStock}  •  Rp ${v.warehouseData.offlinePrice.toStringAsFixed(0)}',
  //           style: TextStyle(color: Colors.grey[600], fontSize: 13),
  //         ),
  //       ),
  //       trailing: Row(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           IconButton(
  //             icon: const Icon(
  //               Icons.edit_outlined,
  //               size: 20,
  //               color: Colors.grey,
  //             ),
  //             onPressed: () => _showAddVariantDialog(edit: v, editIndex: idx),
  //             tooltip: 'Edit Varian',
  //           ),
  //           IconButton(
  //             icon: const Icon(
  //               Icons.delete_outline,
  //               size: 20,
  //               color: Colors.redAccent,
  //             ),
  //             onPressed: () {
  //               setState(() {
  //                 _variants.removeAt(idx);
  //               });
  //             },
  //             tooltip: 'Hapus Varian',
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  // @override
  // Widget build(BuildContext context) {
  //   return SafeArea(
  //       child: Form(
  //         key: _formKey,
  //         child: SingleChildScrollView(
  //           padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               // Header form
  //               Text("Informasi Dasar",
  //                 style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[800])),
  //               const SizedBox(height: 16),
  //               TextFormField(
  //                 controller: _nameCtrl,
  //                 decoration: const InputDecoration(labelText: 'Nama Produk'),
  //                 validator: (v) => (v == null || v.trim().isEmpty)
  //                     ? 'Nama produk wajib diisi'
  //                     : null,
  //               ),
  //               const SizedBox(height: 12),
  //               TextFormField(
  //                 controller: _descCtrl,
  //                 decoration: const InputDecoration(labelText: 'Deskripsi'),
  //                 maxLines: 3,
  //               ),
  //               const SizedBox(height: 12),
  //               Row(
  //                 children: [
  //                   Expanded(
  //                     child: TextFormField(
  //                       controller: _categoryCtrl,
  //                       decoration: const InputDecoration(
  //                         labelText: 'Kategori',
  //                       ),
  //                     ),
  //                   ),
  //                   const SizedBox(width: 12),
  //                   Expanded(child: _buildSupplierDropdown()),
  //                 ],
  //               ),
  //               const SizedBox(height: 12),
  //               InkWell(
  //                 onTap: _pickImage,
  //                 child: Row(
  //                   children: [
  //                     Icon(
  //                       Icons.add_photo_alternate_outlined,
  //                       color: Colors.blue,
  //                     ),
  //                     const SizedBox(width: 8),
  //                     Text(
  //                       imgCtrl == null ? "Tambahkan Gambar" : "Ubah Gambar",
  //                       style: const TextStyle(
  //                         color: Color(0xFF27AE60),
  //                         fontWeight: FontWeight.bold,
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //               if (imgCtrl != null)
  //                 Padding(
  //                   padding: EdgeInsetsGeometry.only(top: 12),
  //                   child: ClipRRect(
  //                     borderRadius: BorderRadius.circular(8),
  //                     child: Image.file(
  //                       File(imgCtrl!),
  //                       height: 120,
  //                       width: double.infinity,
  //                       fit: BoxFit.cover,
  //                     ),
  //                   ),
  //                 ),

  //               const SizedBox(height: 20),
  //               // Variants section
  //               Row(
  //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                 children: [
  //                   const Text(
  //                     'Varian',
  //                     style: TextStyle(
  //                       fontSize: 16,
  //                       fontWeight: FontWeight.bold,
  //                     ),
  //                   ),
  //                   ElevatedButton.icon(
  //                     onPressed: () => _showAddVariantDialog(),
  //                     icon: const Icon(Icons.add),
  //                     label: const Text('Tambah Varian'),
  //                     style: ElevatedButton.styleFrom(
  //                       backgroundColor: const Color(0xFF27AE60),
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //               const SizedBox(height: 12),
  //               if (_variants.isEmpty)
  //                 Container(
  //                   padding: const EdgeInsets.symmetric(vertical: 24),
  //                   alignment: Alignment.center,
  //                   child: Text(
  //                     'Belum ada varian, tambahkan varian untuk menyimpan produk',
  //                     style: TextStyle(color: Colors.grey[600]),
  //                   ),
  //                 )
  //               else
  //                 ListView.builder(
  //                   shrinkWrap: true,
  //                   physics: const NeverScrollableScrollPhysics(),
  //                   itemCount: _variants.length,
  //                   itemBuilder: (c, i) => _buildVariantTile(_variants[i], i),
  //                 ),
  //               const SizedBox(height: 24),
  //               SizedBox(
  //                 width: double.infinity,
  //                 height: 48,
  //                 child: ElevatedButton(
  //                   onPressed: _isSaving ? null : _saveProduct,
  //                   style: ElevatedButton.styleFrom(
  //                     backgroundColor: const Color(0xFF27AE60),
  //                   ),
  //                   child: _isSaving
  //                       ? const CircularProgressIndicator(color: Colors.white)
  //                       : const Text(
  //                           'Simpan Produk',
  //                           style: TextStyle(fontSize: 16),
  //                         ),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ),
  //   );
  // }

  // Widget _buildVariantTile(ProductVariant v, int idx) {
  //   return Card(
  //     margin: const EdgeInsets.only(bottom: 8),
  //     child: ListTile(
  //       title: Text(v.name),
  //       subtitle: Text(
  //         'SKU: ${v.sku} • Stok: ${v.warehouseData.physicalStock} • Harga: Rp ${v.warehouseData.offlinePrice.toStringAsFixed(0)}',
  //       ),
  //       trailing: Row(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           IconButton(
  //             icon: const Icon(Icons.edit),
  //             onPressed: () => _showAddVariantDialog(edit: v, editIndex: idx),
  //           ),
  //           IconButton(
  //             icon: const Icon(Icons.delete_forever),
  //             onPressed: () {
  //               setState(() {
  //                 _variants.removeAt(idx);
  //               });
  //             },
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

//   Widget _buildSupplierDropdown() {
//     return Consumer<PartyProvider>(
//       builder: (context, partyProvider, _) {
//         final suppliers = partyProvider.parties
//             .where((p) => p.role == PartyRole.SUPPLIER)
//             .toList();

//         return DropdownButtonFormField(
//           initialValue: selectedSupplier,
//           decoration: InputDecoration(labelText: 'Supplier'),
//           items: suppliers.map((s) {
//             return DropdownMenuItem(value: s.id, child: Text(s.name));
//           }).toList(),
//           onChanged: (val) {
//             setState(() {
//               selectedSupplier = val;
//             });
//           },
//           validator: (value) => value == null ? 'Pilih Supplier' : null,
//         );
//       },
//     );
//   }

//   InputDecoration _inputDecoration({
//     required String label,
//     String? hint,
//     Widget? suffix,
//   }) {
//     return InputDecoration(
//       labelText: label,
//       hintText: hint,
//       suffixIcon: suffix,
//       filled: true,
//       fillColor: Colors.grey[50], // Background input sedikit abu (Comfortable)
//       contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//       labelStyle: TextStyle(color: Colors.grey[600]),
//       floatingLabelStyle: TextStyle(
//         color: primaryColor,
//         fontWeight: FontWeight.w600,
//       ),
//       border: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(12),
//         borderSide:
//             BorderSide.none, // Hilangkan border default saat idle agar clean
//       ),
//       enabledBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(12),
//         borderSide: BorderSide(color: Colors.grey[300]!), // Border halus
//       ),
//       focusedBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(12),
//         borderSide: BorderSide(
//           color: primaryColor,
//           width: 1.5,
//         ), // Fokus semi-formal
//       ),
//       errorBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(12),
//         borderSide: const BorderSide(color: Colors.redAccent),
//       ),
//     );
//   }

//   // void _pickImage() async {
//   //   final picker = ImagePicker();
//   //   final XFile? image = await picker.pickImage(source: ImageSource.gallery);
//   //   if (image != null) setState(() => imgCtrl = image.path);
//   // }

//   Future<void> _pickImage() async {
//     final picker = ImagePicker();
//     final XFile? pickedFile = await picker.pickImage(
//       source: ImageSource.gallery,
//     );

//     if (pickedFile != null) {
//       // 1. Ambil direktori permanen aplikasi
//       final Directory appDir = await getApplicationDocumentsDirectory();

//       // 2. Buat nama file baru (agar unik & rapi)
//       String fileName = path.basename(
//         pickedFile.path,
//       ); // misal: image_picker_123.jpg
//       // Opsi: Tambahkan timestamp agar nama file 100% unik
//       // String fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(pickedFile.path)}';

//       // 3. Tentukan path tujuan permanen
//       final String savedPath = path.join(appDir.path, fileName);

//       // 4. Salin file dari Cache (pickedFile) ke Permanen (savedPath)
//       final File localImage = await File(pickedFile.path).copy(savedPath);

//       setState(() {
//         // 5. Simpan path PERMANEN ke state, bukan path cache
//         imgCtrl = localImage.path;
//       });

//       print("Gambar disalin ke: ${localImage.path}"); // Debugging
//     }
//   }
// }
