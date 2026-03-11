import '../dtos/allocation_response_dto.dart';
import '../dtos/budget_response_dto.dart';

// ── Subcategory allocation ────────────────────────────────────────────────

class BudgetSubcategory {
  final int allocationId;
  final int id;
  final String name;
  final int allocatedCents;
  final int spentCents;
  final String allocationType;

  const BudgetSubcategory({
    required this.allocationId,
    required this.id,
    required this.name,
    required this.allocatedCents,
    required this.allocationType,
    this.spentCents = 0,
  });

  bool get isExpense => allocationType == 'Expense';

  double get spentPercent =>
      allocatedCents > 0 ? (spentCents / allocatedCents).clamp(0.0, 2.0) : 0.0;
}

// ── Category inside an area ───────────────────────────────────────────────

class BudgetCategory {
  final int id;
  final String name;
  final List<BudgetSubcategory> subcategories;

  const BudgetCategory({
    required this.id,
    required this.name,
    required this.subcategories,
  });

  int get allocatedCents =>
      subcategories.fold(0, (sum, s) => sum + s.allocatedCents);

  int get spentCents =>
      subcategories.fold(0, (sum, s) => sum + s.spentCents);

  double get spentPercent =>
      allocatedCents > 0 ? (spentCents / allocatedCents).clamp(0.0, 2.0) : 0.0;
}

// ── Area inside a budget ──────────────────────────────────────────────────

class BudgetArea {
  final int id;
  final String name;
  final List<BudgetCategory> categories;

  const BudgetArea({
    required this.id,
    required this.name,
    required this.categories,
  });

  int get allocatedCents =>
      categories.fold(0, (sum, c) => sum + c.allocatedCents);

  int get spentCents =>
      categories.fold(0, (sum, c) => sum + c.spentCents);

  double get spentPercent =>
      allocatedCents > 0 ? (spentCents / allocatedCents).clamp(0.0, 2.0) : 0.0;
}

// ── Budget (top-level) ────────────────────────────────────────────────────

class Budget {
  final int id;
  final String name;
  final String recurrence;
  final DateTime startDate;
  final DateTime endDate;
  final List<BudgetArea> areas;

  const Budget({
    required this.id,
    required this.name,
    required this.recurrence,
    required this.startDate,
    required this.endDate,
    required this.areas,
  });

  int get totalAllocatedCents =>
      areas.fold(0, (sum, a) => sum + a.allocatedCents);

  int get totalSpentCents =>
      areas.fold(0, (sum, a) => sum + a.spentCents);

  double get overallPercent => totalAllocatedCents > 0
      ? (totalSpentCents / totalAllocatedCents).clamp(0.0, 2.0)
      : 0.0;

  static Budget fromDtos({
    required GetBudgetByIdResponseDto budgetDto,
    required List<AllocationByAreaResponseDto> allocationDtos,
  }) {
    final areas = allocationDtos.map((areaDto) {
      final categories = areaDto.categories.map((catDto) {
        final subcategories = catDto.subCategories.map((subDto) {
          return BudgetSubcategory(
            allocationId: subDto.allocationId,
            id: subDto.subCategoryId,
            name: subDto.subCategoryName,
            allocatedCents: subDto.subCategoryExpectedValue,
            allocationType: subDto.allocationType,
          );
        }).toList();
        return BudgetCategory(
          id: catDto.categoryId,
          name: catDto.categoryName,
          subcategories: subcategories,
        );
      }).toList();
      return BudgetArea(
        id: areaDto.areaId,
        name: areaDto.areaName,
        categories: categories,
      );
    }).toList();

    return Budget(
      id: budgetDto.id,
      name: budgetDto.name,
      recurrence: budgetDto.recurrence,
      startDate: DateTime.parse(budgetDto.startDate),
      endDate: DateTime.parse(budgetDto.finishDate),
      areas: areas,
    );
  }
}

// ── Budget summary (from list endpoint) ──────────────────────────────────

class BudgetSummary {
  final int id;
  final String name;
  final String recurrence;

  const BudgetSummary({
    required this.id,
    required this.name,
    required this.recurrence,
  });

  static BudgetSummary fromDto(GetAllBudgetResponseDto dto) => BudgetSummary(
        id: dto.id,
        name: dto.name,
        recurrence: dto.recurrence,
      );
}

// ── Draft models used during the creation wizard ─────────────────────────

class DraftSubcategory {
  final int id;
  final String name;
  final String categoryName;
  int allocatedCents;
  String allocationType;

  DraftSubcategory({
    required this.id,
    required this.name,
    required this.categoryName,
    this.allocatedCents = 0,
    this.allocationType = 'Expense',
  });
}

class DraftArea {
  final String name;
  final List<DraftSubcategory> subcategories;

  DraftArea({required this.name, required this.subcategories});

  int get totalAllocatedCents =>
      subcategories.fold(0, (sum, s) => sum + s.allocatedCents);

  int get totalIncomeCents => subcategories
      .where((s) => s.allocationType == 'Income')
      .fold(0, (sum, s) => sum + s.allocatedCents);

  int get totalExpenseCents => subcategories
      .where((s) => s.allocationType == 'Expense')
      .fold(0, (sum, s) => sum + s.allocatedCents);

  int get balanceCents => totalIncomeCents - totalExpenseCents;
}
