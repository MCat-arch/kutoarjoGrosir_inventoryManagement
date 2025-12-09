import 'package:kg/models/enums.dart';

class TransactioItem {
  final String productId;
  final String variantId;
  final String name;
  final int qty;
  final double price;
  final double cogs; // HPP saat transaksi

  TransactioItem({
    required this.productId,
    required this.variantId,
    required this.name,
    required this.qty,
    required this.price,
    required this.cogs,
  });

  factory TransactioItem.fromMap(Map<String, dynamic> map) {
    return TransactioItem(
      productId: map['product_id']?.toString() ?? '',
      variantId: map['variant_id']?.toString() ?? '',
      // Ambil nama dari snapshot DB jika ada, kalau null baru cari fallback
      name: map['name'] ?? '',
      qty: (map['qty'] ?? 0) as int,
      price: (map['price_at_moment'] ?? map['price'] ?? 0).toDouble(),
      cogs: (map['cost_at_moment'] ?? map['cogs'] ?? 0).toDouble(),
    );
  }

  // Map<String, dynamic> toMap() {
  //   return {
  //     'product_id': productId,
  //     'variant_id': variantId,
  //     'name': name,
  //     'qty': qty,
  //     'price': price,
  //     'cogs': cogs,
  //   };
  // }

  Map<String, dynamic> toMapForDb(String transactionId) {
    return {
      'id':
          DateTime.now().millisecondsSinceEpoch.toString() +
          variantId, // Generate Random ID
      'transaction_id': transactionId,
      'product_id': productId,
      'variant_id': variantId,
      'name': name,
      'qty': qty,
      'price_at_moment': price,
      'cost_at_moment': cogs,
    };
  }
}

// model utama transaksi

class TransactionModel {
  final String id;
  final String trxNumber;
  final DateTime time;

  final trxType typeTransaksi;

  //hubungan dengan party pihak
  final String? partyId;
  final String? partyName;

  final double totalAmount;
  final double paidAmount;

  //detail barang jika ada
  final List<TransactioItem>? items;
  final String? description;
  final String? proofImage;

  TransactionModel({
    required this.id,
    required this.trxNumber,
    required this.time,
    required this.typeTransaksi,
    this.partyId,
    this.partyName,
    required this.totalAmount,
    required this.paidAmount,
    this.items,
    this.description,
    this.proofImage,
  });

  bool get isLunas => paidAmount >= totalAmount;
  double get remainingDebt => totalAmount - paidAmount;

  // --- MAPPING KE DATABASE (FIXED) ---
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'trx_number': trxNumber,
      // Mapping ke nama kolom DB 'type'
      'type': typeTransaksi.toString().split('.').last,
      'party_id': partyId,
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      'description': description,
      'proof_image': proofImage, // Sudah ada kolomnya
      // Mapping ke nama kolom DB 'created_at'
      'created_at': time.toIso8601String(),
      'is_synced': 0,
    };
  }

  // --- MAPPING DARI DATABASE (FIXED) ---
  factory TransactionModel.fromMap(
    Map<String, dynamic> map, {
    List<TransactioItem>? loadedItems,
  }) {
    return TransactionModel(
      id: map['id'].toString(),
      trxNumber: map['trx_number'],
      // Baca dari 'created_at'
      time: DateTime.parse(map['created_at']),
      // Baca dari 'type'
      typeTransaksi: trxType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
        orElse: () => trxType.SALE,
      ),
      partyId: map['party_id'],
      partyName: map['party_name'], // Kolom virtual hasil JOIN party
      totalAmount: (map['total_amount'] ?? 0).toDouble(),
      paidAmount: (map['paid_amount'] ?? 0).toDouble(),
      description: map['description'],
      proofImage: map['proof_image'],
      // Items biasanya di-load terpisah lewat query detail,
      // tapi jika dikirim via parameter loadedItems, pakai itu.
      items: loadedItems,
    );
  }
}
