import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../accounts/data/account_repository.dart';
import '../../accounts/data/dtos/account_response_dto.dart';
import '../data/categories_repository.dart';
import '../data/dtos/category_response_dto.dart';

final accountsProvider =
    FutureProvider<List<AccountResponseDto>>((ref) async {
  return ref.read(accountRepositoryProvider).getAccounts();
});

final categoriesProvider =
    FutureProvider<List<CategoryResponseDto>>((ref) async {
  return ref.read(categoriesRepositoryProvider).getCategories();
});
