import 'package:json_annotation/json_annotation.dart';

part 'create_area_request_dto.g.dart';

@JsonSerializable(createFactory: false)
class CreateAreaRequestDto {
  const CreateAreaRequestDto({required this.budgetId, required this.name});

  final int budgetId;
  final String name;

  Map<String, dynamic> toJson() => _$CreateAreaRequestDtoToJson(this);
}
