import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/paged_response.dart';
import 'dtos/wishlist_dtos.dart';

class WishlistRepository {
  const WishlistRepository(this._dio);

  final Dio _dio;

  Future<PagedResponse<GetWishlistItemResponseDto>> getWishlistItems({
    int page = 1,
    int pageSize = 20,
    String orderBy = 'created_desc',
    int? status,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
      'orderBy': orderBy,
    };
    if (status != null) queryParams['status'] = status;

    final response = await _dio.get(
      ApiEndpoints.wishlist,
      queryParameters: queryParams,
    );
    return PagedResponse.fromJson(
      response.data as Map<String, dynamic>,
      GetWishlistItemResponseDto.fromJson,
    );
  }

  Future<GetWishlistItemByIdResponseDto> getWishlistItemById(int id) async {
    final response = await _dio.get(ApiEndpoints.wishlistById(id));
    return GetWishlistItemByIdResponseDto.fromJson(
        response.data as Map<String, dynamic>);
  }

  Future<GetWishlistItemByIdResponseDto> createWishlistItem(
    CreateWishlistItemRequestDto dto,
  ) async {
    final response = await _dio.post(
      ApiEndpoints.wishlist,
      data: dto.toJson(),
    );
    return GetWishlistItemByIdResponseDto.fromJson(
        response.data as Map<String, dynamic>);
  }

  Future<GetWishlistItemByIdResponseDto> updateWishlistItem(
    int id,
    UpdateWishlistItemRequestDto dto,
  ) async {
    final response = await _dio.patch(
      ApiEndpoints.wishlistById(id),
      data: dto.toJson(),
    );
    return GetWishlistItemByIdResponseDto.fromJson(
        response.data as Map<String, dynamic>);
  }

  Future<void> deleteWishlistItem(int id) async {
    await _dio.delete(ApiEndpoints.wishlistById(id));
  }

  Future<WishlistPriceHistoryResponseDto> registerPrice(
    int id,
    RegisterWishlistPriceRequestDto dto,
  ) async {
    final response = await _dio.post(
      ApiEndpoints.wishlistPrice(id),
      data: dto.toJson(),
    );
    return WishlistPriceHistoryResponseDto.fromJson(
        response.data as Map<String, dynamic>);
  }

  Future<GetWishlistItemByIdResponseDto> purchaseItem(
    int id,
    PurchaseWishlistItemRequestDto dto,
  ) async {
    final response = await _dio.post(
      ApiEndpoints.wishlistPurchase(id),
      data: dto.toJson(),
    );
    return GetWishlistItemByIdResponseDto.fromJson(
        response.data as Map<String, dynamic>);
  }

  Future<List<WishlistPriceHistoryResponseDto>> getPriceHistory(int id) async {
    final response = await _dio.get(ApiEndpoints.wishlistPriceHistory(id));
    return (response.data as List)
        .map((e) =>
            WishlistPriceHistoryResponseDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final wishlistRepositoryProvider = Provider<WishlistRepository>((ref) {
  return WishlistRepository(ref.read(apiClientProvider).dio);
});
