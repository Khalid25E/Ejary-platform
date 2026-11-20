import '../../domain/entities/payment_entity.dart';

class PaymentModel extends PaymentEntity {
  const PaymentModel({
    required super.id,
    required super.contractId,
    required super.invoiceId,
    required super.type,
    required super.payAt,
    required super.amount,
    required super.payMethod,
    required super.payRef,
    required super.billingMonth,
    required super.notes,
    required super.createdAt,
    super.isCancelled = false,
  });

  factory PaymentModel.fromMap(Map<String, dynamic> map) {
    return PaymentModel(
      id: map['id'] as int,
      contractId: map['contract_id'] as int,
      invoiceId: map['invoice_id'] as int,
      type: map['type'] as String,
      payAt: map['pay_at'] as String,
      amount: map['amount'] as num,
      payMethod: map['pay_method'] as String,
      payRef: (map['pay_ref'] as String?) ?? '',
      billingMonth: map['billing_month'] as String,
      notes: (map['notes'] as String?) ?? '',
      createdAt: map['created_at'] as String,
      isCancelled: (map['is_cancelled'] as int) == 1,
    );
  }

  Map<String, dynamic> toMap({bool includeId = true}) {
    return {
      if (includeId && id > 0) 'id': id,
      'contract_id': contractId,
      'invoice_id': invoiceId,
      'type': type,
      'pay_at': payAt,
      'amount': amount.round(),
      'pay_method': payMethod,
      'pay_ref': payRef,
      'billing_month': billingMonth,
      'notes': notes,
      'created_at': createdAt,
      'is_cancelled': isCancelled ? 1 : 0,
    };
  }
}
