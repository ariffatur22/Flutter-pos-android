import 'package:flutter/material.dart';
import 'package:flutter_pos_kasir/core/theme/app_theme.dart';
import 'package:flutter_pos_kasir/presentation/widgets/cart/cart_panel.dart';

/// DraggableScrollableSheet yang membungkus CartPanel — dipakai di mode mobile.
class CartBottomSheet extends StatelessWidget {
  const CartBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.45,
      maxChildSize: 0.97,
      snap: true,
      snapSizes: const [0.45, 0.85, 0.97],
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppTheme.radiusXl),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 20,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              // ── Handle bar ─────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // ── Cart content ───────────────────────────────────────────────
              const Expanded(child: CartPanel()),
            ],
          ),
        );
      },
    );
  }
}
