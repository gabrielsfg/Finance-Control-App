import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../features/auth/providers/user_profile_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'app_widgets.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _indexFromLocation(location);
    final isEmailVerified =
        ref.watch(userProfileProvider).valueOrNull?.isEmailVerified ?? true;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            Theme.of(context).brightness == Brightness.dark
                ? Brightness.light
                : Brightness.dark,
      ),
      child: Scaffold(
        extendBody: true,
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            if (!isEmailVerified) const _VerifyEmailBanner(),
            Expanded(child: child),
          ],
        ),
        floatingActionButton: AppFAB(
          onTap: () => context.push('/transactions/add'),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        bottomNavigationBar: AppNavBar(
          activeIndex: currentIndex,
          onTap: (index) => _onTap(context, index),
        ),
      ),
    );
  }

  int _indexFromLocation(String location) {
    if (location.startsWith('/transactions')) return 1;
    if (location.startsWith('/budgets')) return 2;
    if (location.startsWith('/accounts')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/');
      case 1:
        context.go('/transactions');
      case 2:
        context.go('/budgets');
      case 3:
        context.go('/accounts');
      case 4:
        context.go('/profile');
    }
  }
}

class _VerifyEmailBanner extends StatelessWidget {
  const _VerifyEmailBanner();

  @override
  Widget build(BuildContext context) {
    final t = AppThemeTokens.of(context);
    final topPad = MediaQuery.viewPaddingOf(context).top;

    return Container(
      width: double.infinity,
      color: const Color(0xFFF59E0B).withValues(alpha: t.isDark ? 0.18 : 0.12),
      padding: EdgeInsets.fromLTRB(16, topPad + 8, 16, 8),
      child: Row(
        children: [
          Icon(
            LucideIcons.mailWarning,
            size: 16,
            color: const Color(0xFFF59E0B),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Verifique seu e-mail para ativar sua conta.',
              style: AppTextStyles.bodySm(
                t.isDark ? const Color(0xFFFCD34D) : const Color(0xFF92400E),
              ).copyWith(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
