import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_pos_kasir/core/constants/app_constants.dart';
import 'package:flutter_pos_kasir/core/theme/app_theme.dart';
import 'package:flutter_pos_kasir/data/models/cart_item_model.dart';
import 'package:flutter_pos_kasir/data/models/transaction_model.dart';
import 'package:flutter_pos_kasir/presentation/providers/cart_provider.dart';
import 'package:flutter_pos_kasir/presentation/providers/auth_provider.dart';

class CartPanel extends ConsumerStatefulWidget {
  const CartPanel({super.key});
  @override
  ConsumerState<CartPanel> createState() => _CartPanelState();
}

class _CartPanelState extends ConsumerState<CartPanel> {
  final _discountCtrl = TextEditingController();
  final _paidCtrl     = TextEditingController();
  final _fmt = NumberFormat('#,##0', 'id_ID');

  @override
  void dispose() {
    _discountCtrl.dispose();
    _paidCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    return Column(
      children: [
        _buildHeader(cart),
        Expanded(child: _buildItemList(cart)),
        const Divider(height: 1),
        _buildTotalSection(cart),
        const Divider(height: 1),
        _buildPaymentSection(cart),
        _buildCheckoutBtn(cart),
      ],
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────────
  Widget _buildHeader(CartState cart) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      color: AppTheme.primaryColor.withOpacity(0.06),
      child: Row(
        children: [
          const Icon(Icons.shopping_cart, color: AppTheme.primaryColor, size: 20),
          const SizedBox(width: 8),
          Text('Keranjang', style: AppTheme.heading3),
          const SizedBox(width: 6),
          if (cart.totalItems > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('${cart.totalItems}',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          const Spacer(),
          if (cart.items.isNotEmpty)
            TextButton.icon(
              onPressed: () => _confirmClear(context),
              icon: const Icon(Icons.delete_outline, size: 16, color: AppTheme.errorColor),
              label: const Text('Kosongkan', style: TextStyle(color: AppTheme.errorColor, fontSize: 12)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
        ],
      ),
    );
  }

  // ── Item List ────────────────────────────────────────────────────────────────
  Widget _buildItemList(CartState cart) {
    if (cart.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined,
                size: 56, color: AppTheme.textSecondary.withOpacity(0.3)),
            const SizedBox(height: 10),
            Text('Keranjang kosong', style: AppTheme.body2.copyWith(color: AppTheme.textSecondary)),
            const SizedBox(height: 4),
            Text('Tap produk untuk menambahkan',
                style: AppTheme.caption),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: cart.items.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 12, endIndent: 12),
      itemBuilder: (_, i) => _CartItemTile(item: cart.items[i]),
    );
  }

  // ── Total section ────────────────────────────────────────────────────────────
  Widget _buildTotalSection(CartState cart) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _totalRow('Subtotal', cart.subtotal),
          const SizedBox(height: 6),
          _buildDiscountRow(cart),
          const SizedBox(height: 6),
          _totalRow('PPN (${(AppConstants.taxRate * 100).toStringAsFixed(0)}%)', cart.tax,
              valueColor: AppTheme.textSecondary),
          const Divider(height: 16),
          Row(
            children: [
              Text('TOTAL', style: AppTheme.heading3),
              const Spacer(),
              Text('Rp ${_fmt.format(cart.total)}',
                  style: AppTheme.heading3.copyWith(color: AppTheme.secondaryColor)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDiscountRow(CartState cart) {
    return Row(
      children: [
        Text('Diskon', style: AppTheme.body2),
        const SizedBox(width: 8),
        // Toggle % / Rp
        GestureDetector(
          onTap: () {
            _discountCtrl.clear();
            if (cart.isDiscountPercent) {
              ref.read(cartProvider.notifier).setDiscountNominal(0);
            } else {
              ref.read(cartProvider.notifier).setDiscountPercent(0);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              cart.isDiscountPercent ? '%' : 'Rp',
              style: AppTheme.caption.copyWith(
                  fontWeight: FontWeight.bold, color: AppTheme.accentColor),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 80,
          height: 30,
          child: TextField(
            controller: _discountCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: AppTheme.body2,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              hintText: cart.isDiscountPercent ? '0-100' : '0',
            ),
            onChanged: (v) {
              final val = double.tryParse(v) ?? 0;
              if (cart.isDiscountPercent) {
                ref.read(cartProvider.notifier).setDiscountPercent(val);
              } else {
                ref.read(cartProvider.notifier).setDiscountNominal(val);
              }
            },
          ),
        ),
        const Spacer(),
        Text(
          '- Rp ${_fmt.format(cart.discountValue)}',
          style: AppTheme.body2.copyWith(color: AppTheme.accentColor, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _totalRow(String label, double value, {Color? valueColor}) {
    return Row(
      children: [
        Text(label, style: AppTheme.body2.copyWith(color: AppTheme.textSecondary)),
        const Spacer(),
        Text('Rp ${_fmt.format(value)}',
            style: AppTheme.body2.copyWith(
                color: valueColor ?? AppTheme.textPrimary,
                fontWeight: FontWeight.w500)),
      ],
    );
  }

  // ── Payment section ──────────────────────────────────────────────────────────
  Widget _buildPaymentSection(CartState cart) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Metode Pembayaran', style: AppTheme.caption),
          const SizedBox(height: 6),
          Row(
            children: AppConstants.paymentMethods.map((m) {
              final selected = cart.paymentMethod == m;
              IconData icon;
              switch (m) {
                case 'CARD': icon = Icons.credit_card; break;
                case 'QRIS': icon = Icons.qr_code; break;
                default:     icon = Icons.payments_outlined;
              }
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: OutlinedButton.icon(
                    icon: Icon(icon, size: 14),
                    label: Text(m, style: const TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      foregroundColor: selected ? Colors.white : AppTheme.primaryColor,
                      backgroundColor: selected ? AppTheme.primaryColor : Colors.transparent,
                      side: BorderSide(
                          color: selected ? AppTheme.primaryColor : AppTheme.dividerColor),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
                    ),
                    onPressed: () {
                      _paidCtrl.clear();
                      ref.read(cartProvider.notifier).setPaymentMethod(m);
                    },
                  ),
                ),
              );
            }).toList(),
          ),
          if (cart.paymentMethod == 'CASH') ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _paidCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Jumlah Bayar',
                      prefixText: 'Rp ',
                      isDense: true,
                    ),
                    onChanged: (v) {
                      final val = double.tryParse(v) ?? 0;
                      ref.read(cartProvider.notifier).setPaidAmount(val);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Kembalian', style: AppTheme.caption),
                    Text(
                      'Rp ${_fmt.format(cart.change)}',
                      style: AppTheme.body1.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cart.isChangePositive
                            ? AppTheme.secondaryColor
                            : AppTheme.errorColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  // ── Checkout button ──────────────────────────────────────────────────────────
  Widget _buildCheckoutBtn(CartState cart) {
    final canCheckout = cart.items.isNotEmpty &&
        (cart.paymentMethod != 'CASH' ||
            (cart.paidAmount >= cart.total && cart.paidAmount > 0));
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          onPressed: canCheckout ? () => _processCheckout(cart) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.secondaryColor,
            disabledBackgroundColor: AppTheme.dividerColor,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
          ),
          icon: const Icon(Icons.check_circle_outline),
          label: Text(
            cart.items.isEmpty
                ? 'Tambah Produk Dahulu'
                : 'CHECKOUT — Rp ${_fmt.format(cart.total)}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────
  void _confirmClear(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Kosongkan Keranjang?'),
        content: const Text('Semua item akan dihapus dari keranjang.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(cartProvider.notifier).clearCart();
              _discountCtrl.clear();
              _paidCtrl.clear();
            },
            child: const Text('Hapus', style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );
  }

  void _processCheckout(CartState cart) {
    final auth = ref.read(authProvider);
    final now = DateTime.now();
    final invoiceNum =
        '${AppConstants.invoicePrefix}-${now.year}${now.month.toString().padLeft(2, '0')}-'
        '${now.millisecondsSinceEpoch.toString().substring(7)}';

    final transaction = Transaction(
      id: 'trx_${now.millisecondsSinceEpoch}',
      invoiceNumber: invoiceNum,
      items: cart.items.map((ci) => TransactionItem(
        productId: ci.product.id,
        productName: ci.product.name,
        unit: ci.product.unit,
        price: ci.product.price,
        quantity: ci.quantity,
        subtotal: ci.subtotal,
      )).toList(),
      subtotal: cart.subtotal,
      discount: cart.discountValue,
      tax: cart.tax,
      total: cart.total,
      paid: cart.paymentMethod == 'CASH' ? cart.paidAmount : cart.total,
      change: cart.change,
      paymentMethod: cart.paymentMethod,
      createdAt: now,
      cashierName: auth.cashierName,
    );

    ref.read(cartProvider.notifier).clearCart();
    _discountCtrl.clear();
    _paidCtrl.clear();

    context.push(AppConstants.routeCheckout, extra: transaction);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _CartItemTile extends ConsumerWidget {
  final CartItem item;
  const _CartItemTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = NumberFormat('#,##0', 'id_ID');
    return Dismissible(
      key: ValueKey(item.product.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: AppTheme.errorColor.withOpacity(0.1),
        child: const Icon(Icons.delete_outline, color: AppTheme.errorColor),
      ),
      onDismissed: (_) =>
          ref.read(cartProvider.notifier).removeItem(item.product.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            // Product color avatar
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  item.product.name.isNotEmpty
                      ? item.product.name[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.product.name,
                      style: AppTheme.body2.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text('Rp ${fmt.format(item.product.price)} / ${item.product.unit}',
                      style: AppTheme.caption),
                ],
              ),
            ),
            // Stepper
            _Stepper(
              qty: item.quantity,
              onDecrement: () => ref
                  .read(cartProvider.notifier)
                  .updateQuantity(item.product.id, item.quantity - 1),
              onIncrement: () => ref
                  .read(cartProvider.notifier)
                  .updateQuantity(item.product.id, item.quantity + 1),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 76,
              child: Text(
                'Rp ${fmt.format(item.subtotal)}',
                textAlign: TextAlign.right,
                style: AppTheme.body2.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.secondaryColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _Stepper extends StatelessWidget {
  final int qty;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  const _Stepper(
      {required this.qty, required this.onDecrement, required this.onIncrement});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _stepBtn(Icons.remove, onDecrement,
            color: qty == 1 ? AppTheme.errorColor : AppTheme.primaryColor),
        Container(
          width: 30,
          alignment: Alignment.center,
          child: Text('$qty',
              style: AppTheme.body2.copyWith(fontWeight: FontWeight.bold)),
        ),
        _stepBtn(Icons.add, onIncrement),
      ],
    );
  }

  Widget _stepBtn(IconData icon, VoidCallback onTap, {Color? color}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          border: Border.all(
              color: (color ?? AppTheme.primaryColor).withOpacity(0.4)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, size: 16, color: color ?? AppTheme.primaryColor),
      ),
    );
  }
}
