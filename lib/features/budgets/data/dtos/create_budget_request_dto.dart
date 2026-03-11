import 'package:json_annotation/json_annotation.dart';

part 'create_budget_request_dto.g.dart';

@JsonSerializable(createFactory: false)
class CreateBudgetRequestDto {
  const CreateBudgetRequestDto({
    required this.name,
    required this.startDate,
    required this.recurrence,
    required this.isActive,
  });

  final String name;
  final int startDate;
  final String recurrence;
  final bool isActive;

  Map<String, dynamic> toJson() => _$CreateBudgetRequestDtoToJson(this);
}
