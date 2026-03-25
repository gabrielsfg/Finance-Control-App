import '../dtos/account_response_dto.dart';

// Matches backend EnumAccountType: Checking, Savings, Credit, Cash
enum AccountType { checking, savings, credit, cash }

extension AccountTypeX on AccountType {
  String get apiValue => switch (this) {
        AccountType.checking => 'Checking',
        AccountType.savings => 'Savings',
        AccountType.credit => 'Credit',
        AccountType.cash => 'Cash',
      };

  String get label => switch (this) {
        AccountType.checking => 'Checking',
        AccountType.savings => 'Savings',
        AccountType.credit => 'Credit Card',
        AccountType.cash => 'Cash',
      };

  static AccountType fromApi(String value) => switch (value) {
        'Savings' => AccountType.savings,
        'Credit' => AccountType.credit,
        'Cash' => AccountType.cash,
        _ => AccountType.checking,
      };
}

class Account {
  const Account({
    required this.id,
    required this.name,
    required this.accountType,
    required this.balanceCents,
    required this.isDefault,
    required this.isExcludedFromNetWorth,
    this.billingDueDay,
    this.creditLimitCents,
  });

  final int id;
  final String name;
  final AccountType accountType;
  final int balanceCents;
  final bool isDefault;
  final bool isExcludedFromNetWorth;
  final int? billingDueDay;
  final int? creditLimitCents;

  bool get isCredit => accountType == AccountType.credit;

  factory Account.fromDto(GetAccountItemResponseDto dto) => Account(
        id: dto.id,
        name: dto.name,
        accountType: AccountTypeX.fromApi(dto.accountType),
        balanceCents: dto.currentAmount,
        isDefault: dto.isDefaultAccount,
        isExcludedFromNetWorth: dto.isExcludedFromNetWorth,
        billingDueDay: dto.billingDueDay,
        creditLimitCents: dto.creditLimit,
      );
}
