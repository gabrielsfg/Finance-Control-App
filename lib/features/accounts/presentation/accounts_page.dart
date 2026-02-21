import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/app_widgets.dart';

// ── Mock data (TODO: replace with Riverpod providers) ─────────────────────

const _kNetWorth = 1284350; // R$ 12.843,50

const _kAccounts = [
  _AccountData(
    id: 1,
    name: 'Nubank',
    type: 'Checking',
    balanceCents: 384752,
    isDefault: true,
    excludeFromNetWorth: false,
    color: Color(0xFF8B5CF6),
    icon: LucideIcons.creditCard,
  ),
  _AccountData(
    id: 2,
    name: 'Itaú',
    type: 'Savings',
    balanceCents: 750000,
    isDefault: false,
    excludeFromNetWorth: false,
    color: Color(0xFFF59E0B),
    icon: LucideIcons.building2,
  ),
  _AccountData(
    id: 3,
    name: 'XP Investimentos',
    type: 'Investment',
    balanceCents: 149598,
    isDefault: false,
    excludeFromNetWorth: false,
    color: Color(0xFF06B6D4),
    icon: LucideIcons.trendingUp,
  ),
  _AccountData(
    id: 4,
    name: 'Emergency Fund',
    type: 'Savings',
    balanceCents: 200000,
    isDefault: false,
    excludeFromNetWorth: true,
    color: Color(0xFF22C55E),
    icon: LucideIcons.shieldCheck,
  ),
];

// ── Model ──────────────────────────────────────────────────────────────────

class _AccountData {
  final int id;
  final String name;
  final String type;
  final int balanceCents;
  final bool isDefault;
  final bool excludeFromNetWorth;
  final Color color;
  final IconData icon;

  const _AccountData({
    required this.id,
    required this.name,
    required this.type,
    required this.balanceCents,
    required this.isDefault,
    required this.excludeFromNetWorth,
    required this.color,
    required this.icon,
  });
}

// ── Page ───────────────────────────────────────────────────────────────────

class AccountsPage extends StatelessWidget {
  const AccountsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.viewPaddingOf(context).bottom;

    return AppBackground(
      scrollable: true,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const _Header(),
              const SizedBox(height: 20),
              const _NetWorthCard(),
              const SizedBox(height: 24),
              const _AccountsSection(),
              SizedBox(height: bottomPad + 76 + 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Header ─────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final t = AppThemeTokens.of(context);

    return Row(
      children: [
        Expanded(
          child: Text('Accounts', style: AppTextStyles.h1(t.txtPrimary)),
        ),
        const ThemeToggleButton(),
        const SizedBox(width: 10),
        _AddAccountButton(),
      ],
    );
  }
}

class _AddAccountButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // TODO: navigate to add account page
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.primaryGradient,
          boxShadow: AppShadows.fabShadow,
        ),
        child: const Icon(LucideIcons.plus, color: Colors.white, size: 18),
      ),
    );
  }
}

// ── Net Worth Card ─────────────────────────────────────────────────────────

class _NetWorthCard extends StatelessWidget {
  const _NetWorthCard();

  @override
  Widget build(BuildContext context) {
    final t = AppThemeTokens.of(context);

    final includedCount =
        _kAccounts.where((a) => !a.excludeFromNetWorth).length;
    final excludedCount =
        _kAccounts.where((a) => a.excludeFromNetWorth).length;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'NET WORTH',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption(t.txtTertiary).copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            formatCurrency(_kNetWorth),
            textAlign: TextAlign.center,
            style: AppTextStyles.moneyLg(t.txtPrimary).copyWith(fontSize: 34),
          ),
          const SizedBox(height: 16),
          Divider(
            height: 1,
            thickness: 1,
            color: t.divider.withValues(alpha: t.isDark ? 0.4 : 0.6),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _NetWorthStat(
                label: 'Included',
                count: includedCount,
                icon: LucideIcons.checkCircle,
                color: t.success,
              ),
              Container(
                width: 1,
                height: 32,
                color: t.divider.withValues(alpha: t.isDark ? 0.4 : 0.6),
              ),
              _NetWorthStat(
                label: 'Excluded',
                count: excludedCount,
                icon: LucideIcons.minusCircle,
                color: t.txtTertiary,
              ),
              Container(
                width: 1,
                height: 32,
                color: t.divider.withValues(alpha: t.isDark ? 0.4 : 0.6),
              ),
              _NetWorthStat(
                label: 'Total',
                count: _kAccounts.length,
                icon: LucideIcons.wallet,
                color: t.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NetWorthStat extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color color;

  const _NetWorthStat({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppThemeTokens.of(context);

    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 4),
          Text(
            '$count',
            style: AppTextStyles.h3(t.txtPrimary).copyWith(fontSize: 16),
          ),
          Text(
            label,
            style: AppTextStyles.caption(t.txtTertiary),
          ),
        ],
      ),
    );
  }
}

// ── Accounts Section ───────────────────────────────────────────────────────

class _AccountsSection extends StatelessWidget {
  const _AccountsSection();

  @override
  Widget build(BuildContext context) {
    final t = AppThemeTokens.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('My Accounts', style: AppTextStyles.h3(t.txtPrimary)),
            const Spacer(),
            Text(
              '${_kAccounts.length} accounts',
              style: AppTextStyles.bodySm(t.txtTertiary),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ..._kAccounts.map((account) => _AccountCard(data: account)),
      ],
    );
  }
}

class _AccountCard extends StatelessWidget {
  final _AccountData data;

  const _AccountCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final t = AppThemeTokens.of(context);
    final isNegative = data.balanceCents < 0;
    final balanceColor = isNegative ? t.error : t.txtPrimary;

    return GestureDetector(
      onTap: () {
        // TODO: navigate to account detail / edit
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: t.isDark
              ? const Color(0xFF1C1830).withValues(alpha: 0.72)
              : Colors.white.withValues(alpha: 0.9),
          borderRadius: AppRadius.xlAll,
          border: Border.all(
            color: t.isDark
                ? Colors.white.withValues(alpha: 0.07)
                : const Color(0xFF7C3AED).withValues(alpha: 0.12),
          ),
          boxShadow: t.isDark ? [] : AppShadows.cardLight,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: data.color.withValues(alpha: 0.15),
                borderRadius: AppRadius.lgAll,
              ),
              child: Icon(data.icon, color: data.color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          data.name,
                          style: AppTextStyles.body(t.txtPrimary).copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (data.isDefault) ...[
                        const SizedBox(width: 6),
                        _Badge(label: 'Default', color: t.primary),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        data.type,
                        style: AppTextStyles.bodySm(t.txtTertiary),
                      ),
                      if (data.excludeFromNetWorth) ...[
                        const SizedBox(width: 6),
                        _Badge(label: 'Excluded', color: t.txtTertiary),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatCurrency(data.balanceCents),
                  style: AppTextStyles.moneyMd(balanceColor)
                      .copyWith(fontSize: 15),
                ),
                const SizedBox(height: 2),
                Icon(
                  LucideIcons.chevronRight,
                  size: 16,
                  color: t.txtDisabled,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.pillAll,
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 0.8,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
