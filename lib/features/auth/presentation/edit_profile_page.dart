import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../data/auth_repository.dart';
import '../data/dtos/update_profile_request_dto.dart';
import '../providers/user_profile_provider.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _nameController = TextEditingController();

  bool _isLoading = false;
  bool _initialized = false;
  String? _nameError;
  String? _globalError;
  String? _selectedLanguage;
  String? _selectedCurrency;
  String? _countryController;

  static const _languages = ['pt-BR', 'en-US', 'es-ES'];
  static const _currencies = ['BRL', 'USD', 'EUR'];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _initialize() {
    if (_initialized) return;
    final profile = ref.read(userProfileProvider).valueOrNull;
    if (profile == null) return;
    _nameController.text = profile.name;
    _selectedLanguage = profile.preferredLanguage;
    _selectedCurrency = profile.preferredCurrency;
    _countryController = profile.country;
    _initialized = true;
  }

  bool _validate() {
    final name = _nameController.text.trim();
    String? nameErr;
    if (name.isEmpty) {
      nameErr = 'Informe seu nome';
    } else if (name.length < 2) {
      nameErr = 'Nome muito curto';
    }
    setState(() => _nameError = nameErr);
    return nameErr == null;
  }

  Future<void> _submit() async {
    if (!_validate()) return;

    final profile = ref.read(userProfileProvider).valueOrNull;

    final name = _nameController.text.trim();
    final dto = UpdateProfileRequestDto(
      name: name != profile?.name ? name : null,
      preferredLanguage: _selectedLanguage != profile?.preferredLanguage
          ? _selectedLanguage
          : null,
      preferredCurrency: _selectedCurrency != profile?.preferredCurrency
          ? _selectedCurrency
          : null,
      country: _countryController != profile?.country
          ? _countryController
          : null,
    );

    setState(() {
      _isLoading = true;
      _globalError = null;
    });

    try {
      await ref.read(authRepositoryProvider).updateProfile(dto);
      ref.invalidate(userProfileProvider);
      if (mounted) context.pop();
    } on DioException catch (e) {
      final body = e.response?.data;
      String message;
      if (body is Map && body['error'] is String) {
        message = body['error'] as String;
      } else {
        message = 'Não foi possível salvar. Tente novamente.';
      }
      setState(() => _globalError = message);
    } catch (_) {
      setState(() => _globalError = 'Erro inesperado. Tente novamente.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppThemeTokens.of(context);
    final profileAsync = ref.watch(userProfileProvider);

    profileAsync.whenData((_) => _initialize());

    return Scaffold(
      body: AppBackground(
        scrollable: true,
        child: SafeArea(
          child: Padding(
            padding: AppSpacing.screenPadding.copyWith(top: 0, bottom: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                // ── Header ────────────────────────────────────────────────
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: t.surfaceEl.withValues(
                              alpha: t.isDark ? 0.4 : 0.6),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new,
                          size: 16,
                          color: t.txtPrimary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Editar perfil',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.h2(t.txtPrimary),
                      ),
                    ),
                    const SizedBox(width: 36),
                  ],
                ),
                const SizedBox(height: 32),

                if (_globalError != null) ...[
                  _ErrorBanner(message: _globalError!),
                  const SizedBox(height: 16),
                ],

                // ── Read-only fields ──────────────────────────────────────
                _ReadOnlyField(
                  label: 'E-mail',
                  value: profileAsync.valueOrNull?.email ?? '—',
                ),
                const SizedBox(height: 12),
                _ReadOnlyField(
                  label: 'Status do e-mail',
                  value: profileAsync.valueOrNull?.isEmailVerified == true
                      ? 'Verificado ✓'
                      : 'Não verificado',
                  valueColor: profileAsync.valueOrNull?.isEmailVerified == true
                      ? const Color(0xFF22C55E)
                      : const Color(0xFFF59E0B),
                ),
                const SizedBox(height: 12),
                _ReadOnlyField(
                  label: 'Membro desde',
                  value: profileAsync.valueOrNull?.createdAt != null
                      ? _formatDate(profileAsync.valueOrNull!.createdAt)
                      : '—',
                ),
                const SizedBox(height: 24),

                // ── Editable fields ───────────────────────────────────────
                AppInputField(
                  placeholder: 'Nome',
                  controller: _nameController,
                  errorText: _nameError,
                  keyboardType: TextInputType.name,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setState(() => _nameError = null),
                ),
                const SizedBox(height: 14),

                _DropdownField(
                  label: 'Idioma preferido',
                  value: _selectedLanguage,
                  items: _languages,
                  onChanged: (v) => setState(() => _selectedLanguage = v),
                ),
                const SizedBox(height: 14),

                _DropdownField(
                  label: 'Moeda preferida',
                  value: _selectedCurrency,
                  items: _currencies,
                  onChanged: (v) => setState(() => _selectedCurrency = v),
                ),
                const SizedBox(height: 14),

                AppInputField(
                  placeholder: 'País (código ISO, ex: BR)',
                  controller: TextEditingController(text: _countryController)
                    ..selection = TextSelection.collapsed(
                        offset: (_countryController ?? '').length),
                  textInputAction: TextInputAction.done,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]')),
                    LengthLimitingTextInputFormatter(2),
                  ],
                  onChanged: (v) => setState(
                      () => _countryController = v.toUpperCase().trim()),
                ),
                const SizedBox(height: 32),

                _isLoading
                    ? Center(
                        child: SizedBox(
                          height: 48,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: t.primary,
                              strokeWidth: 2.5,
                            ),
                          ),
                        ),
                      )
                    : PrimaryButton(label: 'Salvar', onPressed: _submit),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}

// ── Read-only field ─────────────────────────────────────────────────────────

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final t = AppThemeTokens.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: t.isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: AppRadius.baseAll,
        border: Border.all(
          color: t.divider.withValues(alpha: t.isDark ? 0.2 : 0.4),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodySm(t.txtTertiary)),
          Text(
            value,
            style: AppTextStyles.bodySm(valueColor ?? t.txtPrimary).copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Dropdown field ──────────────────────────────────────────────────────────

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<String> items;
  final void Function(String?) onChanged;

  @override
  Widget build(BuildContext context) {
    final t = AppThemeTokens.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: t.isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.9),
        borderRadius: AppRadius.baseAll,
        border: Border.all(
          color: t.divider.withValues(alpha: t.isDark ? 0.25 : 0.5),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(value) ? value : null,
          hint: Text(label, style: AppTextStyles.bodySm(t.txtTertiary)),
          isExpanded: true,
          dropdownColor: t.isDark ? const Color(0xFF1C1830) : Colors.white,
          style: AppTextStyles.body(t.txtPrimary),
          items: items
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ── Error banner ────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final t = AppThemeTokens.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: t.error.withValues(alpha: t.isDark ? 0.15 : 0.08),
        borderRadius: AppRadius.baseAll,
        border: Border.all(color: t.error.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: t.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: AppTextStyles.bodySm(t.error)),
          ),
        ],
      ),
    );
  }
}
