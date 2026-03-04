import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import 'dtos/create_transaction_request_dto.dart';
import 'dtos/create_transaction_response_dto.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>(
  (ref) => TransactionRepository(ref.read(apiClientProvider).dio),
);

class TransactionRepository {
  const TransactionRepository(this._dio);

  final Dio _dio;

  Future<CreateTransactionResponseDto> createTransaction(
    CreateTransactionRequestDto dto,
  ) async {
    final response = await _dio.post(
      ApiEndpoints.transactions,
      data: dto.toJson(),
    );
    return CreateTransactionResponseDto.fromJson(
      response.data as Map<String, dynamic>,
    );
  }
}
