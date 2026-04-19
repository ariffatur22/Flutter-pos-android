import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter_pos_kasir/core/constants/app_constants.dart';
import 'package:flutter_pos_kasir/core/theme/app_theme.dart';
import 'package:flutter_pos_kasir/data/models/category_model.dart';
import 'package:flutter_pos_kasir/data/models/product_model.dart';
import 'package:flutter_pos_kasir/presentation/providers/product_provider.dart';
import 'package:flutter_pos_kasir/presentation/providers/cart_provider.dart';

class ProductManagementScreen extends ConsumerStatefulWidget {
  const ProductManagementScreen({super.key});
  @override
  ConsumerState<ProductManagementScreen> createState() =>
      _ProductManagementScreenState();
}

class _ProductManagementScreenState
    extends ConsumerState<ProductManagementScreen> {
  final _searchCtrl = TextEditingController();
  String _filterCategory = 'Semua';
  String _filterStatus = 'Semua';
  int _rowsPerPage = 10;
  int _currentPage = 0;

  final _fmt = NumberFormat('#,##0', 'id_ID');

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productProvider);
    final cats = ref.watch(categoriesProvider);
    final statusList = ['Semua', 'Aktif', 'Non-aktif'];

    List<Product> filtered = state.filtered;
    if (_filterCategory != 'Semua') {
      filtered =
          filtered.where((p) => p.categoryName == _filterCategory).toList();
    }
    if (_filterStatus != 'Semua') {
      filtered = filtered
          .where((p) => _filterStatus == 'Aktif' ? p.isActive : !p.isActive)
          .toList();
    }

    final start = _currentPage * _rowsPerPage;
    final end = (start + _rowsPerPage).clamp(0, filtered.length);
    final paged = filtered.sublist(start, end);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Produk'),
        leading: BackButton(onPressed: () => context.pop()),
        actions: [
          IconButton(
            icon: const Icon(Icons.category_outlined),
            tooltip: 'Kelola Kategori',
            onPressed: () => context.push(AppConstants.routeCategories),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppConstants.routeAddProduct),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Produk'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Column(
        children: [
          // ── Filter bar ───────────────────────────────────────────────────────
          Container(
            color: AppTheme.surfaceColor,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Cari nama / barcode...',
                      prefixIcon: Icon(Icons.search, size: 18),
                      isDense: true,
                    ),
                    onChanged: (v) {
                      ref.read(productProvider.notifier).search(v);
                      setState(() => _currentPage = 0);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: _filterCategory,
                    isDense: true,
                    decoration: const InputDecoration(labelText: 'Kategori'),
                    items: [
                      const DropdownMenuItem(
                          value: 'Semua', child: Text('Semua')),
                      ...cats
                          .where((c) => c.name != 'Semua')
                          .map((c) => DropdownMenuItem(
                                value: c.name,
                                child: Row(
                                  children: [
                                    if (c.imagePath != null &&
                                        c.imagePath!.isNotEmpty)
                                      _buildSmallCategoryAvatar(c, size: 20)
                                    else if (c.iconEmoji != null &&
                                        c.iconEmoji!.isNotEmpty)
                                      Text(c.iconEmoji!,
                                          style: const TextStyle(fontSize: 18)),
                                    const SizedBox(width: 8),
                                    Text(c.name),
                                  ],
                                ),
                              )),
                    ],
                    onChanged: (v) => setState(() {
                      _filterCategory = v!;
                      _currentPage = 0;
                    }),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: _filterStatus,
                    isDense: true,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: statusList
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) => setState(() {
                      _filterStatus = v!;
                      _currentPage = 0;
                    }),
                  ),
                ),
              ],
            ),
          ),

          // ── Info bar ─────────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: AppTheme.backgroundColor,
            child: Row(
              children: [
                Text('Total: ${filtered.length} produk',
                    style: AppTheme.caption),
                const Spacer(),
                Text(
                    'Halaman ${_currentPage + 1} / ${((filtered.length - 1) ~/ _rowsPerPage) + 1}',
                    style: AppTheme.caption),
              ],
            ),
          ),

          // ── DataTable ────────────────────────────────────────────────────────
          Expanded(
            child: DataTable2(
              columnSpacing: 10,
              horizontalMargin: 12,
              minWidth: 680,
              headingRowColor: MaterialStateProperty.all(
                  AppTheme.primaryColor.withOpacity(0.08)),
              columns: const [
                DataColumn2(
                    label: Text('Gambar'), size: ColumnSize.S, fixedWidth: 56),
                DataColumn2(label: Text('Nama Produk'), size: ColumnSize.L),
                DataColumn2(label: Text('Kategori'), size: ColumnSize.M),
                DataColumn2(
                    label: Text('Harga'), numeric: true, size: ColumnSize.M),
                DataColumn2(
                    label: Text('Stok'), numeric: true, size: ColumnSize.S),
                DataColumn2(label: Text('Status'), size: ColumnSize.S),
                DataColumn2(
                    label: Text('Aksi'), size: ColumnSize.M, fixedWidth: 90),
              ],
              rows: paged.map((p) => _buildRow(p)).toList(),
              empty: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child:
                      Text('Tidak ada produk ditemukan', style: AppTheme.body2),
                ),
              ),
            ),
          ),

          // ── Pagination ───────────────────────────────────────────────────────
          _buildPagination(filtered.length),
        ],
      ),
    );
  }

  Widget _buildSmallCategoryAvatar(Category c, {double size = 20}) {
    final isNetwork = c.imagePath!.startsWith('http');
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: AppTheme.backgroundColor,
      child: ClipOval(
        child: isNetwork
            ? Image.network(c.imagePath!,
                fit: BoxFit.cover, width: size, height: size)
            : Image.file(File(c.imagePath!),
                fit: BoxFit.cover, width: size, height: size),
      ),
    );
  }

  DataRow _buildRow(Product p) {
    return DataRow2(
      onTap: () => context.push('/edit-product/${p.id}'),
      cells: [
        // Gambar
        DataCell(
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
              ),
            ),
          ),
        ),
        // Nama
        DataCell(
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(p.name,
                  style: AppTheme.body2.copyWith(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis),
              if (p.barcode != null) Text(p.barcode!, style: AppTheme.caption),
            ],
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(p.categoryName, style: AppTheme.caption),
          ),
        ),
        DataCell(Text('Rp ${_fmt.format(p.price)}',
            style: AppTheme.body2.copyWith(
                color: AppTheme.secondaryColor, fontWeight: FontWeight.w600))),
        DataCell(
          _buildStockCell(p),
        ),
        DataCell(
          Switch.adaptive(
            value: p.isActive,
            onChanged: (v) => ref
                .read(productProvider.notifier)
                .updateProduct(p.copyWith(isActive: v)),
            activeColor: AppTheme.secondaryColor,
          ),
        ),
        // Aksi
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined,
                    size: 18, color: AppTheme.primaryColor),
                tooltip: 'Edit',
                onPressed: () => context.push('/edit-product/${p.id}'),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    size: 18, color: AppTheme.errorColor),
                tooltip: 'Hapus',
                onPressed: () => _confirmDelete(p),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStockCell(Product p) {
    Color color;
    if (p.isOutOfStock)
      color = AppTheme.errorColor;
    else if (p.isLowStock)
      color = AppTheme.accentColor;
    else
      color = AppTheme.secondaryColor;
    return Text(
      '${p.stock} ${p.unit}',
      style: AppTheme.body2.copyWith(color: color, fontWeight: FontWeight.w600),
    );
  }

  Widget _buildPagination(int total) {
    final pages = ((total - 1) ~/ _rowsPerPage) + 1;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border(top: BorderSide(color: AppTheme.dividerColor)),
      ),
      child: Row(
        children: [
          DropdownButton<int>(
            value: _rowsPerPage,
            items: [5, 10, 20, 50]
                .map((v) => DropdownMenuItem(value: v, child: Text('$v baris')))
                .toList(),
            onChanged: (v) => setState(() {
              _rowsPerPage = v!;
              _currentPage = 0;
            }),
            underline: const SizedBox(),
            style: AppTheme.body2,
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed:
                _currentPage > 0 ? () => setState(() => _currentPage--) : null,
          ),
          Text('${_currentPage + 1} / $pages', style: AppTheme.body2),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPage < pages - 1
                ? () => setState(() => _currentPage++)
                : null,
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Product p) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Produk?'),
        content: Text('Produk "${p.name}" akan dihapus secara permanen.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal')),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            onPressed: () {
              Navigator.pop(context);
              ref.read(productProvider.notifier).deleteProduct(p.id);
              ref.read(cartProvider.notifier).removeItem(p.id);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Produk "${p.name}" dihapus'),
                backgroundColor: AppTheme.errorColor,
              ));
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
