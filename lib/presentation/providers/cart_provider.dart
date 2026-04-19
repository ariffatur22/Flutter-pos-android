import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_pos_kasir/core/constants/app_constants.dart';
import 'package:flutter_pos_kasir/data/models/product_model.dart';
import 'package:flutter_pos_kasir/data/models/cart_item_model.dart';

class CartState {
  final List<CartItem> items;
  final double discountPercent;
  final double discountNominal;
  final bool isDiscountPercent;
  final String paymentMethod;
  final double paidAmount;

  const CartState({
    this.items = const [],
    this.discountPercent = 0,
    this.discountNominal = 0,
    this.isDiscountPercent = true,
    this.paymentMethod = 'CASH',
    this.paidAmount = 0,
  });

  int get totalItems => items.fold(0, (s, i) => s + i.quantity);
  double get subtotal => items.fold(0.0, (s, i) => s + i.subtotal);

  double get discountValue {
    if (isDiscountPercent) return subtotal * (discountPercent / 100);
    return discountNominal;
  }

  double get afterDiscount => subtotal - discountValue;
  double get tax => afterDiscount * AppConstants.taxRate;
  double get total => afterDiscount + tax;
  double get change => paidAmount >= total ? paidAmount - total : 0;
  bool get isChangePositive => paidAmount >= total;

  CartState copyWith({
    List<CartItem>? items,
    double? discountPercent,
    double? discountNominal,
    bool? isDiscountPercent,
    String? paymentMethod,
    double? paidAmount,
  }) {
    return CartState(
      items: items ?? this.items,
      discountPercent: discountPercent ?? this.discountPercent,
      discountNominal: discountNominal ?? this.discountNominal,
      isDiscountPercent: isDiscountPercent ?? this.isDiscountPercent,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paidAmount: paidAmount ?? this.paidAmount,
    );
  }
}

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(const CartState());

  void addItem(Product product) {
    final idx = state.items.indexWhere((i) => i.product.id == product.id);
    if (idx >= 0) {
      final updated = List<CartItem>.from(state.items);
      updated[idx] = updated[idx].copyWith(quantity: updated[idx].quantity + 1);
      state = state.copyWith(items: updated);
    } else {
      state = state.copyWith(
          items: [...state.items, CartItem(product: product, quantity: 1)]);
    }
  }

  void removeItem(String productId) {
    state = state.copyWith(
        items: state.items.where((i) => i.product.id != productId).toList());
  }

  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }
    final updated = List<CartItem>.from(state.items);
    final idx = updated.indexWhere((i) => i.product.id == productId);
    if (idx >= 0) {
      updated[idx] = updated[idx].copyWith(quantity: quantity);
      state = state.copyWith(items: updated);
    }
  }

  void clearCart() => state = const CartState();

  void setDiscountPercent(double percent) {
    state = state.copyWith(
        discountPercent: percent.clamp(0, 100),
        isDiscountPercent: true);
  }

  void setDiscountNominal(double nominal) {
    state = state.copyWith(discountNominal: nominal, isDiscountPercent: false);
  }

  void setPaymentMethod(String method) {
    state = state.copyWith(paymentMethod: method, paidAmount: 0);
  }

  void setPaidAmount(double amount) {
    state = state.copyWith(paidAmount: amount);
  }
}

final cartProvider =
    StateNotifierProvider<CartNotifier, CartState>((ref) => CartNotifier());
