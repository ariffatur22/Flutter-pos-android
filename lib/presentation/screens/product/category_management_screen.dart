import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_pos_kasir/core/constants/app_constants.dart';
import 'package:flutter_pos_kasir/core/theme/app_theme.dart';
import 'package:flutter_pos_kasir/presentation/providers/product_provider.dart';
import 'package:flutter_pos_kasir/data/models/category_model.dart';

class CategoryManagementScreen extends ConsumerWidget {
  const CategoryManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final sorted = [...categories]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Kategori'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppConstants.routeAddCategory),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Kategori'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        itemCount: sorted.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final category = sorted[index];
          return Material(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            child: ListTile(
              onTap: () {
                if (category.id != '1') {
                  context.push('/edit-category/${category.id}');
                }
              },
              leading: _buildAvatar(category),
              title: Text(category.name,
                  style: AppTheme.body1.copyWith(fontWeight: FontWeight.w600)),
              subtitle:
                  category.iconEmoji != null && category.iconEmoji!.isNotEmpty
                      ? Text('Emoji: ${category.iconEmoji}',
                          style: AppTheme.caption)
                      : null,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () =>
                        context.push('/edit-category/${category.id}'),
                  ),
                  if (category.id != '1')
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () {
                        ref
                            .read(categoriesProvider.notifier)
                            .deleteCategory(category.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                                  Text('Kategori ${category.name} dihapus')),
                        );
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAvatar(Category category) {
    if (category.imagePath != null && category.imagePath!.isNotEmpty) {
      final isNetwork = category.imagePath!.startsWith('http');
      return CircleAvatar(
        radius: 24,
        backgroundColor: AppTheme.backgroundColor,
        child: ClipOval(
          child: isNetwork
              ? Image.network(category.imagePath!,
                  fit: BoxFit.cover, width: 48, height: 48)
              : Image.file(File(category.imagePath!),
                  fit: BoxFit.cover, width: 48, height: 48),
        ),
      );
    }
    return CircleAvatar(
      radius: 24,
      backgroundColor: AppTheme.primaryColor.withOpacity(0.15),
      child: Text(category.iconEmoji ?? category.name[0],
          style: const TextStyle(fontSize: 20)),
    );
  }
}
