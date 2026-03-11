import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../data/models/budget_models.dart';
import '../providers/budget_provider.dart';
import 'budget_wizard_widgets.dart';
import 'create_budget_state.dart';

// ── Page ───────────────────────────────────────────────────────────────────

class CreateBudgetStep3Page extends ConsumerStatefulWidget {
  const CreateBudgetStep3Page({super.key});

  @override
  ConsumerState<CreateBudgetStep3Page> createState() =>
      _CreateBudgetStep3PageState();
}

class _CreateBudgetStep3PageState
    extends ConsumerState<CreateBudgetStep3Page> {
  bool _isLoading = false;
  String? _error;

  Future<void> _confirm() async {
    final s = CreateBudgetState.instance;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await ref.read(budgetNotifierProvider.notifier).createBudget(
            name: s.name,
            recurrence: s.recurrence,
            startDay: s.startDay,
            areas: s.areas,
          );
      if (!mounted) return;
      s.reset();
      context.go('/budgets');
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to create budget. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = CreateBudgetState.instance;
    final t = AppThemeTokens.of(context);
    final bottomPad = MediaQuery.viewPaddingOf(context).bottom;

    final totalIncomeCents = state.areas.fold<int>(
      0,
      (sum, a) => sum + a.totalIncomeCents,
    );
    final totalExpenseCents = state.areas.fold<int>(
      0,
      (sum, a) => sum + a.totalExpenseCents,
    );
    final balanceCents = totalIncomeCents - totalExpenseCents;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        scrollable: false,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // ── App bar ────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: t.isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : t.primary.withValues(alpha: 0.08),
                        ),
                        child: Center(
                          child: Text('←', style: TextStyle(fontSize: 18, color: t.txtPrimary)),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'New Budget',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body(t.txtPrimary).copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                        ),
                      ),
                    ),
                    const SizedBox(width: 36),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const BudgetStepIndicator(current: 3),
              const SizedBox(height: 24),

              Expanded(
                child: SingleChildScrollView(
                  padding: AppSpacing.screenPadding.copyWith(bottom: 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Review & confirm',
                        style: AppTextStyles.h2(t.txtPrimary).copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Check everything before creating your budget.',
                        style: AppTextStyles.body(t.txtSecondary).copyWith(
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Budget info card ──────────────────────────────
                      GlassCard(
                        child: Column(
                          children: [
                            _SummaryRow(
                              label: 'Name',
                              value: state.name,
                              valueStyle: AppTextStyles.body(t.txtPrimary)
                                  .copyWith(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600),
                            ),
                            Divider(
                              height: 16,
                              thickness: 1,
                              color: t.divider
                                  .withValues(alpha: t.isDark ? 0.3 : 0.5),
                            ),
                            _SummaryRow(
                              label: 'Recurrence',
                              value: state.recurrence,
                            ),
                            Divider(
                              height: 16,
                              thickness: 1,
                              color: t.divider
                                  .withValues(alpha: t.isDark ? 0.3 : 0.5),
                            ),
                            _SummaryRow(
                              label: 'Total income',
                              value: formatCurrency(totalIncomeCents),
                              valueStyle: AppTextStyles.mono(t.success,
                                      fontSize: 14)
                                  .copyWith(fontWeight: FontWeight.w700),
                            ),
                            Divider(
                              height: 16,
                              thickness: 1,
                              color: t.divider
                                  .withValues(alpha: t.isDark ? 0.3 : 0.5),
                            ),
                            _SummaryRow(
                              label: 'Total expenses',
                              value: '- ${formatCurrency(totalExpenseCents)}',
                              valueStyle: AppTextStyles.mono(t.error,
                                      fontSize: 14)
                                  .copyWith(fontWeight: FontWeight.w700),
                            ),
                            Divider(
                              height: 16,
                              thickness: 1,
                              color: t.divider
                                  .withValues(alpha: t.isDark ? 0.3 : 0.5),
                            ),
                            _SummaryRow(
                              label: 'Balance',
                              value: '${balanceCents < 0 ? '- ' : ''}${formatCurrency(balanceCents.abs())}',
                              valueStyle: AppTextStyles.mono(
                                      balanceCents >= 0 ? t.success : t.error,
                                      fontSize: 14)
                                  .copyWith(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Areas summary ─────────────────────────────────
                      Text(
                        'Areas',
                        style: AppTextStyles.h3(t.txtPrimary).copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...state.areas.map(
                        (area) => _AreaSummaryCard(area: area),
                      ),
                    ],
                  ),
                ),
              ),

              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    _error!,
                    style: AppTextStyles.bodySm(
                      AppThemeTokens.of(context).error,
                    ).copyWith(fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
              // ── Confirm button ─────────────────────────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(24, 16, 24, bottomPad + 20),
                child: PrimaryButton(
                  label: _isLoading ? 'Creating...' : 'Create Budget',
                  onPressed: _isLoading ? null : _confirm,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Summary Row ───────────────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? valueStyle;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppThemeTokens.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.body(t.txtSecondary).copyWith(fontSize: 13),
        ),
        Text(
          value,
          style: valueStyle ??
              AppTextStyles.body(t.txtPrimary).copyWith(fontSize: 13),
        ),
      ],
    );
  }
}

// ── Area Summary Card ─────────────────────────────────────────────────────────

class _AreaSummaryCard extends StatefulWidget {
  final DraftArea area;

  const _AreaSummaryCard({required this.area});

  @override
  State<_AreaSummaryCard> createState() => _AreaSummaryCardState();
}

class _AreaSummaryCardState extends State<_AreaSummaryCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final t = AppThemeTokens.of(context);
    final area = widget.area;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            // Area header
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        area.name,
                        style: AppTextStyles.body(t.txtPrimary).copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Text(
                      formatCurrency(area.totalAllocatedCents),
                      style: AppTextStyles.mono(t.txtSecondary, fontSize: 14)
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Text('▾', style: TextStyle(fontSize: 20, color: t.txtTertiary, height: 1)),
                    ),
                  ],
                ),
              ),
            ),
            if (_expanded && area.subcategories.isNotEmpty) ...[
              Divider(
                height: 1,
                thickness: 1,
                color: t.divider.withValues(alpha: t.isDark ? 0.3 : 0.5),
              ),
              ...area.subcategories.asMap().entries.map((entry) {
                final sub = entry.value;
                final isLast = entry.key == area.subcategories.length - 1;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sub.name,
                                  style: AppTextStyles.body(t.txtPrimary)
                                      .copyWith(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500),
                                ),
                                if (sub.categoryName.isNotEmpty)
                                  Text(
                                    sub.categoryName,
                                    style: AppTextStyles.caption(t.txtTertiary)
                                        .copyWith(fontSize: 11),
                                  ),
                              ],
                            ),
                          ),
                          Text(
                            '${sub.allocationType == 'Expense' ? '- ' : ''}${formatCurrency(sub.allocatedCents)}',
                            style: AppTextStyles.mono(
                              sub.allocationType == 'Expense' ? t.error : t.success,
                              fontSize: 13,
                            ).copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    if (!isLast)
                      Divider(
                        height: 1,
                        thickness: 1,
                        indent: 16,
                        endIndent: 16,
                        color: t.divider
                            .withValues(alpha: t.isDark ? 0.2 : 0.35),
                      ),
                  ],
                );
              }),
              const SizedBox(height: 6),
            ],
          ],
        ),
      ),
    );
  }
}

