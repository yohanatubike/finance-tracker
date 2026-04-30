class OutgoingPayment {
  final int? id;
  final String name;
  final String description;
  final double amount;
  final bool isCompleted;
  final int sourceFundId;

  /// When this outgoing payment should be made (optional). Used for prioritizing pending items.
  final DateTime? deadlineAt;

  final String ledgerNote;
  final String externalRef;

  OutgoingPayment({
    this.id,
    required this.name,
    required this.description,
    required this.amount,
    this.isCompleted = false,
    required this.sourceFundId,
    this.deadlineAt,
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
      'sourceFundId': sourceFundId,
      'deadlineAt': deadlineAt?.toIso8601String(),
      'ledgerNote': ledgerNote,
      'externalRef': externalRef,
    };
  }

  factory OutgoingPayment.fromMap(Map<String, dynamic> map) {
    final rawDeadline = map['deadlineAt'] as String?;
    return OutgoingPayment(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String,
      amount: map['amount'] as double,
      isCompleted: map['isCompleted'] == 1,
      sourceFundId: map['sourceFundId'] as int,
      deadlineAt: rawDeadline != null ? DateTime.tryParse(rawDeadline) : null,
      ledgerNote: map['ledgerNote'] as String? ?? '',
      externalRef: map['externalRef'] as String? ?? '',
    );
  }

  OutgoingPayment copyWith({
    int? id,
    String? name,
    String? description,
    double? amount,
    bool? isCompleted,
    int? sourceFundId,
    DateTime? deadlineAt,
    String? ledgerNote,
    String? externalRef,
  }) {
    return OutgoingPayment(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      isCompleted: isCompleted ?? this.isCompleted,
      sourceFundId: sourceFundId ?? this.sourceFundId,
      deadlineAt: deadlineAt ?? this.deadlineAt,
      ledgerNote: ledgerNote ?? this.ledgerNote,
      externalRef: externalRef ?? this.externalRef,
    );
  }
}
