import 'package:flutter/material.dart';
import 'package:kg/components/section_widget.dart';
import 'package:kg/models/model_produk.dart';
import 'package:kg/models/produk.dart';
import 'package:kg/services/inventory_service.dart';

class EditProduk extends StatefulWidget {
  final ProductModel produk;

  const EditProduk({super.key, required this.produk});

  @override
  State<EditProduk> createState() => _EditProdukState();
}

class _EditProdukState extends State<EditProduk> {
  final _formKey = GlobalKey<FormState>();
  // final ProductService _productService = ProductService();\
  final InventoryService _invService = InventoryService();

  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _supplierCtrl;
  late TextEditingController _categoryCtrl;
  late TextEditingController _imgUrl;

  late List<ProductVariant> _tempVar;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.produk.name);
    _descCtrl = TextEditingController(text: widget.produk.description);
    _supplierCtrl = TextEditingController(text: widget.produk.description);
    _categoryCtrl = TextEditingController(text: widget.produk.categoryName);
    _imgUrl = TextEditingController(text: widget.produk.mainImageUrl);

    _tempVar = List.from(widget.produk.variants);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _supplierCtrl.dispose();
    _categoryCtrl.dispose();
    _imgUrl.dispose();
    super.dispose();
  }

  Future<void> saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      ProductModel NewProduk = widget.produk.copyWith(
        name: _nameCtrl.text,
        description: _descCtrl.text,
        mainImageUrl: _imgUrl.text,
        categoryName: _categoryCtrl.text,
        supplierName: _supplierCtrl.text,
        variants: _tempVar,
        lastUpdated: DateTime.now(),
      );

      // await _productService.saveProduct(updatedProduct);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Berhasil memperbarui produk!")),
        );
        Navigator.pop(context); // Kembali ke layar sebelumnya
        Navigator.pop(context); // Tutup BottomSheet Detail juga jika perlu
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal Menyimpan"),
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
            // onPressed: _isLoading ? null : _saveProduct,
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
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
                        Expanded(
                          child: buildTextField("Supplier", _supplierCtrl),
                        ),
                      ],
                    ),
                    buildTextField("URL Gambar", _imgUrl),
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
}
