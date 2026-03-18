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
import '../data/dtos/register_request_dto.dart';
import '../providers/auth_provider.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _globalError;
  PasswordStrength? _passwordStrength;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onPasswordChanged(String value) {
    setState(() {
      _passwordError = null;
      _passwordStrength =
          value.isEmpty ? null : evaluatePasswordStrength(value);
    });
  }

  bool _validate() {
    String? nameErr;
    String? emailErr;
    String? passErr;
    String? confirmErr;

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      nameErr = 'Informe seu nome';
    } else if (name.length < 2) {
      nameErr = 'Nome muito curto';
    }

    final email = _emailController.text.trim();
    if (email.isEmpty) {
      emailErr = 'Informe seu e-mail';
    } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      emailErr = 'E-mail inválido';
    }

    final password = _passwordController.text;
    if (password.isEmpty) {
      passErr = 'Informe uma senha';
    } else {
      final strength = evaluatePasswordStrength(password);
      if (strength == PasswordStrength.invalid) {
        passErr =
            'A senha deve ter 8+ caracteres, maiúscula, minúscula, número e caractere especial';
      }
    }

    if (_confirmPasswordController.text.isEmpty) {
      confirmErr = 'Confirme sua senha';
    } else if (_confirmPasswordController.text != _passwordController.text) {
      confirmErr = 'As senhas não coincidem';
    }

    setState(() {
      _nameError = nameErr;
      _emailError = emailErr;
      _passwordError = passErr;
      _confirmPasswordError = confirmErr;
    });

    return nameErr == null &&
        emailErr == null &&
        passErr == null &&
        confirmErr == null;
  }

  Future<void> _submit() async {
    if (!_validate()) return;

    setState(() {
      _isLoading = true;
      _globalError = null;
    });

    try {
      final response = await ref.read(authRepositoryProvider).register(
            RegisterRequestDto(
              name: _nameController.text.trim(),
              email: _emailController.text.trim(),
              password: _passwordController.text,
            ),
          );
      await ref.read(authNotifierProvider.notifier).onLoginSuccess(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken,
          );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final String message;
      if (status == 429) {
        message =
            'Muitas tentativas. Aguarde 15 minutos antes de tentar novamente.';
      } else {
        final body = e.response?.data;
        // FluentValidation returns ValidationProblemDetails:
        // { "errors": { "FieldName": ["msg1", "msg2"] } }
        if (body is Map && body['errors'] is Map) {
          final errors = body['errors'] as Map;
          final messages = errors.values
              .expand((v) => v is List ? v.cast<String>() : <String>[])
              .toList();
          message = messages.isNotEmpty
              ? messages.join('\n')
              : 'Não foi possível criar a conta. Tente novamente.';
        } else if (body is Map && body['error'] is String) {
          message = body['error'] as String;
        } else {
          message = 'Não foi possível criar a conta. Tente novamente.';
        }
      }
      setState(() => _globalError = message);
    } catch (_) {
      setState(() =>
          _globalError = 'Não foi possível criar a conta. Tente novamente.');
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

                // ── Header ─────────────────────────────────────────────────
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
                        'Criar conta',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.h2(t.txtPrimary),
                      ),
                    ),
                    const ThemeToggleButton(),
                  ],
                ),
                const SizedBox(height: 32),

                // ── Heading ────────────────────────────────────────────────
                Text(
                  'Comece agora 🚀',
                  style: AppTextStyles.h1(t.txtPrimary),
                ),
                const SizedBox(height: 6),
                Text(
                  'Crie sua conta e assuma o controle das suas finanças',
                  style: AppTextStyles.body(t.txtSecondary),
                ),
                const SizedBox(height: 32),

                // ── Global error ───────────────────────────────────────────
                if (_globalError != null) ...[
                  _ErrorBanner(message: _globalError!),
                  const SizedBox(height: 16),
                ],

                // ── Full name ──────────────────────────────────────────────
                AppInputField(
                  placeholder: 'Nome completo',
                  controller: _nameController,
                  errorText: _nameError,
                  keyboardType: TextInputType.name,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setState(() => _nameError = null),
                ),
                const SizedBox(height: 14),

                // ── Email ──────────────────────────────────────────────────
                AppInputField(
                  placeholder: 'Email',
                  controller: _emailController,
                  errorText: _emailError,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setState(() => _emailError = null),
                ),
                const SizedBox(height: 14),

                // ── Password ───────────────────────────────────────────────
                AppInputField(
                  placeholder: 'Senha',
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

                // ── Confirm password ───────────────────────────────────────
                AppInputField(
                  placeholder: 'Confirmar senha',
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  errorText: _confirmPasswordError,
                  textInputAction: TextInputAction.done,
                  onSubmitted: _submit,
                  onChanged: (_) =>
                      setState(() => _confirmPasswordError = null),
                  rightIcon: GestureDetector(
                    onTap: () => setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // ── Submit button ──────────────────────────────────────────
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
                        label: 'Criar conta',
                        onPressed: _submit,
                      ),
                const SizedBox(height: 24),

                // ── Login link ─────────────────────────────────────────────
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Já tem conta? ',
                        style: AppTextStyles.body(t.txtSecondary)
                            .copyWith(fontSize: 14),
                      ),
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Text(
                          'Entrar',
                          style: AppTextStyles.body(t.primary).copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Password Strength Indicator ────────────────────────────────────────────

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

// ── Error Banner ───────────────────────────────────────────────────────────

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
