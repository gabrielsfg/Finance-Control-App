import 'package:json_annotation/json_annotation.dart';

part 'update_account_request_dto.g.dart';

@JsonSerializable(createFactory: false)
class UpdateAccountRequestDto {
  const UpdateAccountRequestDto({
    required this.name,
    required this.accountType,
    required this.isDefaultAccount,
    required this.isExcludedFromNetWorth,
    this.goalAmount,
    this.billingDueDay,
    this.creditLimit,
  });

  final String name;
  final String accountType;
  final bool isDefaultAccount;
  final bool isExcludedFromNetWorth;
  final int? goalAmount;
  final int? billingDueDay;
  final int? creditLimit;

  Map<String, dynamic> toJson() => _$UpdateAccountRequestDtoToJson(this);
}
