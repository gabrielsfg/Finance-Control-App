import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../data/dtos/create_account_request_dto.dart';
import '../data/models/account.dart';
import '../providers/accounts_provider.dart';

class CreateAccountPage extends ConsumerStatefulWidget {
  const CreateAccountPage({super.key});

  @override
  ConsumerState<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends ConsumerState<CreateAccountPage> {
  final _nameController = TextEditingController();
  final _goalController = TextEditingController();
  final _creditLimitController = TextEditingController();
  final _billingDueDayController = TextEditingController();

  AccountType _accountType = AccountType.checking;
  bool _isDefault = true;
  bool _excludeFromNetWorth = false;
  bool _isLoading = false;

  String? _nameError;
  String? _creditLimitError;
  String? _billingDueDayError;
  String? _submitError;

  @override
  void dispose() {
    _nameController.dispose();
    _goalController.dispose();
    _creditLimitController.dispose();
    _billingDueDayController.dispose();
    super.dispose();
  }

  static int _parseCents(String raw) {
    if (raw.trim().isEmpty) return 0;
    return CentsInputFormatter.parseCents(raw);
  }

  bool _validate() {
    String? nameErr;
    String? creditErr;
    String? dayErr;

    if (_nameController.text.trim().isEmpty) {
      nameErr = 'Account name is required';
    }

    if (_accountType == AccountType.credit) {
      final limit = _parseCents(_creditLimitController.text);
      if (limit <= 0) creditErr = 'Enter a valid credit limit';

      final dayText = _billingDueDayController.text.trim();
      if (dayText.isEmpty) {
        dayErr = 'Enter the billing due day';
      } else {
        final day = int.tryParse(dayText);
        if (day == null || day < 1 || day > 31) {
          dayErr = 'Day must be between 1 and 31';
        }
      }
    }

    setState(() {
      _nameError = nameErr;
      _creditLimitError = creditErr;
      _billingDueDayError = dayErr;
    });

    return nameErr == null && creditErr == null && dayErr == null;
  }

  Future<void> _submit() async {
    if (!_validate()) return;

    setState(() {
      _isLoading = true;
      _submitError = null;
    });

    try {
      final isCredit = _accountType == AccountType.credit;
      final goalCents = _parseCents(_goalController.text);
      await ref.read(accountsNotifierProvider.notifier).createAccount(
            CreateAccountRequestDto(
              name: _nameController.text.trim(),
              accountType: _accountType.apiValue,
              isDefaultAccount: _isDefault,
              isExcludedFromNetWorth: _excludeFromNetWorth,
              goalAmount: goalCents > 0 ? goalCents : null,
              creditLimit: isCredit
                  ? _parseCents(_creditLimitController.text)
                  : null,
              billingDueDay: isCredit
                  ? int.tryParse(_billingDueDayController.text.trim())
                  : null,
            ),
          );
      if (mounted) context.pop();
    } catch (e) {
      setState(() {
        _submitError = 'Failed to create account. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppThemeTokens.of(context);
    final bottomPad = MediaQuery.viewPaddingOf(context).bottom;
    final isCredit = _accountType == AccountType.credit;

    return Scaffold(
      backgroundColor: t.bg,
      body: AppBackground(
        scrollable: true,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: AppSpacing.screenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                // ── Header ──────────────────────────────────────────────────
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Icon(
                        LucideIcons.arrowLeft,
                        color: t.txtPrimary,
                        size: 22,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'New Account',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body(t.txtPrimary).copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                        ),
                      ),
                    ),
                    const SizedBox(width: 22),
                  ],
                ),
                const SizedBox(height: 24),
                // ── Account type selector ────────────────────────────────────
                _AccountTypeSelector(
                  selected: _accountType,
                  onChanged: (type) => setState(() {
                    _accountType = type;
                    _creditLimitError = null;
                    _billingDueDayError = null;
                  }),
                ),
                const SizedBox(height: 20),
                // ── Account name ─────────────────────────────────────────────
                AppInputField(
                  label: 'Account name',
                  placeholder: 'e.g. Nubank, Cash, Savings',
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  errorText: _nameError,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) {
                    if (_nameError != null) setState(() => _nameError = null);
                  },
                ),
                const SizedBox(height: 14),
                // ── Goal ─────────────────────────────────────────────────────
                AppInputField(
                  label: 'Goal (optional)',
                  placeholder: '0,00',
                  controller: _goalController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    const CentsInputFormatter(),
                  ],
                  textInputAction:
                      isCredit ? TextInputAction.next : TextInputAction.done,
                  leftIcon: const Icon(LucideIcons.target, size: 16),
                ),
                // ── Credit-only fields ────────────────────────────────────────
                if (isCredit) ...[
                  const SizedBox(height: 14),
                  AppInputField(
                    label: 'Credit limit',
                    placeholder: '0,00',
                    controller: _creditLimitController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      const CentsInputFormatter(),
                    ],
                    errorText: _creditLimitError,
                    textInputAction: TextInputAction.next,
                    leftIcon: const Icon(LucideIcons.creditCard, size: 16),
                    onChanged: (_) {
                      if (_creditLimitError != null) {
                        setState(() => _creditLimitError = null);
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  AppInputField(
                    label: 'Billing due day',
                    placeholder: 'e.g. 10',
                    controller: _billingDueDayController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(2),
                    ],
                    errorText: _billingDueDayError,
                    textInputAction: TextInputAction.done,
                    leftIcon: const Icon(LucideIcons.calendarDays, size: 16),
                    onChanged: (_) {
                      if (_billingDueDayError != null) {
                        setState(() => _billingDueDayError = null);
                      }
                    },
                  ),
                ],
                const SizedBox(height: 20),
                // ── Toggles ───────────────────────────────────────────────────
                GlassCard(
                  child: Column(
                    children: [
                      _ToggleRow(
                        label: 'Default Account',
                        subtitle: 'Pre-select in new transactions',
                        value: _isDefault,
                        onChanged: (v) => setState(() => _isDefault = v),
                      ),
                      Divider(
                        height: 20,
                        thickness: 1,
                        color: t.divider.withValues(alpha: 0.4),
                      ),
                      _ToggleRow(
                        label: 'Exclude from Net Worth',
                        subtitle: 'For investment accounts',
                        value: _excludeFromNetWorth,
                        onChanged: (v) =>
                            setState(() => _excludeFromNetWorth = v),
                      ),
                    ],
                  ),
                ),
                if (_submitError != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _submitError!,
                    style: AppTextStyles.caption(t.error),
                  ),
                ],
                const SizedBox(height: 24),
                // ── Save button ───────────────────────────────────────────────
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : PrimaryButton(
                        label: 'Save',
                        onPressed: _submit,
                      ),
                SizedBox(height: bottomPad + 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Account Type Selector ──────────────────────────────────────────────────────

class _AccountTypeSelector extends StatelessWidget {
  final AccountType selected;
  final ValueChanged<AccountType> onChanged;

  const _AccountTypeSelector({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppThemeTokens.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Account type',
          style: AppTextStyles.caption(t.txtSecondary)
              .copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Row(
          children: AccountType.values.map((type) {
            final isSelected = selected == type;
            return Expanded(
              child: GestureDetector(
                onTap: () => onChanged(type),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: EdgeInsets.only(
                    right: type != AccountType.values.last ? 8 : 0,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? t.primary.withValues(alpha: 0.15)
                        : t.surfaceEl.withValues(alpha: t.isDark ? 0.3 : 0.5),
                    borderRadius: AppRadius.baseAll,
                    border: Border.all(
                      color: isSelected
                          ? t.primary.withValues(alpha: 0.6)
                          : t.divider.withValues(alpha: 0.4),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _typeIcon(type),
                        size: 18,
                        color: isSelected ? t.primary : t.txtTertiary,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        type.label,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.caption(
                          isSelected ? t.primary : t.txtTertiary,
                        ).copyWith(
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  IconData _typeIcon(AccountType type) => switch (type) {
        AccountType.checking => LucideIcons.landmark,
        AccountType.savings => LucideIcons.piggyBank,
        AccountType.credit => LucideIcons.creditCard,
        AccountType.cash => LucideIcons.banknote,
      };
}

// ── Toggle Row ─────────────────────────────────────────────────────────────────

class _ToggleRow extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppThemeTokens.of(context);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.body(t.txtPrimary)
                    .copyWith(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              Text(
                subtitle,
                style: AppTextStyles.caption(t.txtTertiary),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: t.primary,
        ),
      ],
    );
  }
}
