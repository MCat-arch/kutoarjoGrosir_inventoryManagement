import 'package:flutter/material.dart';

class ForecastEngineMVA {
  static double calculateSimpleMovingAverage(
    List<int> salesData,
    int windowSize,
  ) {
    if (salesData.isEmpty) return 0.0;

    int count = 0;
    int sum = 0;


    for (int i = salesData.length - 1; i >= 0; i--) {
      sum += salesData[i];
      count++;
      if (count >= windowSize) break;
    }
    if (count == 0) return 0.0;

    return sum / count;
  }

  static int calculateRestockSuggestion({
    required double dailyBurnRate,
    required int currentStock,
    required String priority,
  }) {
    // A (Winning) -> Stok harus cukup untuk 14 hari
    // B (Standard) -> Stok harus cukup untuk 7 hari
    // C (Dead) -> Tidak usah restock

    int daysCover = 0;
    if (priority == 'A')
      daysCover = 14;
    else if (priority == 'B')
      daysCover = 7;
    else
      return 0;

    int targetStock = (dailyBurnRate * daysCover).ceil();

    if (currentStock >= targetStock) return 0; // Stok masih aman
    return targetStock - currentStock; // Jumlah yang harus dibeli
  }
}
