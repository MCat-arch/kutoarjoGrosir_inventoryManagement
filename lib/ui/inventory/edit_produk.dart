import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kg/components/section_widget.dart';
import 'package:kg/models/enums.dart';
import 'package:kg/models/produk_model.dart';
import 'package:kg/models/variant_model.dart';
import 'package:kg/providers/inventory_provider.dart';
import 'package:kg/providers/party_provider.dart';
import 'package:kg/services/inventory_service.dart';
import 'package:provider/provider.dart';

class EditProduk extends StatefulWidget {
  final ProductModel produk;

  const EditProduk({super.key, required this.produk});

  @override
  State<EditProduk> createState() => _EditProdukState();
}

class _EditProdukState extends State<EditProduk> {
  final _formKey = GlobalKey<FormState>();
  final InventoryService _invService = InventoryService();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _categoryCtrl;

  late List<ProductVariant> _tempVar;
  String? selectedSupplierId;
  bool _isLoading = false;
  File? selectedImg;
  int _skuCounter = 1;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.produk.name);
    _descCtrl = TextEditingController(text: widget.produk.description);
    _categoryCtrl = TextEditingController(text: widget.produk.categoryName);
    selectedSupplierId = widget.produk.supplierId;
    _tempVar = List.from(widget.produk.variants); // Copy list agar aman

    // FIX: Cek null sebelum akses path gambar
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
        mainImageUrl: selectedImg?.path, // Aman karena nullable
        categoryName: _categoryCtrl.text,
        supplierId: selectedSupplierId,
        variants: List<ProductVariant>.from(_tempVar),
        lastUpdated: DateTime.now(),
      );

      await InventoryProvider().updateProduct(widget.produk, newProduk);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Berhasil memperbarui produk!")),
        );
        Navigator.pop(context, true);
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

  // --- DIALOG TAMBAH / EDIT VARIAN ---
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
        title: Text(editData == null ? "Tambah Varian Baru" : "Edit Varian"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.grey[200],
                child: Text(
                  "SKU : $sku",
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Gunakan TextField helper Anda atau TextField biasa
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
                  labelText: 'Harga Jual (Offline)',
                ),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: cogsCtrl,
                decoration: const InputDecoration(labelText: 'HPP / Modal'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () {
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

              final String variantId =
                  editData?.id ??
                  (DateTime.now().millisecondsSinceEpoch.toString() +
                      Random().nextInt(99).toString());

              final newVariant = ProductVariant(
                id: variantId,
                sku: sku.isNotEmpty
                    ? sku
                    : DateTime.now().millisecondsSinceEpoch.toString(),
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
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        selectedImg = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Produk"),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _isLoading ? null : saveProduct,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    buildSectionTitle("Informasi Produk"),
                    buildTextField("Nama Produk", _nameCtrl),
                    buildTextField("Deskripsi", _descCtrl),
                    Row(
                      children: [
                        Expanded(
                          child: buildTextField("Kategori", _categoryCtrl),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: _buildSupplierDropdown()),
                      ],
                    ),
                    const SizedBox(height: 20),

                    buildSectionTitle("Gambar Produk"),
                    _buildImageSection(),

                    const SizedBox(height: 20),

                    // HEADER VARIAN + TOMBOL TAMBAH
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        buildSectionTitle("Varian & Stok"),
                        TextButton.icon(
                          onPressed: () =>
                              _showEditVariantDialog(), // Mode Tambah
                          icon: const Icon(Icons.add_circle, size: 18),
                          label: const Text("Tambah Varian"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // LIST VARIAN
                    ListView.separated(
                      itemCount: _tempVar.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      separatorBuilder: (c, i) => const Divider(),
                      itemBuilder: (context, index) {
                        final variant = _tempVar[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue[100],
                            child: Text(
                              variant.name.isNotEmpty ? variant.name[0] : "?",
                            ),
                          ),
                          title: Text(
                            variant.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            "Stok: ${variant.warehouseData.physicalStock} | Rp ${variant.warehouseData.offlinePrice.toStringAsFixed(0)}",
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                onPressed: () => _showEditVariantDialog(
                                  editData: variant,
                                  index: index,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _tempVar.removeAt(index);
                                  });
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : saveProduct,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.blue[800],
                          foregroundColor: Colors.white,
                        ),
                        child: const Text("SIMPAN PERUBAHAN"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // --- WIDGET HELPER ---
  Widget _buildSupplierDropdown() {
    return Consumer<PartyProvider>(
      builder: (context, partyProvider, _) {
        final suppliers = partyProvider.parties
            .where((p) => p.role == PartyRole.SUPPLIER)
            .toList();
        return DropdownButtonFormField<String>(
          value: selectedSupplierId,
          decoration: const InputDecoration(labelText: 'Supplier'),
          items: suppliers
              .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name)))
              .toList(),
          onChanged: (val) => setState(() => selectedSupplierId = val),
          validator: (value) => value == null ? 'Pilih Supplier' : null,
        );
      },
    );
  }

  Widget _buildImageSection() {
    return Column(
      children: [
        if (selectedImg != null)
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(selectedImg!, fit: BoxFit.cover),
            ),
          )
        else
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                "Tidak ada gambar",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: _pickImage,
          icon: const Icon(Icons.image),
          label: const Text("Pilih Gambar Baru"),
        ),
      ],
    );
  }
}
