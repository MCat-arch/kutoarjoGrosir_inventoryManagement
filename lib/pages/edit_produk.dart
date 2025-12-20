import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Tambah import untuk image picker
import 'package:kg/components/section_widget.dart';
import 'package:kg/models/enums.dart';
import 'package:kg/models/produk_model.dart';
import 'package:kg/models/variant_model.dart';
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
  final ImagePicker _picker = ImagePicker(); // Tambah untuk pick image

  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _categoryCtrl;

  late List<ProductVariant> _tempVar;
  String? selectedSupplierId; // Ubah nama jadi selectedSupplierId untuk jelas
  bool _isLoading = false;
  File? selectedImg;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.produk.name);
    _descCtrl = TextEditingController(text: widget.produk.description);
    _categoryCtrl = TextEditingController(text: widget.produk.categoryName);
    selectedSupplierId = widget.produk.supplierId; // Set dari produk
    _tempVar = List.from(widget.produk.variants);
    // selectedImg mulai null, atau set dari mainImageUrl jika local path
    if (widget.produk.mainImageUrl != null &&
        widget.produk.mainImageUrl!.isNotEmpty) {
      selectedImg = File(widget.produk.mainImageUrl!); // Asumsi path local
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _categoryCtrl.dispose();

    super.dispose();
  }

  Future<void> saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      ProductModel newProduk = widget.produk.copyWith(
        name: _nameCtrl.text,
        description: _descCtrl.text,
        mainImageUrl: selectedImg?.path, // Gunakan path dari selectedImg
        categoryName: _categoryCtrl.text,
        supplierId: selectedSupplierId, // Gunakan selectedSupplierId
        variants: _tempVar,
        lastUpdated: DateTime.now(),
      );

      await _invService.updateProduct(newProduk); // Gunakan updateProduct

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Berhasil memperbarui produk!")),
        );
        Navigator.pop(context, true); // Kembali dengan refresh
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
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
              key: _formKey, // Tambah key
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
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
                        SizedBox(width: 10),
                        Expanded(child: _buildSupplierDropdown()),
                      ],
                    ),
                    SizedBox(height: 20),
                    buildSectionTitle("Gambar Produk"),
                    _buildImageSection(),
                    // TODO: IMAGE SECTION
                    SizedBox(height: 20),
                    buildSectionTitle("Kelola Varian & Stok"),
                    Text(
                      "Ketuk varian untuk mengedit stok, harga toko, atau modal.",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    SizedBox(height: 10),
                    ListView.separated(
                      itemBuilder: (context, index) {
                        return _buildVariantItem(index);
                      },
                      separatorBuilder: (context, index) => const Divider(),
                      itemCount: _tempVar.length,
                      physics: NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () async {
                                // _isLoading ? null : _saveProduct
                                setState(() {
                                  _isLoading = true;
                                });

                                try {
                                  ProductModel
                                  newProductData = widget.produk.copyWith(
                                    name: _nameCtrl.text,
                                    variants:
                                        _tempVar, // List varian yang sudah diedit stoknya
                                    lastUpdated: DateTime.now(),
                                  );

                                  await InventoryService()
                                      .updateProductWithHistory(
                                        widget.produk,
                                        newProductData,
                                      );

                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("Stok Berhasil Diupdate"),
                                      ),
                                    );
                                    Navigator.pop(
                                      context,
                                      true,
                                    ); // Kembali & Refresh
                                  }
                                } catch (e) {
                                  print(e);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Gagal: $e")),
                                  );
                                } finally {
                                  if (mounted)
                                    setState(() {
                                      _isLoading = false;
                                    });
                                }
                              },
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

  // VARIANT

  Widget _buildVariantItem(int index) {
    final variant = _tempVar[index];
    final whData = variant.warehouseData;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      tileColor: Colors.white,
      leading: CircleAvatar(
        backgroundColor: Colors.blue,
        child: Text(variant.name.substring(0, 1)),
      ),
      title: Text(
        variant.name,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text("Stok : ${whData.physicalStock} || HPP: ${whData.cogs}"),
      trailing: Icon(Icons.edit, color: Colors.blue),
      onTap: () {
        _showEditVariantDialog(index);
      },
    );
  }

  Widget _buildSupplierDropdown() {
    return Consumer<PartyProvider>(
      builder: (context, partyProvider, _) {
        final suppliers = partyProvider.parties
            .where((p) => p.role == PartyRole.SUPPLIER)
            .toList();

        return DropdownButtonFormField<String>(
          value: selectedSupplierId, // Gunakan value, bukan initialValue
          decoration: const InputDecoration(labelText: 'Supplier'),
          items: suppliers.map((s) {
            return DropdownMenuItem(value: s.id, child: Text(s.name));
          }).toList(),
          onChanged: (val) {
            setState(() {
              selectedSupplierId = val;
            });
          },
          validator: (value) => value == null ? 'Pilih Supplier' : null,
        );
      },
    );
  }

  // fungsi edit varian
  void _showEditVariantDialog(int index) {
    final variant = _tempVar[index];
    final whData = variant.warehouseData;

    final stock = TextEditingController(text: whData.physicalStock.toString());
    final priceList = TextEditingController(
      text: whData.offlinePrice.toStringAsFixed(0),
    );
    final cogs = TextEditingController(text: whData.cogs.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Edit ${variant.name}"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                buildNumberField("Stok Fisik", stock),
                SizedBox(height: 10),
                buildNumberField("Harga Jual Offline", priceList),
                SizedBox(height: 10),
                buildNumberField("HPP / Modal (COGS)", cogs),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () {
                int newStok = int.tryParse(stock.text) ?? 0;
                double newPrice = double.tryParse(priceList.text) ?? 0;
                double newCogs = double.tryParse(cogs.text) ?? 0;

                WarehouseVariantData newData = whData.copyWith(
                  physicalStock: newStok,
                  cogs: newCogs,
                  offlinePrice: newPrice,
                  // Field lain tidak perlu ditulis jika logic copyWith-nya benar (nullable),
                  // dia akan otomatis pakai data lama.
                );
                ProductVariant updatedVariant = ProductVariant(
                  id: variant.id,
                  sku: variant.sku,
                  name: variant.name,
                  shopeeData: variant.shopeeData, // Jangan sentuh data shopee
                  warehouseData: newData,
                );
                setState(() {
                  _tempVar[index] = updatedVariant;
                });

                Navigator.pop(context);
              },
              child: Text("Simpan Varian"),
            ),
          ],
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

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        selectedImg = File(pickedFile.path);
      });
    }
  }
}
