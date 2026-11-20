import '../entities/invoice_entity.dart';
import '../repositories/invoice_repository.dart';

class ManageInvoicesUseCase {
  final InvoiceRepository _repository;

  const ManageInvoicesUseCase(this._repository);

  Future<List<InvoiceEntity>> getInvoices({
    String? status,
    String? billingMonth,
    int? propertyId,
    int? apartmentId,
    int? tenantId,
    int? contractId,
  }) =>
      _repository.getAllInvoices(
        status: status,
        billingMonth: billingMonth,
        propertyId: propertyId,
        apartmentId: apartmentId,
        tenantId: tenantId,
        contractId: contractId,
      );

  Future<InvoiceEntity?> getInvoiceById(int id) =>
      _repository.getInvoiceById(id);

  Future<int> generateMonthlyInvoices(
    String billingMonth, {
    String? referenceTodayIso,
  }) =>
      _repository.generateMonthlyInvoices(
        billingMonth,
        referenceTodayIso: referenceTodayIso,
      );

  Future<int> refreshOverdueStatuses({String? referenceTodayIso}) =>
      _repository.refreshOverdueStatuses(referenceTodayIso: referenceTodayIso);
}
