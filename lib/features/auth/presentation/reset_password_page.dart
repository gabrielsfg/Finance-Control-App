import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../data/auth_repository.dart';

class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({super.key, required this.token});

  final String token;

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _isLoading = false;
  bool _success = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _passwordError;
  String? _confirmError;
  String? _globalError;
  PasswordStrength? _passwordStrength;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _onPasswordChanged(String value) {
    setState(() {
      _passwordError = null;
      _passwordStrength = value.isEmpty ? null : evaluatePasswordStrength(value);
    });
  }

  bool _validate() {
    String? passErr;
    String? confirmErr;

    final password = _passwordController.text;
    if (password.isEmpty) {
      passErr = 'Informe a nova senha';
    } else if (evaluatePasswordStrength(password) == PasswordStrength.invalid) {
      passErr =
          'A senha deve ter 8+ caracteres, maiúscula, minúscula, número e caractere especial';
    }

    if (_confirmController.text.isEmpty) {
      confirmErr = 'Confirme a nova senha';
    } else if (_confirmController.text != password) {
      confirmErr = 'As senhas não coincidem';
    }

    setState(() {
      _passwordError = passErr;
      _confirmError = confirmErr;
    });
    return passErr == null && confirmErr == null;
  }

  Future<void> _submit() async {
    if (!_validate()) return;

    setState(() {
      _isLoading = true;
      _globalError = null;
    });

    try {
      await ref.read(authRepositoryProvider).resetPassword(
            token: widget.token,
            newPassword: _passwordController.text,
          );
      if (mounted) setState(() => _success = true);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final String message;
      if (status == 400) {
        message = 'Link inválido ou expirado. Solicite um novo link.';
      } else if (status == 429) {
        message =
            'Muitas tentativas. Aguarde 15 minutos antes de tentar novamente.';
      } else {
        message = 'Erro ao redefinir senha. Tente novamente.';
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
                // ── Header ──────────────────────────────────────────────────
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.go('/login'),
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
                    const SizedBox(width: 12),
                    Text(
                      'Redefinir senha',
                      style: AppTextStyles.h2(t.txtPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                if (_success) ...[
                  // ── Success state ────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E)
                          .withValues(alpha: t.isDark ? 0.15 : 0.08),
                      borderRadius: AppRadius.baseAll,
                      border: Border.all(
                        color: const Color(0xFF22C55E).withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_outline,
                            color: Color(0xFF22C55E), size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Senha redefinida com sucesso! Faça login com sua nova senha.',
                            style: AppTextStyles.body(
                              t.isDark
                                  ? const Color(0xFF86EFAC)
                                  : const Color(0xFF166534),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  PrimaryButton(
                    label: 'Ir para o login',
                    onPressed: () => context.go('/login'),
                  ),
                ] else ...[
                  // ── Form state ───────────────────────────────────────────
                  Text(
                    'Nova senha',
                    style: AppTextStyles.h1(t.txtPrimary),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Escolha uma senha forte para sua conta.',
                    style: AppTextStyles.body(t.txtSecondary),
                  ),
                  const SizedBox(height: 32),

                  if (_globalError != null) ...[
                    _ErrorBanner(message: _globalError!),
                    const SizedBox(height: 16),
                  ],

                  AppInputField(
                    placeholder: 'Nova senha',
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    errorText: _passwordError,
                    textInputAction: TextInputAction.next,
                    onChanged: _onPasswordChanged,
                    rightIcon: GestureDetector(
                      onTap: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  if (_passwordStrength != null) ...[
                    const SizedBox(height: 8),
                    _PasswordStrengthIndicator(strength: _passwordStrength!),
                  ],
                  const SizedBox(height: 14),

                  AppInputField(
                    placeholder: 'Confirmar nova senha',
                    controller: _confirmController,
                    obscureText: _obscureConfirm,
                    errorText: _confirmError,
                    textInputAction: TextInputAction.done,
                    onSubmitted: _submit,
                    onChanged: (_) => setState(() => _confirmError = null),
                    rightIcon: GestureDetector(
                      onTap: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          _obscureConfirm
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 20,
                        ),
                      ),
                    ),
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
                      : PrimaryButton(
                          label: 'Redefinir senha',
                          onPressed: _submit,
                        ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PasswordStrengthIndicator extends StatelessWidget {
  const _PasswordStrengthIndicator({required this.strength});

  final PasswordStrength strength;

  @override
  Widget build(BuildContext context) {
    final t = AppThemeTokens.of(context);

    final (label, color, filledSegments) = switch (strength) {
      PasswordStrength.invalid => ('Fraca', t.error, 1),
      PasswordStrength.weak => ('Fraca', t.error, 1),
      PasswordStrength.medium => ('Média', const Color(0xFFF59E0B), 2),
      PasswordStrength.strong => ('Forte', const Color(0xFF22C55E), 3),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(3, (i) {
            final filled = i < filledSegments;
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
                height: 4,
                decoration: BoxDecoration(
                  color: filled
                      ? color
                      : t.divider.withValues(alpha: t.isDark ? 0.3 : 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
        Text(
          'Senha $label',
          style: AppTextStyles.caption(color).copyWith(fontSize: 11),
        ),
      ],
    );
  }
}

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
