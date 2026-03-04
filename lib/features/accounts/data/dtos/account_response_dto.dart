import 'package:json_annotation/json_annotation.dart';

part 'account_response_dto.g.dart';

@JsonSerializable(createToJson: false)
class AccountResponseDto {
  const AccountResponseDto({
    required this.id,
    required this.name,
    required this.balance,
    required this.initialBalance,
    required this.isDefault,
    required this.excludeFromNetWorth,
    this.goalAmount,
  });

  final int id;
  final String name;
  final int balance;
  final int initialBalance;
  final bool isDefault;
  final bool excludeFromNetWorth;
  final int? goalAmount;

  factory AccountResponseDto.fromJson(Map<String, dynamic> json) =>
      _$AccountResponseDtoFromJson(json);
}
