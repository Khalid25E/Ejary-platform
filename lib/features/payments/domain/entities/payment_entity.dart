class PaymentEntity {
  final int id;
  final int contractId;
  final int invoiceId;
  final String type; // full, partial
  final String payAt;
  final num amount;
  final String payMethod; // cash, bank, remittance, other
  final String payRef;
  final String billingMonth;
  final String notes;
  final String createdAt;
  final bool isCancelled;

  const PaymentEntity({
    required this.id,
    required this.contractId,
    required this.invoiceId,
    required this.type,
    required this.payAt,
    required this.amount,
    required this.payMethod,
    required this.payRef,
    required this.billingMonth,
    required this.notes,
    required this.createdAt,
    this.isCancelled = false,
  });
}
