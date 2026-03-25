import '../dtos/wishlist_dtos.dart';
import '../enums/wishlist_enums.dart';

class WishlistItem {
  const WishlistItem({
    required this.id,
    required this.name,
    required this.currentPriceCents,
    required this.priority,
    required this.status,
    required this.createdAt,
    this.imageUrl,
    this.targetPriceCents,
    this.deadline,
  });

  final int id;
  final String name;
  final String? imageUrl;

  /// Current price in cents.
  final int currentPriceCents;

  /// Target price in cents (optional).
  final int? targetPriceCents;

  final WishlistPriority priority;

  /// Parsed from "YYYY-MM-DD".
  final DateTime? deadline;

  final WishlistStatus status;
  final DateTime createdAt;

  factory WishlistItem.fromDto(GetWishlistItemResponseDto dto) {
    return WishlistItem(
      id: dto.id,
      name: dto.name,
      imageUrl: dto.imageUrl,
      currentPriceCents: dto.currentPrice,
      targetPriceCents: dto.targetPrice,
      priority: WishlistPriorityExtension.fromInt(dto.priority),
      deadline:
          dto.deadline != null ? DateTime.tryParse(dto.deadline!) : null,
      status: WishlistStatusExtension.fromInt(dto.status),
      createdAt: dto.createdAt,
    );
  }
}

class WishlistItemDetail {
  const WishlistItemDetail({
    required this.id,
    required this.name,
    required this.currentPriceCents,
    required this.priority,
    required this.status,
    required this.createdAt,
    required this.links,
    this.imageUrl,
    this.targetPriceCents,
    this.deadline,
    this.purchasedTransactionId,
    this.minPriceCents,
    this.maxPriceCents,
  });

  final int id;
  final String name;
  final String? imageUrl;
  final int currentPriceCents;
  final int? targetPriceCents;
  final WishlistPriority priority;
  final DateTime? deadline;
  final WishlistStatus status;
  final DateTime createdAt;
  final int? purchasedTransactionId;
  final int? minPriceCents;
  final int? maxPriceCents;
  final List<WishlistItemLink> links;

  factory WishlistItemDetail.fromDto(GetWishlistItemByIdResponseDto dto) {
    return WishlistItemDetail(
      id: dto.id,
      name: dto.name,
      imageUrl: dto.imageUrl,
      currentPriceCents: dto.currentPrice,
      targetPriceCents: dto.targetPrice,
      priority: WishlistPriorityExtension.fromInt(dto.priority),
      deadline:
          dto.deadline != null ? DateTime.tryParse(dto.deadline!) : null,
      status: WishlistStatusExtension.fromInt(dto.status),
      createdAt: dto.createdAt,
      purchasedTransactionId: dto.purchasedTransactionId,
      minPriceCents: dto.minPrice,
      maxPriceCents: dto.maxPrice,
      links: dto.links
          .map((l) => WishlistItemLink(
                id: l.id,
                url: l.url,
                storeName: l.storeName,
              ))
          .toList(),
    );
  }

  WishlistItem toWishlistItem() => WishlistItem(
        id: id,
        name: name,
        imageUrl: imageUrl,
        currentPriceCents: currentPriceCents,
        targetPriceCents: targetPriceCents,
        priority: priority,
        deadline: deadline,
        status: status,
        createdAt: createdAt,
      );
}

class WishlistItemLink {
  const WishlistItemLink({
    required this.id,
    required this.url,
    this.storeName,
  });

  final int id;
  final String url;
  final String? storeName;
}

class WishlistPriceHistory {
  const WishlistPriceHistory({
    required this.id,
    required this.priceCents,
    required this.recordedAt,
  });

  final int id;

  /// Price in cents.
  final int priceCents;

  final DateTime recordedAt;

  factory WishlistPriceHistory.fromDto(WishlistPriceHistoryResponseDto dto) {
    return WishlistPriceHistory(
      id: dto.id,
      priceCents: dto.price,
      recordedAt: dto.recordedAt,
    );
  }
}
