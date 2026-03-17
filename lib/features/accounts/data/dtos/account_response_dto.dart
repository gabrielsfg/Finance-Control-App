import 'package:json_annotation/json_annotation.dart';

part 'account_response_dto.g.dart';

@JsonSerializable(createToJson: false)
class GetAccountItemResponseDto {
  const GetAccountItemResponseDto({
    required this.id,
    required this.name,
    required this.accountType,
    required this.currentAmount,
    required this.isDefaultAccount,
    required this.isExcludedFromNetWorth,
    this.billingDueDay,
    this.creditLimit,
  });

  final int id;
  final String name;
  final String accountType;
  final int currentAmount;
  final bool isDefaultAccount;
  final bool isExcludedFromNetWorth;
  final int? billingDueDay;
  final int? creditLimit;

  factory GetAccountItemResponseDto.fromJson(Map<String, dynamic> json) =>
      _$GetAccountItemResponseDtoFromJson(json);
}
