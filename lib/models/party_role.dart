import 'package:kg/models/enums.dart';

class PartyModel {
  final String id;
  final String name;
  final PartyRole role;
  final String? phone;
  final String? email;
  final String? alamat;
  final String? imagePath;
  final double balance;
  final DateTime? lastTransactionDate;

  PartyModel({
    required this.id,
    required this.name,
    required this.role,
    this.phone,
    this.email,
    this.alamat,
    this.imagePath,
    this.balance = 0,
    this.lastTransactionDate,
  });

  factory PartyModel.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
      if (v is num) return DateTime.fromMillisecondsSinceEpoch(v.toInt());
      if (v is String) {
        // Try parse ISO8601, fall back to parse int string
        try {
          return DateTime.parse(v);
        } catch (_) {
          final n = int.tryParse(v);
          if (n != null) return DateTime.fromMillisecondsSinceEpoch(n);
          return null;
        }
      }
      if (v is Map) {
        // Firestore-like timestamp { '_seconds': ..., '_nanoseconds': ... }
        if (v.containsKey('_seconds')) {
          final seconds = v['_seconds'];
          final nanos = v['_nanoseconds'] ?? 0;
          if (seconds is int || seconds is num) {
            final ms = (seconds.toInt() * 1000) + (nanos ~/ 1000000);
            return DateTime.fromMillisecondsSinceEpoch(ms);
          }
        }
        // Some Firestore Timestamp objects can be represented with toDate function
        try {
          if (v['toDate'] != null && v['toDate'] is Function) {
            return v['toDate']();
          }
        } catch (_) {}
      }
      return null;
    }

    final roleStr =
        map['role'] ?? map['role_name'] ?? map['roleName'] ?? 'OTHER';
    final role = PartyRole.values.firstWhere(
      (e) => e.toString() == 'PartyRole.$roleStr',
      orElse: () => PartyRole.OTHER,
    );

    return PartyModel(
      id: map['id']?.toString() ?? '',
      name: map['name'] ?? '',
      role: role,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      alamat: map['alamat'] as String?,
      imagePath: map['image_path'] as String?,
      balance: (map['balance'] ?? 0).toDouble(),
      lastTransactionDate: parseDate(
        map['last_transaction_date'],
        // map['lastTransactionDate'] ??
        // map['last_transaction'],
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'role': role.toString().split('.').last,
      'phone': phone,
      'email': email,
      'alamat': alamat,
      'image_path': imagePath,
      'balance': balance,
      'last_transaction_date': lastTransactionDate?.toIso8601String(),
    };
  }
}
