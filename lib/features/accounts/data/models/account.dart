import '../dtos/account_response_dto.dart';

class Account {
  const Account({
    required this.id,
    required this.name,
    required this.balanceCents,
    required this.isDefault,
    required this.isExcludedFromNetWorth,
  });

  final int id;
  final String name;
  final int balanceCents;
  final bool isDefault;
  final bool isExcludedFromNetWorth;

  factory Account.fromDto(GetAccountItemResponseDto dto) => Account(
        id: dto.id,
        name: dto.name,
        balanceCents: dto.currentAmount,
        isDefault: dto.isDefaultAccount,
        isExcludedFromNetWorth: dto.isExcludedFromNetWorth,
      );
}
