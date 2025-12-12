import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kg/models/enums.dart';
import 'package:kg/models/model_produk.dart';
import 'package:kg/models/produk.dart';
import 'package:kg/providers/inventory_provider.dart';
import 'package:kg/utils/colors.dart';
import 'package:provider/provider.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _categoryCtrl = TextEditingController();
  final TextEditingController _supplierCtrl = TextEditingController();
  // final TextEditingController _imageCtrl = TextEditingController();

  final List<ProductVariant> _variants = [];

  bool _isSaving = false;
  String _skuNumber = "";
  String? imgCtrl;

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
    _supplierCtrl.dispose();
    super.dispose();
  }

  void _generateSKU() {
    _skuNumber =
        "VR-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}";
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
      _isSaving = true;
    });

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final product = ProductModel(
      id: id,
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      mainImageUrl: imgCtrl,
      categoryName: _categoryCtrl.text.trim().isEmpty
          ? 'Umum'
          : _categoryCtrl.text.trim(),
      supplierName: _supplierCtrl.text.trim().isEmpty
          ? 'Unknown'
          : _supplierCtrl.text.trim(),
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
          _isSaving = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Produk'),
        backgroundColor: backgroundAppBar,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Header form
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nama Produk'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Nama produk wajib diisi'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descCtrl,
                  decoration: const InputDecoration(labelText: 'Deskripsi'),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _categoryCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Kategori',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _supplierCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Supplier',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _pickImage,
                  child: Row(
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        imgCtrl == null ? "Tambahkan Gambar" : "Ubah Gambar",
                        style: const TextStyle(
                          color: Color(0xFF27AE60),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                if (imgCtrl != null)
                  Padding(
                    padding: EdgeInsetsGeometry.only(top: 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(imgCtrl!),
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                const SizedBox(height: 20),
                // Variants section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Varian',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showAddVariantDialog(),
                      icon: const Icon(Icons.add),
                      label: const Text('Tambah Varian'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF27AE60),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_variants.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    alignment: Alignment.center,
                    child: Text(
                      'Belum ada varian, tambahkan varian untuk menyimpan produk',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _variants.length,
                    itemBuilder: (c, i) => _buildVariantTile(_variants[i], i),
                  ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveProduct,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF27AE60),
                    ),
                    child: _isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Simpan Produk',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVariantTile(ProductVariant v, int idx) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(v.name),
        subtitle: Text(
          'SKU: ${v.sku} • Stok: ${v.warehouseData.physicalStock} • Harga: Rp ${v.warehouseData.offlinePrice.toStringAsFixed(0)}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showAddVariantDialog(edit: v, editIndex: idx),
            ),
            IconButton(
              icon: const Icon(Icons.delete_forever),
              onPressed: () {
                setState(() {
                  _variants.removeAt(idx);
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  void _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => imgCtrl = image.path);
  }
}
