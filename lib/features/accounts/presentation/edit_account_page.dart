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
import '../data/dtos/update_account_request_dto.dart';
import '../data/models/account.dart';
import '../data/models/account_detail.dart';
import '../providers/accounts_provider.dart';

class EditAccountPage extends ConsumerStatefulWidget {
  final int accountId;

  const EditAccountPage({super.key, required this.accountId});

  @override
  ConsumerState<EditAccountPage> createState() => _EditAccountPageState();
}

class _EditAccountPageState extends ConsumerState<EditAccountPage> {
  final _nameController = TextEditingController();
  final _goalController = TextEditingController();
  final _creditLimitController = TextEditingController();
  final _billingDueDayController = TextEditingController();

  AccountType _accountType = AccountType.checking;
  bool _isDefault = false;
  bool _excludeFromNetWorth = false;
  bool _initialized = false;

  String? _nameError;
  String? _creditLimitError;
  String? _billingDueDayError;
  String? _submitError;
  bool _isSaving = false;
  bool _isDeleting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _goalController.dispose();
    _creditLimitController.dispose();
    _billingDueDayController.dispose();
    super.dispose();
  }

  void _initFromDetail(AccountDetail detail) {
    if (_initialized) return;
    _initialized = true;
    _nameController.text = detail.name;
    _accountType = detail.accountType;
    if (detail.goalAmountCents != null && detail.goalAmountCents! > 0) {
      _goalController.text = _formatCentsForInput(detail.goalAmountCents!);
    }
    if (detail.isCredit) {
      if (detail.creditLimitCents != null && detail.creditLimitCents! > 0) {
        _creditLimitController.text =
            _formatCentsForInput(detail.creditLimitCents!);
      }
      if (detail.billingDueDay != null) {
        _billingDueDayController.text = '${detail.billingDueDay}';
      }
    }
    _isDefault = detail.isDefault;
    _excludeFromNetWorth = detail.excludeFromNetWorth;
  }

  static String _formatCentsForInput(int cents) {
    if (cents == 0) return '';
    final abs = cents.abs();
    final digits = abs.toString().padLeft(3, '0');
    final intPart = digits.substring(0, digits.length - 2);
    final fracPart = digits.substring(digits.length - 2);
    return '$intPart,$fracPart';
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

  Future<void> _save() async {
    if (!_validate()) return;
    setState(() {
      _isSaving = true;
      _submitError = null;
    });

    try {
      final isCredit = _accountType == AccountType.credit;
      final goalCents = _parseCents(_goalController.text);
      await ref.read(accountsNotifierProvider.notifier).updateAccount(
            widget.accountId,
            UpdateAccountRequestDto(
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
        _submitError = 'Failed to save changes. Please try again.';
        _isSaving = false;
      });
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _DeleteConfirmDialog(
        accountName: _nameController.text.trim(),
      ),
    );
    if (confirmed != true) return;

    setState(() => _isDeleting = true);
    try {
      await ref
          .read(accountsNotifierProvider.notifier)
          .deleteAccount(widget.accountId);
      if (mounted) context.pop();
    } catch (e) {
      setState(() {
        _submitError = 'Failed to delete account. Please try again.';
        _isDeleting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(accountDetailProvider(widget.accountId));
    final t = AppThemeTokens.of(context);
    final bottomPad = MediaQuery.viewPaddingOf(context).bottom;

    return Scaffold(
      backgroundColor: t.bg,
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.alertCircle, color: t.error, size: 32),
              const SizedBox(height: 8),
              Text('Failed to load account',
                  style: AppTextStyles.body(t.txtSecondary)),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () =>
                    ref.invalidate(accountDetailProvider(widget.accountId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (detail) {
          _initFromDetail(detail);
          final isCredit = _accountType == AccountType.credit;

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
                    // ── Header ─────────────────────────────────────────────
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => context.pop(),
                          child: Icon(LucideIcons.arrowLeft,
                              color: t.txtPrimary, size: 22),
                        ),
                        Expanded(
                          child: Text(
                            'Edit Account',
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
                    // ── Account type selector ──────────────────────────────
                    _AccountTypeSelector(
                      selected: _accountType,
                      onChanged: (type) => setState(() {
                        _accountType = type;
                        _creditLimitError = null;
                        _billingDueDayError = null;
                      }),
                    ),
                    const SizedBox(height: 20),
                    // ── Account name ───────────────────────────────────────
                    AppInputField(
                      label: 'Account name',
                      placeholder: 'e.g. Nubank, Cash, Savings',
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      errorText: _nameError,
                      textInputAction: TextInputAction.next,
                      onChanged: (_) {
                        if (_nameError != null) {
                          setState(() => _nameError = null);
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    // ── Goal ──────────────────────────────────────────────
                    AppInputField(
                      label: 'Goal (optional)',
                      placeholder: '0,00',
                      controller: _goalController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        const CentsInputFormatter(),
                      ],
                      textInputAction: isCredit
                          ? TextInputAction.next
                          : TextInputAction.done,
                      leftIcon: const Icon(LucideIcons.target, size: 16),
                    ),
                    // ── Credit-only fields ─────────────────────────────────
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
                        leftIcon:
                            const Icon(LucideIcons.creditCard, size: 16),
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
                        leftIcon:
                            const Icon(LucideIcons.calendarDays, size: 16),
                        onChanged: (_) {
                          if (_billingDueDayError != null) {
                            setState(() => _billingDueDayError = null);
                          }
                        },
                      ),
                    ],
                    const SizedBox(height: 20),
                    // ── Toggles ────────────────────────────────────────────
                    GlassCard(
                      child: Column(
                        children: [
                          _ToggleRow(
                            label: 'Default Account',
                            subtitle: 'Pre-select in new transactions',
                            value: _isDefault,
                            onChanged: (v) =>
                                setState(() => _isDefault = v),
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
                    const SizedBox(height: 28),
                    // ── Recent Transactions ────────────────────────────────
                    if (detail.recentTransactions.isNotEmpty) ...[
                      _RecentTransactionsSection(
                        transactions: detail.recentTransactions,
                      ),
                      const SizedBox(height: 28),
                    ],
                    // ── Error ──────────────────────────────────────────────
                    if (_submitError != null) ...[
                      Text(
                        _submitError!,
                        style: AppTextStyles.caption(t.error),
                      ),
                      const SizedBox(height: 12),
                    ],
                    // ── Action Buttons ─────────────────────────────────────
                    _ActionButtons(
                      isSaving: _isSaving,
                      isDeleting: _isDeleting,
                      onNewTransaction: () =>
                          context.push('/transactions/add'),
                      onDelete: _delete,
                      onSave: _save,
                    ),
                    SizedBox(height: bottomPad + 24),
                  ],
                ),
              ),
            ),
          );
        },
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

// ── Recent Transactions Section ────────────────────────────────────────────────

class _RecentTransactionsSection extends StatelessWidget {
  final List<RecentTransaction> transactions;

  const _RecentTransactionsSection({required this.transactions});

  @override
  Widget build(BuildContext context) {
    final t = AppThemeTokens.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Recent Transactions',
              style: AppTextStyles.body(t.txtPrimary)
                  .copyWith(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const Spacer(),
            GestureDetector(
              // TODO: navigate to transactions page with account filter
              onTap: () {},
              child: Text(
                'View all',
                style: AppTextStyles.caption(t.primary)
                    .copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (int i = 0; i < transactions.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: t.divider.withValues(alpha: 0.35),
                    indent: 16,
                    endIndent: 16,
                  ),
                _TransactionRow(transaction: transactions[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _TransactionRow extends StatelessWidget {
  final RecentTransaction transaction;

  const _TransactionRow({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final t = AppThemeTokens.of(context);
    final isExpense = transaction.isExpense;
    final valueColor = isExpense ? t.error : t.success;
    final valuePrefix = isExpense ? '-' : '+';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: valueColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isExpense ? LucideIcons.arrowDownLeft : LucideIcons.arrowUpRight,
              color: valueColor,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description?.isNotEmpty == true
                      ? transaction.description!
                      : transaction.subCategoryName,
                  style: AppTextStyles.body(t.txtPrimary)
                      .copyWith(fontSize: 13, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  transaction.categoryName,
                  style: AppTextStyles.caption(t.txtTertiary),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$valuePrefix${formatCurrency(transaction.valueCents.abs())}',
            style: AppTextStyles.moneyMd(valueColor)
                .copyWith(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ── Action Buttons ─────────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  final bool isSaving;
  final bool isDeleting;
  final VoidCallback onNewTransaction;
  final VoidCallback onDelete;
  final VoidCallback onSave;

  const _ActionButtons({
    required this.isSaving,
    required this.isDeleting,
    required this.onNewTransaction,
    required this.onDelete,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppThemeTokens.of(context);
    final isBusy = isSaving || isDeleting;

    return Column(
      children: [
        OutlinedButton.icon(
          onPressed: isBusy ? null : onNewTransaction,
          icon: Icon(LucideIcons.plus, size: 16, color: t.primary),
          label: Text(
            '+ New Transaction',
            style: AppTextStyles.body(t.primary)
                .copyWith(fontWeight: FontWeight.w600),
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            side: BorderSide(color: t.primary.withValues(alpha: 0.5)),
            shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: isDeleting
                  ? const Center(child: CircularProgressIndicator())
                  : OutlinedButton.icon(
                      onPressed: isBusy ? null : onDelete,
                      icon: Icon(LucideIcons.trash2,
                          size: 15, color: t.error),
                      label: Text(
                        'Delete',
                        style: AppTextStyles.body(t.error)
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        side: BorderSide(
                            color: t.error.withValues(alpha: 0.5)),
                        shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.lgAll),
                      ),
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: isSaving
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: isBusy ? null : onSave,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        backgroundColor: t.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.lgAll),
                        elevation: 0,
                      ),
                      child: Text(
                        'Save Changes',
                        style: AppTextStyles.body(Colors.white)
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Delete Confirm Dialog ──────────────────────────────────────────────────────

class _DeleteConfirmDialog extends StatelessWidget {
  final String accountName;

  const _DeleteConfirmDialog({required this.accountName});

  @override
  Widget build(BuildContext context) {
    final t = AppThemeTokens.of(context);

    return AlertDialog(
      backgroundColor: t.bg,
      title: Text('Delete Account', style: AppTextStyles.h3(t.txtPrimary)),
      content: Text(
        'Are you sure you want to delete "$accountName"? This action cannot be undone.',
        style: AppTextStyles.body(t.txtSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('Cancel', style: AppTextStyles.body(t.txtTertiary)),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            'Delete',
            style: AppTextStyles.body(t.error)
                .copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
