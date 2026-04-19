import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_pos_kasir/core/constants/app_constants.dart';
import 'package:flutter_pos_kasir/core/theme/app_theme.dart';
import 'package:flutter_pos_kasir/presentation/providers/auth_provider.dart';
import 'package:flutter_pos_kasir/presentation/providers/cart_provider.dart';
import 'package:flutter_pos_kasir/data/models/category_model.dart';
import 'package:flutter_pos_kasir/presentation/providers/product_provider.dart';
import 'package:flutter_pos_kasir/presentation/widgets/pos/product_grid.dart';
import 'package:flutter_pos_kasir/presentation/widgets/cart/cart_panel.dart';
import 'package:flutter_pos_kasir/presentation/widgets/cart/cart_bottom_sheet.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late Timer _clockTimer;
  DateTime _now = DateTime.now();
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= AppConstants.breakpointDesktop;
    return Scaffold(
      appBar: _buildAppBar(isDesktop),
      body: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
      floatingActionButton: isDesktop ? null : _buildCartFab(),
    );
  }

  // ── AppBar ───────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(bool isDesktop) {
    final auth = ref.watch(authProvider);
    final timeStr = DateFormat('HH:mm:ss').format(_now);
    final dateStr = DateFormat('EEE, dd MMM yyyy', 'id_ID').format(_now);
    return AppBar(
      title: Row(
        children: [
          const Icon(Icons.point_of_sale, color: Colors.white, size: 22),
          const SizedBox(width: 8),
          Text(AppConstants.appName,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          if (isDesktop) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(20)),
              child: Text('KASIR',
                  style: AppTheme.caption.copyWith(color: Colors.white)),
            ),
          ],
        ],
      ),
      actions: [
        if (isDesktop) ...[
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(timeStr,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      letterSpacing: 0.5)),
              Text(dateStr,
                  style: const TextStyle(color: Colors.white70, fontSize: 11)),
            ],
          ),
          const SizedBox(width: 16),
          _iconBtn(Icons.sync_rounded, 'Sinkronisasi', () {
            ref.read(productProvider.notifier).loadProducts();
          }),
        ],
        _iconBtn(Icons.bar_chart_rounded, 'Laporan',
            () => context.push(AppConstants.routeReport)),
        if (auth.isAdmin)
          _iconBtn(Icons.inventory_2_outlined, 'Produk',
              () => context.push(AppConstants.routeProducts)),
        PopupMenuButton<String>(
          icon: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.account_circle, color: Colors.white),
              Text(auth.cashierName,
                  style: const TextStyle(color: Colors.white70, fontSize: 9),
                  overflow: TextOverflow.ellipsis),
            ],
          ),
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  const Icon(Icons.logout,
                      size: 18, color: AppTheme.errorColor),
                  const SizedBox(width: 8),
                  Text('Logout',
                      style:
                          AppTheme.body2.copyWith(color: AppTheme.errorColor)),
                ],
              ),
            ),
          ],
          onSelected: (v) {
            if (v == 'logout') {
              ref.read(authProvider.notifier).logout();
              context.go(AppConstants.routeLogin);
            }
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _iconBtn(IconData icon, String tooltip, VoidCallback onTap) {
    return IconButton(
      icon: Icon(icon, color: Colors.white),
      tooltip: tooltip,
      onPressed: onTap,
    );
  }

  // ── Desktop layout ───────────────────────────────────────────────────────────
  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Column(
            children: [
              _buildSearchAndFilter(),
              Expanded(child: const ProductGrid()),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        SizedBox(
          width: 360,
          child: const CartPanel(),
        ),
      ],
    );
  }

  // ── Mobile layout ────────────────────────────────────────────────────────────
  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildSearchAndFilter(),
        Expanded(child: const ProductGrid()),
      ],
    );
  }

  // ── Search + Category Filter ─────────────────────────────────────────────────
  Widget _buildSearchAndFilter() {
    final categories = ref.watch(categoriesProvider);
    final selectedId = ref.watch(productProvider).selectedCategoryId;
    return Container(
      color: AppTheme.surfaceColor,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: Column(
        children: [
          TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Cari produk atau scan barcode...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchCtrl.clear();
                        ref.read(productProvider.notifier).search('');
                      })
                  : null,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
            onChanged: (v) {
              ref.read(productProvider.notifier).search(v);
              setState(() {});
            },
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                final cat = categories[i];
                final selected = cat.id == selectedId;
                return ChoiceChip(
                  avatar: _buildCategoryAvatar(cat),
                  label: Text(cat.name),
                  selected: selected,
                  selectedColor: AppTheme.primaryColor,
                  onSelected: (_) => ref
                      .read(productProvider.notifier)
                      .filterByCategory(cat.id),
                  labelStyle: TextStyle(
                      color: selected ? Colors.white : AppTheme.textPrimary,
                      fontSize: 12),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildCategoryAvatar(Category cat) {
    if (cat.imagePath != null && cat.imagePath!.isNotEmpty) {
      final isNetwork = cat.imagePath!.startsWith('http');
      return CircleAvatar(
        radius: 12,
        backgroundColor: AppTheme.backgroundColor,
        child: ClipOval(
          child: isNetwork
              ? Image.network(cat.imagePath!,
                  fit: BoxFit.cover, width: 24, height: 24)
              : Image.file(File(cat.imagePath!),
                  fit: BoxFit.cover, width: 24, height: 24),
        ),
      );
    }
    return CircleAvatar(
      radius: 12,
      backgroundColor: AppTheme.primaryColor.withOpacity(0.15),
      child: Text(cat.iconEmoji ?? cat.name[0],
          style: const TextStyle(fontSize: 12)),
    );
  }

  // ── Cart FAB (mobile) ────────────────────────────────────────────────────────
  Widget _buildCartFab() {
    final cart = ref.watch(cartProvider);
    return FloatingActionButton.extended(
      onPressed: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const CartBottomSheet(),
      ),
      backgroundColor: AppTheme.primaryColor,
      icon: Badge(
        isLabelVisible: cart.totalItems > 0,
        label: Text('${cart.totalItems}',
            style: const TextStyle(fontSize: 10, color: Colors.white)),
        backgroundColor: AppTheme.errorColor,
        child: const Icon(Icons.shopping_cart, color: Colors.white),
      ),
      label: Text(
        cart.totalItems == 0 ? 'Keranjang' : 'Rp ${_fmt(cart.total)}',
        style:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  String _fmt(double val) => NumberFormat('#,##0', 'id_ID').format(val);
}
