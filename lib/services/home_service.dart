import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:kg/models/enums.dart';
import 'package:kg/models/transaction_model.dart';
import 'package:kg/models/produk_model.dart';
import 'package:kg/widgets/home_widget.dart';

class HomeService {
  Map<String, double> calculateFinancialSummary(
    List<TransactionModel> transactions,
  ) {
    double totalIcome = 0;
    double totalExpense = 0;

    for (var trx in transactions) {
      if (trx.typeTransaksi == trxType.SALE ||
          trx.typeTransaksi == trxType.INCOME_OTHER ||
          trx.typeTransaksi == trxType.UANG_MASUK ||
          trx.typeTransaksi == trxType.PURCHASE_RETURN) {
        totalIcome += trx.paidAmount;
      } else if (trx.typeTransaksi == trxType.EXPENSE ||
          trx.typeTransaksi == trxType.UANG_KELUAR ||
          trx.typeTransaksi == trxType.PURCHASE ||
          trx.typeTransaksi == trxType.SALE_RETURN) {
        totalExpense += trx.paidAmount;
      }
    }

    return {
      'income': totalIcome,
      'expense': totalExpense,
      'profit': totalIcome - totalExpense,
    };
  }

  double calculateTotalAssetValue(List<ProductModel> product) {
    double total = 0;
    for (var p in product) {
      for (var v in p.variants) {
        total += (v.warehouseData.cogs * v.warehouseData.physicalStock);
      }
    }
    return total;
  }

  int countLowStock(List<ProductModel> products) {
    int count = 0;
    for (var p in products) {
      for (var v in p.variants) {
        if (v.warehouseData.physicalStock < 5) {
          count++;
        }
      }
    }
    return count;
  }

  List<BarChartGroupData> generateChartData(
    List<TransactionModel> transactions,
  ) {
    Map<int, double> incomPerDay = {};
    Map<int, double> expensePerDay = {};

    for (int i = 0; i < 7; i++) {
      incomPerDay[i] = 0;
      expensePerDay[i] = 0;
    }

    final now = DateTime.now();
    for (var trx in transactions) {
      final daysDiff = now.difference(trx.time).inDays;
      if (daysDiff >= 0 && daysDiff < 7) {
        final dayIndex = 6 - daysDiff;
        if (trx.typeTransaksi == trxType.SALE ||
            trx.typeTransaksi == trxType.INCOME_OTHER ||
            trx.typeTransaksi == trxType.UANG_MASUK ||
            trx.typeTransaksi == trxType.PURCHASE_RETURN) {
          incomPerDay[dayIndex] = (incomPerDay[dayIndex] ?? 0) + trx.paidAmount;
        } else if (trx.typeTransaksi == trxType.EXPENSE ||
            trx.typeTransaksi == trxType.UANG_KELUAR ||
            trx.typeTransaksi == trxType.PURCHASE ||
            trx.typeTransaksi == trxType.SALE_RETURN) {
          expensePerDay[dayIndex] =
              (expensePerDay[dayIndex] ?? 0) + trx.paidAmount;
        }
      }
    }
    List<BarChartGroupData> barGroups = [];
    for (int i = 0; i < 7; i++) {
      barGroups.add(
        _makeGroupData(
          i,
          (incomPerDay[i] ?? 0) / 1000000,
          (expensePerDay[i] ?? 0) / 1000000,
        ),
      );
    }
    return barGroups;
  }

  List<BarChartGroupData> generateMonthlyChartData(
    List<TransactionModel> transaction,
  ) {
    Map<int, double> incomePerMonth = {};
    Map<int, double> expensePerMonth = {};

    for (int i = 0; i < 12; i++) {
      incomePerMonth[i] = 0;
      expensePerMonth[i] = 0;
    }

    final now = DateTime.now();
    for (var trx in transaction) {
      final monthsDiff = _monthsBetween(trx.time, now);
      if (monthsDiff >= 0 && monthsDiff < 12) {
        final monthIndex = 11 - monthsDiff;
        if (_isIncomeTransaction(trx.typeTransaksi)) {
          incomePerMonth[monthIndex] =
              (incomePerMonth[monthIndex] ?? 0) + trx.paidAmount;
        } else if (_isExpenseTransaction(trx.typeTransaksi)) {
          expensePerMonth[monthIndex] =
              (expensePerMonth[monthIndex] ?? 0) + trx.paidAmount;
        }
      }
    }

    List<BarChartGroupData> barGroups = [];
    for (int i = 0; i < 12; i++) {
      barGroups.add(
        _makeGroupData(
          i,
          (incomePerMonth[i] ?? 0) / 1000000,
          (expensePerMonth[i] ?? 0) / 1000000,
        ),
      );
    }
    return barGroups;
  }

  BarChartGroupData _makeGroupData(int x, double y1, double y2) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y1,
          color: Color(0xFF4CAF50),
          width: 8,
          borderRadius: BorderRadius.circular(2),
        ),
        BarChartRodData(
          toY: y2,
          color: Colors.redAccent,
          width: 8,
          borderRadius: BorderRadius.circular(2),
        ),
      ],
    );
  }

  int _monthsBetween(DateTime from, DateTime to) {
    return (to.year - from.year) * 12 + (to.month - from.month);
  }

  /// Cek apakah transaksi adalah income
  bool _isIncomeTransaction(trxType type) {
    return type == trxType.SALE ||
        type == trxType.INCOME_OTHER ||
        type == trxType.UANG_MASUK ||
        type == trxType.PURCHASE_RETURN;
  }

  /// Cek apakah transaksi adalah expense
  bool _isExpenseTransaction(trxType type) {
    return type == trxType.EXPENSE ||
        type == trxType.UANG_KELUAR ||
        type == trxType.PURCHASE ||
        type == trxType.SALE_RETURN;
  }
}
