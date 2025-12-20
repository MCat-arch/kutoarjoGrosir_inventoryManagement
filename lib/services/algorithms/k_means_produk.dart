import 'dart:math';
import 'package:kg/models/performance_variants_model.dart';

class KMeansProduk {
  final int k;
  final int maxIterations;

  KMeansProduk({this.k = 3, this.maxIterations = 100});

  //data normalisasi
  void execute(List<VariantPerformance> data) {
    if (data.length < k) {
      for (var item in data) {
        item.category = 'B';
      }
      return;
    }

    //min max untuk normalisasi
    double minQty = double.infinity, maxQty = -double.infinity;
    double minRev = double.infinity, maxRev = -double.infinity;

    for (var item in data) {
      if (item.totalQtySold < minQty) minQty = item.totalQtySold.toDouble();
      if (item.totalQtySold > maxQty) maxQty = item.totalQtySold.toDouble();
      if (item.totalRevenue < minRev) minRev = item.totalRevenue.toDouble();
      if (item.totalRevenue > maxRev) maxRev = item.totalRevenue.toDouble();
    }

    if (maxQty == minQty) maxQty += 1;
    if (maxRev == minRev) maxQty += 1;

    //normalisasi scale 0-1
    List<_Point> points = data.map((item) {
      return _Point(
        originalData: item,
        normQty: (item.totalQtySold - minQty) / (maxQty - minQty),
        normRev: (item.totalRevenue - minRev) / (maxRev - minRev),
      );
    }).toList();

    //mengurtkan data
    points.sort((a, b) => a.normRev.compareTo(b.normRev));

    List<_Centroid> centroids = [
      _Centroid(0, points[0].normQty, points[0].normRev), //low
      _Centroid(
        1,
        points[points.length ~/ 2].normQty,
        points[points.length ~/ 2].normRev,
      ),
      _Centroid(
        2,
        points[points.length - 1].normQty,
        points[points.length - 1].normRev,
      ),
    ];

    // training loop
    bool changed = true;
    int iter = 0;

    while (changed && iter < maxIterations) {
      changed = false;
      iter++;

      for (var c in centroids) {
        c.points.clear();
      }

      for (var p in points) {
        int bestCluster = -1;
        double minDistance = double.infinity;

        //assign ke cluster tertentu
        for (int i = 0; i < k; i++) {
          double dist = _euclideanDistance(p, centroids[i]);
          if (dist < minDistance) {
            minDistance = dist;
            bestCluster = i;
          }
        }
        if (p.clusterIndex != bestCluster) {
          p.clusterIndex = bestCluster;
          changed = true;
        }
        centroids[bestCluster].points.add(p);
      }

      //update centroid pusat
      for (var c in centroids) {
        if (c.points.isNotEmpty) {
          double sumQty = 0;
          double sumRev = 0;
          for (var p in c.points) {
            sumQty += p.normQty;
            sumRev += p.normRev;
          }
          c.xQty = sumQty / c.points.length;
          c.yRev = sumRev / c.points.length;
        }
      }
    }

    centroids.sort((a, b) => b.yRev.compareTo(a.yRev)); //descending

    for (int i = 0; i < centroids.length; i++) {
      String label = 'B';
      if (i == 0) {
        label = 'A';
      } else if (i == 1) {
        label = 'B';
      } else {
        label = 'C';
      }
      for (var p in centroids[i].points) {
        p.originalData.category = label;
      }
    }
  }

  double _euclideanDistance(_Point p, _Centroid c) {
    return sqrt(pow(p.normQty - c.xQty, 2) + pow(p.normRev - c.yRev, 2));
  }
}

// helper class
class _Point {
  final VariantPerformance originalData;
  final double normQty;
  final double normRev;
  int clusterIndex = -1;

  _Point({
    required this.originalData,
    required this.normQty,
    required this.normRev,
  });
}

class _Centroid {
  final int id;
  double xQty;
  double yRev;
  final List<_Point> points = [];

  _Centroid(this.id, this.xQty, this.yRev);
}
