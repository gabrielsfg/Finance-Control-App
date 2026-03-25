import 'package:json_annotation/json_annotation.dart';

part 'update_category_request_dto.g.dart';

@JsonSerializable(createFactory: false)
class UpdateCategoryRequestDto {
  const UpdateCategoryRequestDto({required this.name});

  final String name;

  Map<String, dynamic> toJson() => _$UpdateCategoryRequestDtoToJson(this);
}
