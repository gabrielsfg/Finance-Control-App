import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_widgets.dart';
import 'budget_wizard_widgets.dart';
import 'create_budget_state.dart';

// ── Recurrence options ───────────────────────────────────────────────────────

final _kRecurrenceOptions = [
  ('Monthly', '📅'),
  ('Weekly', '📆'),
  ('Biweekly', '🗓️'),
  ('Quarterly', '📊'),
  ('Annually', '🗒️'),
];

// ── Page ───────────────────────────────────────────────────────────────────

class CreateBudgetStep1Page extends StatefulWidget {
  const CreateBudgetStep1Page({super.key});

  @override
  State<CreateBudgetStep1Page> createState() => _CreateBudgetStep1PageState();
}

class _CreateBudgetStep1PageState extends State<CreateBudgetStep1Page> {
  final _nameController = TextEditingController(
    text: CreateBudgetState.instance.name,
  );
  String _recurrence = CreateBudgetState.instance.recurrence;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _canProceed => _nameController.text.trim().isNotEmpty;

  void _next() {
    if (!_canProceed) return;
    CreateBudgetState.instance
      ..name = _nameController.text.trim()
      ..recurrence = _recurrence;
    context.push('/budgets/create/step2');
  }

  @override
  Widget build(BuildContext context) {
    final t = AppThemeTokens.of(context);
    final bottomPad = MediaQuery.viewPaddingOf(context).bottom;

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
              // ── Step indicator ─────────────────────────────────────────
              const BudgetStepIndicator(current: 1),
              const SizedBox(height: 28),

              Expanded(
                child: SingleChildScrollView(
                  padding: AppSpacing.screenPadding.copyWith(bottom: 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Budget details',
                        style: AppTextStyles.h2(t.txtPrimary).copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Give your budget a name and choose how often it repeats.',
                        style: AppTextStyles.body(t.txtSecondary).copyWith(
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 28),
                      AppInputField(
                        label: 'Budget name',
                        placeholder: 'e.g. Fixed Costs',
                        controller: _nameController,
                        textCapitalization: TextCapitalization.sentences,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'Recurrence',
                        style: AppTextStyles.caption(t.txtSecondary).copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ..._kRecurrenceOptions.map((option) {
                        final (label, emoji) = option;
                        final isSelected = _recurrence == label;
                        return _RecurrenceTile(
                          label: label,
                          emoji: emoji,
                          selected: isSelected,
                          onTap: () => setState(() => _recurrence = label),
                        );
                      }),
                    ],
                  ),
                ),
              ),

              // ── Next button ────────────────────────────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(24, 16, 24, bottomPad + 20),
                child: PrimaryButton(
                  label: 'Next: Define Areas',
                  onPressed: _canProceed ? _next : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Recurrence Tile ───────────────────────────────────────────────────────────

class _RecurrenceTile extends StatelessWidget {
  final String label;
  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  const _RecurrenceTile({
    required this.label,
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppThemeTokens.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? t.primary.withValues(alpha: t.isDark ? 0.18 : 0.08)
              : t.isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.white.withValues(alpha: 0.7),
          borderRadius: AppRadius.baseAll,
          border: Border.all(
            color: selected
                ? t.primary.withValues(alpha: t.isDark ? 0.55 : 0.4)
                : t.isDark
                    ? Colors.white.withValues(alpha: 0.07)
                    : t.primary.withValues(alpha: 0.12),
            width: selected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Text(
              emoji,
              style: TextStyle(
                fontSize: 20,
                color: selected ? t.primary : t.txtTertiary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.body(
                  selected ? t.primary : t.txtPrimary,
                ).copyWith(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (selected)
              Text('✓', style: TextStyle(fontSize: 18, color: t.primary, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
