import 'package:json_annotation/json_annotation.dart';

part 'create_account_request_dto.g.dart';

@JsonSerializable(createFactory: false)
class CreateAccountRequestDto {
  const CreateAccountRequestDto({
    required this.name,
    required this.currentBalance,
    required this.isDefaultAccount,
    required this.isExcludedFromNetWorth,
    this.goalAmount,
  });

  final String name;
  final int currentBalance;
  final bool isDefaultAccount;
  final bool isExcludedFromNetWorth;
  final int? goalAmount;

  Map<String, dynamic> toJson() => _$CreateAccountRequestDtoToJson(this);
}
