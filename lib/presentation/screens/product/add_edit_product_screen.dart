import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_pos_kasir/core/theme/app_theme.dart';
import 'package:flutter_pos_kasir/data/models/category_model.dart';
import 'package:flutter_pos_kasir/data/models/product_model.dart';
import 'package:flutter_pos_kasir/presentation/providers/product_provider.dart';

class AddEditProductScreen extends ConsumerStatefulWidget {
  final String? productId;
  const AddEditProductScreen({super.key, this.productId});
  @override
  ConsumerState<AddEditProductScreen> createState() =>
      _AddEditProductScreenState();
}

class _AddEditProductScreenState extends ConsumerState<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  String? _selectedImagePath;
  bool _isSaving = false;

  // Controllers
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _barcodeCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _minStockCtrl = TextEditingController();
  final _unitCtrl = TextEditingController(text: 'pcs');

  String _selectedCategoryId = '2';
  bool _isActive = true;

  Product? get _editProduct {
    if (widget.productId == null) return null;
    return ref
        .read(productProvider)
        .products
        .where((p) => p.id == widget.productId)
        .firstOrNull;
  }

  bool get isEdit => widget.productId != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _populateForm());
  }

  void _populateForm() {
    final p = _editProduct;
    if (p != null) {
      _nameCtrl.text = p.name;
      _descCtrl.text = p.description ?? '';
      _barcodeCtrl.text = p.barcode ?? '';
      _priceCtrl.text = p.price.toStringAsFixed(0);
      _costCtrl.text = p.costPrice.toStringAsFixed(0);
      _stockCtrl.text = p.stock.toString();
      _minStockCtrl.text = p.minStock.toString();
      _unitCtrl.text = p.unit;
      _selectedCategoryId = p.categoryId;
      _selectedImagePath = p.imageUrl;
      setState(() => _isActive = p.isActive);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _barcodeCtrl.dispose();
    _priceCtrl.dispose();
    _costCtrl.dispose();
    _stockCtrl.dispose();
    _minStockCtrl.dispose();
    _unitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories =
        ref.watch(categoriesProvider).where((c) => c.id != '1').toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Produk' : 'Tambah Produk'),
        leading: BackButton(onPressed: () => context.pop()),
        actions: [
          if (isEdit)
            TextButton.icon(
              onPressed: _isSaving ? null : _saveProduct,
              icon: const Icon(Icons.save_outlined, color: Colors.white),
              label:
                  const Text('Simpan', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          children: [
            // ── Image picker ─────────────────────────────────────────────────
            _buildImagePicker(),
            const SizedBox(height: 20),

            // ── Basic Info ───────────────────────────────────────────────────
            _sectionTitle('Informasi Produk'),
            const SizedBox(height: 12),
            _textField(_nameCtrl, 'Nama Produk *',
                maxLength: 100,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Nama produk wajib diisi'
                    : null),
            const SizedBox(height: 12),
            _textField(_descCtrl, 'Deskripsi', maxLines: 3),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _textField(_barcodeCtrl, 'Barcode',
                      keyboardType: TextInputType.number),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: _scanBarcode,
                  icon: const Icon(Icons.qr_code_scanner, size: 18),
                  label: const Text('Scan'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 54),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Pricing ──────────────────────────────────────────────────────
            _sectionTitle('Harga'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _textField(
                    _priceCtrl,
                    'Harga Jual *',
                    prefixText: 'Rp ',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) {
                      final val = double.tryParse(v ?? '');
                      if (val == null || val <= 0)
                        return 'Masukkan harga valid';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _textField(
                    _costCtrl,
                    'Harga Modal',
                    prefixText: 'Rp ',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Stock ────────────────────────────────────────────────────────
            _sectionTitle('Stok'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _textField(
                    _stockCtrl,
                    'Stok Awal *',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Wajib diisi';
                      if (int.tryParse(v) == null) return 'Angka tidak valid';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _textField(
                    _minStockCtrl,
                    'Min. Stok',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _textField(_unitCtrl, 'Satuan',
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Wajib diisi' : null),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Category ─────────────────────────────────────────────────────
            _sectionTitle('Kategori & Status'),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedCategoryId,
              decoration: const InputDecoration(labelText: 'Kategori *'),
              items: categories
                  .map((c) => DropdownMenuItem(
                        value: c.id,
                        child: Row(
                          children: [
                            if (c.imagePath != null && c.imagePath!.isNotEmpty)
                              _buildCategoryPreview(c, size: 24)
                            else if (c.iconEmoji != null &&
                                c.iconEmoji!.isNotEmpty)
                              Text(c.iconEmoji!,
                                  style: const TextStyle(fontSize: 18)),
                            const SizedBox(width: 8),
                            Text(c.name),
                          ],
                        ),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCategoryId = v!),
              validator: (v) => v == null ? 'Pilih kategori' : null,
            ),
            const SizedBox(height: 14),
            SwitchListTile.adaptive(
              title: Text('Produk Aktif', style: AppTheme.body1),
              subtitle: Text(
                _isActive
                    ? 'Tampil di halaman kasir'
                    : 'Disembunyikan dari kasir',
                style: AppTheme.caption,
              ),
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
              activeColor: AppTheme.secondaryColor,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 28),

            // ── Save button ──────────────────────────────────────────────────
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveProduct,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save_rounded),
                label: Text(_isSaving
                    ? 'Menyimpan...'
                    : (isEdit ? 'Simpan Perubahan' : 'Tambah Produk')),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── Widgets ──────────────────────────────────────────────────────────────────
  Widget _sectionTitle(String title) {
    return Row(
      children: [
        Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(title, style: AppTheme.heading3.copyWith(fontSize: 16)),
      ],
    );
  }

  Widget _textField(
    TextEditingController ctrl,
    String label, {
    int maxLines = 1,
    int? maxLength,
    String? prefixText,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefixText,
        counterText: '',
      ),
      validator: validator,
    );
  }

  Widget _buildCategoryPreview(Category c, {double size = 24}) {
    final isNetwork = c.imagePath!.startsWith('http');
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: AppTheme.backgroundColor,
      child: ClipOval(
        child: isNetwork
            ? Image.network(c.imagePath!,
                width: size, height: size, fit: BoxFit.cover)
            : Image.file(File(c.imagePath!),
                width: size, height: size, fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Center(
      child: Stack(
        children: [
          GestureDetector(
            onTap: _showImageSourceSheet,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: AppTheme.dividerColor, width: 2),
              ),
              child: _selectedImagePath != null
                  ? ClipRRect(
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMd - 2),
                      child: Image.file(File(_selectedImagePath!),
                          fit: BoxFit.cover))
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.image_outlined,
                            size: 36, color: AppTheme.primaryColor),
                        const SizedBox(height: 4),
                        Text('Foto Produk', style: AppTheme.caption),
                      ],
                    ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _showImageSourceSheet,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
                child:
                    const Icon(Icons.camera_alt, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Actions ──────────────────────────────────────────────────────────────────
  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Ambil Foto'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Pilih dari Galeri'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (_selectedImagePath != null)
              ListTile(
                leading: const Icon(Icons.delete_outline,
                    color: AppTheme.errorColor),
                title: const Text('Hapus Foto',
                    style: TextStyle(color: AppTheme.errorColor)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _selectedImagePath = null);
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
          'product_${DateTime.now().millisecondsSinceEpoch}${path.extension(picked.path)}';
      final permanentPath = path.join(appDir.path, fileName);

      final originalFile = File(picked.path);
      final permanentFile = File(permanentPath);
      await permanentFile.writeAsBytes(await originalFile.readAsBytes());

      setState(() {
        _selectedImagePath = permanentPath;
      });
    }
  }

  void _scanBarcode() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Scan barcode: integrasikan paket mobile_scanner')),
    );
  }

  Future<void> _saveProduct() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);

    final cats = ref.read(categoriesProvider);
    final cat = cats.firstWhere((c) => c.id == _selectedCategoryId,
        orElse: () => cats.first);

    await Future.delayed(const Duration(milliseconds: 400));

    final product = Product(
      id: _editProduct?.id ?? 'p_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      imageUrl: _selectedImagePath,
      barcode:
          _barcodeCtrl.text.trim().isEmpty ? null : _barcodeCtrl.text.trim(),
      price: double.tryParse(_priceCtrl.text) ?? 0,
      costPrice: double.tryParse(_costCtrl.text) ?? 0,
      stock: int.tryParse(_stockCtrl.text) ?? 0,
      minStock: int.tryParse(_minStockCtrl.text) ?? 5,
      unit: _unitCtrl.text.trim(),
      categoryId: _selectedCategoryId,
      categoryName: cat.name,
      isActive: _isActive,
    );

    if (isEdit) {
      ref.read(productProvider.notifier).updateProduct(product);
    } else {
      ref.read(productProvider.notifier).addProduct(product);
    }

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isEdit ? 'Produk diperbarui!' : 'Produk ditambahkan!'),
        backgroundColor: AppTheme.secondaryColor,
      ));
      context.pop();
    }
  }
}
