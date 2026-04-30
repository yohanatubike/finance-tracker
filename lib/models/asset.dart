class Asset {
  final int? id;
  final String name;
  final String description;
  final double amount;

  Asset({
    this.id,
    required this.name,
    required this.description,
    required this.amount,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'amount': amount,
    };
  }

  factory Asset.fromMap(Map<String, dynamic> map) {
    return Asset(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String,
      amount: map['amount'] as double,
    );
  }

  Asset copyWith({
    int? id,
    String? name,
    String? description,
    double? amount,
  }) {
    return Asset(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      amount: amount ?? this.amount,
    );
  }
}
