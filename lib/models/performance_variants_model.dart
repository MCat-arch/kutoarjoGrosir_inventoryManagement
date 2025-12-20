import 'package:flutter/material.dart';

class VariantPerformance {
  final String variantId;
  final String productName;
  final String variantName;
  final int totalQtySold;
  final double totalRevenue;
  final int currentStock;

  String category = 'C';
  double dailyBurnRate = 0;
  int suggestedStock = 0;

  VariantPerformance({
    required this.variantId,
    required this.productName,
    required this.variantName,
    required this.totalQtySold,
    required this.totalRevenue,
    required this.currentStock,
  });
}
