import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../data/auth_repository.dart';
import '../providers/user_profile_provider.dart';

class VerifyEmailPage extends ConsumerStatefulWidget {
  const VerifyEmailPage({super.key, required this.token});

  final String token;

  @override
  ConsumerState<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends ConsumerState<VerifyEmailPage> {
  bool _isLoading = false;
  bool _success = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.token.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _verify());
    }
  }

  Future<void> _verify() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await ref.read(authRepositoryProvider).verifyEmail(widget.token);
      // Invalidate profile so the banner in AppShell disappears.
      ref.invalidate(userProfileProvider);
      if (mounted) setState(() => _success = true);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final String message;
      if (status == 400) {
        message = 'Link inválido ou expirado. Solicite um novo link de verificação.';
      } else if (status == 429) {
        message = 'Muitas tentativas. Aguarde antes de tentar novamente.';
      } else {
        message = 'Erro ao verificar e-mail. Tente novamente.';
      }
      if (mounted) setState(() => _error = message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Erro inesperado. Tente novamente.');
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
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isLoading) ...[
                    CircularProgressIndicator(color: t.primary, strokeWidth: 2.5),
                    const SizedBox(height: 20),
                    Text(
                      'Verificando seu e-mail...',
                      style: AppTextStyles.body(t.txtSecondary),
                    ),
                  ] else if (_success) ...[
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
                              'E-mail verificado com sucesso! Sua conta está ativa.',
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
                      label: 'Continuar',
                      onPressed: () => context.go('/'),
                    ),
                  ] else if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: t.error.withValues(
                            alpha: t.isDark ? 0.15 : 0.08),
                        borderRadius: AppRadius.baseAll,
                        border:
                            Border.all(color: t.error.withValues(alpha: 0.35)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.error_outline,
                              color: t.error, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _error!,
                              style: AppTextStyles.body(t.error),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    PrimaryButton(
                      label: 'Tentar novamente',
                      onPressed: _verify,
                    ),
                  ] else ...[
                    // Shown when token is empty (arrived without deep link).
                    const Icon(Icons.mark_email_unread_outlined,
                        size: 56, color: Color(0xFFF59E0B)),
                    const SizedBox(height: 20),
                    Text(
                      'Verifique seu e-mail',
                      style: AppTextStyles.h2(t.txtPrimary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Enviamos um link de confirmação para o seu e-mail. Clique no link para ativar sua conta.',
                      style: AppTextStyles.body(t.txtSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
