import 'package:kg/models/enums.dart';

class PartyModel {
  final String id;
  final String name;
  final PartyRole role;
  final String? phone;
  final String? email;
  final String? alamat;

  final double balance;
  final DateTime? lastTransactionDate;

  PartyModel({
    required this.id,
    required this.name,
    required this.role,
    this.phone,
    this.email,
    this.alamat,
    this.balance = 0,
    this.lastTransactionDate,
  });

  factory PartyModel.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic v) {
      if (v == null) return DateTime.fromMillisecondsSinceEpoch(0);
      if (v is DateTime) return v;
      try {
        if (v is Map && v['toDate'] != null) return v['toDate']();
      } catch (_) {}
      if (v is String) return DateTime.parse(v);
      if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
      return DateTime.fromMillisecondsSinceEpoch(0);
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
      balance: (map['balance'] ?? 0).toDouble(),
      lastTransactionDate: parseDate(
        map['last_transaction_date'] ??
            map['lastTransactionDate'] ??
            map['last_transaction'],
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
      'balance': balance,
      'last_transaction_date': lastTransactionDate,
    };
  }
}
