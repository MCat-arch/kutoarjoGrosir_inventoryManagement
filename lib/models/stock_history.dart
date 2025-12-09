class StockHistoryModel {
  final String id;
  final String variantId;
  final String productName;
  final String variantName;
  final int previousStock;
  final int currentStock;
  final int changeAmount;
  final String type; // 'MANUAL', 'SALE', 'PURCHASE'
  final String description;
  final DateTime createdAt;

  StockHistoryModel({
    required this.id,
    required this.variantId,
    required this.productName,
    required this.variantName,
    required this.previousStock,
    required this.currentStock,
    required this.changeAmount,
    required this.type,
    required this.description,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'variant_id': variantId,
      'product_name': productName,
      'variant_name': variantName,
      'previous_stock': previousStock,
      'current_stock': currentStock,
      'change_amount': changeAmount,
      'type': type,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory StockHistoryModel.fromMap(Map<String, dynamic> map) {
    return StockHistoryModel(
      id: map['id'],
      variantId: map['variant_id'],
      productName: map['product_name'] ?? '',
      variantName: map['variant_name'] ?? '',
      previousStock: map['previous_stock'],
      currentStock: map['current_stock'],
      changeAmount: map['change_amount'],
      type: map['type'],
      description: map['description'] ?? '',
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}