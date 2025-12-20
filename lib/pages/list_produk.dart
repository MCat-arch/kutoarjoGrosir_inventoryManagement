import 'package:flutter/material.dart';
import 'package:kg/ui/party/add_party_page.dart';
import 'package:kg/ui/inventory/add_product.dart';
import 'package:kg/utils/colors.dart';
import 'package:provider/provider.dart';
import 'package:kg/models/produk_model.dart';
import 'package:kg/models/enums.dart';
import 'package:kg/widgets/card_produk.dart';
import 'package:kg/providers/inventory_provider.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  // State Filter & Search
  String _searchQuery = "";
  String? _selectedCategory; // Null = Semua Kategori
  String _sortBy = "name_asc";

  @override
  void initState() {
    super.initState();
    // Load products via provider after first frame (context available)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<InventoryProvider>(context, listen: false).loadProducts();
    });
  }

  // Helper to compute filtered list using provider + local filters (search/category/sort)
  List<ProductModel> _applyLocalFilters(List<ProductModel> products) {
    List<ProductModel> result = products.where((p) {
      final matchName = p.name.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      final matchCategory =
          _selectedCategory == null ||
          _selectedCategory == "Semua" ||
          p.categoryName == _selectedCategory;
      return matchName && matchCategory;
    }).toList();

    switch (_sortBy) {
      case "price_high":
        result.sort((a, b) => b.minPrice.compareTo(a.minPrice));
        break;
      case "price_low":
        result.sort((a, b) => a.minPrice.compareTo(b.minPrice));
        break;
      case "stock_low":
        result.sort((a, b) => a.totalStock.compareTo(b.totalStock));
        break;
      case "name_asc":
      default:
        result.sort((a, b) => a.name.compareTo(b.name));
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundAppBar,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Consumer<InventoryProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.products.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final allProducts = provider.products;
          final categories = [
            "Semua",
            ...allProducts.map((e) => e.categoryName).toSet().toList(),
          ];
          final filtered = _applyLocalFilters(allProducts);

          return Column(
            children: [
              // SEARCH & FILTER
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: "Cari nama produk...",
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedCategory ?? "Semua",
                                isExpanded: true,
                                items: categories.map((cat) {
                                  return DropdownMenuItem(
                                    value: cat,
                                    child: Text(
                                      cat,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    _selectedCategory = (val == "Semua")
                                        ? null
                                        : val;
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        PopupMenuButton<String>(
                          icon: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.sort, color: Colors.blue[800]),
                          ),
                          onSelected: (val) => setState(() => _sortBy = val),
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: "name_asc",
                              child: Text("Abjad (A-Z)"),
                            ),
                            PopupMenuItem(
                              value: "price_high",
                              child: Text("Harga Tertinggi"),
                            ),
                            PopupMenuItem(
                              value: "price_low",
                              child: Text("Harga Terendah"),
                            ),
                            PopupMenuItem(
                              value: "stock_low",
                              child: Text("Stok Paling Sedikit"),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // GRID PRODUK / EMPTY STATE
              Expanded(
                child: provider.isLoading && filtered.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : filtered.isEmpty
                    ? const Center(child: Text("Produk tidak ditemukan"))
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.68,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final product = filtered[index];
                          return buildProductCard(product, context);
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddProductPage()),
          );
        },
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:kg/models/model_produk.dart';
// import 'package:kg/models/produk.dart';
// import 'package:kg/models/enums.dart'; // Pastikan Enum StatusProduk & ShopeeItemStatus ada disini
// import 'package:kg/widgets/card_produk.dart'; // Pastikan widget card menerima ProductModel

// class InventoryScreen extends StatefulWidget {
//   const InventoryScreen({super.key});

//   @override
//   State<InventoryScreen> createState() => _InventoryScreenState();
// }

// class _InventoryScreenState extends State<InventoryScreen> {
//   // State Filter & Search
//   String _searchQuery = "";
//   String? _selectedCategory; // Null = Semua Kategori
//   String _sortBy = "name_asc"; 

//   // --- DUMMY DATA YANG DISESUAIKAN DENGAN MODEL BARU ---
//   late List<ProductModel> _allProducts;

//   @override
//   void initState() {
//     super.initState();
//     _generateDummyData();
//   }

//   void _generateDummyData() {
//     // Helper untuk membuat varian simple
//     ProductVariant createSimpleVariant(String sku, String name, int stock, double price, double cogs, StatusProduk status, int soldCount) {
//       return ProductVariant(
//         id: DateTime.now().toString(), // Dummy ID
//         sku: sku,
//         name: name,
//         warehouseData: WarehouseVariantData(
//           physicalStock: stock,
//           offlinePrice: price,
//           cogs: cogs,
//           hargaProduksi: cogs * 0.8, // Asumsi harga jahit 80% dari HPP
//           status: status,
//           soldCount: soldCount,
//         ),
//       );
//     }

//     _allProducts = [
//       ProductModel(
//         id: '1',
//         name: 'Kemeja Flanel Kotak',
//         description: 'Kemeja flanel bahan tebal',
//         categoryName: 'Kemeja',
//         supplierName: 'Pak Budi Tailor',
//         shopeeStatus: ShopeeItemStatus.NORMAL,
//         lastUpdated: DateTime.now(),
//         variants: [
//           createSimpleVariant('FL-RED-S', 'Merah - S', 10, 150000, 90000, StatusProduk.NORMAL, 4),
//           createSimpleVariant('FL-RED-M', 'Merah - M', 14, 150000, 90000, StatusProduk.NORMAL,5),
//         ],
//       ),
//       ProductModel(
//         id: '2',
//         name: 'Celana Chino Cream',
//         description: 'Celana panjang slim fit',
//         categoryName: 'Celana',
//         supplierName: 'Garment A',
//         shopeeStatus: ShopeeItemStatus.NORMAL,
//         lastUpdated: DateTime.now(),
//         variants: [
//           createSimpleVariant('CH-CRM-30', 'Cream - 30', 5, 200000, 120000, StatusProduk.NORMAL, 6),
//         ],
//       ),
//       ProductModel(
//         id: '3',
//         name: 'Kaos Polos Hitam',
//         description: 'Cotton Combed 30s',
//         categoryName: 'Kaos',
//         supplierName: 'Konveksi X',
//         shopeeStatus: ShopeeItemStatus.UNLIST, // Contoh status Shopee
//         lastUpdated: DateTime.now(),
//         variants: [
//           createSimpleVariant('TS-BLK-L', 'Hitam - L', 0, 50000, 30000, StatusProduk.REJECT, 4),
//         ],
//       ),
//       ProductModel(
//         id: '4',
//         name: 'Jaket Denim',
//         description: 'Bahan Jeans Tebal',
//         categoryName: 'Jaket',
//         supplierName: 'Pak Budi Tailor',
//         shopeeStatus: ShopeeItemStatus.BANNED,
//         lastUpdated: DateTime.now(),
//         variants: [
//           createSimpleVariant('JKT-DNM-XL', 'Denim - XL', 12, 350000, 250000, StatusProduk.REJECT, 6),
//         ],
//       ),
//     ];
//   }

//   // Logic Filter & Sort
//   List<ProductModel> get filteredProducts {
//     List<ProductModel> result = _allProducts.where((p) {
//       final matchName = p.name.toLowerCase().contains(_searchQuery.toLowerCase());
//       // Perhatikan field 'categoryName' sesuai model
//       final matchCategory = _selectedCategory == null || p.categoryName == _selectedCategory;
//       return matchName && matchCategory;
//     }).toList();

//     // Sorting Logic (Menggunakan GETTER helper dari Model)
//     switch (_sortBy) {
//       case "price_high":
//         // minPrice adalah getter di ProductModel yang mencari harga terendah dari varian
//         result.sort((a, b) => b.minPrice.compareTo(a.minPrice)); 
//         break;
//       case "price_low":
//         result.sort((a, b) => a.minPrice.compareTo(b.minPrice));
//         break;
//       case "stock_low":
//         // totalStock adalah getter di ProductModel yang menjumlahkan stok varian
//         result.sort((a, b) => a.totalStock.compareTo(b.totalStock)); 
//         break;
//       case "name_asc":
//       default:
//         result.sort((a, b) => a.name.compareTo(b.name));
//     }
//     return result;
//   }

//   @override
//   Widget build(BuildContext context) {
//     // Ambil list unik kategori untuk dropdown dari field categoryName
//     final categories = ["Semua", ..._allProducts.map((e) => e.categoryName).toSet().toList()];

//     return Scaffold(
//       backgroundColor: Colors.grey[100],
//       appBar: AppBar(
//         // title: const Text("Stok Gudang", style: TextStyle(color: Colors.black)),
//         backgroundColor: Colors.white,
//         elevation: 0,
//         iconTheme: const IconThemeData(color: Colors.black),
//       ),
//       body: Column(
//         children: [
//           // --- BAGIAN 1: SEARCH & FILTER ---
//           Container(
//             color: Colors.white,
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               children: [
//                 // Search Bar
//                 TextField(
//                   onChanged: (val) => setState(() => _searchQuery = val),
//                   decoration: InputDecoration(
//                     hintText: "Cari nama produk...",
//                     prefixIcon: const Icon(Icons.search),
//                     filled: true,
//                     fillColor: Colors.grey[100],
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12),
//                       borderSide: BorderSide.none,
//                     ),
//                     contentPadding: const EdgeInsets.symmetric(vertical: 0),
//                   ),
//                 ),
//                 const SizedBox(height: 12),
                
//                 // Row Filter (Category & Sort)
//                 Row(
//                   children: [
//                     // Dropdown Kategori
//                     Expanded(
//                       child: Container(
//                         padding: const EdgeInsets.symmetric(horizontal: 12),
//                         decoration: BoxDecoration(
//                           border: Border.all(color: Colors.grey.shade300),
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: DropdownButtonHideUnderline(
//                           child: DropdownButton<String>(
//                             value: _selectedCategory ?? "Semua",
//                             isExpanded: true,
//                             items: categories.map((cat) {
//                               return DropdownMenuItem(
//                                 value: cat,
//                                 child: Text(cat, style: const TextStyle(fontSize: 14)),
//                               );
//                             }).toList(),
//                             onChanged: (val) {
//                               setState(() {
//                                 _selectedCategory = (val == "Semua") ? null : val;
//                               });
//                             },
//                           ),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 10),
                    
//                     // Dropdown Sort
//                     PopupMenuButton<String>(
//                       icon: Container(
//                         padding: const EdgeInsets.all(10),
//                         decoration: BoxDecoration(
//                           color: Colors.blue[50],
//                           borderRadius: BorderRadius.circular(8)
//                         ),
//                         child: Icon(Icons.sort, color: Colors.blue[800]),
//                       ),
//                       onSelected: (val) => setState(() => _sortBy = val),
//                       itemBuilder: (context) => [
//                         const PopupMenuItem(value: "name_asc", child: Text("Abjad (A-Z)")),
//                         const PopupMenuItem(value: "price_high", child: Text("Harga Tertinggi")),
//                         const PopupMenuItem(value: "price_low", child: Text("Harga Terendah")),
//                         const PopupMenuItem(value: "stock_low", child: Text("Stok Paling Sedikit")),
//                       ],
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),

//           // --- BAGIAN 2: GRID PRODUK ---
//           Expanded(
//             child: filteredProducts.isEmpty 
//             ? const Center(child: Text("Produk tidak ditemukan"))
//             : GridView.builder(
//               padding: const EdgeInsets.all(16),
//               gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                 crossAxisCount: 2, // 2 Kolom
//                 childAspectRatio: 0.68, // Rasio Tinggi vs Lebar Card
//                 crossAxisSpacing: 16,
//                 mainAxisSpacing: 16,
//               ),
//               itemCount: filteredProducts.length,
//               itemBuilder: (context, index) {
//                 final product = filteredProducts[index];
//                 // Panggil Widget Card yang sudah dipisah
//                 // Pastikan CardProduk menerima parameter 'product' bertipe ProductModel
//                 return buildProductCard( product, context); 
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }