import '../dtos/user_profile_response_dto.dart';

class UserProfile {
  const UserProfile({
    required this.name,
    required this.email,
    required this.preferredCurrency,
    required this.preferredLanguage,
    required this.createdAt,
  });

  final String name;
  final String email;
  final String preferredCurrency;
  final String preferredLanguage;
  final DateTime createdAt;

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  factory UserProfile.fromDto(UserProfileResponseDto dto) => UserProfile(
        name: dto.name,
        email: dto.email,
        preferredCurrency: dto.preferredCurrency,
        preferredLanguage: dto.preferredLanguage,
        createdAt: dto.createdAt,
      );
}
