import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/dtos/create_transaction_request_dto.dart';
import '../data/dtos/create_transaction_response_dto.dart';
import '../data/transaction_repository.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

sealed class CreateTransactionState {
  const CreateTransactionState();
}

class CreateTransactionIdle extends CreateTransactionState {
  const CreateTransactionIdle();
}

class CreateTransactionLoading extends CreateTransactionState {
  const CreateTransactionLoading();
}

class CreateTransactionSuccess extends CreateTransactionState {
  const CreateTransactionSuccess({required this.transactions});
  final List<TransactionDto> transactions;
}

class CreateTransactionError extends CreateTransactionState {
  const CreateTransactionError({
    required this.message,
    this.fieldErrors = const {},
  });
  final String message;

  /// Maps field names to validation messages (from 400 responses).
  final Map<String, String> fieldErrors;
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class CreateTransactionNotifier
    extends Notifier<CreateTransactionState> {
  @override
  CreateTransactionState build() => const CreateTransactionIdle();

  Future<void> submit(CreateTransactionRequestDto dto) async {
    state = const CreateTransactionLoading();

    try {
      final result = await ref
          .read(transactionRepositoryProvider)
          .createTransaction(dto);
      state = CreateTransactionSuccess(transactions: result.transactions);
    } on DioException catch (e) {
      state = _mapDioError(e);
    } catch (_) {
      state = const CreateTransactionError(message: 'Unexpected error. Please try again.');
    }
  }

  void reset() => state = const CreateTransactionIdle();

  CreateTransactionError _mapDioError(DioException e) {
    final statusCode = e.response?.statusCode;

    if (statusCode == 400) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        final raw = data['errors'];
        if (raw is Map<String, dynamic>) {
          final fieldErrors = raw.map((key, value) {
            final messages = value is List ? value : [value.toString()];
            return MapEntry(key, messages.first.toString());
          });
          return CreateTransactionError(
            message: 'Please check the highlighted fields.',
            fieldErrors: fieldErrors,
          );
        }
      }
      return const CreateTransactionError(
        message: 'Invalid data. Please review the form.',
      );
    }

    if (statusCode == 404) {
      final data = e.response?.data;
      final errorMsg = data is Map<String, dynamic> ? data['error'] as String? : null;

      return switch (errorMsg) {
        'No active budget found.' => const CreateTransactionError(
            message:
                'You do not have an active budget. Disable the option or create a budget.',
          ),
        'Invalid parameters.' => const CreateTransactionError(
            message: 'Invalid account or subcategory.',
          ),
        'Invalid transaction type.' => const CreateTransactionError(
            message: 'Invalid transaction type.',
          ),
        'Invalid payment type.' => const CreateTransactionError(
            message: 'Invalid payment type.',
          ),
        _ => const CreateTransactionError(
            message: 'Resource not found.',
          ),
      };
    }

    if (statusCode != null && statusCode >= 500) {
      return const CreateTransactionError(
        message: 'Unexpected error. Please try again.',
      );
    }

    return const CreateTransactionError(
      message: 'Unexpected error. Please try again.',
    );
  }
}

final createTransactionProvider =
    NotifierProvider<CreateTransactionNotifier, CreateTransactionState>(
  CreateTransactionNotifier.new,
);
