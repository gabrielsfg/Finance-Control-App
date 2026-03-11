import 'package:json_annotation/json_annotation.dart';

part 'budget_response_dto.g.dart';

@JsonSerializable(createToJson: false)
class GetAllBudgetResponseDto {
  const GetAllBudgetResponseDto({
    required this.id,
    required this.name,
    required this.recurrence,
  });

  final int id;
  final String name;
  final String recurrence;

  factory GetAllBudgetResponseDto.fromJson(Map<String, dynamic> json) =>
      _$GetAllBudgetResponseDtoFromJson(json);
}

@JsonSerializable(createToJson: false)
class GetBudgetByIdResponseDto {
  const GetBudgetByIdResponseDto({
    required this.id,
    required this.name,
    required this.startDate,
    required this.finishDate,
    required this.recurrence,
  });

  final int id;
  final String name;
  final String startDate;
  final String finishDate;
  // API has a typo "reccurence" but user confirmed it was fixed to "recurrence"
  final String recurrence;

  factory GetBudgetByIdResponseDto.fromJson(Map<String, dynamic> json) =>
      _$GetBudgetByIdResponseDtoFromJson(json);
}
