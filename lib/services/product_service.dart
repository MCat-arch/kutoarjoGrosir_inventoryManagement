// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:kg/models/model_produk.dart';
// import 'package:kg/models/product_model.dart';
// import 'package:kg/models/product_variant.dart';

// class ProductService {
//   // Referensi ke Collection 'products' di Firestore
//   final CollectionReference _productRef = 
//       FirebaseFirestore.instance.collection('products');

//   // =========================================================
//   // 1. STORE (CREATE / UPDATE FULL DOC)
//   // Menyimpan Produk Baru atau Menimpa Data Lama
//   // =========================================================
//   Future<void> saveProduct(ProductModel product) async {
//     try {
//       // .set() akan membuat dokumen baru jika ID belum ada,
//       // atau menimpa (overwrite) jika ID sudah ada.
//       // Kita pakai toMap() karena Firestore hanya mengerti Map/JSON.
//       await _productRef.doc(product.id).set(product.toMap());
//     } catch (e) {
//       throw Exception('Gagal menyimpan produk: $e');
//     }
//   }

//   // =========================================================
//   // 2. GET (READ STREAM)
//   // Mengambil Data untuk Grid View (Real-time)
//   // =========================================================
//   Stream<List<ProductModel>> getProductsStream() {
//     // snapshots() memberikan aliran data terus menerus.
//     // Jika stok berubah di database, UI otomatis berubah.
//     return _productRef.snapshots().map((snapshot) {
//       return snapshot.docs.map((doc) {
//         // Mengubah JSON Firestore kembali menjadi Object ProductModel
//         return ProductModel.fromMap(
//           doc.data() as Map<String, dynamic>, 
//           doc.id
//         );
//       }).toList();
//     });
//   }

//   // =========================================================
//   // 3. UPDATE SPECIFIC VARIANT STOCK (TRICKY PART)
//   // Cara mengupdate stok varian tertentu (misal: Merah - S)
//   // =========================================================
//   Future<void> updateVariantStock(String productId, String variantSku, int newStock) async {
//     // Langkah 1: Baca Dokumen Produk dulu (Transaction untuk keamanan data)
//     return FirebaseFirestore.instance.runTransaction((transaction) async {
//       DocumentReference docRef = _productRef.doc(productId);
//       DocumentSnapshot snapshot = await transaction.get(docRef);

//       if (!snapshot.exists) throw Exception("Produk tidak ditemukan!");

//       // Langkah 2: Konversi ke Object
//       ProductModel product = ProductModel.fromMap(
//         snapshot.data() as Map<String, dynamic>, 
//         snapshot.id
//       );

//       // Langkah 3: Cari Varian yang mau diedit di dalam List
//       List<ProductVariant> updatedVariants = List.from(product.variants);
//       int index = updatedVariants.indexWhere((v) => v.sku == variantSku);

//       if (index == -1) throw Exception("Varian SKU $variantSku tidak ditemukan!");

//       // Langkah 4: Modifikasi Data Varian (Immutable style)
//       var oldVariant = updatedVariants[index];
      
//       // Update Warehouse Data
//       var newWhData = WarehouseVariantData(
//         physicalStock: newStock, // <-- Update Stok Disini
//         safetyStock: oldVariant.warehouseData.safetyStock,
//         hargaProduksi: oldVariant.warehouseData.hargaProduksi,
//         cogs: oldVariant.warehouseData.cogs,
//         offlinePrice: oldVariant.warehouseData.offlinePrice,
//         status: newStock == 0 ? StatusProduk.HABIS : oldVariant.warehouseData.status,
//       );

//       // Buat Variant Baru
//       var newVariant = ProductVariant(
//         id: oldVariant.id,
//         sku: oldVariant.sku,
//         name: oldVariant.name,
//         imageUrl: oldVariant.imageUrl,
//         shopeeData: oldVariant.shopeeData, // Data Shopee tetap utuh
//         warehouseData: newWhData,
//       );

//       // Masukkan kembali ke List
//       updatedVariants[index] = newVariant;

//       // Langkah 5: Simpan List Varian Baru ke Firestore
//       // Kita hanya update field 'variants' agar hemat bandwidth
//       transaction.update(docRef, {
//         'variants': updatedVariants.map((v) => v.toMap()).toList(),
//         'last_updated': DateTime.now(),
//       });
//     });
//   }
// }