import 'account.dart';
import '../dtos/get_account_by_id_response_dto.dart';

class RecentTransaction {
  const RecentTransaction({
    required this.id,
    required this.description,
    required this.valueCents,
    required this.type,
    required this.subCategoryName,
    required this.categoryName,
  });

  final int id;
  final String? description;
  final int valueCents;
  final String type;
  final String subCategoryName;
  final String categoryName;

  bool get isExpense => type == 'Expense';

  factory RecentTransaction.fromDto(RecentTransactionDto dto) =>
      RecentTransaction(
        id: dto.id,
        description: dto.description,
        valueCents: dto.value,
        type: dto.type,
        subCategoryName: dto.subCategoryName,
        categoryName: dto.categoryName,
      );
}

class AccountDetail {
  const AccountDetail({
    required this.id,
    required this.name,
    required this.accountType,
    required this.balanceCents,
    required this.isDefault,
    required this.excludeFromNetWorth,
    this.goalAmountCents,
    this.billingDueDay,
    this.creditLimitCents,
    required this.recentTransactions,
  });

  final int id;
  final String name;
  final AccountType accountType;
  final int balanceCents;
  final bool isDefault;
  final bool excludeFromNetWorth;
  final int? goalAmountCents;
  final int? billingDueDay;
  final int? creditLimitCents;
  final List<RecentTransaction> recentTransactions;

  bool get isCredit => accountType == AccountType.credit;

  factory AccountDetail.fromDto(GetAccountByIdResponseDto dto) => AccountDetail(
        id: dto.id,
        name: dto.name,
        accountType: AccountTypeX.fromApi(dto.accountType),
        balanceCents: dto.currentAmount,
        isDefault: dto.isDefaultAccount,
        excludeFromNetWorth: dto.isExcludedFromNetWorth,
        goalAmountCents: dto.goalAmount,
        billingDueDay: dto.billingDueDay,
        creditLimitCents: dto.creditLimit,
        recentTransactions:
            dto.recentTransactions.map(RecentTransaction.fromDto).toList(),
      );
}
