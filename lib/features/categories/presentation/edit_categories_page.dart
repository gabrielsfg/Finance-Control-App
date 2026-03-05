import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../data/category_repository.dart';
import '../data/dtos/category_response_dto.dart';
import '../providers/categories_provider.dart';

// ── Provider ───────────────────────────────────────────────────────────────

final _editCategoriesProvider =
    FutureProvider<List<CategoryItemResponseDto>>((ref) async {
  // Re-fetches whenever categoriesNotifierProvider changes so that
  // create/delete actions are reflected here without a manual refresh.
  ref.watch(categoriesNotifierProvider);
  return ref.read(categoryRepositoryProvider).getCategories();
});

// ── Page ───────────────────────────────────────────────────────────────────

class EditCategoriesPage extends ConsumerStatefulWidget {
  const EditCategoriesPage({super.key});

  @override
  ConsumerState<EditCategoriesPage> createState() => _EditCategoriesPageState();
}

class _EditCategoriesPageState extends ConsumerState<EditCategoriesPage> {
  final _searchController = TextEditingController();
  String _filter = '';

  // id → new name for every locally-modified category
  final Map<int, String> _pendingChanges = {};
  bool _saving = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onNameChanged(int id, String originalName, String newName) {
    setState(() {
      final trimmed = newName.trim();
      if (trimmed.isEmpty || trimmed == originalName) {
        _pendingChanges.remove(id);
      } else {
        _pendingChanges[id] = trimmed;
      }
    });
  }

  Future<void> _saveAll() async {
    if (_pendingChanges.isEmpty) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(categoriesNotifierProvider.notifier)
          .updateCategories(Map.from(_pendingChanges));
      if (mounted) {
        setState(() => _pendingChanges.clear());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Categorias salvas com sucesso.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao salvar categorias.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(_editCategoriesProvider);
    final bottomPad = MediaQuery.viewPaddingOf(context).bottom;
    final t = AppThemeTokens.of(context);
    final hasPending = _pendingChanges.isNotEmpty;

    return Scaffold(
      backgroundColor: t.bg,
      body: AppBackground(
        scrollable: false,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: AppSpacing.screenPadding.copyWith(top: 8, bottom: 0),
                child: Column(
                  children: [
                    const _Header(),
                    const SizedBox(height: 16),
                    _SearchBar(
                      controller: _searchController,
                      onChanged: (v) =>
                          setState(() => _filter = v.toLowerCase()),
                    ),
                    const SizedBox(height: 14),
                    const _ActionButtons(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              Expanded(
                child: categoriesAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => _ErrorView(
                    onRetry: () => ref.invalidate(_editCategoriesProvider),
                  ),
                  data: (categories) {
                    final filtered = _filter.isEmpty
                        ? categories
                        : categories
                            .where((c) =>
                                c.name.toLowerCase().contains(_filter) ||
                                c.subCategories.any((s) =>
                                    s.name.toLowerCase().contains(_filter)))
                            .toList();

                    if (filtered.isEmpty) return const _EmptyView();

                    return ListView.builder(
                      padding: EdgeInsets.fromLTRB(
                          24, 0, 24, hasPending ? 24 : bottomPad + 24),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) => _CategoryGroup(
                        category: filtered[i],
                        pendingName: _pendingChanges[filtered[i].id],
                        onNameChanged: (newName) => _onNameChanged(
                          filtered[i].id,
                          filtered[i].name,
                          newName,
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (hasPending)
                Padding(
                  padding: EdgeInsets.fromLTRB(24, 12, 24, bottomPad + 16),
                  child: GestureDetector(
                    onTap: _saving ? null : _saveAll,
                    child: Container(
                      height: 52,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient:
                            _saving ? null : AppColors.primaryGradient,
                        color: _saving
                            ? t.primary.withValues(alpha: 0.4)
                            : null,
                        borderRadius: AppRadius.baseAll,
                        boxShadow:
                            _saving ? [] : AppShadows.primaryBtnShadow,
                      ),
                      child: Center(
                        child: _saving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                'Salvar alterações',
                                style:
                                    AppTextStyles.body(Colors.white).copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
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
        GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: t.primary.withValues(alpha: t.isDark ? 0.15 : 0.1),
              border: Border.all(
                color: t.primary.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Icon(LucideIcons.chevronLeft, size: 18, color: t.primary),
          ),
        ),
        Expanded(
          child: Text(
            'Editar Categorias',
            textAlign: TextAlign.center,
            style: AppTextStyles.body(t.txtPrimary).copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),
        ),
        const SizedBox(width: 36),
      ],
    );
  }
}

// ── Search Bar ─────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final t = AppThemeTokens.of(context);

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: t.isDark
            ? const Color(0xFF1C1830).withValues(alpha: 0.72)
            : Colors.white.withValues(alpha: 0.9),
        borderRadius: AppRadius.baseAll,
        border: Border.all(
          color: t.isDark
              ? Colors.white.withValues(alpha: 0.07)
              : const Color(0xFF7C3AED).withValues(alpha: 0.12),
        ),
        boxShadow: t.isDark ? [] : AppShadows.cardLight,
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: AppTextStyles.body(t.txtPrimary).copyWith(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Filtrar por nome...',
          hintStyle: AppTextStyles.body(t.txtDisabled).copyWith(fontSize: 14),
          prefixIcon:
              Icon(LucideIcons.search, size: 16, color: t.txtDisabled),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    );
  }
}

// ── Action Buttons ─────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  const _ActionButtons();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PrimaryActionButton(
            label: '+ Nova Sub',
            filled: true,
            onTap: () {
              // TODO: open create subcategory sheet
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _PrimaryActionButton(
            label: '+ Categoria',
            filled: false,
            onTap: () => context.push('/categories/create'),
          ),
        ),
      ],
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  final String label;
  final bool filled;
  final VoidCallback onTap;

  const _PrimaryActionButton({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppThemeTokens.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          gradient: filled ? AppColors.primaryGradient : null,
          color: filled
              ? null
              : (t.isDark
                  ? const Color(0xFF1C1830).withValues(alpha: 0.72)
                  : Colors.white.withValues(alpha: 0.9)),
          borderRadius: AppRadius.baseAll,
          border: filled
              ? null
              : Border.all(
                  color: t.primary.withValues(alpha: 0.4),
                  width: 1.5,
                ),
          boxShadow: filled ? AppShadows.primaryBtnShadow : [],
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.body(
              filled ? Colors.white : t.primary,
            ).copyWith(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
      ),
    );
  }
}

// ── Category Group ─────────────────────────────────────────────────────────

class _CategoryGroup extends ConsumerStatefulWidget {
  final CategoryItemResponseDto category;
  final String? pendingName;
  final ValueChanged<String> onNameChanged;

  const _CategoryGroup({
    required this.category,
    required this.pendingName,
    required this.onNameChanged,
  });

  @override
  ConsumerState<_CategoryGroup> createState() => _CategoryGroupState();
}

class _CategoryGroupState extends ConsumerState<_CategoryGroup> {
  bool _deleting = false;
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.pendingName ?? widget.category.name,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    final confirmed = await _showDeleteConfirm();
    if (!confirmed) return;
    setState(() => _deleting = true);
    try {
      await ref
          .read(categoriesNotifierProvider.notifier)
          .deleteCategory(widget.category.id);
    } catch (_) {
      if (mounted) {
        setState(() => _deleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao deletar categoria.')),
        );
      }
    }
  }

  Future<bool> _showDeleteConfirm() async {
    final t = AppThemeTokens.of(context);
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor:
                t.isDark ? const Color(0xFF1C1830) : Colors.white,
            title: Text('Deletar categoria',
                style: AppTextStyles.h3(t.txtPrimary)),
            content: Text(
              'Deseja deletar "${widget.category.name}"? Esta ação não pode ser desfeita.',
              style: AppTextStyles.body(t.txtSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Cancelar',
                    style: AppTextStyles.body(t.txtTertiary)),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Deletar',
                    style: AppTextStyles.body(t.error)
                        .copyWith(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppThemeTokens.of(context);
    final isDirty = widget.pendingName != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: t.isDark
            ? const Color(0xFF1C1830).withValues(alpha: 0.72)
            : Colors.white.withValues(alpha: 0.9),
        borderRadius: AppRadius.xlAll,
        border: Border.all(
          color: isDirty
              ? t.primary.withValues(alpha: 0.5)
              : (t.isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : const Color(0xFF7C3AED).withValues(alpha: 0.12)),
          width: isDirty ? 1.5 : 1,
        ),
        boxShadow: t.isDark ? [] : AppShadows.cardLight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Category header row ──────────────────────────────────────
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.sentences,
                    style: AppTextStyles.body(
                      isDirty ? t.primary : t.txtPrimary,
                    ).copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 6, horizontal: 8),
                      filled: true,
                      fillColor: isDirty
                          ? t.primary.withValues(alpha: 0.06)
                          : Colors.transparent,
                      border: OutlineInputBorder(
                        borderRadius: AppRadius.smAll,
                        borderSide: BorderSide(
                            color: isDirty
                                ? t.primary.withValues(alpha: 0.3)
                                : Colors.transparent),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: AppRadius.smAll,
                        borderSide: BorderSide(
                            color: isDirty
                                ? t.primary.withValues(alpha: 0.3)
                                : Colors.transparent),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: AppRadius.smAll,
                        borderSide:
                            BorderSide(color: t.primary, width: 1.5),
                      ),
                    ),
                    onChanged: widget.onNameChanged,
                  ),
                ),
                const SizedBox(width: 10),
                if (_deleting)
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: t.error),
                  )
                else
                  GestureDetector(
                    onTap: _delete,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: t.error.withValues(alpha: 0.1),
                        borderRadius: AppRadius.pillAll,
                        border: Border.all(
                          color: t.error.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'Deletar',
                        style: AppTextStyles.caption(t.error).copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: t.divider.withValues(alpha: t.isDark ? 0.3 : 0.5),
          ),
          // ── Subcategory rows ─────────────────────────────────────────
          ...widget.category.subCategories.map(
            (sub) => _SubcategoryRow(subcategoryName: sub.name),
          ),
          if (widget.category.subCategories.isEmpty)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text(
                'Nenhuma subcategoria',
                style: AppTextStyles.caption(t.txtDisabled),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Subcategory Row ────────────────────────────────────────────────────────

class _SubcategoryRow extends StatelessWidget {
  final String subcategoryName;

  const _SubcategoryRow({required this.subcategoryName});

  @override
  Widget build(BuildContext context) {
    final t = AppThemeTokens.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  subcategoryName,
                  style: AppTextStyles.body(t.txtPrimary).copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  // TODO: edit subcategory
                },
                child: Text(
                  'Editar',
                  style: AppTextStyles.bodySm(t.primary)
                      .copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  // TODO: delete subcategory
                },
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: t.error.withValues(alpha: 0.1),
                    border: Border.all(
                        color: t.error.withValues(alpha: 0.3), width: 1),
                  ),
                  child: Icon(LucideIcons.x, size: 12, color: t.error),
                ),
              ),
            ],
          ),
        ),
        Divider(
          height: 1,
          thickness: 1,
          indent: 16,
          color: t.divider.withValues(alpha: t.isDark ? 0.2 : 0.4),
        ),
      ],
    );
  }
}

// ── Empty View ─────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    final t = AppThemeTokens.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.tag, size: 40, color: t.txtDisabled),
          const SizedBox(height: 12),
          Text('Nenhuma categoria encontrada',
              style: AppTextStyles.body(t.txtSecondary)),
        ],
      ),
    );
  }
}

// ── Error View ─────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final t = AppThemeTokens.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.alertCircle, color: t.error, size: 32),
          const SizedBox(height: 8),
          Text('Failed to load categories',
              style: AppTextStyles.body(t.txtSecondary)),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
