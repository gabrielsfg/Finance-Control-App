import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';

final paymentMethodsRepositoryProvider = Provider<PaymentMethodsRepository>(
  (ref) => PaymentMethodsRepository(ref.read(apiClientProvider).dio),
);

class PaymentMethodsRepository {
  const PaymentMethodsRepository(this._dio);

  final Dio _dio;

  /// Returns available payment method strings for [country].
  /// If [country] is null the backend uses the authenticated user's country.
  Future<List<String>> getPaymentMethods({String? country}) async {
    final response = await _dio.get(
      ApiEndpoints.paymentMethods,
      queryParameters: country != null ? {'country': country} : null,
    );
    final data = response.data as Map<String, dynamic>;
    return (data['paymentMethods'] as List).cast<String>();
  }
}
