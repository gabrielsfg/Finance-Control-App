import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../../transactions/providers/picker_providers.dart';
import '../../data/dtos/wishlist_dtos.dart';
import '../../data/wishlist_repository.dart';
import '../../providers/wishlist_provider.dart';

class PurchaseBottomSheet extends ConsumerStatefulWidget {
  final int itemId;
  final String itemName;

  const PurchaseBottomSheet({
    super.key,
    required this.itemId,
    required this.itemName,
  });

  @override
  ConsumerState<PurchaseBottomSheet> createState() =>
      _PurchaseBottomSheetState();
}

class _PurchaseBottomSheetState extends ConsumerState<PurchaseBottomSheet> {
  bool _createTransaction = false;
  int? _selectedAccountId;
  int? _selectedSubCategoryId;
  DateTime _transactionDate = DateTime.now();
  late final TextEditingController _descriptionController;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _descriptionController =
        TextEditingController(text: widget.itemName);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _transactionDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _transactionDate = picked);
    }
  }

  Future<void> _confirm() async {
    if (_createTransaction) {
      if (_selectedAccountId == null) {
        setState(() => _errorMessage = 'Selecione uma conta.');
        return;
      }
      if (_selectedSubCategoryId == null) {
        setState(() => _errorMessage = 'Selecione uma subcategoria.');
        return;
      }
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final dto = PurchaseWishlistItemRequestDto(
        createTransaction: _createTransaction,
        accountId: _createTransaction ? _selectedAccountId : null,
        subCategoryId: _createTransaction ? _selectedSubCategoryId : null,
        transactionDate:
            _createTransaction ? _formatDate(_transactionDate) : null,
        description: _createTransaction &&
                _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
      );

      await ref.read(wishlistRepositoryProvider).purchaseItem(widget.itemId, dto);

      ref.invalidate(wishlistItemDetailProvider(widget.itemId));
      ref.read(wishlistNotifierProvider.notifier).refresh();

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item marcado como comprado!')),
        );
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Erro ao marcar como comprado. Tente novamente.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppThemeTokens.of(context);
    final accountsAsync = ref.watch(accountsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Container(
      decoration: BoxDecoration(
        color: t.isDark ? const Color(0xFF1C1830) : Colors.white,
        borderRadius: AppRadius.xl3All.copyWith(
          bottomLeft: Radius.zero,
          bottomRight: Radius.zero,
        ),
        boxShadow: AppShadows.bottomSheet,
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: t.divider,
                  borderRadius: AppRadius.pillAll,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Marcar como Comprado', style: AppTextStyles.h3(t.txtPrimary)),
            const SizedBox(height: 20),

            // Toggle: create transaction
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Criar transação financeira',
                        style: AppTextStyles.body(t.txtPrimary)
                            .copyWith(fontWeight: FontWeight.w500, fontSize: 14),
                      ),
                      Text(
                        'Registrar gasto automaticamente',
                        style: AppTextStyles.caption(t.txtTertiary),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _createTransaction,
                  onChanged: (v) => setState(() => _createTransaction = v),
                  activeColor: t.primary,
                ),
              ],
            ),

            if (_createTransaction) ...[
              const SizedBox(height: 16),
              Divider(color: t.divider.withValues(alpha: 0.5)),
              const SizedBox(height: 16),

              // Account dropdown
              Text(
                'Conta',
                style: AppTextStyles.caption(t.txtSecondary)
                    .copyWith(fontSize: 12, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 6),
              accountsAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, __) =>
                    Text('Erro ao carregar contas', style: AppTextStyles.bodySm(t.error)),
                data: (accounts) => _buildDropdown<int>(
                  t: t,
                  value: _selectedAccountId,
                  hint: 'Selecione a conta',
                  items: accounts
                      .map((a) => DropdownMenuItem(
                            value: a.id,
                            child: Text(a.name,
                                style: AppTextStyles.body(t.txtPrimary)
                                    .copyWith(fontSize: 14)),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedAccountId = v),
                ),
              ),
              const SizedBox(height: 12),

              // Subcategory dropdown (flat list with category prefix)
              Text(
                'Subcategoria',
                style: AppTextStyles.caption(t.txtSecondary)
                    .copyWith(fontSize: 12, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 6),
              categoriesAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, __) =>
                    Text('Erro ao carregar categorias', style: AppTextStyles.bodySm(t.error)),
                data: (categories) {
                  final items = <DropdownMenuItem<int>>[];
                  for (final cat in categories) {
                    for (final sub in cat.subCategories) {
                      items.add(DropdownMenuItem(
                        value: sub.id,
                        child: Text(
                          '${cat.name} › ${sub.name}',
                          style: AppTextStyles.body(t.txtPrimary)
                              .copyWith(fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ));
                    }
                  }
                  return _buildDropdown<int>(
                    t: t,
                    value: _selectedSubCategoryId,
                    hint: 'Selecione a subcategoria',
                    items: items,
                    onChanged: (v) => setState(() => _selectedSubCategoryId = v),
                  );
                },
              ),
              const SizedBox(height: 12),

              // Date picker
              Text(
                'Data',
                style: AppTextStyles.caption(t.txtSecondary)
                    .copyWith(fontSize: 12, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: t.isDark
                        ? const Color(0xFF1C1830).withValues(alpha: 0.85)
                        : const Color(0xFFEDE9FE).withValues(alpha: 0.5),
                    borderRadius: AppRadius.baseAll,
                    border: Border.all(
                      color: t.isDark
                          ? Colors.white.withValues(alpha: 0.09)
                          : const Color(0xFF7C3AED).withValues(alpha: 0.18),
                      width: 1.5,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      Icon(LucideIcons.calendar, size: 18, color: t.txtTertiary),
                      const SizedBox(width: 10),
                      Text(
                        formatDate(_transactionDate),
                        style: AppTextStyles.body(t.txtPrimary)
                            .copyWith(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Description
              Text(
                'Descrição (opcional)',
                style: AppTextStyles.caption(t.txtSecondary)
                    .copyWith(fontSize: 12, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 6),
              AppInputField(
                placeholder: widget.itemName,
                controller: _descriptionController,
                textCapitalization: TextCapitalization.sentences,
              ),
            ],

            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(_errorMessage!, style: AppTextStyles.bodySm(t.error)),
            ],

            const SizedBox(height: 20),
            PrimaryButton(
              label: _isSubmitting ? 'Confirmando...' : 'Confirmar',
              onPressed: _isSubmitting ? null : _confirm,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required AppThemeTokens t,
    required T? value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: t.isDark
            ? const Color(0xFF1C1830).withValues(alpha: 0.85)
            : const Color(0xFFEDE9FE).withValues(alpha: 0.5),
        borderRadius: AppRadius.baseAll,
        border: Border.all(
          color: t.isDark
              ? Colors.white.withValues(alpha: 0.09)
              : const Color(0xFF7C3AED).withValues(alpha: 0.18),
          width: 1.5,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(hint,
              style: AppTextStyles.body(t.txtTertiary).copyWith(fontSize: 14)),
          items: items,
          onChanged: onChanged,
          isExpanded: true,
          style: AppTextStyles.body(t.txtPrimary).copyWith(fontSize: 14),
          dropdownColor: t.isDark ? const Color(0xFF1C1830) : Colors.white,
          icon: Icon(LucideIcons.chevronDown, size: 18, color: t.txtTertiary),
        ),
      ),
    );
  }
}
