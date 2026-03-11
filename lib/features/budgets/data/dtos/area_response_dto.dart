import 'package:json_annotation/json_annotation.dart';

part 'area_response_dto.g.dart';

@JsonSerializable(createToJson: false)
class AreaResponseDto {
  const AreaResponseDto({
    required this.id,
    required this.name,
  });

  final int id;
  final String name;

  factory AreaResponseDto.fromJson(Map<String, dynamic> json) =>
      _$AreaResponseDtoFromJson(json);
}
