import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import 'dtos/account_response_dto.dart';

final accountRepositoryProvider = Provider<AccountRepository>(
  (ref) => AccountRepository(ref.read(apiClientProvider).dio),
);

class AccountRepository {
  const AccountRepository(this._dio);

  final Dio _dio;

  Future<List<AccountResponseDto>> getAccounts() async {
    final response = await _dio.get(ApiEndpoints.accounts);
    return (response.data as List)
        .map((e) => AccountResponseDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
