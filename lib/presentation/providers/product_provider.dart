import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_pos_kasir/data/models/product_model.dart';
import 'package:flutter_pos_kasir/data/models/category_model.dart';

// ── Sample data ───────────────────────────────────────────────────────────────
final List<Category> sampleCategories = [
  const Category(
    id: '1',
    name: 'Semua',
    iconEmoji: '🛍️',
    imagePath:
        'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=400&q=60',
    sortOrder: 0,
  ),
  const Category(
    id: '2',
    name: 'Minuman',
    iconEmoji: '☕',
    imagePath:
        'https://images.unsplash.com/photo-1510627498534-cf7e9002facc?auto=format&fit=crop&w=400&q=60',
    sortOrder: 1,
  ),
  const Category(
    id: '3',
    name: 'Makanan',
    iconEmoji: '🍱',
    imagePath:
        'https://images.unsplash.com/photo-1490645935967-10de6ba17061?auto=format&fit=crop&w=400&q=60',
    sortOrder: 2,
  ),
  const Category(
    id: '4',
    name: 'Snack',
    iconEmoji: '🍿',
    imagePath:
        'https://images.unsplash.com/photo-1511688878357-319ae4edda1b?auto=format&fit=crop&w=400&q=60',
    sortOrder: 3,
  ),
  const Category(
    id: '5',
    name: 'Lainnya',
    iconEmoji: '📦',
    imagePath:
        'https://images.unsplash.com/photo-1557682250-92be77257a8e?auto=format&fit=crop&w=400&q=60',
    sortOrder: 4,
  ),
];

final List<Product> _sampleProducts = [
  const Product(
      id: 'p1',
      name: 'Kopi Americano',
      description: 'Espresso + air panas',
      imageUrl: null,
      barcode: '001',
      price: 25000,
      costPrice: 8000,
      stock: 100,
      minStock: 10,
      unit: 'cup',
      categoryId: '2',
      categoryName: 'Minuman',
      isActive: true),
  const Product(
      id: 'p2',
      name: 'Kopi Susu',
      description: 'Espresso + susu segar',
      imageUrl: null,
      barcode: '002',
      price: 32000,
      costPrice: 10000,
      stock: 80,
      minStock: 10,
      unit: 'cup',
      categoryId: '2',
      categoryName: 'Minuman',
      isActive: true),
  const Product(
      id: 'p3',
      name: 'Teh Tarik',
      description: 'Teh dengan susu kental',
      imageUrl: null,
      barcode: '003',
      price: 20000,
      costPrice: 6000,
      stock: 4,
      minStock: 10,
      unit: 'cup',
      categoryId: '2',
      categoryName: 'Minuman',
      isActive: true),
  const Product(
      id: 'p4',
      name: 'Nasi Ayam',
      description: 'Nasi + ayam goreng + lalapan',
      imageUrl: null,
      barcode: '004',
      price: 35000,
      costPrice: 18000,
      stock: 25,
      minStock: 5,
      unit: 'porsi',
      categoryId: '3',
      categoryName: 'Makanan',
      isActive: true),
  const Product(
      id: 'p5',
      name: 'Nasi Goreng',
      description: 'Nasi goreng special',
      imageUrl: null,
      barcode: '005',
      price: 30000,
      costPrice: 15000,
      stock: 0,
      minStock: 5,
      unit: 'porsi',
      categoryId: '3',
      categoryName: 'Makanan',
      isActive: true),
  const Product(
      id: 'p6',
      name: 'Mie Ayam',
      description: 'Mie ayam bakso',
      imageUrl: null,
      barcode: '006',
      price: 25000,
      costPrice: 12000,
      stock: 30,
      minStock: 5,
      unit: 'mangkuk',
      categoryId: '3',
      categoryName: 'Makanan',
      isActive: true),
  const Product(
      id: 'p7',
      name: 'Kentang Goreng',
      description: 'Kentang goreng crispy',
      imageUrl: null,
      barcode: '007',
      price: 18000,
      costPrice: 7000,
      stock: 50,
      minStock: 10,
      unit: 'porsi',
      categoryId: '4',
      categoryName: 'Snack',
      isActive: true),
  const Product(
      id: 'p8',
      name: 'Pisang Goreng',
      description: '3 pcs pisang goreng',
      imageUrl: null,
      barcode: '008',
      price: 15000,
      costPrice: 5000,
      stock: 40,
      minStock: 10,
      unit: 'porsi',
      categoryId: '4',
      categoryName: 'Snack',
      isActive: true),
  const Product(
      id: 'p9',
      name: 'Roti Bakar',
      description: 'Roti bakar keju coklat',
      imageUrl: null,
      barcode: '009',
      price: 22000,
      costPrice: 9000,
      stock: 3,
      minStock: 5,
      unit: 'pcs',
      categoryId: '4',
      categoryName: 'Snack',
      isActive: false),
  const Product(
      id: 'p10',
      name: 'Air Mineral',
      description: 'Botol 600ml',
      imageUrl: null,
      barcode: '010',
      price: 5000,
      costPrice: 2500,
      stock: 200,
      minStock: 20,
      unit: 'botol',
      categoryId: '2',
      categoryName: 'Minuman',
      isActive: true),
  const Product(
      id: 'p11',
      name: 'Tissue',
      description: 'Tissue meja 1 pak',
      imageUrl: null,
      barcode: '011',
      price: 3000,
      costPrice: 1500,
      stock: 100,
      minStock: 20,
      unit: 'pak',
      categoryId: '5',
      categoryName: 'Lainnya',
      isActive: true),
  const Product(
      id: 'p12',
      name: 'Jus Jeruk',
      description: 'Jus jeruk segar tanpa gula',
      imageUrl: null,
      barcode: '012',
      price: 28000,
      costPrice: 10000,
      stock: 60,
      minStock: 10,
      unit: 'gelas',
      categoryId: '2',
      categoryName: 'Minuman',
      isActive: true),
];

// ── State ─────────────────────────────────────────────────────────────────────
class ProductState {
  final List<Product> products;
  final List<Product> filtered;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  final String selectedCategoryId; // '1' = Semua

  const ProductState({
    this.products = const [],
    this.filtered = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.selectedCategoryId = '1',
  });

  ProductState copyWith({
    List<Product>? products,
    List<Product>? filtered,
    bool? isLoading,
    String? error,
    bool clearError = false,
    String? searchQuery,
    String? selectedCategoryId,
  }) {
    return ProductState(
      products: products ?? this.products,
      filtered: filtered ?? this.filtered,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
    );
  }
}

// ── Category Notifier ───────────────────────────────────────────────────────────
class CategoryNotifier extends StateNotifier<List<Category>> {
  CategoryNotifier() : super(sampleCategories);

  void addCategory(Category category) {
    state = [...state, category];
  }

  void updateCategory(Category category) {
    state = state.map((c) => c.id == category.id ? category : c).toList();
  }

  void deleteCategory(String id) {
    if (id == '1') return;
    state = state.where((c) => c.id != id).toList();
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────
class ProductNotifier extends StateNotifier<ProductState> {
  ProductNotifier() : super(const ProductState()) {
    loadProducts();
  }

  void loadProducts() {
    state = state.copyWith(isLoading: true, clearError: true);
    // TODO: ganti dengan fetch Supabase / sqflite
    state = state.copyWith(
      isLoading: false,
      products: _sampleProducts,
      filtered: _sampleProducts,
    );
  }

  void search(String query) {
    state = state.copyWith(searchQuery: query);
    _applyFilters();
  }

  void filterByCategory(String categoryId) {
    state = state.copyWith(selectedCategoryId: categoryId);
    _applyFilters();
  }

  void _applyFilters() {
    var list = List<Product>.from(state.products);
    if (state.selectedCategoryId != '1') {
      list =
          list.where((p) => p.categoryId == state.selectedCategoryId).toList();
    }
    if (state.searchQuery.isNotEmpty) {
      final q = state.searchQuery.toLowerCase();
      list = list
          .where((p) =>
              p.name.toLowerCase().contains(q) ||
              (p.barcode?.contains(q) ?? false))
          .toList();
    }
    state = state.copyWith(filtered: list);
  }

  void addProduct(Product product) {
    final updated = [...state.products, product];
    state = state.copyWith(products: updated);
    _applyFilters();
  }

  void updateProduct(Product product) {
    final updated =
        state.products.map((p) => p.id == product.id ? product : p).toList();
    state = state.copyWith(products: updated);
    _applyFilters();
  }

  void deleteProduct(String id) {
    final updated = state.products.where((p) => p.id != id).toList();
    state = state.copyWith(products: updated);
    _applyFilters();
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────
final productProvider = StateNotifierProvider<ProductNotifier, ProductState>(
    (ref) => ProductNotifier());

final categoriesProvider =
    StateNotifierProvider<CategoryNotifier, List<Category>>(
  (ref) => CategoryNotifier(),
);
