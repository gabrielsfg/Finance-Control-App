import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../data/auth_repository.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _emailController = TextEditingController();

  bool _isLoading = false;
  bool _submitted = false;
  String? _emailError;
  String? _globalError;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  bool _validate() {
    final email = _emailController.text.trim();
    String? err;
    if (email.isEmpty) {
      err = 'Informe seu e-mail';
    } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      err = 'E-mail inválido';
    }
    setState(() => _emailError = err);
    return err == null;
  }

  Future<void> _submit() async {
    if (!_validate()) return;

    setState(() {
      _isLoading = true;
      _globalError = null;
    });

    try {
      await ref.read(authRepositoryProvider).forgotPassword(
            _emailController.text.trim(),
          );
      if (mounted) setState(() => _submitted = true);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 429) {
        setState(() => _globalError =
            'Muitas tentativas. Aguarde 15 minutos antes de tentar novamente.');
      } else {
        // Always show success message — never reveal if email exists.
        if (mounted) setState(() => _submitted = true);
      }
    } catch (_) {
      if (mounted) setState(() => _submitted = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppThemeTokens.of(context);

    return Scaffold(
      body: AppBackground(
        scrollable: false,
        child: SizedBox.expand(
          child: SafeArea(
            child: Padding(
              padding: AppSpacing.screenPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
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
                      const SizedBox(width: 12),
                      Text(
                        'Recuperar senha',
                        style: AppTextStyles.h2(t.txtPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  if (_submitted) ...[
                    // ── Success state ──────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E)
                            .withValues(alpha: t.isDark ? 0.15 : 0.08),
                        borderRadius: AppRadius.baseAll,
                        border: Border.all(
                          color: const Color(0xFF22C55E)
                              .withValues(alpha: 0.35),
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
                              'Se esse e-mail estiver cadastrado, você receberá um link em breve.',
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
                      label: 'Voltar ao login',
                      onPressed: () => context.go('/login'),
                    ),
                  ] else ...[
                    // ── Form state ────────────────────────────────────────
                    Text(
                      'Esqueceu sua senha?',
                      style: AppTextStyles.h1(t.txtPrimary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Informe seu e-mail e enviaremos um link para redefinir sua senha.',
                      style: AppTextStyles.body(t.txtSecondary),
                    ),
                    const SizedBox(height: 32),

                    if (_globalError != null) ...[
                      _ErrorBanner(message: _globalError!),
                      const SizedBox(height: 16),
                    ],

                    AppInputField(
                      placeholder: 'E-mail',
                      controller: _emailController,
                      errorText: _emailError,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      onSubmitted: _submit,
                      onChanged: (_) => setState(() => _emailError = null),
                    ),
                    const SizedBox(height: 28),

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
                            label: 'Enviar link de recuperação',
                            onPressed: _submit,
                          ),
                  ],

                  const Spacer(),

                  Center(
                    child: GestureDetector(
                      onTap: () => context.go('/login'),
                      child: Text(
                        'Voltar ao login',
                        style: AppTextStyles.body(t.primary).copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
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
