import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../data/budget_repository.dart';
import '../data/dtos/allocation_request_dto.dart';
import '../data/dtos/create_budget_request_dto.dart';
import '../data/models/budget_models.dart';

// ── Active budget provider ────────────────────────────────────────────────────
//
// Loads the most recently created budget (first in the list) as the active one.
// Returns null when there are no budgets.

class BudgetNotifier extends AsyncNotifier<Budget?> {
  @override
  Future<Budget?> build() async {
    final authState = await ref.watch(authNotifierProvider.future);
    if (!authState.isAuthenticated || authState.accessToken == null) {
      return null;
    }
    return _fetchActive();
  }

  Future<Budget?> _fetchActive() async {
    final repo = ref.read(budgetRepositoryProvider);
    final summaries = await repo.getAllBudgets();
    if (summaries.isEmpty) return null;

    // Use the first budget in the list as the active one
    final id = summaries.first.id;
    final budgetDto = await repo.getBudgetById(id);
    final allocationDtos = await repo.getAllocations(id);

    return Budget.fromDtos(
      budgetDto: budgetDto,
      allocationDtos: allocationDtos,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchActive);
  }

  /// Creates a new budget and posts all area+allocation data from the wizard.
  Future<void> createBudget({
    required String name,
    required String recurrence,
    required int startDay,
    required List<DraftArea> areas,
  }) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(budgetRepositoryProvider);

      // 1. Create the budget
      final budgetDto = await repo.createBudget(
        CreateBudgetRequestDto(
          name: name,
          startDate: startDay,
          recurrence: recurrence,
          isActive: true,
        ),
      );

      // 2. For each draft area: create the area, then post each allocation
      for (final draftArea in areas) {
        final areaDto = await repo.createArea(budgetDto.id, draftArea.name);

        for (final draftSub in draftArea.subcategories) {
          if (draftSub.allocatedCents <= 0) continue;
          await repo.createAllocation(
            budgetDto.id,
            CreateAllocationRequestDto(
              areaId: areaDto.id,
              subCategoryId: draftSub.id,
              expectedValue: draftSub.allocatedCents,
              allocationType: draftSub.allocationType,
            ),
          );
        }
      }

      // 3. Reload the full budget with allocations
      final allocationDtos = await repo.getAllocations(budgetDto.id);
      state = AsyncData(Budget.fromDtos(
        budgetDto: budgetDto,
        allocationDtos: allocationDtos,
      ));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> deleteBudget(int id) async {
    state = const AsyncLoading();
    await ref.read(budgetRepositoryProvider).deleteBudget(id);
    state = await AsyncValue.guard(_fetchActive);
  }
}

final budgetNotifierProvider =
    AsyncNotifierProvider<BudgetNotifier, Budget?>(BudgetNotifier.new);

