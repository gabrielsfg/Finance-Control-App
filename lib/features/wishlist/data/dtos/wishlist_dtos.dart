import 'package:json_annotation/json_annotation.dart';

part 'wishlist_dtos.g.dart';

// ── Response DTOs ─────────────────────────────────────────────────────────────

@JsonSerializable(createToJson: false)
class GetWishlistItemResponseDto {
  const GetWishlistItemResponseDto({
    required this.id,
    required this.name,
    required this.currentPrice,
    required this.priority,
    required this.status,
    required this.createdAt,
    this.imageUrl,
    this.targetPrice,
    this.deadline,
  });

  final int id;
  final String name;
  final String? imageUrl;

  /// Current price in cents.
  final int currentPrice;

  /// Target price in cents (optional).
  final int? targetPrice;

  /// 0 = Low, 1 = Medium, 2 = High
  final int priority;

  /// Format: "YYYY-MM-DD" (optional)
  final String? deadline;

  /// 0 = Active, 1 = Purchased, 2 = Archived
  final int status;

  final DateTime createdAt;

  factory GetWishlistItemResponseDto.fromJson(Map<String, dynamic> json) =>
      _$GetWishlistItemResponseDtoFromJson(json);
}

@JsonSerializable(createToJson: false)
class GetWishlistItemByIdResponseDto {
  const GetWishlistItemByIdResponseDto({
    required this.id,
    required this.name,
    required this.currentPrice,
    required this.priority,
    required this.status,
    required this.createdAt,
    required this.links,
    this.imageUrl,
    this.targetPrice,
    this.deadline,
    this.purchasedTransactionId,
    this.minPrice,
    this.maxPrice,
  });

  final int id;
  final String name;
  final String? imageUrl;
  final int currentPrice;
  final int? targetPrice;
  final int priority;
  final String? deadline;
  final int status;
  final int? purchasedTransactionId;
  final DateTime createdAt;
  final int? minPrice;
  final int? maxPrice;
  final List<WishlistItemLinkDto> links;

  factory GetWishlistItemByIdResponseDto.fromJson(Map<String, dynamic> json) =>
      _$GetWishlistItemByIdResponseDtoFromJson(json);
}

@JsonSerializable(createToJson: false)
class WishlistItemLinkDto {
  const WishlistItemLinkDto({
    required this.id,
    required this.url,
    this.storeName,
  });

  final int id;
  final String url;
  final String? storeName;

  factory WishlistItemLinkDto.fromJson(Map<String, dynamic> json) =>
      _$WishlistItemLinkDtoFromJson(json);
}

@JsonSerializable(createToJson: false)
class WishlistPriceHistoryResponseDto {
  const WishlistPriceHistoryResponseDto({
    required this.id,
    required this.price,
    required this.recordedAt,
  });

  final int id;

  /// Price in cents.
  final int price;

  final DateTime recordedAt;

  factory WishlistPriceHistoryResponseDto.fromJson(
          Map<String, dynamic> json) =>
      _$WishlistPriceHistoryResponseDtoFromJson(json);
}

// ── Request DTOs ──────────────────────────────────────────────────────────────

@JsonSerializable(createFactory: false)
class CreateWishlistItemRequestDto {
  const CreateWishlistItemRequestDto({
    required this.name,
    required this.currentPrice,
    required this.priority,
    required this.links,
    this.imageUrl,
    this.targetPrice,
    this.deadline,
  });

  final String name;
  final String? imageUrl;

  /// In cents.
  final int currentPrice;

  /// In cents (optional).
  final int? targetPrice;

  /// 0 = Low, 1 = Medium, 2 = High
  final int priority;

  /// Format: "YYYY-MM-DD" (optional)
  final String? deadline;

  final List<CreateWishlistLinkDto> links;

  Map<String, dynamic> toJson() => _$CreateWishlistItemRequestDtoToJson(this);
}

@JsonSerializable(createFactory: false)
class CreateWishlistLinkDto {
  const CreateWishlistLinkDto({
    required this.url,
    this.storeName,
  });

  final String url;
  final String? storeName;

  Map<String, dynamic> toJson() => _$CreateWishlistLinkDtoToJson(this);
}

@JsonSerializable(createFactory: false, includeIfNull: false)
class UpdateWishlistItemRequestDto {
  const UpdateWishlistItemRequestDto({
    this.name,
    this.imageUrl,
    this.targetPrice,
    this.priority,
    this.deadline,
  });

  final String? name;
  final String? imageUrl;

  /// In cents (optional).
  final int? targetPrice;

  /// 0 = Low, 1 = Medium, 2 = High (optional)
  final int? priority;

  /// Format: "YYYY-MM-DD" (optional)
  final String? deadline;

  Map<String, dynamic> toJson() => _$UpdateWishlistItemRequestDtoToJson(this);
}

@JsonSerializable(createFactory: false)
class RegisterWishlistPriceRequestDto {
  const RegisterWishlistPriceRequestDto({required this.price});

  /// In cents.
  final int price;

  Map<String, dynamic> toJson() =>
      _$RegisterWishlistPriceRequestDtoToJson(this);
}

@JsonSerializable(createFactory: false, includeIfNull: false)
class PurchaseWishlistItemRequestDto {
  const PurchaseWishlistItemRequestDto({
    required this.createTransaction,
    this.accountId,
    this.subCategoryId,
    this.transactionDate,
    this.description,
  });

  final bool createTransaction;
  final int? accountId;
  final int? subCategoryId;

  /// Format: "YYYY-MM-DD" (optional)
  final String? transactionDate;

  final String? description;

  Map<String, dynamic> toJson() =>
      _$PurchaseWishlistItemRequestDtoToJson(this);
}
