enum DebtPaymentKind {
  installment,
  extra;

  String get dbValue => name;

  static DebtPaymentKind fromDb(String v) {
    switch (v) {
      case 'installment':
        return DebtPaymentKind.installment;
      case 'extra':
        return DebtPaymentKind.extra;
      default:
        return DebtPaymentKind.extra;
    }
  }
}

class DebtPayment {
  final int? id;
  final int debtId;
  final DateTime paidAt;
  final double amount;
  final DebtPaymentKind kind;
  final String paymentMethod;
  final String note;

  /// Optional bank/transfer reference separate from free-form [note].
  final String externalRef;

  const DebtPayment({
    this.id,
    required this.debtId,
    required this.paidAt,
    required this.amount,
    required this.kind,
    this.paymentMethod = '',
    this.note = '',
    this.externalRef = '',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'debtId': debtId,
        'paidAt': paidAt.toIso8601String(),
        'amount': amount,
        'kind': kind.dbValue,
        'paymentMethod': paymentMethod,
        'note': note,
        'externalRef': externalRef,
      };

  factory DebtPayment.fromMap(Map<String, dynamic> map) => DebtPayment(
        id: map['id'] as int?,
        debtId: map['debtId'] as int,
        paidAt: DateTime.parse(map['paidAt'] as String),
        amount: (map['amount'] as num).toDouble(),
        kind: DebtPaymentKind.fromDb(map['kind'] as String? ?? 'extra'),
        paymentMethod: map['paymentMethod'] as String? ?? '',
        note: map['note'] as String? ?? '',
        externalRef: map['externalRef'] as String? ?? '',
      );
}
