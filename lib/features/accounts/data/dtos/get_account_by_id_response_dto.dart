import 'package:json_annotation/json_annotation.dart';

part 'get_account_by_id_response_dto.g.dart';

@JsonSerializable(createToJson: false)
class GetAccountByIdResponseDto {
  const GetAccountByIdResponseDto({
    required this.id,
    required this.name,
    required this.accountType,
    required this.currentAmount,
    required this.isDefaultAccount,
    this.isExcludedFromNetWorth = false,
    this.goalAmount,
    this.billingDueDay,
    this.creditLimit,
    required this.recentTransactions,
  });

  final int id;
  final String name;
  final String accountType;
  final int currentAmount;
  final bool isDefaultAccount;
  final bool isExcludedFromNetWorth;
  final int? goalAmount;
  final int? billingDueDay;
  final int? creditLimit;
  final List<RecentTransactionDto> recentTransactions;

  factory GetAccountByIdResponseDto.fromJson(Map<String, dynamic> json) =>
      _$GetAccountByIdResponseDtoFromJson(json);
}

@JsonSerializable(createToJson: false)
class RecentTransactionDto {
  const RecentTransactionDto({
    required this.id,
    required this.description,
    required this.value,
    required this.type,
    required this.subCategoryName,
    required this.categoryName,
  });

  final int id;
  final String? description;
  final int value;
  final String type;
  final String subCategoryName;
  final String categoryName;

  factory RecentTransactionDto.fromJson(Map<String, dynamic> json) =>
      _$RecentTransactionDtoFromJson(json);
}
