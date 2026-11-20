import '../entities/payment_entity.dart';
import '../repositories/payment_repository.dart';

class ManagePaymentsUseCase {
  final PaymentRepository _repository;

  const ManagePaymentsUseCase(this._repository);

  Future<List<PaymentEntity>> getPayments({
    int? invoiceId,
    int? contractId,
  }) =>
      _repository.getAllPayments(
        invoiceId: invoiceId,
        contractId: contractId,
      );

  Future<PaymentEntity?> getPaymentById(int id) =>
      _repository.getPaymentById(id);

  Future<int> recordPayment(
    PaymentEntity payment, {
    String? referenceTodayIso,
  }) =>
      _repository.recordPaymentAtomically(
        payment,
        referenceTodayIso: referenceTodayIso,
      );

  Future<void> cancelPayment(
    int paymentId, {
    String? referenceTodayIso,
  }) =>
      _repository.cancelPaymentAtomically(
        paymentId,
        referenceTodayIso: referenceTodayIso,
      );
}
