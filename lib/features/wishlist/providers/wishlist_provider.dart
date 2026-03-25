import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/enums/wishlist_enums.dart';
import '../data/models/wishlist_item.dart';
import '../data/wishlist_repository.dart';

// ── Wishlist State ────────────────────────────────────────────────────────────

class WishlistState {
  const WishlistState({
    required this.items,
    required this.page,
    required this.hasNextPage,
    required this.isLoadingMore,
    required this.orderBy,
    this.statusFilter,
  });

  final List<WishlistItem> items;
  final int page;
  final bool hasNextPage;
  final bool isLoadingMore;
  final String orderBy;
  final WishlistStatus? statusFilter;

  WishlistState copyWith({
    List<WishlistItem>? items,
    int? page,
    bool? hasNextPage,
    bool? isLoadingMore,
    String? orderBy,
    WishlistStatus? Function()? statusFilter,
  }) {
    return WishlistState(
      items: items ?? this.items,
      page: page ?? this.page,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      orderBy: orderBy ?? this.orderBy,
      statusFilter:
          statusFilter != null ? statusFilter() : this.statusFilter,
    );
  }
}

// ── Wishlist Notifier ─────────────────────────────────────────────────────────

class WishlistNotifier extends AsyncNotifier<WishlistState> {
  static const int _pageSize = 20;

  @override
  Future<WishlistState> build() async {
    return _fetchPage(
      page: 1,
      orderBy: 'created_desc',
      statusFilter: WishlistStatus.active,
      existing: [],
    );
  }

  Future<WishlistState> _fetchPage({
    required int page,
    required String orderBy,
    required WishlistStatus? statusFilter,
    required List<WishlistItem> existing,
  }) async {
    final paged = await ref.read(wishlistRepositoryProvider).getWishlistItems(
          page: page,
          pageSize: _pageSize,
          orderBy: orderBy,
          status: statusFilter?.toInt(),
        );

    final newItems = paged.items.map(WishlistItem.fromDto).toList();
    return WishlistState(
      items: [...existing, ...newItems],
      page: paged.currentPage,
      hasNextPage: paged.hasNextPage,
      isLoadingMore: false,
      orderBy: orderBy,
      statusFilter: statusFilter,
    );
  }

  Future<void> loadNextPage() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasNextPage || current.isLoadingMore) {
      return;
    }
    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final paged = await ref.read(wishlistRepositoryProvider).getWishlistItems(
            page: current.page + 1,
            pageSize: _pageSize,
            orderBy: current.orderBy,
            status: current.statusFilter?.toInt(),
          );
      final newItems = paged.items.map(WishlistItem.fromDto).toList();
      state = AsyncData(current.copyWith(
        items: [...current.items, ...newItems],
        page: paged.currentPage,
        hasNextPage: paged.hasNextPage,
        isLoadingMore: false,
      ));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> refresh() async {
    final current = state.valueOrNull;
    final orderBy = current?.orderBy ?? 'created_desc';
    final statusFilter = current?.statusFilter ?? WishlistStatus.active;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchPage(
          page: 1,
          orderBy: orderBy,
          statusFilter: statusFilter,
          existing: [],
        ));
  }

  Future<void> setOrderBy(String orderBy) async {
    final current = state.valueOrNull;
    final statusFilter = current?.statusFilter ?? WishlistStatus.active;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchPage(
          page: 1,
          orderBy: orderBy,
          statusFilter: statusFilter,
          existing: [],
        ));
  }

  Future<void> setStatusFilter(WishlistStatus? statusFilter) async {
    final current = state.valueOrNull;
    final orderBy = current?.orderBy ?? 'created_desc';
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchPage(
          page: 1,
          orderBy: orderBy,
          statusFilter: statusFilter,
          existing: [],
        ));
  }

  Future<void> deleteItem(int id) async {
    await ref.read(wishlistRepositoryProvider).deleteWishlistItem(id);
    await refresh();
  }

  void invalidateDetail(int id) {
    ref.invalidate(wishlistItemDetailProvider(id));
    ref.invalidate(wishlistPriceHistoryProvider(id));
  }
}

final wishlistNotifierProvider =
    AsyncNotifierProvider<WishlistNotifier, WishlistState>(
  WishlistNotifier.new,
);

// ── Detail Provider ───────────────────────────────────────────────────────────

final wishlistItemDetailProvider =
    FutureProvider.family<WishlistItemDetail, int>((ref, id) async {
  final dto =
      await ref.read(wishlistRepositoryProvider).getWishlistItemById(id);
  return WishlistItemDetail.fromDto(dto);
});

// ── Price History Provider ────────────────────────────────────────────────────

final wishlistPriceHistoryProvider =
    FutureProvider.family<List<WishlistPriceHistory>, int>((ref, id) async {
  final dtos = await ref.read(wishlistRepositoryProvider).getPriceHistory(id);
  return dtos.map(WishlistPriceHistory.fromDto).toList();
});
