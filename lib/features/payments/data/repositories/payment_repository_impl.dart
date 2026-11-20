import 'package:sqflite/sqflite.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_tables.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../../../invoices/data/models/invoice_model.dart';
import '../../domain/entities/payment_entity.dart';
import '../../domain/repositories/payment_repository.dart';
import '../models/payment_model.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final AppDatabase _appDb;

  PaymentRepositoryImpl(this._appDb);

  Database get _db => _appDb.db;

  @override
  Future<List<PaymentEntity>> getAllPayments({
    int? invoiceId,
    int? contractId,
  }) async {
    final whereClauses = <String>[];
    final args = <Object?>[];

    if (invoiceId != null && invoiceId > 0) {
      whereClauses.add('invoice_id = ?');
      args.add(invoiceId);
    }
    if (contractId != null && contractId > 0) {
      whereClauses.add('contract_id = ?');
      args.add(contractId);
    }

    final rows = await _db.query(
      DatabaseTables.payments,
      where: whereClauses.isEmpty ? null : whereClauses.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'pay_at DESC, id DESC',
    );
    return rows.map(PaymentModel.fromMap).toList();
  }

  @override
  Future<PaymentEntity?> getPaymentById(int id) async {
    final rows = await _db.query(
      DatabaseTables.payments,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return PaymentModel.fromMap(rows.first);
  }

  @override
  Future<int> recordPaymentAtomically(
    PaymentEntity payment, {
    String? referenceTodayIso,
  }) async {
    final amountInt = payment.amount.round();
    // FR-11 Rule 1: Do not accept zero or negative amounts
    if (amountInt <= 0) {
      throw const ValidationException(
        'Payment amount must be strictly greater than zero.',
      );
    }

    final todayIso =
        referenceTodayIso ?? DateTime.now().toIso8601String().substring(0, 10);

    return _db.transaction<int>((txn) async {
      final invRows = await txn.query(
        DatabaseTables.invoices,
        where: 'id = ?',
        whereArgs: [payment.invoiceId],
        limit: 1,
      );
      if (invRows.isEmpty) {
        throw const NotFoundException('Target invoice not found.');
      }
      final invoice = InvoiceModel.fromMap(invRows.first);

      // FR-11 Rule 2: Do not allow paying more than remaining balance
      if (amountInt > invoice.remainingAmount.round()) {
        throw const ValidationException(
          'Payment amount exceeds the remaining balance of the invoice.',
        );
      }

      final actualType =
          amountInt == invoice.remainingAmount.round() ? 'full' : 'partial';

      final payModel = PaymentModel(
        id: 0,
        contractId: invoice.contractId,
        invoiceId: invoice.id,
        type: actualType,
        payAt: payment.payAt,
        amount: amountInt,
        payMethod: payment.payMethod,
        payRef: payment.payRef.trim(),
        billingMonth: invoice.billingMonth,
        notes: payment.notes.trim(),
        createdAt: payment.createdAt,
        isCancelled: false,
      );

      final paymentId = await txn.insert(
        DatabaseTables.payments,
        payModel.toMap(includeId: false),
      );

      // FR-11 Rule 4 & 5 & 6: Recalculate invoice paid/remaining from non-cancelled payments atomically
      await _recalculateInvoiceInsideTxn(
        txn,
        invoiceId: invoice.id,
        todayIso: todayIso,
      );

      return paymentId;
    });
  }

  @override
  Future<void> cancelPaymentAtomically(
    int paymentId, {
    String? referenceTodayIso,
  }) async {
    final todayIso =
        referenceTodayIso ?? DateTime.now().toIso8601String().substring(0, 10);

    await _db.transaction((txn) async {
      final payRows = await txn.query(
        DatabaseTables.payments,
        where: 'id = ?',
        whereArgs: [paymentId],
        limit: 1,
      );
      if (payRows.isEmpty) {
        throw const NotFoundException('Payment record not found.');
      }
      final pay = PaymentModel.fromMap(payRows.first);

      // Mark payment as cancelled while keeping audit record
      await txn.update(
        DatabaseTables.payments,
        {'is_cancelled': 1},
        where: 'id = ?',
        whereArgs: [paymentId],
      );

      // Recalculate invoice excluding cancelled payment
      await _recalculateInvoiceInsideTxn(
        txn,
        invoiceId: pay.invoiceId,
        todayIso: todayIso,
      );
    });
  }

  static Future<void> _recalculateInvoiceInsideTxn(
    Transaction txn, {
    required int invoiceId,
    required String todayIso,
  }) async {
    final invRows = await txn.query(
      DatabaseTables.invoices,
      where: 'id = ?',
      whereArgs: [invoiceId],
      limit: 1,
    );
    if (invRows.isEmpty) return;
    final inv = InvoiceModel.fromMap(invRows.first);

    final sumRows = await txn.rawQuery('''
      SELECT COALESCE(SUM(amount), 0) AS total_paid
      FROM ${DatabaseTables.payments}
      WHERE invoice_id = ? AND is_cancelled = 0
    ''', [invoiceId]);

    final totalPaid = (sumRows.first['total_paid'] as num?)?.round() ?? 0;
    final totalAmount = inv.totalAmount.round();
    final remaining = (totalAmount - totalPaid).clamp(0, totalAmount);

    String newStatus;
    if (remaining == 0 && totalAmount > 0) {
      newStatus = 'Paid';
    } else if (totalPaid > 0 && remaining > 0) {
      newStatus = 'Partially Paid';
    } else if (inv.dueDate.compareTo(todayIso) < 0) {
      newStatus = 'Overdue';
    } else {
      newStatus = 'Pending';
    }

    await txn.update(
      DatabaseTables.invoices,
      {
        'paid_amount': totalPaid,
        'remaining_amount': remaining,
        'status': newStatus,
      },
      where: 'id = ?',
      whereArgs: [invoiceId],
    );
  }
}
