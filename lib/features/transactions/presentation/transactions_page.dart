import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../data/models/transaction_item.dart';

// ── Filter enum ────────────────────────────────────────────────────────────

enum _TransactionFilter { all, expenses, income, recurring }

// ── Page ───────────────────────────────────────────────────────────────────

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  _TransactionFilter _filter = _TransactionFilter.all;
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    });
  }

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
              const _SummaryHeader(
                income: 0,
                expense: 0,
                balance: 0,
              ),
              const SizedBox(height: 16),
              _FilterChips(
                selected: _filter,
                onChanged: (f) => setState(() => _filter = f),
              ),
              const SizedBox(height: 16),
              _MonthNavigator(
                month: _selectedMonth,
                onPrevious: _previousMonth,
                onNext: _nextMonth,
              ),
              const SizedBox(height: 8),
              SizedBox(height: bottomPad + 76 + 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Summary Header ─────────────────────────────────────────────────────────

class _SummaryHeader extends StatelessWidget {
  final int income;
  final int expense;
  final int balance;

  const _SummaryHeader({
    required this.income,
    required this.expense,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppThemeTokens.of(context);

    return Column(
      children: [
        Text(
          'Transactions',
          style: AppTextStyles.h2(t.txtPrimary).copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 22,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 14),
        GlassCard(
          child: Row(
            children: [
              Expanded(
                child: _SummaryColumn(
                  label: 'Income',
                  value: formatCurrency(income),
                  color: t.success,
                ),
              ),
              _VerticalDivider(),
              Expanded(
                child: _SummaryColumn(
                  label: 'Expenses',
                  value: formatCurrency(expense),
                  color: t.error,
                ),
              ),
              _VerticalDivider(),
              Expanded(
                child: _SummaryColumn(
                  label: 'Balance',
                  value: formatCurrency(balance),
                  color: t.success,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryColumn({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppThemeTokens.of(context);
    return Column(
      children: [
        Text(
          label,
          style: AppTextStyles.caption(t.txtSecondary).copyWith(fontSize: 11),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.mono(color, fontSize: 13).copyWith(
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = AppThemeTokens.of(context);
    return Container(
      width: 1,
      height: 32,
      color: t.divider.withValues(alpha: t.isDark ? 0.4 : 0.6),
    );
  }
}

// ── Filter Chips ────────────────────────────────────────────────────────────

class _FilterChips extends StatelessWidget {
  final _TransactionFilter selected;
  final ValueChanged<_TransactionFilter> onChanged;

  const _FilterChips({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const filters = [
      (_TransactionFilter.all, 'All'),
      (_TransactionFilter.expenses, 'Expenses'),
      (_TransactionFilter.income, 'Income'),
      (_TransactionFilter.recurring, 'Recurring'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: filters.map((entry) {
          final (filter, label) = entry;
          final isActive = selected == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: AppChip(
              label: label,
              active: isActive,
              onTap: () => onChanged(filter),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Month Navigator ─────────────────────────────────────────────────────────

class _MonthNavigator extends StatelessWidget {
  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const _MonthNavigator({
    required this.month,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppThemeTokens.of(context);
    final label = formatMonthYear(month);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: onPrevious,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: t.isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : t.primary.withValues(alpha: 0.08),
            ),
            child: Center(
              child: Text(
                '‹',
                style: TextStyle(fontSize: 22, color: t.txtSecondary, height: 1),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Text(
          label,
          style: AppTextStyles.body(t.txtPrimary).copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        const SizedBox(width: 16),
        GestureDetector(
          onTap: onNext,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: t.isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : t.primary.withValues(alpha: 0.08),
            ),
            child: Center(
              child: Text(
                '›',
                style: TextStyle(fontSize: 22, color: t.txtSecondary, height: 1),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Transaction Group Section ───────────────────────────────────────────────

class _TransactionGroupSection extends StatelessWidget {
  final TransactionGroup group;

  const _TransactionGroupSection({required this.group});

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  String _groupLabel() {
    if (_isToday(group.date)) return 'TODAY';
    if (_isYesterday(group.date)) return 'YESTERDAY';
    return formatDayHeader(group.date);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppThemeTokens.of(context);
    final label = _groupLabel();
    final dayStr = formatDayHeader(group.date);
    final headerText = label == dayStr ? label : '$label — $dayStr';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          headerText,
          style: AppTextStyles.caption(t.txtTertiary).copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: List.generate(group.items.length, (i) {
              return _TransactionRow(
                item: group.items[i],
                showDivider: i < group.items.length - 1,
              );
            }),
          ),
        ),
      ],
    );
  }
}

// ── Transaction Row ─────────────────────────────────────────────────────────

class _TransactionRow extends StatelessWidget {
  final TransactionItem item;
  final bool showDivider;

  const _TransactionRow({required this.item, this.showDivider = true});

  @override
  Widget build(BuildContext context) {
    final t = AppThemeTokens.of(context);
    final isExpense = item.amountCents < 0;
    final amountColor = isExpense ? t.error : t.success;
    final sign = isExpense ? '-' : '+';
    final amountStr = '$sign${formatCurrency(item.amountCents.abs())}';

    return Column(
      children: [
        GestureDetector(
          onTap: () => context.push('/transactions/detail', extra: item),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Color(item.color).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(item.emoji, style: const TextStyle(fontSize: 20)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: AppTextStyles.body(t.txtPrimary).copyWith(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle,
                        style: AppTextStyles.bodySm(t.txtTertiary)
                            .copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Text(
                  amountStr,
                  style: AppTextStyles.mono(amountColor, fontSize: 13).copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            color: t.divider.withValues(alpha: t.isDark ? 0.35 : 0.6),
          ),
      ],
    );
  }
}
