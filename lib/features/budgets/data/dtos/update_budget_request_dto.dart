import 'package:json_annotation/json_annotation.dart';

part 'update_budget_request_dto.g.dart';

@JsonSerializable(createFactory: false)
class UpdateBudgetRequestDto {
  const UpdateBudgetRequestDto({
    required this.id,
    required this.name,
    required this.startDate,
    required this.recurrence,
    required this.isActive,
  });

  final int id;
  final String name;
  final int startDate;
  final String recurrence;
  final bool isActive;

  Map<String, dynamic> toJson() => _$UpdateBudgetRequestDtoToJson(this);
}
