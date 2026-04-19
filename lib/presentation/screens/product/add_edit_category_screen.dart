import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_pos_kasir/core/constants/app_constants.dart';
import 'package:flutter_pos_kasir/core/theme/app_theme.dart';
import 'package:flutter_pos_kasir/data/models/category_model.dart';
import 'package:flutter_pos_kasir/presentation/providers/product_provider.dart';

class AddEditCategoryScreen extends ConsumerStatefulWidget {
  final String? categoryId;
  const AddEditCategoryScreen({super.key, this.categoryId});

  @override
  ConsumerState<AddEditCategoryScreen> createState() =>
      _AddEditCategoryScreenState();
}

class _AddEditCategoryScreenState extends ConsumerState<AddEditCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  String? _imagePath;
  final _nameCtrl = TextEditingController();
  final _iconCtrl = TextEditingController();
  bool _isSaving = false;

  Category? get _editCategory {
    if (widget.categoryId == null) return null;
    final list = ref
        .read(categoriesProvider)
        .where((c) => c.id == widget.categoryId)
        .toList();
    return list.isEmpty ? null : list.first;
  }

  bool get isEdit => widget.categoryId != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _populateForm());
  }

  void _populateForm() {
    final category = _editCategory;
    if (category != null) {
      _nameCtrl.text = category.name;
      _iconCtrl.text = category.iconEmoji ?? '';
      _imagePath = category.imagePath;
      setState(() {});
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _iconCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Kategori' : 'Tambah Kategori'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        children: [
          _buildImagePicker(),
          const SizedBox(height: 20),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Nama Kategori *'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Nama kategori wajib diisi'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _iconCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Emoji Kategori',
                    hintText: 'Contoh: 🍰 atau ☕',
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveCategory,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.save_rounded),
                    label: Text(_isSaving
                        ? 'Menyimpan...'
                        : isEdit
                            ? 'Simpan Kategori'
                            : 'Tambah Kategori'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePicker() {
    final hasImage = _imagePath != null && _imagePath!.isNotEmpty;
    final isNetwork = hasImage && _imagePath!.startsWith('http');

    return GestureDetector(
      onTap: _showImageSourceSheet,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppTheme.dividerColor, width: 2),
        ),
        child: Center(
          child: hasImage
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd - 2),
                  child: isNetwork
                      ? Image.network(_imagePath!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity)
                      : Image.file(File(_imagePath!),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.image_outlined,
                        size: 40, color: AppTheme.primaryColor),
                    SizedBox(height: 8),
                    Text('Pilih Gambar Kategori',
                        style: TextStyle(color: AppTheme.primaryColor)),
                  ],
                ),
        ),
      ),
    );
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Pilih dari Galeri'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (_imagePath != null)
              ListTile(
                leading: const Icon(Icons.delete_outline,
                    color: AppTheme.errorColor),
                title: const Text('Hapus Gambar',
                    style: TextStyle(color: AppTheme.errorColor)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _imagePath = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(
        source: source, imageQuality: 80, maxWidth: 800);
    if (picked != null) {
      // Salin gambar ke direktori permanen aplikasi
      final appDir = await getApplicationDocumentsDirectory();
      final fileName =
          'category_${DateTime.now().millisecondsSinceEpoch}${path.extension(picked.path)}';
      final permanentPath = path.join(appDir.path, fileName);

      final originalFile = File(picked.path);
      final permanentFile = File(permanentPath);
      await permanentFile.writeAsBytes(await originalFile.readAsBytes());

      setState(() {
        _imagePath = permanentPath;
      });
    }
  }

  Future<void> _saveCategory() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);

    final category = Category(
      id: _editCategory?.id ?? 'cat_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameCtrl.text.trim(),
      iconEmoji: _iconCtrl.text.trim().isEmpty ? null : _iconCtrl.text.trim(),
      imagePath: _imagePath,
      sortOrder:
          _editCategory?.sortOrder ?? ref.read(categoriesProvider).length,
    );

    if (isEdit) {
      ref.read(categoriesProvider.notifier).updateCategory(category);
    } else {
      ref.read(categoriesProvider.notifier).addCategory(category);
    }

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isEdit ? 'Kategori diperbarui' : 'Kategori ditambahkan'),
        backgroundColor: AppTheme.primaryColor,
      ));
      context.go(AppConstants.routeCategories);
    }
  }
}
