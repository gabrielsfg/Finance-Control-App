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
import '../data/dtos/wishlist_dtos.dart';
import '../data/enums/wishlist_enums.dart';
import '../data/models/wishlist_item.dart';
import '../data/models/wishlist_link_form_entry.dart';
import '../data/wishlist_repository.dart';
import '../providers/wishlist_provider.dart';

class WishlistFormPage extends ConsumerStatefulWidget {
  final int? itemId;
  final WishlistItem? initialItem;

  const WishlistFormPage({super.key, this.itemId, this.initialItem});

  @override
  ConsumerState<WishlistFormPage> createState() => _WishlistFormPageState();
}

class _WishlistFormPageState extends ConsumerState<WishlistFormPage> {
  final _nameController = TextEditingController();
  final _currentPriceController = TextEditingController();
  final _targetPriceController = TextEditingController();
  final _imageUrlController = TextEditingController();

  WishlistPriority _priority = WishlistPriority.low;
  DateTime? _deadline;
  bool _isSubmitting = false;
  String? _errorMessage;

  // Links management
  final List<WishlistLinkFormEntry> _links = [];
  bool _showAddLinkForm = false;
  final _newLinkUrlController = TextEditingController();
  final _newLinkStoreNameController = TextEditingController();

  bool get _isEdit => widget.itemId != null;

  @override
  void initState() {
    super.initState();
    if (widget.initialItem != null) {
      _nameController.text = widget.initialItem!.name;
      _imageUrlController.text = widget.initialItem!.imageUrl ?? '';
      _priority = widget.initialItem!.priority;
      _deadline = widget.initialItem!.deadline;
      if (widget.initialItem!.targetPriceCents != null) {
        final cents = widget.initialItem!.targetPriceCents!;
        // Format cents as "X,XX" for the text field by simulating digit input.
        final digits = cents.abs().toString();
        _targetPriceController.text = digits;
        // Apply formatter to produce the right display format.
        final formatter = const CentsInputFormatter();
        final formatted = formatter.formatEditUpdate(
          const TextEditingValue(text: ''),
          TextEditingValue(text: digits),
        );
        _targetPriceController.text = formatted.text;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _currentPriceController.dispose();
    _targetPriceController.dispose();
    _imageUrlController.dispose();
    _newLinkUrlController.dispose();
    _newLinkStoreNameController.dispose();
    super.dispose();
  }

  String _formatDeadline(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _deadline = picked);
    }
  }

  void _addLink() {
    final url = _newLinkUrlController.text.trim();
    if (url.isEmpty) return;
    setState(() {
      _links.add(WishlistLinkFormEntry(
        url: url,
        storeName: _newLinkStoreNameController.text.trim().isEmpty
            ? null
            : _newLinkStoreNameController.text.trim(),
      ));
      _newLinkUrlController.clear();
      _newLinkStoreNameController.clear();
      _showAddLinkForm = false;
    });
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _errorMessage = 'Nome é obrigatório.');
      return;
    }

    final targetPriceCents = _targetPriceController.text.trim().isEmpty
        ? null
        : CentsInputFormatter.parseCents(_targetPriceController.text);

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      if (_isEdit) {
        final original = widget.initialItem;
        final dto = UpdateWishlistItemRequestDto(
          name: name != original?.name ? name : null,
          imageUrl: _imageUrlController.text.trim().isEmpty
              ? null
              : _imageUrlController.text.trim(),
          targetPrice: targetPriceCents != original?.targetPriceCents
              ? targetPriceCents
              : null,
          priority: _priority != original?.priority ? _priority.toInt() : null,
          deadline: _deadline != original?.deadline
              ? (_deadline != null ? _formatDeadline(_deadline!) : null)
              : null,
        );
        await ref
            .read(wishlistRepositoryProvider)
            .updateWishlistItem(widget.itemId!, dto);
      } else {
        final currentPriceCents =
            CentsInputFormatter.parseCents(_currentPriceController.text);
        if (currentPriceCents <= 0) {
          setState(() {
            _isSubmitting = false;
            _errorMessage = 'Preço atual deve ser maior que zero.';
          });
          return;
        }
        final dto = CreateWishlistItemRequestDto(
          name: name,
          imageUrl: _imageUrlController.text.trim().isEmpty
              ? null
              : _imageUrlController.text.trim(),
          currentPrice: currentPriceCents,
          targetPrice: targetPriceCents,
          priority: _priority.toInt(),
          deadline: _deadline != null ? _formatDeadline(_deadline!) : null,
          links: _links
              .map((l) =>
                  CreateWishlistLinkDto(url: l.url, storeName: l.storeName))
              .toList(),
        );
        await ref.read(wishlistRepositoryProvider).createWishlistItem(dto);
      }

      ref.read(wishlistNotifierProvider.notifier).refresh();
      if (mounted) context.pop();
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Erro ao salvar. Tente novamente.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppThemeTokens.of(context);
    final title = _isEdit ? 'Editar Item' : 'Novo Item';

    return AppBackground(
      scrollable: true,
      child: SafeArea(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              _buildHeader(t, title),
              const SizedBox(height: 24),

              // Name
              AppInputField(
                label: 'Nome',
                placeholder: 'Ex: Fone de ouvido Sony',
                controller: _nameController,
                textCapitalization: TextCapitalization.sentences,
                inputFormatters: [LengthLimitingTextInputFormatter(150)],
              ),
              const SizedBox(height: 16),

              // Current price (create only)
              if (!_isEdit) ...[
                AppInputField(
                  label: 'Preço atual',
                  placeholder: '0,00',
                  controller: _currentPriceController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    const CentsInputFormatter(),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // Target price
              AppInputField(
                label: 'Preço-alvo (opcional)',
                placeholder: '0,00',
                controller: _targetPriceController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  const CentsInputFormatter(),
                ],
              ),
              const SizedBox(height: 16),

              // Priority
              _buildPriorityPicker(t),
              const SizedBox(height: 16),

              // Deadline
              _buildDeadlinePicker(t),
              const SizedBox(height: 16),

              // Image URL
              AppInputField(
                label: 'URL da imagem (opcional)',
                placeholder: 'https://...',
                controller: _imageUrlController,
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),

              // Links
              if (!_isEdit) _buildLinksSection(t),

              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: AppTextStyles.bodySm(t.error),
                ),
              ],

              const SizedBox(height: 24),
              PrimaryButton(
                label: _isSubmitting ? 'Salvando...' : 'Salvar',
                onPressed: _isSubmitting ? null : _submit,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppThemeTokens t, String title) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => context.pop(),
          child: Icon(LucideIcons.arrowLeft, size: 22, color: t.txtPrimary),
        ),
        const SizedBox(width: 12),
        Text(title, style: AppTextStyles.h2(t.txtPrimary)),
      ],
    );
  }

  Widget _buildPriorityPicker(AppThemeTokens t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Prioridade',
          style: AppTextStyles.caption(t.txtSecondary)
              .copyWith(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Row(
          children: WishlistPriority.values.map((p) {
            final isSelected = _priority == p;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: p == WishlistPriority.high ? 0 : 8,
                ),
                child: GestureDetector(
                  onTap: () => setState(() => _priority = p),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? p.color.withValues(alpha: 0.2)
                          : t.primary.withValues(alpha: t.isDark ? 0.08 : 0.05),
                      borderRadius: AppRadius.baseAll,
                      border: Border.all(
                        color: isSelected
                            ? p.color
                            : t.divider.withValues(alpha: 0.5),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        p.label,
                        style: AppTextStyles.bodySm(
                          isSelected ? p.color : t.txtTertiary,
                        ).copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDeadlinePicker(AppThemeTokens t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Prazo',
          style: AppTextStyles.caption(t.txtSecondary)
              .copyWith(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickDeadline,
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
                Expanded(
                  child: Text(
                    _deadline != null
                        ? formatDate(_deadline!)
                        : 'Sem prazo',
                    style: AppTextStyles.body(
                      _deadline != null ? t.txtPrimary : t.txtTertiary,
                    ).copyWith(fontSize: 14),
                  ),
                ),
                if (_deadline != null)
                  GestureDetector(
                    onTap: () => setState(() => _deadline = null),
                    child: Icon(LucideIcons.x, size: 16, color: t.txtDisabled),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLinksSection(AppThemeTokens t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Links de lojas',
          style: AppTextStyles.caption(t.txtSecondary)
              .copyWith(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),

        // Existing links
        ..._links.asMap().entries.map((entry) {
          final index = entry.key;
          final link = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: t.primary.withValues(alpha: t.isDark ? 0.08 : 0.05),
                borderRadius: AppRadius.baseAll,
                border: Border.all(
                  color: t.divider.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.link, size: 14, color: t.txtTertiary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (link.storeName != null)
                          Text(
                            link.storeName!,
                            style: AppTextStyles.bodySm(t.txtPrimary)
                                .copyWith(fontWeight: FontWeight.w600),
                          ),
                        Text(
                          link.url,
                          style: AppTextStyles.caption(t.txtTertiary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _links.removeAt(index)),
                    child: Icon(LucideIcons.trash2, size: 14, color: t.error),
                  ),
                ],
              ),
            ),
          );
        }),

        // Add link form
        if (_showAddLinkForm) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: t.primary.withValues(alpha: t.isDark ? 0.08 : 0.05),
              borderRadius: AppRadius.baseAll,
              border: Border.all(color: t.divider.withValues(alpha: 0.5)),
            ),
            child: Column(
              children: [
                AppInputField(
                  placeholder: 'URL (https://...)',
                  controller: _newLinkUrlController,
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 8),
                AppInputField(
                  placeholder: 'Nome da loja (opcional)',
                  controller: _newLinkStoreNameController,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _showAddLinkForm = false),
                        child: Container(
                          height: 36,
                          decoration: BoxDecoration(
                            borderRadius: AppRadius.baseAll,
                            border: Border.all(color: t.divider),
                          ),
                          child: Center(
                            child: Text(
                              'Cancelar',
                              style: AppTextStyles.bodySm(t.txtSecondary),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: _addLink,
                        child: Container(
                          height: 36,
                          decoration: BoxDecoration(
                            color: t.primary,
                            borderRadius: AppRadius.baseAll,
                          ),
                          child: Center(
                            child: Text(
                              'Adicionar',
                              style: AppTextStyles.bodySm(Colors.white)
                                  .copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ] else ...[
          GestureDetector(
            onTap: () => setState(() => _showAddLinkForm = true),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                borderRadius: AppRadius.baseAll,
                border: Border.all(
                  color: t.primary.withValues(alpha: 0.4),
                  style: BorderStyle.solid,
                ),
                color: t.primary.withValues(alpha: 0.05),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.plus, size: 16, color: t.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Adicionar link',
                    style: AppTextStyles.bodySm(t.primary)
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 8),
      ],
    );
  }
}
