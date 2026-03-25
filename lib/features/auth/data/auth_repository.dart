import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import 'dtos/auth_response_dto.dart';
import 'dtos/login_request_dto.dart';
import 'dtos/register_request_dto.dart';
import 'dtos/update_profile_request_dto.dart';
import 'dtos/user_profile_response_dto.dart';
import 'models/user_profile.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.read(apiClientProvider).dio),
);

class AuthRepository {
  const AuthRepository(this._dio);

  final Dio _dio;

  Future<AuthResponseDto> login(LoginRequestDto dto) async {
    final response = await _dio.post(
      ApiEndpoints.login,
      data: dto.toJson(),
    );
    return AuthResponseDto.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AuthResponseDto> register(RegisterRequestDto dto) async {
    final response = await _dio.post(
      ApiEndpoints.register,
      data: dto.toJson(),
    );
    return AuthResponseDto.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> logout(String refreshToken) async {
    await _dio.post(
      ApiEndpoints.logout,
      data: {'refreshToken': refreshToken},
    );
  }

  Future<void> forgotPassword(String email) async {
    await _dio.post(
      ApiEndpoints.forgotPassword,
      data: {'email': email},
    );
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    await _dio.post(
      ApiEndpoints.resetPassword,
      data: {'token': token, 'newPassword': newPassword},
    );
  }

  Future<void> verifyEmail(String token) async {
    await _dio.post(
      ApiEndpoints.verifyEmail,
      data: {'token': token},
    );
  }

  Future<UserProfile> getProfile() async {
    final response = await _dio.get(ApiEndpoints.userMe);
    return UserProfile.fromDto(
      UserProfileResponseDto.fromJson(response.data as Map<String, dynamic>),
    );
  }

  Future<UserProfile> updateProfile(UpdateProfileRequestDto dto) async {
    final response = await _dio.patch(
      ApiEndpoints.userMe,
      data: dto.toJson(),
    );
    return UserProfile.fromDto(
      UserProfileResponseDto.fromJson(response.data as Map<String, dynamic>),
    );
  }

  Future<void> deleteAccount(String password) async {
    await _dio.delete(
      ApiEndpoints.userMe,
      data: {'password': password},
    );
  }

  Future<void> resetData(String password) async {
    await _dio.post(
      ApiEndpoints.resetData,
      data: {'password': password},
    );
  }
}
