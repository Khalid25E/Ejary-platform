import '../../../contracts/domain/entities/contract_entity.dart';
import '../../../invoices/domain/entities/invoice_entity.dart';
import '../../../payments/domain/entities/payment_entity.dart';
import 'tenant_entity.dart';

class TenantLedgerEntry {
  final String date;
  final String type; // INVOICE or PAYMENT
  final String title;
  final num amount;
  final String status;
  final bool isDebit;
  final bool isCancelled;
  final int referenceId;

  const TenantLedgerEntry({
    required this.date,
    required this.type,
    required this.title,
    required this.amount,
    required this.status,
    required this.isDebit,
    this.isCancelled = false,
    required this.referenceId,
  });
}

class TenantStatementEntity {
  final TenantEntity tenant;
  final List<ContractEntity> contracts;
  final List<InvoiceEntity> invoices;
  final List<PaymentEntity> payments;
  final num totalBilled;
  final num totalPaid;
  final num totalOverdue;
  final num remainingBalance;
  final List<TenantLedgerEntry> ledger;

  const TenantStatementEntity({
    required this.tenant,
    required this.contracts,
    required this.invoices,
    required this.payments,
    required this.totalBilled,
    required this.totalPaid,
    required this.totalOverdue,
    required this.remainingBalance,
    required this.ledger,
  });
}
