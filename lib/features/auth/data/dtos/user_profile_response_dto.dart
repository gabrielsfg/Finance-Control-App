import 'package:json_annotation/json_annotation.dart';

part 'user_profile_response_dto.g.dart';

@JsonSerializable(createToJson: false)
class UserProfileResponseDto {
  const UserProfileResponseDto({
    required this.name,
    required this.email,
    required this.preferredCurrency,
    required this.preferredLanguage,
    required this.createdAt,
    required this.isEmailVerified,
    this.country,
  });

  final String name;
  final String email;
  final String preferredCurrency;
  final String preferredLanguage;
  final DateTime createdAt;
  @JsonKey(defaultValue: false)
  final bool isEmailVerified;
  final String? country;

  factory UserProfileResponseDto.fromJson(Map<String, dynamic> json) =>
      _$UserProfileResponseDtoFromJson(json);
}
