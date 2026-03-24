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
import '../data/enums/wishlist_enums.dart';
import '../data/models/wishlist_item.dart';
import '../providers/wishlist_provider.dart';
import 'widgets/purchase_bottom_sheet.dart';
import 'widgets/register_price_bottom_sheet.dart';

class WishlistDetailPage extends ConsumerStatefulWidget {
  final int itemId;
  final WishlistItem? initialItem;

  const WishlistDetailPage({
    super.key,
    required this.itemId,
    this.initialItem,
  });

  @override
  ConsumerState<WishlistDetailPage> createState() => _WishlistDetailPageState();
}

class _WishlistDetailPageState extends ConsumerState<WishlistDetailPage> {
  final _monthlyAmountController = TextEditingController();
  int? _monthlyAmountCents;

  @override
  void dispose() {
    _monthlyAmountController.dispose();
    super.dispose();
  }

  Future<void> _deleteItem() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir item'),
        content: const Text('Deseja realmente excluir este item da lista?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Excluir',
              style: TextStyle(color: AppThemeTokens.of(context).error),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref
          .read(wishlistNotifierProvider.notifier)
          .deleteItem(widget.itemId);
      if (mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppThemeTokens.of(context);
    final detailAsync = ref.watch(wishlistItemDetailProvider(widget.itemId));
    final historyAsync = ref.watch(wishlistPriceHistoryProvider(widget.itemId));

    final displayName = detailAsync.valueOrNull?.name ??
        widget.initialItem?.name ??
        'Detalhes';

    return AppBackground(
      scrollable: false,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(t, displayName, detailAsync.valueOrNull),
            Expanded(
              child: detailAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.alertCircle,
                          size: 48, color: t.error),
                      const SizedBox(height: 12),
                      Text('Erro ao carregar detalhes',
                          style: AppTextStyles.body(t.txtPrimary)),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () => ref
                            .invalidate(wishlistItemDetailProvider(widget.itemId)),
                        child: Text(
                          'Tentar novamente',
                          style: AppTextStyles.body(t.primary),
                        ),
                      ),
                    ],
                  ),
                ),
                data: (item) => _buildContent(t, item, historyAsync),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    AppThemeTokens t,
    String name,
    WishlistItemDetail? item,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Icon(LucideIcons.arrowLeft, size: 22, color: t.txtPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: AppTextStyles.h2(t.txtPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (item != null)
            GestureDetector(
              onTap: () => _showKebabMenu(item),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: t.primary.withValues(alpha: t.isDark ? 0.15 : 0.08),
                  borderRadius: AppRadius.baseAll,
                ),
                child: Icon(LucideIcons.moreVertical,
                    size: 18, color: t.primary),
              ),
            ),
        ],
      ),
    );
  }

  void _showKebabMenu(WishlistItemDetail item) {
    final t = AppThemeTokens.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: t.isDark ? const Color(0xFF1C1830) : Colors.white,
          borderRadius: AppRadius.xl3All.copyWith(
            bottomLeft: Radius.zero,
            bottomRight: Radius.zero,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: t.divider,
                  borderRadius: AppRadius.pillAll,
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Icon(LucideIcons.pencil, color: t.primary),
                title: Text('Editar',
                    style: AppTextStyles.body(t.txtPrimary)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  context.push(
                    '/wishlist/${widget.itemId}/edit',
                    extra: item.toWishlistItem(),
                  );
                },
              ),
              ListTile(
                leading: Icon(LucideIcons.trash2, color: t.error),
                title: Text('Excluir',
                    style: AppTextStyles.body(t.error)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _deleteItem();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    AppThemeTokens t,
    WishlistItemDetail item,
    AsyncValue<List<WishlistPriceHistory>> historyAsync,
  ) {
    return SingleChildScrollView(
      padding: AppSpacing.screenPadding.copyWith(top: 8, bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroImage(t, item),
          const SizedBox(height: 16),
          _buildStatusRow(t, item),
          const SizedBox(height: 20),
          _buildPricesSection(t, item),
          const SizedBox(height: 20),
          _buildPriceHistorySection(t, item, historyAsync),
          const SizedBox(height: 20),
          _buildProjectionSection(t, item),
          if (item.links.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildLinksSection(t, item),
          ],
          const SizedBox(height: 20),
          _buildActionsSection(t, item),
        ],
      ),
    );
  }

  Widget _buildHeroImage(AppThemeTokens t, WishlistItemDetail item) {
    return ClipRRect(
      borderRadius: AppRadius.xlAll,
      child: SizedBox(
        width: double.infinity,
        height: 200,
        child: item.imageUrl != null
            ? Image.network(
                item.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildImagePlaceholder(t),
              )
            : _buildImagePlaceholder(t),
      ),
    );
  }

  Widget _buildImagePlaceholder(AppThemeTokens t) {
    return Container(
      color: t.primary.withValues(alpha: 0.1),
      child: Center(
        child: Icon(
          LucideIcons.gift,
          size: 64,
          color: t.primary.withValues(alpha: 0.4),
        ),
      ),
    );
  }

  Widget _buildStatusRow(AppThemeTokens t, WishlistItemDetail item) {
    return Row(
      children: [
        _StatusBadge(priority: item.priority),
        const SizedBox(width: 8),
        _WishlistStatusBadge(status: item.status),
        if (item.deadline != null) ...[
          const SizedBox(width: 8),
          Row(
            children: [
              Icon(LucideIcons.calendar, size: 12, color: t.txtTertiary),
              const SizedBox(width: 4),
              Text(
                formatDate(item.deadline!),
                style: AppTextStyles.caption(t.txtTertiary),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildPricesSection(AppThemeTokens t, WishlistItemDetail item) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preços',
            style: AppTextStyles.bodySm(t.txtTertiary).copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            formatCurrency(item.currentPriceCents),
            style: AppTextStyles.moneyLg(t.txtPrimary),
          ),
          Text(
            'Preço atual',
            style: AppTextStyles.caption(t.txtTertiary),
          ),
          if (item.targetPriceCents != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Preço-alvo: ',
                  style: AppTextStyles.bodySm(t.txtSecondary),
                ),
                Text(
                  formatCurrency(item.targetPriceCents!),
                  style: AppTextStyles.bodySm(t.primary)
                      .copyWith(fontWeight: FontWeight.w600),
                ),
                if (item.currentPriceCents <= item.targetPriceCents!) ...[
                  const SizedBox(width: 8),
                  Text(
                    'Alvo atingido! 🎯',
                    style: AppTextStyles.bodySm(t.success)
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
          ],
          if (item.minPriceCents != null || item.maxPriceCents != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (item.minPriceCents != null) ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mínimo registrado',
                        style: AppTextStyles.caption(t.txtTertiary),
                      ),
                      Text(
                        formatCurrency(item.minPriceCents!),
                        style: AppTextStyles.bodySm(t.success)
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(width: 24),
                ],
                if (item.maxPriceCents != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Máximo registrado',
                        style: AppTextStyles.caption(t.txtTertiary),
                      ),
                      Text(
                        formatCurrency(item.maxPriceCents!),
                        style: AppTextStyles.bodySm(t.error)
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPriceHistorySection(
    AppThemeTokens t,
    WishlistItemDetail item,
    AsyncValue<List<WishlistPriceHistory>> historyAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Histórico de Preços',
          style: AppTextStyles.h3(t.txtPrimary),
        ),
        const SizedBox(height: 12),
        historyAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Text(
            'Erro ao carregar histórico',
            style: AppTextStyles.bodySm(t.error),
          ),
          data: (history) {
            if (history.isEmpty) {
              return Text(
                'Registre mais preços para ver o gráfico',
                style: AppTextStyles.bodySm(t.txtTertiary),
              );
            }
            if (history.length < 2) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Registre mais preços para ver o gráfico',
                    style: AppTextStyles.bodySm(t.txtTertiary),
                  ),
                  const SizedBox(height: 8),
                  _buildHistoryList(t, history),
                ],
              );
            }
            return _buildHistoryList(t, history);
          },
        ),
      ],
    );
  }

  Widget _buildHistoryList(
      AppThemeTokens t, List<WishlistPriceHistory> history) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: history.map((entry) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    formatDate(entry.recordedAt),
                    style: AppTextStyles.bodySm(t.txtTertiary),
                  ),
                ),
                Text(
                  formatCurrency(entry.priceCents),
                  style: AppTextStyles.bodySm(t.txtPrimary)
                      .copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProjectionSection(AppThemeTokens t, WishlistItemDetail item) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Projeção', style: AppTextStyles.h3(t.txtPrimary)),
          const SizedBox(height: 12),
          Text(
            'Quanto você pode guardar por mês?',
            style: AppTextStyles.bodySm(t.txtSecondary),
          ),
          const SizedBox(height: 8),
          AppInputField(
            placeholder: '0,00',
            controller: _monthlyAmountController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              const CentsInputFormatter(),
            ],
            onChanged: (_) {
              setState(() {
                _monthlyAmountCents = CentsInputFormatter.parseCents(
                    _monthlyAmountController.text);
              });
            },
          ),
          if (_monthlyAmountCents != null && _monthlyAmountCents! > 0) ...[
            const SizedBox(height: 12),
            Builder(builder: (context) {
              final months = (item.currentPriceCents / _monthlyAmountCents!)
                  .ceil();
              return Text(
                'Você consegue comprar em $months ${months == 1 ? 'mês' : 'meses'}',
                style: AppTextStyles.body(t.primary).copyWith(
                  fontWeight: FontWeight.w600,
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildLinksSection(AppThemeTokens t, WishlistItemDetail item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Links', style: AppTextStyles.h3(t.txtPrimary)),
        const SizedBox(height: 12),
        GlassCard(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: item.links.map((link) {
              final displayText = link.storeName?.isNotEmpty == true
                  ? link.storeName!
                  : _truncateUrl(link.url);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(LucideIcons.link, size: 14, color: t.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayText,
                            style: AppTextStyles.bodySm(t.txtPrimary)
                                .copyWith(fontWeight: FontWeight.w500),
                          ),
                          if (link.storeName?.isNotEmpty == true)
                            SelectableText(
                              link.url,
                              style: AppTextStyles.caption(t.txtTertiary),
                            ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: link.url));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('URL copiada!')),
                        );
                      },
                      child: Icon(LucideIcons.copy,
                          size: 16, color: t.txtDisabled),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildActionsSection(AppThemeTokens t, WishlistItemDetail item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ações', style: AppTextStyles.h3(t.txtPrimary)),
        const SizedBox(height: 12),
        if (item.status == WishlistStatus.active) ...[
          _ActionButton(
            label: 'Atualizar preço',
            icon: LucideIcons.trendingUp,
            color: t.primary,
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              backgroundColor: Colors.transparent,
              isScrollControlled: true,
              builder: (ctx) =>
                  RegisterPriceBottomSheet(itemId: widget.itemId),
            ),
          ),
          const SizedBox(height: 10),
          _ActionButton(
            label: 'Marcar como Comprado',
            icon: LucideIcons.shoppingBag,
            color: t.success,
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              backgroundColor: Colors.transparent,
              isScrollControlled: true,
              builder: (ctx) => PurchaseBottomSheet(
                itemId: widget.itemId,
                itemName: item.name,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Tooltip(
            message: 'Em breve',
            child: _ActionButton(
              label: 'Arquivar',
              icon: LucideIcons.archive,
              color: t.txtDisabled,
              onPressed: null,
            ),
          ),
        ] else if (item.status == WishlistStatus.purchased) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: t.success.withValues(alpha: 0.1),
              borderRadius: AppRadius.baseAll,
              border: Border.all(
                color: t.success.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.checkCircle, color: t.success, size: 20),
                const SizedBox(width: 10),
                Text(
                  'Item comprado',
                  style: AppTextStyles.body(t.success)
                      .copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          if (item.purchasedTransactionId != null) ...[
            const SizedBox(height: 10),
            _ActionButton(
              label: 'Transação #${item.purchasedTransactionId} criada',
              icon: LucideIcons.receipt,
              color: t.info,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Transação #${item.purchasedTransactionId} criada'),
                  ),
                );
              },
            ),
          ],
        ] else if (item.status == WishlistStatus.archived) ...[
          Tooltip(
            message: 'Em breve',
            child: _ActionButton(
              label: 'Reativar',
              icon: LucideIcons.refreshCw,
              color: t.txtDisabled,
              onPressed: null,
            ),
          ),
        ],
      ],
    );
  }

  String _truncateUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host.isNotEmpty ? uri.host : url;
    } catch (_) {
      return url.length > 40 ? '${url.substring(0, 40)}...' : url;
    }
  }
}

// ── Badges ────────────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final WishlistPriority priority;
  const _StatusBadge({required this.priority});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: priority.color.withValues(alpha: 0.15),
        borderRadius: AppRadius.pillAll,
      ),
      child: Text(
        priority.label,
        style: AppTextStyles.caption(priority.color)
            .copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _WishlistStatusBadge extends StatelessWidget {
  final WishlistStatus status;
  const _WishlistStatusBadge({required this.status});

  Color _statusColor(AppThemeTokens t) {
    switch (status) {
      case WishlistStatus.active:
        return t.info;
      case WishlistStatus.purchased:
        return t.success;
      case WishlistStatus.archived:
        return t.txtDisabled;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppThemeTokens.of(context);
    final color = _statusColor(t);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: AppRadius.pillAll,
      ),
      child: Text(
        status.label,
        style: AppTextStyles.caption(color)
            .copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

// ── Action Button ─────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppThemeTokens.of(context);
    final isDisabled = onPressed == null;

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: isDisabled
              ? t.divider.withValues(alpha: 0.3)
              : color.withValues(alpha: t.isDark ? 0.15 : 0.1),
          borderRadius: AppRadius.baseAll,
          border: Border.all(
            color: isDisabled
                ? t.divider.withValues(alpha: 0.5)
                : color.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 18,
                color: isDisabled ? t.txtDisabled : color),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.body(isDisabled ? t.txtDisabled : color)
                  .copyWith(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
