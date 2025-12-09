class AccountCategoryModel {
  final String id;
  final String name;
  final String type; // 'INCOME' atau 'EXPENSE'

  AccountCategoryModel({
    required this.id,
    required this.name,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
    };
  }

  factory AccountCategoryModel.fromMap(Map<String, dynamic> map) {
    return AccountCategoryModel(
      id: map['id'],
      name: map['name'],
      type: map['type'],
    );
  }
}