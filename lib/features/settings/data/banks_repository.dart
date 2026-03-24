import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';

class BankDto {
  const BankDto({
    required this.id,
    required this.name,
    required this.country,
    this.code,
  });

  final int id;
  final String name;
  final String country;
  final String? code;

  factory BankDto.fromJson(Map<String, dynamic> json) => BankDto(
        id: json['id'] as int,
        name: json['name'] as String,
        country: json['country'] as String,
        code: json['code'] as String?,
      );
}

final banksRepositoryProvider = Provider<BanksRepository>(
  (ref) => BanksRepository(ref.read(apiClientProvider).dio),
);

class BanksRepository {
  const BanksRepository(this._dio);

  final Dio _dio;

  /// Returns banks, optionally filtered by [country] ISO 2-letter code.
  Future<List<BankDto>> getBanks({String? country}) async {
    final response = await _dio.get(
      ApiEndpoints.banks,
      queryParameters: country != null ? {'country': country} : null,
    );
    return (response.data as List)
        .map((e) => BankDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
