import '../../domain/entities/invoice_entity.dart';

class InvoiceModel extends InvoiceEntity {
  const InvoiceModel({
    required super.id,
    required super.contractId,
    required super.billingMonth,
    required super.dueDate,
    required super.baseRent,
    required super.servicesTotal,
    required super.totalAmount,
    required super.paidAmount,
    required super.remainingAmount,
    required super.status,
    required super.createdAt,
  });

  factory InvoiceModel.fromMap(Map<String, dynamic> map) {
    return InvoiceModel(
      id: map['id'] as int,
      contractId: map['contract_id'] as int,
      billingMonth: map['billing_month'] as String,
      dueDate: map['due_date'] as String,
      baseRent: map['base_rent'] as num,
      servicesTotal: map['services_total'] as num,
      totalAmount: map['total_amount'] as num,
      paidAmount: map['paid_amount'] as num,
      remainingAmount: map['remaining_amount'] as num,
      status: map['status'] as String,
      createdAt: map['created_at'] as String,
    );
  }

  Map<String, dynamic> toMap({bool includeId = true}) {
    return {
      if (includeId && id > 0) 'id': id,
      'contract_id': contractId,
      'billing_month': billingMonth,
      'due_date': dueDate,
      'base_rent': baseRent.round(),
      'services_total': servicesTotal.round(),
      'total_amount': totalAmount.round(),
      'paid_amount': paidAmount.round(),
      'remaining_amount': remainingAmount.round(),
      'status': status,
      'created_at': createdAt,
    };
  }
}
