import 'package:flutter/material.dart';
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

class WishlistPage extends ConsumerStatefulWidget {
  const WishlistPage({super.key});

  @override
  ConsumerState<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends ConsumerState<WishlistPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      ref.read(wishlistNotifierProvider.notifier).loadNextPage();
    }
  }

  Future<void> _showSortSheet() async {
    final current = ref.read(wishlistNotifierProvider).valueOrNull;
    final currentOrder = current?.orderBy ?? 'created_desc';

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SortBottomSheet(
        currentOrder: currentOrder,
        onSelected: (order) {
          Navigator.of(ctx).pop();
          ref.read(wishlistNotifierProvider.notifier).setOrderBy(order);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppThemeTokens.of(context);
    final wishlistAsync = ref.watch(wishlistNotifierProvider);
    final currentState = wishlistAsync.valueOrNull;
    final statusFilter = currentState?.statusFilter ?? WishlistStatus.active;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: GestureDetector(
        onTap: () => context.push('/wishlist/create'),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.primaryGradient,
            boxShadow: AppShadows.fabShadow,
          ),
          child: const Icon(LucideIcons.plus, color: Colors.white, size: 24),
        ),
      ),
      body: AppBackground(
        scrollable: false,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(t),
              _buildStatusChips(t, statusFilter),
              Expanded(
                child: wishlistAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => _ErrorState(
                    message: error.toString(),
                    onRetry: () =>
                        ref.read(wishlistNotifierProvider.notifier).refresh(),
                  ),
                  data: (state) {
                    if (state.items.isEmpty) {
                      return _EmptyState(statusFilter: statusFilter);
                    }
                    return RefreshIndicator(
                      onRefresh: () =>
                          ref.read(wishlistNotifierProvider.notifier).refresh(),
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 8),
                        itemCount:
                            state.items.length + (state.isLoadingMore ? 1 : 0),
                        itemBuilder: (ctx, index) {
                          if (index == state.items.length) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child:
                                  Center(child: CircularProgressIndicator()),
                            );
                          }
                          final item = state.items[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _WishlistCard(
                              item: item,
                              onTap: () => context.push(
                                  '/wishlist/${item.id}',
                                  extra: item),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppThemeTokens t) {
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
              'Lista de Desejos',
              style: AppTextStyles.h2(t.txtPrimary),
            ),
          ),
          GestureDetector(
            onTap: _showSortSheet,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: t.primary.withValues(alpha: t.isDark ? 0.15 : 0.08),
                borderRadius: AppRadius.baseAll,
              ),
              child: Icon(LucideIcons.arrowUpDown, size: 18, color: t.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChips(AppThemeTokens t, WishlistStatus selected) {
    final options = [
      (WishlistStatus.active, 'Ativos'),
      (WishlistStatus.purchased, 'Comprados'),
      (WishlistStatus.archived, 'Arquivados'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      child: Row(
        children: options.map((entry) {
          final (status, label) = entry;
          final isSelected = selected == status;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => ref
                  .read(wishlistNotifierProvider.notifier)
                  .setStatusFilter(status),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected
                      ? t.primary
                      : t.primary.withValues(alpha: t.isDark ? 0.12 : 0.07),
                  borderRadius: AppRadius.pillAll,
                ),
                child: Text(
                  label,
                  style: AppTextStyles.caption(
                    isSelected ? Colors.white : t.txtTertiary,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Wishlist Card ─────────────────────────────────────────────────────────────

class _WishlistCard extends StatelessWidget {
  final WishlistItem item;
  final VoidCallback onTap;

  const _WishlistCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = AppThemeTokens.of(context);

    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImage(t),
            const SizedBox(width: 12),
            Expanded(child: _buildContent(t)),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(AppThemeTokens t) {
    return ClipRRect(
      borderRadius: AppRadius.lgAll,
      child: SizedBox(
        width: 72,
        height: 72,
        child: item.imageUrl != null
            ? Image.network(
                item.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _ImagePlaceholder(t: t),
              )
            : _ImagePlaceholder(t: t),
      ),
    );
  }

  Widget _buildContent(AppThemeTokens t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                item.name,
                style: AppTextStyles.body(t.txtPrimary).copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            _PriorityBadge(priority: item.priority),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          formatCurrency(item.currentPriceCents),
          style: AppTextStyles.bodySm(t.primary).copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        if (item.targetPriceCents != null) ...[
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(LucideIcons.target, size: 11, color: t.txtDisabled),
              const SizedBox(width: 3),
              Text(
                formatCurrency(item.targetPriceCents!),
                style: AppTextStyles.caption(t.txtDisabled),
              ),
              if (item.currentPriceCents <= item.targetPriceCents!) ...[
                const SizedBox(width: 4),
                Text(
                  'Alvo atingido',
                  style: AppTextStyles.caption(t.success).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ],
        if (item.deadline != null) ...[
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(LucideIcons.calendar, size: 11, color: t.txtDisabled),
              const SizedBox(width: 3),
              Text(
                formatDate(item.deadline!),
                style: AppTextStyles.caption(t.txtDisabled),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  final AppThemeTokens t;
  const _ImagePlaceholder({required this.t});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: t.primary.withValues(alpha: 0.1),
      child: Icon(LucideIcons.gift, size: 28, color: t.primary.withValues(alpha: 0.5)),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  final WishlistPriority priority;
  const _PriorityBadge({required this.priority});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: priority.color.withValues(alpha: 0.15),
        borderRadius: AppRadius.pillAll,
      ),
      child: Text(
        priority.label,
        style: AppTextStyles.caption(priority.color).copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }
}

// ── Empty & Error States ──────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final WishlistStatus statusFilter;
  const _EmptyState({required this.statusFilter});

  @override
  Widget build(BuildContext context) {
    final t = AppThemeTokens.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.gift, size: 48, color: t.txtDisabled),
          const SizedBox(height: 16),
          Text(
            'Nenhum item encontrado',
            style: AppTextStyles.body(t.txtSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            'Adicione itens na sua lista de desejos',
            style: AppTextStyles.bodySm(t.txtDisabled),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final t = AppThemeTokens.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.alertCircle, size: 48, color: t.error),
            const SizedBox(height: 16),
            Text(
              'Erro ao carregar lista',
              style: AppTextStyles.body(t.txtPrimary)
                  .copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTextStyles.bodySm(t.txtSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: t.primary,
                  borderRadius: AppRadius.baseAll,
                ),
                child: Text(
                  'Tentar novamente',
                  style: AppTextStyles.body(Colors.white)
                      .copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sort Bottom Sheet ─────────────────────────────────────────────────────────

class _SortBottomSheet extends StatelessWidget {
  final String currentOrder;
  final void Function(String) onSelected;

  const _SortBottomSheet({
    required this.currentOrder,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppThemeTokens.of(context);

    final options = [
      ('created_desc', 'Mais recentes'),
      ('created_asc', 'Mais antigos'),
      ('price_asc', 'Menor preço'),
      ('price_desc', 'Maior preço'),
      ('priority_desc', 'Maior prioridade'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: t.isDark ? const Color(0xFF1C1830) : Colors.white,
        borderRadius: AppRadius.xl3All.copyWith(
          bottomLeft: Radius.zero,
          bottomRight: Radius.zero,
        ),
        boxShadow: AppShadows.bottomSheet,
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
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Ordenar por',
                style: AppTextStyles.h3(t.txtPrimary),
              ),
            ),
            const SizedBox(height: 12),
            ...options.map((entry) {
              final (value, label) = entry;
              final isSelected = currentOrder == value;
              return ListTile(
                title: Text(
                  label,
                  style: AppTextStyles.body(
                    isSelected ? t.primary : t.txtPrimary,
                  ).copyWith(fontWeight: isSelected ? FontWeight.w600 : null),
                ),
                trailing: isSelected
                    ? Icon(LucideIcons.check, color: t.primary, size: 18)
                    : null,
                onTap: () => onSelected(value),
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
