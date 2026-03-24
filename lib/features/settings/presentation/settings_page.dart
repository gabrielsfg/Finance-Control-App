import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/storage/local_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../features/auth/data/auth_repository.dart';
import '../../../features/auth/data/dtos/update_profile_request_dto.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/auth/data/models/user_profile.dart';
import '../../../features/auth/providers/user_profile_provider.dart';
import '../../../main.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../data/currencies_repository.dart';

// ── Local providers ──────────────────────────────────────────────────────────

final _currenciesProvider = FutureProvider<List<String>>((ref) {
  return ref.read(currenciesRepositoryProvider).getCurrencies();
});

// ── Page ─────────────────────────────────────────────────────────────────────

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  // Regional prefs (local state, saved on tap of "Save")
  String? _country;
  String? _currency;
  String? _language;
  bool _regionalInitialized = false;
  bool _isSaving = false;

  void _initRegional(UserProfile profile) {
    if (_regionalInitialized) return;
    _regionalInitialized = true;
    _country = profile.country;
    _currency = profile.preferredCurrency;
    _language = profile.preferredLanguage;
  }

  // ── Country picker ─────────────────────────────────────────────────────────

  void _openCountryPicker() {
    showCountryPicker(
      context: context,
      showPhoneCode: false,
      onSelect: (country) {
        setState(() => _country = country.countryCode);
      },
    );
  }

  // ── Currency picker ────────────────────────────────────────────────────────

  void _openCurrencyPicker(List<String> currencies) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _CurrencyPickerSheet(
        currencies: currencies,
        selected: _currency,
        onSelected: (code) => setState(() => _currency = code),
      ),
    );
  }

  // ── Language picker ────────────────────────────────────────────────────────

  void _openLanguagePicker() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _LanguagePickerSheet(
        selected: _language,
        onSelected: (lang) => setState(() => _language = lang),
      ),
    );
  }

  // ── Save regional prefs ────────────────────────────────────────────────────

  Future<void> _saveRegional() async {
    setState(() => _isSaving = true);
    try {
      await ref.read(authRepositoryProvider).updateProfile(
            UpdateProfileRequestDto(
              preferredCurrency: _currency,
              preferredLanguage: _language,
              country: _country,
            ),
          );
      ref.invalidate(userProfileProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preferências salvas com sucesso.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao salvar preferências.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppThemeTokens.of(context);
    final bottomPad = MediaQuery.viewPaddingOf(context).bottom;
    final profileAsync = ref.watch(userProfileProvider);
    final currenciesAsync = ref.watch(_currenciesProvider);
    final localPrefs = ref.read(localPreferencesProvider);
    final themeMode = ref.watch(themeModeProvider);
    final firstDayOfWeek = localPrefs.getFirstDayOfWeek();

    profileAsync.whenData((profile) {
      if (profile != null) _initRegional(profile);
    });

    return Scaffold(
      backgroundColor: t.bg,
      body: AppBackground(
        scrollable: true,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: AppSpacing.screenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                // ── Header ──────────────────────────────────────────────────
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Icon(LucideIcons.arrowLeft,
                          color: t.txtPrimary, size: 22),
                    ),
                    Expanded(
                      child: Text(
                        'Configurações',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body(t.txtPrimary).copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                        ),
                      ),
                    ),
                    const SizedBox(width: 22),
                  ],
                ),
                const SizedBox(height: 28),

                // ── Section 1: Regional Preferences ─────────────────────────
                _SectionHeader(title: 'Preferências Regionais'),
                const SizedBox(height: 12),
                GlassCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      // Country
                      _SettingRow(
                        icon: LucideIcons.mapPin,
                        iconColor: const Color(0xFF06B6D4),
                        label: 'País',
                        trailingLabel: _country != null
                            ? '${countryCodeToFlag(_country!)} $_country'
                            : 'Selecionar',
                        onTap: _openCountryPicker,
                      ),
                      _Divider(),
                      // Currency
                      _SettingRow(
                        icon: LucideIcons.dollarSign,
                        iconColor: const Color(0xFF22C55E),
                        label: 'Moeda',
                        trailingLabel: _currency ?? '—',
                        onTap: currenciesAsync.valueOrNull != null
                            ? () =>
                                _openCurrencyPicker(currenciesAsync.value!)
                            : null,
                      ),
                      _Divider(),
                      // Language
                      _SettingRow(
                        icon: LucideIcons.globe,
                        iconColor: const Color(0xFF8B5CF6),
                        label: 'Idioma',
                        trailingLabel: _languageLabel(_language),
                        onTap: _openLanguagePicker,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _isSaving
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _saveRegional,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          backgroundColor: t.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: AppRadius.lgAll),
                          elevation: 0,
                        ),
                        child: Text(
                          'Salvar',
                          style: AppTextStyles.body(Colors.white)
                              .copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                const SizedBox(height: 28),

                // ── Section 2: App Preferences ───────────────────────────────
                _SectionHeader(title: 'Preferências do App'),
                const SizedBox(height: 12),
                GlassCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      // Theme
                      _SettingRow(
                        icon: LucideIcons.sun,
                        iconColor: const Color(0xFFF59E0B),
                        label: 'Tema',
                        trailingLabel: _themeModeLabel(themeMode),
                        onTap: () => _openThemePicker(themeMode),
                      ),
                      _Divider(),
                      // First day of week
                      _SettingRow(
                        icon: LucideIcons.calendarDays,
                        iconColor: t.primary,
                        label: 'Primeiro dia da semana',
                        trailingLabel:
                            firstDayOfWeek == 1 ? 'Segunda' : 'Domingo',
                        onTap: () => _openFirstDayPicker(firstDayOfWeek),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // ── Section 3: Account Info ──────────────────────────────────
                _SectionHeader(title: 'Conta'),
                const SizedBox(height: 12),
                GlassCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _InfoRow(
                        icon: LucideIcons.user,
                        iconColor: t.primary,
                        label: 'Nome',
                        value: profileAsync.valueOrNull?.name ?? '—',
                      ),
                      _Divider(),
                      _InfoRow(
                        icon: LucideIcons.mail,
                        iconColor: const Color(0xFF06B6D4),
                        label: 'Email',
                        value: profileAsync.valueOrNull?.email ?? '—',
                      ),
                    ],
                  ),
                ),

                SizedBox(height: bottomPad + 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Theme picker ───────────────────────────────────────────────────────────

  void _openThemePicker(ThemeMode current) {
    final prefs = ref.read(localPreferencesProvider);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _OptionsSheet(
        title: 'Tema',
        options: const [
          _Option(value: 'system', label: 'Automático (sistema)'),
          _Option(value: 'light', label: 'Claro'),
          _Option(value: 'dark', label: 'Escuro'),
        ],
        selectedValue: switch (current) {
          ThemeMode.light => 'light',
          ThemeMode.dark => 'dark',
          ThemeMode.system => 'system',
        },
        onSelected: (val) {
          final mode = switch (val) {
            'light' => ThemeMode.light,
            'dark' => ThemeMode.dark,
            _ => ThemeMode.system,
          };
          ref.read(themeModeProvider.notifier).state = mode;
          prefs.setThemeMode(mode);
        },
      ),
    );
  }

  // ── First day picker ───────────────────────────────────────────────────────

  void _openFirstDayPicker(int current) {
    final prefs = ref.read(localPreferencesProvider);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _OptionsSheet(
        title: 'Primeiro dia da semana',
        options: const [
          _Option(value: '1', label: 'Segunda-feira'),
          _Option(value: '7', label: 'Domingo'),
        ],
        selectedValue: current == 7 ? '7' : '1',
        onSelected: (val) {
          final day = int.parse(val);
          prefs.setFirstDayOfWeek(day);
          setState(() {}); // re-read from prefs
        },
      ),
    );
  }

  String _languageLabel(String? lang) => switch (lang) {
        'pt-BR' => 'Português (BR)',
        'en-US' => 'English (US)',
        _ => lang ?? '—',
      };

  String _themeModeLabel(ThemeMode mode) => switch (mode) {
        ThemeMode.light => 'Claro',
        ThemeMode.dark => 'Escuro',
        ThemeMode.system => 'Automático',
      };
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final t = AppThemeTokens.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 0),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.caption(t.txtTertiary).copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = AppThemeTokens.of(context);
    return Divider(
      height: 1,
      thickness: 1,
      indent: 54,
      color: t.divider.withValues(alpha: t.isDark ? 0.3 : 0.6),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String? trailingLabel;
  final VoidCallback? onTap;

  const _SettingRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.trailingLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppThemeTokens.of(context);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.13),
                borderRadius: AppRadius.mdAll,
              ),
              child: Icon(icon, size: 17, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.body(t.txtPrimary).copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
            if (trailingLabel != null) ...[
              Text(
                trailingLabel!,
                style: AppTextStyles.bodySm(t.txtTertiary),
              ),
              const SizedBox(width: 4),
            ],
            Icon(LucideIcons.chevronRight, size: 16, color: t.txtDisabled),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppThemeTokens.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.13),
              borderRadius: AppRadius.mdAll,
            ),
            child: Icon(icon, size: 17, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.body(t.txtPrimary).copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.bodySm(t.txtTertiary),
          ),
        ],
      ),
    );
  }
}

// ── Currency Picker Sheet ─────────────────────────────────────────────────────

class _CurrencyPickerSheet extends StatefulWidget {
  final List<String> currencies;
  final String? selected;
  final ValueChanged<String> onSelected;

  const _CurrencyPickerSheet({
    required this.currencies,
    required this.selected,
    required this.onSelected,
  });

  @override
  State<_CurrencyPickerSheet> createState() => _CurrencyPickerSheetState();
}

class _CurrencyPickerSheetState extends State<_CurrencyPickerSheet> {
  final _searchController = TextEditingController();
  List<String> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.currencies;
    _searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch() {
    final q = _searchController.text.toLowerCase();
    setState(() {
      _filtered = widget.currencies
          .where((c) => c.toLowerCase().contains(q))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppThemeTokens.of(context);
    final bottomPad = MediaQuery.viewPaddingOf(context).bottom;

    return Container(
      decoration: BoxDecoration(
        color: t.isDark ? const Color(0xFF1C1830) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: AppShadows.bottomSheet,
      ),
      padding: EdgeInsets.fromLTRB(0, 0, 0, bottomPad + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: t.isDark
                  ? Colors.white.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Selecionar Moeda',
                    style: AppTextStyles.h3(t.txtPrimary)),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Pesquisar...',
                    prefixIcon: Icon(LucideIcons.search,
                        size: 16, color: t.txtTertiary),
                    isDense: true,
                    filled: true,
                    fillColor: t.surfaceEl.withValues(alpha: 0.4),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            child: ListView(
              shrinkWrap: true,
              children: _filtered.map((code) {
                final isSelected = code == widget.selected;
                return GestureDetector(
                  onTap: () {
                    widget.onSelected(code);
                    Navigator.of(context).pop();
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            code,
                            style: AppTextStyles.body(
                              isSelected ? t.primary : t.txtPrimary,
                            ).copyWith(
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(LucideIcons.check,
                              size: 18, color: t.primary),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Language Picker Sheet ─────────────────────────────────────────────────────

class _LanguagePickerSheet extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onSelected;

  const _LanguagePickerSheet({
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return _OptionsSheet(
      title: 'Idioma',
      options: const [
        _Option(value: 'pt-BR', label: 'Português (BR)'),
        _Option(value: 'en-US', label: 'English (US)'),
      ],
      selectedValue: selected ?? 'pt-BR',
      onSelected: onSelected,
    );
  }
}

// ── Generic Options Sheet ─────────────────────────────────────────────────────

class _Option {
  final String value;
  final String label;

  const _Option({required this.value, required this.label});
}

class _OptionsSheet extends StatelessWidget {
  final String title;
  final List<_Option> options;
  final String selectedValue;
  final ValueChanged<String> onSelected;

  const _OptionsSheet({
    required this.title,
    required this.options,
    required this.selectedValue,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppThemeTokens.of(context);
    final bottomPad = MediaQuery.viewPaddingOf(context).bottom;

    return Container(
      decoration: BoxDecoration(
        color: t.isDark ? const Color(0xFF1C1830) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: AppShadows.bottomSheet,
      ),
      padding: EdgeInsets.fromLTRB(0, 0, 0, bottomPad + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: t.isDark
                  ? Colors.white.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(title, style: AppTextStyles.h3(t.txtPrimary)),
            ),
          ),
          ...options.map((opt) {
            final isSelected = opt.value == selectedValue;
            return GestureDetector(
              onTap: () {
                onSelected(opt.value);
                Navigator.of(context).pop();
              },
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        opt.label,
                        style: AppTextStyles.body(
                          isSelected ? t.primary : t.txtPrimary,
                        ).copyWith(
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(LucideIcons.check, size: 18, color: t.primary),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
