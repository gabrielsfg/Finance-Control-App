import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../data/dtos/wishlist_dtos.dart';
import '../../data/wishlist_repository.dart';
import '../../providers/wishlist_provider.dart';

class RegisterPriceBottomSheet extends ConsumerStatefulWidget {
  final int itemId;

  const RegisterPriceBottomSheet({super.key, required this.itemId});

  @override
  ConsumerState<RegisterPriceBottomSheet> createState() =>
      _RegisterPriceBottomSheetState();
}

class _RegisterPriceBottomSheetState
    extends ConsumerState<RegisterPriceBottomSheet> {
  final _priceController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final priceCents = CentsInputFormatter.parseCents(_priceController.text);
    if (priceCents <= 0) {
      setState(() => _errorMessage = 'Informe um preço válido.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await ref.read(wishlistRepositoryProvider).registerPrice(
            widget.itemId,
            RegisterWishlistPriceRequestDto(price: priceCents),
          );

      ref.invalidate(wishlistItemDetailProvider(widget.itemId));
      ref.invalidate(wishlistPriceHistoryProvider(widget.itemId));

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preço atualizado!')),
        );
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Erro ao atualizar preço. Tente novamente.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppThemeTokens.of(context);

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
          Text('Atualizar Preço', style: AppTextStyles.h3(t.txtPrimary)),
          const SizedBox(height: 20),
          AppInputField(
            label: 'Novo preço',
            placeholder: '0,00',
            controller: _priceController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              const CentsInputFormatter(),
            ],
            leftIcon: const Icon(LucideIcons.dollarSign, size: 18),
          ),
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
    );
  }
}
