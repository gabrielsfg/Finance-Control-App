/// Generic wrapper for paginated API responses.
class PagedResponse<T> {
  const PagedResponse({
    required this.currentPage,
    required this.totalPages,
    required this.pageSize,
    required this.rowCount,
    required this.totalItems,
    required this.items,
  });

  final int currentPage;
  final int totalPages;
  final int pageSize;
  final int rowCount;
  final int totalItems;
  final List<T> items;

  bool get hasNextPage => currentPage < totalPages;

  factory PagedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return PagedResponse(
      currentPage: json['currentPage'] as int,
      totalPages: json['totalPages'] as int,
      pageSize: json['pageSize'] as int,
      rowCount: json['rowCount'] as int,
      totalItems: json['totalItems'] as int,
      items: (json['items'] as List)
          .map((e) => fromJsonT(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
