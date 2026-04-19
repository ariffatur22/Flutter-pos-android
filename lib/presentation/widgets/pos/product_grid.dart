import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:flutter_pos_kasir/core/constants/app_constants.dart';
import 'package:flutter_pos_kasir/core/theme/app_theme.dart';
import 'package:flutter_pos_kasir/data/models/product_model.dart';
import 'package:flutter_pos_kasir/presentation/providers/product_provider.dart';
import 'package:flutter_pos_kasir/presentation/providers/cart_provider.dart';

class ProductGrid extends ConsumerWidget {
  const ProductGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(productProvider);
    final width = MediaQuery.of(context).size.width;

    final maxExtent = width >= AppConstants.breakpointDesktop
        ? AppConstants.productCardMaxExtentDesktop
        : width >= AppConstants.breakpointTablet
            ? AppConstants.productCardMaxExtentTablet
            : AppConstants.productCardMaxExtentMobile;

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 64, color: AppTheme.textSecondary.withOpacity(0.4)),
            const SizedBox(height: 12),
            Text('Produk tidak ditemukan',
                style: AppTheme.body1.copyWith(color: AppTheme.textSecondary)),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(AppTheme.spacingSm),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: maxExtent,
        childAspectRatio: 0.72,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: state.filtered.length,
      itemBuilder: (_, i) => _ProductCard(product: state.filtered[i]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _ProductCard extends ConsumerWidget {
  final Product product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOut = product.isOutOfStock;
    final isLow = product.isLowStock;
    final fmt = NumberFormat('#,##0', 'id_ID');
    final colors = _categoryColor(product.categoryId);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // ── Main content ────────────────────────────────────────────────────
          InkWell(
            onTap: isOut
                ? null
                : () => ref.read(cartProvider.notifier).addItem(product),
            onLongPress: () => _showDetailDialog(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product image
                Expanded(
                  flex: 5,
                  child: _buildImage(colors),
                ),
                // Product info
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: AppTheme.body2
                              .copyWith(fontWeight: FontWeight.w600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Rp ${fmt.format(product.price)}',
                                style: AppTheme.body2.copyWith(
                                    color: AppTheme.secondaryColor,
                                    fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // + button
                            if (!isOut)
                              _AddButton(
                                  onTap: () => ref
                                      .read(cartProvider.notifier)
                                      .addItem(product)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Stock badge ──────────────────────────────────────────────────────
          Positioned(
            top: 6,
            right: 6,
            child: _StockBadge(
              stock: product.stock,
              isLow: isLow,
              isOut: isOut,
            ),
          ),

          // ── Out of stock overlay ─────────────────────────────────────────────
          if (isOut)
            Positioned.fill(
              child: Container(
                color: Colors.white.withOpacity(0.72),
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('HABIS',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImage(List<Color> colors) {
    final imageUrl = product.imageUrl;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      if (imageUrl.startsWith('http')) {
        return CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          placeholder: (_, __) => _colorPlaceholder(colors),
          errorWidget: (_, __, ___) => _colorPlaceholder(colors),
        );
      }
      final file = File(imageUrl);
      if (file.existsSync()) {
        return Image.file(file,
            fit: BoxFit.cover,
            width: double.infinity,
            errorBuilder: (_, __, ___) => _colorPlaceholder(colors));
      }
    }
    return _colorPlaceholder(colors);
  }

  Widget _colorPlaceholder(List<Color> colors) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
      ),
      child: Center(
        child: Text(
          product.name.isNotEmpty ? product.name[0].toUpperCase() : '?',
          style: const TextStyle(
              fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }

  List<Color> _categoryColor(String catId) {
    const palettes = [
      [Color(0xFF1E40AF), Color(0xFF3B82F6)],
      [Color(0xFF065F46), Color(0xFF10B981)],
      [Color(0xFF92400E), Color(0xFFF59E0B)],
      [Color(0xFF7C2D12), Color(0xFFEF4444)],
      [Color(0xFF4C1D95), Color(0xFF8B5CF6)],
    ];
    final idx = int.tryParse(catId) ?? 1;
    return palettes[(idx - 1) % palettes.length];
  }

  void _showDetailDialog(BuildContext context) {
    final fmt = NumberFormat('#,##0', 'id_ID');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(product.name, style: AppTheme.heading3),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (product.description != null)
              Text(product.description!, style: AppTheme.body2),
            const SizedBox(height: 12),
            _detailRow('Harga Jual', 'Rp ${fmt.format(product.price)}'),
            _detailRow('Kategori', product.categoryName),
            _detailRow('Stok', '${product.stock} ${product.unit}'),
            _detailRow('Barcode', product.barcode ?? '-'),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup')),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(width: 90, child: Text(label, style: AppTheme.caption)),
          Expanded(
              child: Text(value,
                  style: AppTheme.body2.copyWith(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _StockBadge extends StatelessWidget {
  final int stock;
  final bool isLow;
  final bool isOut;
  const _StockBadge(
      {required this.stock, required this.isLow, required this.isOut});

  @override
  Widget build(BuildContext context) {
    if (isOut) return const SizedBox.shrink();
    if (!isLow) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.accentColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text('Stok: $stock',
          style: const TextStyle(
              color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _AddButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddButton({required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 18),
      ),
    );
  }
}
