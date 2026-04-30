class IncomingPayment {
  final int? id;
  final String name;
  final String description;
  final double amount;
  final bool isCompleted;
  final int targetFundId;

  /// Set when marking received — for your records (bank memo, reconciliation).
  final String ledgerNote;

  /// Optional external id (transfer ref, receipt #, etc.).
  final String externalRef;

  IncomingPayment({
    this.id,
    required this.name,
    required this.description,
    required this.amount,
    this.isCompleted = false,
    required this.targetFundId,
    this.ledgerNote = '',
    this.externalRef = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'amount': amount,
      'isCompleted': isCompleted ? 1 : 0,
      'targetFundId': targetFundId,
      'ledgerNote': ledgerNote,
      'externalRef': externalRef,
    };
  }

  factory IncomingPayment.fromMap(Map<String, dynamic> map) {
    return IncomingPayment(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String,
      amount: map['amount'] as double,
      isCompleted: map['isCompleted'] == 1,
      targetFundId: map['targetFundId'] as int,
      ledgerNote: map['ledgerNote'] as String? ?? '',
      externalRef: map['externalRef'] as String? ?? '',
    );
  }

  IncomingPayment copyWith({
    int? id,
    String? name,
    String? description,
    double? amount,
    bool? isCompleted,
    int? targetFundId,
    String? ledgerNote,
    String? externalRef,
  }) {
    return IncomingPayment(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      isCompleted: isCompleted ?? this.isCompleted,
      targetFundId: targetFundId ?? this.targetFundId,
      ledgerNote: ledgerNote ?? this.ledgerNote,
      externalRef: externalRef ?? this.externalRef,
    );
  }
}
