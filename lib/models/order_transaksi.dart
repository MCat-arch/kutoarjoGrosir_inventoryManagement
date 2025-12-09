// import 'package:kg/models/enums.dart';

// class OrderModel {
//   final String id; // Firestore ID
//   final OrderSource source;
//   final String orderSn; // Shopee Order SN (Unique String)
//   final ShopeeOrderStatus? status;
//   final ShopeeLogisticsStatus? logisticsStatus;

//   // Data Logistik (Penting untuk Cetak Resi)
//   final String? trackingNumber; // No Resi
//   final String? shippingCarrier; // JNE, J&T, etc
//   final String? shippingDocumentType; // NORMAL_AIR_WAYBILL / THERMAL

//   // Data Keuangan
//   final double totalAmount; //omzet
//   final double totalCogs; //total modal (HPP)
//   final double?
//   escrowAmount; // Uang yang akan diterima seller (setelah potongan)

//   // List Barang
//   final List<OrderItem> items;

//   // Flag Cetak
//   final bool isResiPrinted;
//   final DateTime orderDate;

//   // 1. Laba Kotor (Berdasarkan Barang Jual vs Modal)
//   double get grossProfit => totalAmount - totalCogs;

//   // 2. Estimasi Laba Bersih (Setelah dipotong biaya admin Shopee)
//   // Logic: (Uang Cair - Modal Barang)
//   double get netProfitEstimate {
//     final revenueReceived = escrowAmount ?? totalAmount;
//     return revenueReceived - totalCogs;
//   }

//   // 3. Persentase Margin
//   double get marginPercentage {
//     if (totalAmount == 0) return 0;
//     return (grossProfit / totalAmount) * 100;
//   }

//   OrderModel({
//     required this.id,
//     required this.source,
//     required this.orderSn,
//     required this.status,
//     required this.logisticsStatus,
//     this.trackingNumber,
//     this.shippingCarrier,
//     this.shippingDocumentType,
//     required this.totalAmount,
//     required this.totalCogs,
//     this.escrowAmount,
//     required this.items,
//     this.isResiPrinted = false,
//     required this.orderDate,
//   });

//   factory OrderModel.createOffline({
//     required String id,
//     required String orderSn,
//     required List<OrderItem> items,
//     required DateTime orderDate,
//   }) {
//     double calcTotalAmount = 0;
//     double calcTotalCogs = 0;

//     for (var item in items) {
//       calcTotalAmount += item.totalRevenue;
//       calcTotalCogs += (item.cogs * item.quantity);
//     }

//     return OrderModel(
//       id: id,
//       source: OrderSource.MANUAL_ADMIN,
//       orderSn: orderSn,
//       status: ShopeeOrderStatus.COMPLETED, // Offline langsung selesai
//       logisticsStatus: null,
//       totalAmount: calcTotalAmount,
//       totalCogs: calcTotalCogs,
//       escrowAmount: calcTotalAmount, // Offline tidak ada potongan admin shopee
//       items: items,
//       orderDate: orderDate,
//     );
//   }

//   factory OrderModel.fromJson(Map<String, dynamic> json) {
//     DateTime parseDate(dynamic v) {
//       if (v == null) return DateTime.fromMillisecondsSinceEpoch(0);
//       if (v is DateTime) return v;
//       try {
//         if (v is Map && v['toDate'] != null) return v['toDate']();
//       } catch (_) {}
//       if (v is String) return DateTime.parse(v);
//       if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
//       return DateTime.fromMillisecondsSinceEpoch(0);
//     }

//     OrderSource parseSource(dynamic v) {
//       if (v is String) {
//         return OrderSource.values.firstWhere(
//           (e) => e.toString() == 'OrderSource.$v',
//           orElse: () => OrderSource.MANUAL_ADMIN,
//         );
//       }
//       return OrderSource.MANUAL_ADMIN;
//     }

//     final itemsList =
//         (json['items'] as List<dynamic>?) ??
//         (json['line_items'] as List<dynamic>?) ??
//         [];

//     return OrderModel(
//       id: json['id']?.toString() ?? '',
//       source: parseSource(json['source'] ?? json['order_source']),
//       orderSn: json['order_sn'] ?? json['orderSn'] ?? '',
//       status: (json['status'] is String)
//           ? ShopeeOrderStatus.values.firstWhere(
//               (e) => e.toString() == 'ShopeeOrderStatus.${json['status']}',
//               orElse: () => ShopeeOrderStatus.UNKNOWN,
//             )
//           : null,
//       logisticsStatus: (json['logistics_status'] is String)
//           ? ShopeeLogisticsStatus.values.firstWhere(
//               (e) =>
//                   e.toString() ==
//                   'ShopeeLogisticsStatus.${json['logistics_status']}',
//               orElse: () => ShopeeLogisticsStatus.UNKNOWN,
//             )
//           : null,
//       trackingNumber:
//           json['tracking_number'] ?? json['trackingNumber'] as String?,
//       shippingCarrier:
//           json['shipping_carrier'] ?? json['shippingCarrier'] as String?,
//       shippingDocumentType:
//           json['shipping_document_type'] ??
//           json['shippingDocumentType'] as String?,
//       totalAmount: (json['total_amount'] ?? json['total'] ?? 0).toDouble(),
//       totalCogs: (json['total_cogs'] ?? json['totalCogs'] ?? 0).toDouble(),
//       escrowAmount: (json['escrow_amount'] ?? json['escrowAmount'])?.toDouble(),
//       items: itemsList
//           .map((e) => OrderItem.fromJson(Map<String, dynamic>.from(e)))
//           .toList(),
//       isResiPrinted: json['is_resi_printed'] ?? json['isResiPrinted'] ?? false,
//       orderDate: parseDate(
//         json['order_date'] ?? json['orderDate'] ?? json['created_at'],
//       ),
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'source': source.toString().split('.').last,
//       'order_sn': orderSn,
//       'status': status?.toString().split('.').last,
//       'logistics_status': logisticsStatus?.toString().split('.').last,
//       'tracking_number': trackingNumber,
//       'shipping_carrier': shippingCarrier,
//       'shipping_document_type': shippingDocumentType,
//       'total_amount': totalAmount,
//       'total_cogs': totalCogs,
//       'escrow_amount': escrowAmount,
//       'items': items.map((i) => i.toJson()).toList(),
//       'is_resi_printed': isResiPrinted,
//       'order_date': orderDate,
//     };
//   }
// }

// // ========== ORDER ITEM =====================

// class OrderItem {
//   final int shopeeItemId;
//   final int? shopeeModelId; // Null jika tidak ada varian
//   final String sku;
//   final String name;
//   final int quantity;
//   final double originalPrice;
//   final double discountedPrice; // Harga saat deal
//   final double cogs;

//   OrderItem({
//     required this.shopeeItemId,
//     this.shopeeModelId,
//     required this.sku,
//     required this.name,
//     required this.quantity,
//     required this.originalPrice,
//     required this.discountedPrice,
//     required this.cogs,
//   });

//   // 1. Margin per pcs (Diskon Price - Modal)
//   double get marginPerItem => discountedPrice - cogs;

//   // 2. Total Omzet Item ini
//   double get totalRevenue => discountedPrice * quantity;

//   // 3. Total Profit Item ini (Margin * Qty)
//   double get totalProfit => marginPerItem * quantity;

//   // toMap & fromMap...
//   Map<String, dynamic> toJson() {
//     return {
//       'shopee_item_id': shopeeItemId,
//       'shopee_model_id': shopeeModelId,
//       'sku': sku,
//       'name': name,
//       'quantity': quantity,
//       'original_price': originalPrice,
//       'discounted_price': discountedPrice,
//       'cogs': cogs, // Disimpan ke DB
//     };
//   }

//   factory OrderItem.fromJson(Map<String, dynamic> json) {
//     int parseInt(dynamic v) {
//       if (v == null) return 0;
//       if (v is int) return v;
//       if (v is String) return int.tryParse(v) ?? 0;
//       if (v is double) return v.toInt();
//       return 0;
//     }

//     double parseDouble(dynamic v) {
//       if (v == null) return 0;
//       if (v is double) return v;
//       if (v is int) return v.toDouble();
//       if (v is String) return double.tryParse(v) ?? 0.0;
//       return 0.0;
//     }

//     return OrderItem(
//       shopeeItemId: parseInt(
//         json['shopee_item_id'] ?? json['shopeeItemId'] ?? json['item_id'],
//       ),
//       shopeeModelId: (json['shopee_model_id'] ?? json['shopeeModelId']) != null
//           ? parseInt(json['shopee_model_id'] ?? json['shopeeModelId'])
//           : null,
//       sku: (json['sku'] ?? json['SKU'] ?? '') as String,
//       name: (json['name'] ?? '') as String,
//       quantity: parseInt(json['quantity'] ?? json['qty']),
//       originalPrice: parseDouble(
//         json['original_price'] ?? json['originalPrice'],
//       ),
//       discountedPrice: parseDouble(
//         json['discounted_price'] ?? json['discountedPrice'] ?? json['price'],
//       ),
//       cogs: parseDouble(json['cogs'] ?? 0),
//     );
//   }
// }
