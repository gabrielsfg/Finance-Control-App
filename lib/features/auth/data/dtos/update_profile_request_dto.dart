import 'package:json_annotation/json_annotation.dart';

part 'update_profile_request_dto.g.dart';

@JsonSerializable(createFactory: false, includeIfNull: false)
class UpdateProfileRequestDto {
  const UpdateProfileRequestDto({
    this.name,
    this.preferredCurrency,
    this.preferredLanguage,
    this.country,
  });

  final String? name;
  final String? preferredCurrency;
  final String? preferredLanguage;
  final String? country;

  Map<String, dynamic> toJson() => _$UpdateProfileRequestDtoToJson(this);
}
