/// App-wide formatting utilities.
///
/// All formatting logic for currency, dates, percentages, and labels must live
/// here. Never define formatting functions inside a page or widget file.
library;

import 'package:flutter/services.dart';

/// A [TextInputFormatter] that formats monetary input as cents-based currency.
///
/// The user types only digits (and optionally a leading `-` when [allowNegative]
/// is true). The formatter automatically inserts the decimal separator so that
/// the last two digits are always the cent portion.
///
/// Examples (allowNegative: false):
///   typing "4"    → "0,04"
///   typing "43"   → "0,43"
///   typing "432"  → "4,32"
///   typing "43254"→ "432,54"
///
/// To read the value back as cents, call [CentsInputFormatter.parseCents].
class CentsInputFormatter extends TextInputFormatter {
  const CentsInputFormatter({this.allowNegative = false});

  final bool allowNegative;

  /// Parses a formatted string (e.g. "-1.234,56") back to cents.
  static int parseCents(String formatted) {
    final isNegative = formatted.startsWith('-');
    final digits = formatted.replaceAll(RegExp(r'[^\d]'), '');
    final value = int.tryParse(digits) ?? 0;
    return isNegative ? -value : value;
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = newValue.text;
    final isNegative = allowNegative && raw.startsWith('-');
    final digits = raw.replaceAll(RegExp(r'[^\d]'), '');

    // If the user just typed '-' and no digits yet, keep the '-' as-is so
    // they can continue typing digits.
    if (isNegative && digits.isEmpty) {
      return const TextEditingValue(
        text: '-',
        selection: TextSelection.collapsed(offset: 1),
      );
    }

    final formatted = _format(digits, isNegative);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  static String _format(String digits, bool isNegative) {
    if (digits.isEmpty) return '';

    // Pad to at least 3 digits so we always have a cent portion.
    final padded = digits.padLeft(3, '0');

    final rawInt = padded.substring(0, padded.length - 2);
    final centPart = padded.substring(padded.length - 2);

    // Strip leading zeros from the integer part (keep at least one digit).
    final intPart = rawInt.replaceFirst(RegExp(r'^0+'), '').isEmpty
        ? '0'
        : rawInt.replaceFirst(RegExp(r'^0+'), '');

    // Insert thousand separators in the integer part.
    final buf = StringBuffer();
    for (var i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buf.write('.');
      buf.write(intPart[i]);
    }

    final result = '$buf,$centPart';
    return isNegative ? '-$result' : result;
  }
}

/// Formats an integer amount in cents to the Brazilian Real format.
///
/// Examples:
///   formatCurrency(384752)  → "R$ 3.847,52"
///   formatCurrency(100)     → "R$ 1,00"
///   formatCurrency(-6790)   → "R$ 67,90"  (sign is the caller's responsibility)
String formatCurrency(int cents) {
  final str = (cents.abs() / 100).toStringAsFixed(2);
  final parts = str.split('.');
  final integerPart = parts[0];
  final buf = StringBuffer();
  for (var i = 0; i < integerPart.length; i++) {
    if (i > 0 && (integerPart.length - i) % 3 == 0) buf.write('.');
    buf.write(integerPart[i]);
  }
  return 'R\$ $buf,${parts[1]}';
}

/// Returns the full Portuguese month name for the given 1-based month number.
///
/// Used for UI display only (product copy — Portuguese is intentional here).
String monthName(int month) => const [
      '',
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ][month];

/// Returns the abbreviated Portuguese month name for the given 1-based month number.
///
/// Examples: 1 → "Jan", 2 → "Fev", 3 → "Mar"
String shortMonthName(int month) => const [
      '',
      'Jan',
      'Fev',
      'Mar',
      'Abr',
      'Mai',
      'Jun',
      'Jul',
      'Ago',
      'Set',
      'Out',
      'Nov',
      'Dez',
    ][month];

/// Returns a formatted date string like "19 FEV" for use in transaction group headers.
String formatDayHeader(DateTime date) {
  return '${date.day} ${shortMonthName(date.month).toUpperCase()}';
}

/// Returns a formatted month/year string like "Fevereiro 2026".
String formatMonthYear(DateTime date) => '${monthName(date.month)} ${date.year}';

/// Returns a formatted date string like "18/02/2026".
String formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

/// Password strength levels.
enum PasswordStrength { invalid, weak, medium, strong }

/// Evaluates the strength of a password.
///
/// Requirements to be considered valid (not [PasswordStrength.invalid]):
///   - At least 8 characters
///   - At least 1 uppercase letter
///   - At least 1 lowercase letter
///   - At least 1 digit
///   - At least 1 special character
///
/// Beyond the minimum, scoring:
///   - [PasswordStrength.weak]   — meets minimum exactly (score = 0 bonus)
///   - [PasswordStrength.medium] — 1 bonus point (length ≥ 12 OR variety breadth)
///   - [PasswordStrength.strong] — 2+ bonus points (length ≥ 14 AND extra variety)
PasswordStrength evaluatePasswordStrength(String password) {
  if (password.length < 8) return PasswordStrength.invalid;

  final hasUpper = RegExp(r'[A-Z]').hasMatch(password);
  final hasLower = RegExp(r'[a-z]').hasMatch(password);
  final hasDigit = RegExp(r'[0-9]').hasMatch(password);
  final hasSpecial = RegExp(r'[^A-Za-z0-9]').hasMatch(password);

  if (!hasUpper || !hasLower || !hasDigit || !hasSpecial) {
    return PasswordStrength.invalid;
  }

  // Minimum requirements met — compute bonus score.
  var bonus = 0;
  if (password.length >= 12) bonus++;
  if (password.length >= 14) bonus++;
  // Extra special characters (more than one)
  final specialCount = RegExp(r'[^A-Za-z0-9]').allMatches(password).length;
  if (specialCount >= 2) bonus++;

  if (bonus >= 2) return PasswordStrength.strong;
  if (bonus == 1) return PasswordStrength.medium;
  return PasswordStrength.weak;
}

/// Converts an ISO 3166-1 alpha-2 country code to a flag emoji.
///
/// Uses Regional Indicator Symbol arithmetic: each letter + 0x1F1A5 maps to
/// the corresponding Regional Indicator Symbol Letter (A–Z).
///
/// Examples:
///   countryCodeToFlag("BR") → "🇧🇷"
///   countryCodeToFlag("US") → "🇺🇸"
///   countryCodeToFlag("PT") → "🇵🇹"
String countryCodeToFlag(String isoCode) {
  if (isoCode.length != 2) return '';
  final upper = isoCode.toUpperCase();
  final first = String.fromCharCode(upper.codeUnitAt(0) + 0x1F1A5);
  final second = String.fromCharCode(upper.codeUnitAt(1) + 0x1F1A5);
  return '$first$second';
}

/// Formats a lockout duration in seconds to a user-friendly Portuguese string.
///
/// Examples:
///   formatLockoutDuration(45)  → "45 segundos"
///   formatLockoutDuration(90)  → "1 minuto e 30 segundos"
///   formatLockoutDuration(120) → "2 minutos"
String formatLockoutDuration(int totalSeconds) {
  if (totalSeconds <= 0) return '0 segundos';
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  if (minutes == 0) return '$totalSeconds segundo${totalSeconds == 1 ? '' : 's'}';
  if (seconds == 0) return '$minutes minuto${minutes == 1 ? '' : 's'}';
  return '$minutes minuto${minutes == 1 ? '' : 's'} e $seconds segundo${seconds == 1 ? '' : 's'}';
}
