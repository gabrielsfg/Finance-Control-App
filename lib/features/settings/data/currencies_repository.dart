import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';

final currenciesRepositoryProvider = Provider<CurrenciesRepository>(
  (ref) => CurrenciesRepository(ref.read(apiClientProvider).dio),
);

class CurrenciesRepository {
  const CurrenciesRepository(this._dio);

  final Dio _dio;

  /// Returns the list of all ISO 4217 currency codes supported by the backend.
  Future<List<String>> getCurrencies() async {
    final response = await _dio.get(ApiEndpoints.currencies);
    final data = response.data as Map<String, dynamic>;
    return (data['currencies'] as List).cast<String>();
  }
}
