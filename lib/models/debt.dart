class Debt {
  final int? id;
  final String personName;
  final String description;
  /// Current outstanding balance (reduces when payments are recorded).
  final double amount;
  final bool isOwedByMe;
  final bool isPaid;

  /// Monthly installment (principal + interest rolled into one figure). Null if not tracked.
  final double? monthlyInstallment;

  /// First day of the loan / agreement (installment #1 due date is derived as start + 1 month).
  final DateTime? loanStartDate;

  /// Preferred method label for scheduled payments (Cash, Bank transfer, …).
  final String defaultPaymentMethod;

  /// Whether monthly installment tracking UI applies (only meaningful for debts you owe).
  final bool hasInstallmentSchedule;

  /// Opening principal when loan was created (for payoff-from-original estimate).
  final double originalPrincipal;

  const Debt({
    this.id,
    required this.personName,
    required this.description,
    required this.amount,
    required this.isOwedByMe,
    this.isPaid = false,
    this.monthlyInstallment,
    this.loanStartDate,
    this.defaultPaymentMethod = '',
    this.hasInstallmentSchedule = false,
    this.originalPrincipal = 0,
  });

  bool get hasLoanScheduleData =>
      isOwedByMe &&
      hasInstallmentSchedule &&
      monthlyInstallment != null &&
      monthlyInstallment! > 0 &&
      loanStartDate != null;

  Map<String, dynamic> toMap() => {
        'id': id,
        'personName': personName,
        'description': description,
        'amount': amount,
        'isOwedByMe': isOwedByMe ? 1 : 0,
        'isPaid': isPaid ? 1 : 0,
        'monthlyInstallment': monthlyInstallment,
        'loanStartDate': loanStartDate?.toIso8601String(),
        'defaultPaymentMethod': defaultPaymentMethod,
        'hasInstallmentSchedule': hasInstallmentSchedule ? 1 : 0,
        'originalPrincipal': originalPrincipal,
      };

  factory Debt.fromMap(Map<String, dynamic> map) {
    final mi = map['monthlyInstallment'];
    final ld = map['loanStartDate'];
    final op = map['originalPrincipal'];

    return Debt(
      id: map['id'] as int?,
      personName: map['personName'] as String,
      description: map['description'] as String,
      amount: (map['amount'] as num).toDouble(),
      isOwedByMe: map['isOwedByMe'] == 1,
      isPaid: map['isPaid'] == 1,
      monthlyInstallment: mi == null ? null : (mi as num).toDouble(),
      loanStartDate:
          ld == null || (ld as String).isEmpty ? null : DateTime.parse(ld),
      defaultPaymentMethod: map['defaultPaymentMethod'] as String? ?? '',
      hasInstallmentSchedule: map['hasInstallmentSchedule'] == 1,
      originalPrincipal: op == null
          ? (map['amount'] as num).toDouble()
          : (op as num).toDouble(),
    );
  }

  Debt copyWith({
    int? id,
    String? personName,
    String? description,
    double? amount,
    bool? isOwedByMe,
    bool? isPaid,
    double? monthlyInstallment,
    DateTime? loanStartDate,
    String? defaultPaymentMethod,
    bool? hasInstallmentSchedule,
    double? originalPrincipal,
    bool clearMonthlyInstallment = false,
    bool clearLoanStartDate = false,
  }) =>
      Debt(
        id: id ?? this.id,
        personName: personName ?? this.personName,
        description: description ?? this.description,
        amount: amount ?? this.amount,
        isOwedByMe: isOwedByMe ?? this.isOwedByMe,
        isPaid: isPaid ?? this.isPaid,
        monthlyInstallment:
            clearMonthlyInstallment ? null : (monthlyInstallment ?? this.monthlyInstallment),
        loanStartDate:
            clearLoanStartDate ? null : (loanStartDate ?? this.loanStartDate),
        defaultPaymentMethod:
            defaultPaymentMethod ?? this.defaultPaymentMethod,
        hasInstallmentSchedule:
            hasInstallmentSchedule ?? this.hasInstallmentSchedule,
        originalPrincipal: originalPrincipal ?? this.originalPrincipal,
      );
}
