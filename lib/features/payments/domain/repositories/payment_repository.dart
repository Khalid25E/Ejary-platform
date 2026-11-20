import '../entities/payment_entity.dart';

abstract class PaymentRepository {
  Future<List<PaymentEntity>> getAllPayments({
    int? invoiceId,
    int? contractId,
  });
  Future<PaymentEntity?> getPaymentById(int id);

  /// Records a full or partial payment inside a SQLite Transaction and updates
  /// the linked invoice's paidAmount, remainingAmount, and status atomically.
  Future<int> recordPaymentAtomically(
    PaymentEntity payment, {
    String? referenceTodayIso,
  });

  /// Cancels a payment (keeping its audit record with isCancelled=true) and
  /// recalculates the linked invoice's paidAmount, remainingAmount, and status.
  Future<void> cancelPaymentAtomically(
    int paymentId, {
    String? referenceTodayIso,
  });
}
