import '../entities/invoice_entity.dart';

abstract class InvoiceRepository {
  Future<List<InvoiceEntity>> getAllInvoices({
    String? status,
    String? billingMonth,
    int? propertyId,
    int? apartmentId,
    int? tenantId,
    int? contractId,
  });
  Future<InvoiceEntity?> getInvoiceById(int id);

  /// Idempotently generates monthly invoices for active/expiring contracts
  /// whose period covers [billingMonth] (YYYY-MM). Returns count of newly generated invoices.
  Future<int> generateMonthlyInvoices(
    String billingMonth, {
    String? referenceTodayIso,
  });

  /// Updates Pending invoices whose dueDate < referenceTodayIso and remainingAmount > 0 to Overdue.
  Future<int> refreshOverdueStatuses({String? referenceTodayIso});
}
