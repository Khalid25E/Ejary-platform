class InvoiceEntity {
  final int id;
  final int contractId;
  final String billingMonth; // YYYY-MM
  final String dueDate;
  final num baseRent;
  final num servicesTotal;
  final num totalAmount;
  final num paidAmount;
  final num remainingAmount;
  final String status; // Pending, Partially Paid, Paid, Overdue, Cancelled
  final String createdAt;

  const InvoiceEntity({
    required this.id,
    required this.contractId,
    required this.billingMonth,
    required this.dueDate,
    required this.baseRent,
    required this.servicesTotal,
    required this.totalAmount,
    required this.paidAmount,
    required this.remainingAmount,
    required this.status,
    required this.createdAt,
  });
}
