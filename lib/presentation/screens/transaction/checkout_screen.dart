import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_pos_kasir/core/constants/app_constants.dart';
import 'package:flutter_pos_kasir/core/theme/app_theme.dart';
import 'package:flutter_pos_kasir/data/models/transaction_model.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  final Transaction? transaction;
  const CheckoutScreen({super.key, this.transaction});
  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _checkCtrl;
  late Animation<double> _checkScale;
  late Animation<double> _checkOpacity;
  bool _showDetail = false;

  final _fmt = NumberFormat('#,##0', 'id_ID');
  final _dateFmt = DateFormat('dd/MM/yyyy HH:mm', 'id_ID');

  @override
  void initState() {
    super.initState();
    _checkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _checkScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _checkCtrl, curve: Curves.elasticOut),
    );
    _checkOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _checkCtrl,
          curve: const Interval(0, 0.4, curve: Curves.easeIn)),
    );
    _checkCtrl.forward();
  }

  @override
  void dispose() {
    _checkCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trx = widget.transaction;
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Transaksi Berhasil'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                const SizedBox(height: 16),
                // ── Success animation ────────────────────────────────────────
                _buildSuccessIcon(),
                const SizedBox(height: 20),
                Text('Pembayaran Berhasil!', style: AppTheme.heading2),
                if (trx != null) ...[
                  const SizedBox(height: 4),
                  Text(trx.invoiceNumber,
                      style: AppTheme.body2.copyWith(color: AppTheme.textSecondary)),
                ],
                const SizedBox(height: 28),

                // ── Summary card ─────────────────────────────────────────────
                if (trx != null) _buildSummaryCard(trx),
                const SizedBox(height: 12),

                // ── Detail toggle ────────────────────────────────────────────
                if (trx != null) _buildDetailToggle(trx),
                const SizedBox(height: 28),

                // ── Action buttons ───────────────────────────────────────────
                _buildActionButtons(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessIcon() {
    return AnimatedBuilder(
      animation: _checkCtrl,
      builder: (_, __) => Opacity(
        opacity: _checkOpacity.value,
        child: Transform.scale(
          scale: _checkScale.value,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.secondaryColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.secondaryColor.withOpacity(0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 56),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(Transaction trx) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          children: [
            _summaryRow('Tanggal', _dateFmt.format(trx.createdAt)),
            _summaryRow('Kasir', trx.cashierName ?? '-'),
            _summaryRow('Metode', trx.paymentMethod),
            const Divider(height: 20),
            _summaryRow('Subtotal', 'Rp ${_fmt.format(trx.subtotal)}'),
            if (trx.discount > 0)
              _summaryRow('Diskon', '- Rp ${_fmt.format(trx.discount)}',
                  valueColor: AppTheme.accentColor),
            _summaryRow('PPN', 'Rp ${_fmt.format(trx.tax)}'),
            const Divider(height: 16),
            Row(
              children: [
                Text('TOTAL', style: AppTheme.heading3),
                const Spacer(),
                Text('Rp ${_fmt.format(trx.total)}',
                    style: AppTheme.heading3.copyWith(color: AppTheme.secondaryColor)),
              ],
            ),
            const SizedBox(height: 8),
            _summaryRow('Dibayar', 'Rp ${_fmt.format(trx.paid)}'),
            _summaryRow('Kembalian', 'Rp ${_fmt.format(trx.change)}',
                valueColor: AppTheme.primaryColor,
                valueBold: true),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value,
      {Color? valueColor, bool valueBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label,
              style: AppTheme.body2.copyWith(color: AppTheme.textSecondary)),
          const Spacer(),
          Text(value,
              style: AppTheme.body2.copyWith(
                  color: valueColor ?? AppTheme.textPrimary,
                  fontWeight:
                      valueBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  Widget _buildDetailToggle(Transaction trx) {
    return Column(
      children: [
        TextButton.icon(
          onPressed: () => setState(() => _showDetail = !_showDetail),
          icon: Icon(_showDetail ? Icons.expand_less : Icons.expand_more),
          label: Text(_showDetail ? 'Sembunyikan Detail' : 'Lihat Detail Item'),
        ),
        if (_showDetail) _buildItemDetail(trx),
      ],
    );
  }

  Widget _buildItemDetail(Transaction trx) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Detail Item (${trx.items.length} produk)',
                style: AppTheme.body2.copyWith(fontWeight: FontWeight.w600)),
            const Divider(height: 14),
            ...trx.items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text('${item.productName} x${item.quantity}',
                        style: AppTheme.body2),
                  ),
                  Text('Rp ${_fmt.format(item.subtotal)}',
                      style: AppTheme.body2
                          .copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: () => _printReceipt(),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            minimumSize: const Size.fromHeight(50),
          ),
          icon: const Icon(Icons.print_outlined),
          label: const Text('Cetak Struk'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => context.go(AppConstants.routeHome),
          style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50)),
          icon: const Icon(Icons.add_shopping_cart),
          label: const Text('Transaksi Baru'),
        ),
      ],
    );
  }

  void _printReceipt() {
    final trx = widget.transaction;
    if (trx == null) return;
    // TODO: implementasi Bluetooth printer atau PDF
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text('Mencetak struk ${trx.invoiceNumber}...'),
          ],
        ),
        backgroundColor: AppTheme.secondaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
      ),
    );
  }
}
