import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kg/models/enums.dart';
import 'package:kg/models/produk_model.dart';
import 'package:kg/models/variant_model.dart';
import 'package:kg/providers/inventory_provider.dart';
import 'package:kg/providers/party_provider.dart';
import 'package:kg/services/inventory_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as path;

class EditProduk extends StatefulWidget {
  final ProductModel produk;

  const EditProduk({super.key, required this.produk});

  @override
  State<EditProduk> createState() => _EditProdukState();
}

class _EditProdukState extends State<EditProduk> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _categoryCtrl;

  late List<ProductVariant> _tempVar;
  String? selectedSupplierId;
  bool _isLoading = false;
  File? selectedImg;
  int _skuCounter = 1;

  // --- THEME COLORS (Retro Palette) ---
  final Color _bgCream = const Color(0xFFFFFEF7);
  final Color _borderColor = Colors.black;
  final Color _shadowColor = Colors.black;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.produk.name);
    _descCtrl = TextEditingController(text: widget.produk.description);
    _categoryCtrl = TextEditingController(text: widget.produk.categoryName);
    selectedSupplierId = widget.produk.supplierId;
    _tempVar = List.from(widget.produk.variants);

    if (widget.produk.mainImageUrl != null &&
        widget.produk.mainImageUrl!.isNotEmpty) {
      selectedImg = File(widget.produk.mainImageUrl!);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _categoryCtrl.dispose();
    super.dispose();
  }

  // --- LOGIC FUNCTIONS ---
  String _generateSKU() {
    String random = Random().nextInt(999).toString().padLeft(3, '0');
    String time = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
    return "VR-$time-$random-$_skuCounter";
  }

  Future<void> saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_tempVar.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Minimal harus ada 1 varian!")),
      );
      return;
    }
    setState(() => _isLoading = true);

    try {
      ProductModel newProduk = widget.produk.copyWith(
        name: _nameCtrl.text,
        description: _descCtrl.text,
        mainImageUrl: selectedImg?.path,
        categoryName: _categoryCtrl.text,
        supplierId: selectedSupplierId,
        variants: List<ProductVariant>.from(_tempVar),
        lastUpdated: DateTime.now(),
      );

      // Gunakan Provider.of agar context aman
      await Provider.of<InventoryProvider>(
        context,
        listen: false,
      ).updateProduct(widget.produk, newProduk);

      if (mounted) {
        Navigator.pop(context, true); // Kembali dengan result true
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Berhasil memperbarui produk!")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal Menyimpan: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
        selectedImg = localImage;
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
          "Edit Produk",
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
                    if (_tempVar.isEmpty)
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
                        itemCount: _tempVar.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        separatorBuilder: (c, i) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          return _buildRetroVariantCard(_tempVar[index], index);
                        },
                      ),

                    const SizedBox(height: 40),

                    // SAVE BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: saveProduct,
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
                          "SIMPAN PERUBAHAN",
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
            value: selectedSupplierId,
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
            onChanged: (val) => setState(() => selectedSupplierId = val),
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
          image: selectedImg != null
              ? DecorationImage(
                  image: FileImage(selectedImg!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: selectedImg == null
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
                      onTap: () => setState(() => _tempVar.removeAt(index)),
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
              _buildRetroTextField(stockCtrl, "Stok Fisik"),
              const SizedBox(height: 12),
              _buildRetroTextField(priceCtrl, "Harga Jual"),
              const SizedBox(height: 12),
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
                  _tempVar[index] = newVariant;
                } else {
                  _tempVar.add(newVariant);
                  _skuCounter++;
                }
              });
              Navigator.pop(ctx);
            },
            child: const Text(
              "SIMPAN",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

// import 'dart:io';
// import 'dart:math';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:kg/components/section_widget.dart';
// import 'package:kg/models/enums.dart';
// import 'package:kg/models/produk_model.dart';
// import 'package:kg/models/variant_model.dart';
// import 'package:kg/providers/inventory_provider.dart';
// import 'package:kg/providers/party_provider.dart';
// import 'package:kg/services/inventory_service.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:provider/provider.dart';
// import 'package:path/path.dart' as path;

// class EditProduk extends StatefulWidget {
//   final ProductModel produk;

//   const EditProduk({super.key, required this.produk});

//   @override
//   State<EditProduk> createState() => _EditProdukState();
// }

// class _EditProdukState extends State<EditProduk> {
//   final _formKey = GlobalKey<FormState>();
//   final InventoryService _invService = InventoryService();
//   final ImagePicker _picker = ImagePicker();

//   late TextEditingController _nameCtrl;
//   late TextEditingController _descCtrl;
//   late TextEditingController _categoryCtrl;

//   late List<ProductVariant> _tempVar;
//   String? selectedSupplierId;
//   bool _isLoading = false;
//   File? selectedImg;
//   int _skuCounter = 1;

//   @override
//   void initState() {
//     super.initState();
//     _nameCtrl = TextEditingController(text: widget.produk.name);
//     _descCtrl = TextEditingController(text: widget.produk.description);
//     _categoryCtrl = TextEditingController(text: widget.produk.categoryName);
//     selectedSupplierId = widget.produk.supplierId;
//     _tempVar = List.from(widget.produk.variants); // Copy list agar aman

//     // FIX: Cek null sebelum akses path gambar
//     if (widget.produk.mainImageUrl != null &&
//         widget.produk.mainImageUrl!.isNotEmpty) {
//       selectedImg = File(widget.produk.mainImageUrl!);
//     }
//   }

//   @override
//   void dispose() {
//     _nameCtrl.dispose();
//     _descCtrl.dispose();
//     _categoryCtrl.dispose();
//     super.dispose();
//   }

//   String _generateSKU() {
//     String random = Random().nextInt(999).toString().padLeft(3, '0');
//     String time = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
//     return "VR-$time-$random-$_skuCounter";
//   }

//   Future<void> saveProduct() async {
//     if (!_formKey.currentState!.validate()) return;
//     if (_tempVar.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Minimal harus ada 1 varian!")),
//       );
//       return;
//     }
//     setState(() => _isLoading = true);

//     try {
//       ProductModel newProduk = widget.produk.copyWith(
//         name: _nameCtrl.text,
//         description: _descCtrl.text,
//         mainImageUrl: selectedImg?.path, // Aman karena nullable
//         categoryName: _categoryCtrl.text,
//         supplierId: selectedSupplierId,
//         variants: List<ProductVariant>.from(_tempVar),
//         lastUpdated: DateTime.now(),
//       );

//       await InventoryProvider().updateProduct(widget.produk, newProduk);

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Berhasil memperbarui produk!")),
//         );
//         Navigator.pop(context, true);
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text("Gagal Menyimpan: $e"),
//             backgroundColor: Colors.redAccent,
//           ),
//         );
//       }
//     } finally {
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }

//   // --- DIALOG TAMBAH / EDIT VARIAN ---
//   Future<void> _showEditVariantDialog({
//     ProductVariant? editData,
//     int? index,
//   }) async {
//     final String sku = editData?.sku ?? _generateSKU();
//     final nameCtrl = TextEditingController(text: editData?.name ?? '');
//     final stockCtrl = TextEditingController(
//       text: editData?.warehouseData.physicalStock.toString() ?? '0',
//     );
//     final priceCtrl = TextEditingController(
//       text: editData?.warehouseData.offlinePrice.toStringAsFixed(0) ?? '0',
//     );
//     final cogsCtrl = TextEditingController(
//       text: editData?.warehouseData.cogs.toStringAsFixed(0) ?? '0',
//     );

//     await showDialog(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         title: Text(editData == null ? "Tambah Varian Baru" : "Edit Varian"),
//         content: SingleChildScrollView(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(8),
//                 color: Colors.grey[200],
//                 child: Text(
//                   "SKU : $sku",
//                   style: const TextStyle(
//                     fontSize: 12,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 10),
//               // Gunakan TextField helper Anda atau TextField biasa
//               TextField(
//                 controller: nameCtrl,
//                 decoration: const InputDecoration(labelText: 'Nama Varian'),
//               ),
//               TextField(
//                 controller: stockCtrl,
//                 decoration: const InputDecoration(labelText: 'Stok Fisik'),
//                 keyboardType: TextInputType.number,
//               ),
//               TextField(
//                 controller: priceCtrl,
//                 decoration: const InputDecoration(
//                   labelText: 'Harga Jual (Offline)',
//                 ),
//                 keyboardType: TextInputType.number,
//               ),
//               TextField(
//                 controller: cogsCtrl,
//                 decoration: const InputDecoration(labelText: 'HPP / Modal'),
//                 keyboardType: TextInputType.number,
//               ),
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(ctx),
//             child: const Text("Batal"),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               final name = nameCtrl.text.trim();
//               final stock = int.tryParse(stockCtrl.text.trim()) ?? 0;
//               final price = double.tryParse(priceCtrl.text.trim()) ?? 0;
//               final cogs = double.tryParse(cogsCtrl.text.trim()) ?? 0;

//               if (name.isEmpty) {
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(content: Text('Nama varian wajib diisi')),
//                 );
//                 return;
//               }

//               final String variantId =
//                   editData?.id ??
//                   (DateTime.now().millisecondsSinceEpoch.toString() +
//                       Random().nextInt(99).toString());

//               final newVariant = ProductVariant(
//                 id: variantId,
//                 sku: sku.isNotEmpty
//                     ? sku
//                     : DateTime.now().millisecondsSinceEpoch.toString(),
//                 name: name,
//                 shopeeData: editData?.shopeeData,
//                 warehouseData: WarehouseVariantData(
//                   physicalStock: stock,
//                   safetyStock: editData?.warehouseData.safetyStock ?? 0,
//                   hargaProduksi: (cogs > 0) ? cogs : 0,
//                   cogs: cogs,
//                   offlinePrice: price,
//                   status: StatusProduk.NORMAL,
//                   soldCount: editData?.warehouseData.soldCount ?? 0,
//                 ),
//               );

//               setState(() {
//                 if (index != null) {
//                   _tempVar[index] = newVariant;
//                 } else {
//                   _tempVar.add(newVariant);
//                   _skuCounter++;
//                 }
//               });

//               Navigator.pop(ctx);
//             },
//             child: const Text("Simpan"),
//           ),
//         ],
//       ),
//     );
//   }

//   // Future<void> _pickImage() async {
//   //   final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
//   //   if (pickedFile != null) {
//   //     setState(() {
//   //       selectedImg = File(pickedFile.path);
//   //     });
//   //   }
//   // }

//   Future<void> _pickImage() async {
//     final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    
//     if (pickedFile != null) {
//       final Directory appDir = await getApplicationDocumentsDirectory();

//       String fileName = path.basename(pickedFile.path); 

//       final String savedPath = path.join(appDir.path, fileName);

//       final File localImage = await File(pickedFile.path).copy(savedPath);

//       setState(() {
//         selectedImg = localImage; 
//       });
      
//       print("Gambar disalin ke: ${localImage.path}"); // Debugging
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Edit Produk"),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.check),
//             onPressed: _isLoading ? null : saveProduct,
//           ),
//         ],
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : Form(
//               key: _formKey,
//               child: SingleChildScrollView(
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   children: [
//                     buildSectionTitle("Informasi Produk"),
//                     buildTextField("Nama Produk", _nameCtrl),
//                     buildTextField("Deskripsi", _descCtrl),
//                     Row(
//                       children: [
//                         Expanded(
//                           child: buildTextField("Kategori", _categoryCtrl),
//                         ),
//                         const SizedBox(width: 10),
//                         Expanded(child: _buildSupplierDropdown()),
//                       ],
//                     ),
//                     const SizedBox(height: 20),

//                     buildSectionTitle("Gambar Produk"),
//                     _buildImageSection(),

//                     const SizedBox(height: 20),

//                     // HEADER VARIAN + TOMBOL TAMBAH
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         buildSectionTitle("Varian & Stok"),
//                         TextButton.icon(
//                           onPressed: () =>
//                               _showEditVariantDialog(), // Mode Tambah
//                           icon: const Icon(Icons.add_circle, size: 18),
//                           label: const Text("Tambah Varian"),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 10),

//                     // LIST VARIAN
//                     ListView.separated(
//                       itemCount: _tempVar.length,
//                       shrinkWrap: true,
//                       physics: const NeverScrollableScrollPhysics(),
//                       separatorBuilder: (c, i) => const Divider(),
//                       itemBuilder: (context, index) {
//                         final variant = _tempVar[index];
//                         return ListTile(
//                           contentPadding: EdgeInsets.zero,
//                           leading: CircleAvatar(
//                             backgroundColor: Colors.blue[100],
//                             child: Text(
//                               variant.name.isNotEmpty ? variant.name[0] : "?",
//                             ),
//                           ),
//                           title: Text(
//                             variant.name,
//                             style: const TextStyle(fontWeight: FontWeight.bold),
//                           ),
//                           subtitle: Text(
//                             "Stok: ${variant.warehouseData.physicalStock} | Rp ${variant.warehouseData.offlinePrice.toStringAsFixed(0)}",
//                           ),
//                           trailing: Row(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               IconButton(
//                                 icon: const Icon(
//                                   Icons.edit,
//                                   color: Colors.blue,
//                                 ),
//                                 onPressed: () => _showEditVariantDialog(
//                                   editData: variant,
//                                   index: index,
//                                 ),
//                               ),
//                               IconButton(
//                                 icon: const Icon(
//                                   Icons.delete,
//                                   color: Colors.red,
//                                 ),
//                                 onPressed: () {
//                                   setState(() {
//                                     _tempVar.removeAt(index);
//                                   });
//                                 },
//                               ),
//                             ],
//                           ),
//                         );
//                       },
//                     ),

//                     const SizedBox(height: 40),
//                     SizedBox(
//                       width: double.infinity,
//                       child: ElevatedButton(
//                         onPressed: _isLoading ? null : saveProduct,
//                         style: ElevatedButton.styleFrom(
//                           padding: const EdgeInsets.symmetric(vertical: 16),
//                           backgroundColor: Colors.blue[800],
//                           foregroundColor: Colors.white,
//                         ),
//                         child: const Text("SIMPAN PERUBAHAN"),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//     );
//   }

//   // --- WIDGET HELPER ---
//   Widget _buildSupplierDropdown() {
//     return Consumer<PartyProvider>(
//       builder: (context, partyProvider, _) {
//         final suppliers = partyProvider.parties
//             .where((p) => p.role == PartyRole.SUPPLIER)
//             .toList();
//         return DropdownButtonFormField<String>(
//           value: selectedSupplierId,
//           decoration: const InputDecoration(labelText: 'Supplier'),
//           items: suppliers
//               .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name)))
//               .toList(),
//           onChanged: (val) => setState(() => selectedSupplierId = val),
//           validator: (value) => value == null ? 'Pilih Supplier' : null,
//         );
//       },
//     );
//   }

//   Widget _buildImageSection() {
//     return Column(
//       children: [
//         if (selectedImg != null)
//           Container(
//             height: 150,
//             width: double.infinity,
//             decoration: BoxDecoration(
//               border: Border.all(color: Colors.grey),
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: ClipRRect(
//               borderRadius: BorderRadius.circular(8),
//               child: Image.file(selectedImg!, fit: BoxFit.cover),
//             ),
//           )
//         else
//           Container(
//             height: 150,
//             width: double.infinity,
//             decoration: BoxDecoration(
//               border: Border.all(color: Colors.grey),
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: const Center(
//               child: Text(
//                 "Tidak ada gambar",
//                 style: TextStyle(color: Colors.grey),
//               ),
//             ),
//           ),
//         const SizedBox(height: 10),
//         ElevatedButton.icon(
//           onPressed: _pickImage,
//           icon: const Icon(Icons.image),
//           label: const Text("Pilih Gambar Baru"),
//         ),
//       ],
//     );
//   }
// }
