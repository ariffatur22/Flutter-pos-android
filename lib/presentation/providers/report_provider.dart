import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_pos_kasir/data/models/transaction_model.dart';

class SalesChartData {
  final DateTime date;
  final double total;
  final int count;
  const SalesChartData({required this.date, required this.total, required this.count});
}

class TopProduct {
  final String name;
  final int qty;
  final double revenue;
  const TopProduct({required this.name, required this.qty, required this.revenue});
}

class ReportState {
  final List<Transaction> transactions;
  final List<SalesChartData> chartData;
  final List<TopProduct> topProducts;
  final DateTime startDate;
  final DateTime endDate;
  final bool isLoading;
  final String? error;

  double get totalRevenue =>
      transactions.fold(0.0, (s, t) => s + t.total);
  int get totalTransactions => transactions.length;
  double get averageTransaction =>
      totalTransactions == 0 ? 0 : totalRevenue / totalTransactions;

  const ReportState({
    this.transactions = const [],
    this.chartData = const [],
    this.topProducts = const [],
    required this.startDate,
    required this.endDate,
    this.isLoading = false,
    this.error,
  });

  ReportState copyWith({
    List<Transaction>? transactions,
    List<SalesChartData>? chartData,
    List<TopProduct>? topProducts,
    DateTime? startDate,
    DateTime? endDate,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return ReportState(
      transactions: transactions ?? this.transactions,
      chartData: chartData ?? this.chartData,
      topProducts: topProducts ?? this.topProducts,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ReportNotifier extends StateNotifier<ReportState> {
  ReportNotifier()
      : super(ReportState(
          startDate: DateTime.now().subtract(const Duration(days: 6)),
          endDate: DateTime.now(),
        )) {
    loadReport();
  }

  void loadReport() {
    state = state.copyWith(isLoading: true, clearError: true);
    // Generate mock data for last 7 days
    final now = DateTime.now();
    final mockChartData = List.generate(7, (i) {
      final date = now.subtract(Duration(days: 6 - i));
      final total = 200000.0 + (i * 150000) + (i % 3 == 0 ? 250000 : 0);
      return SalesChartData(date: date, total: total, count: 5 + i);
    });

    final mockTransactions = _generateMockTransactions(now);
    final topProducts = _generateTopProducts();

    state = state.copyWith(
      isLoading: false,
      transactions: mockTransactions,
      chartData: mockChartData,
      topProducts: topProducts,
    );
  }

  void setDateRange(DateTime start, DateTime end) {
    state = state.copyWith(startDate: start, endDate: end);
    loadReport();
  }

  List<Transaction> _generateMockTransactions(DateTime now) {
    return List.generate(10, (i) {
      final date = now.subtract(Duration(days: i ~/ 3, hours: i * 2));
      return Transaction(
        id: 'trx_$i',
        invoiceNumber: 'INV-${now.year}${(now.month).toString().padLeft(2, '0')}-${(1000 + i).toString()}',
        items: [
          const TransactionItem(productId: 'p1', productName: 'Kopi Americano',
              unit: 'cup', price: 25000, quantity: 2, subtotal: 50000),
          const TransactionItem(productId: 'p4', productName: 'Nasi Ayam',
              unit: 'porsi', price: 35000, quantity: 1, subtotal: 35000),
        ],
        subtotal: 85000,
        discount: 0,
        tax: 9350,
        total: 94350,
        paid: 100000,
        change: 5650,
        paymentMethod: i % 3 == 0 ? 'QRIS' : (i % 3 == 1 ? 'CARD' : 'CASH'),
        createdAt: date,
        cashierName: 'Kasir',
      );
    });
  }

  List<TopProduct> _generateTopProducts() {
    return const [
      TopProduct(name: 'Kopi Americano', qty: 120, revenue: 3000000),
      TopProduct(name: 'Kopi Susu',      qty: 95,  revenue: 3040000),
      TopProduct(name: 'Nasi Ayam',      qty: 80,  revenue: 2800000),
      TopProduct(name: 'Mie Ayam',       qty: 75,  revenue: 1875000),
      TopProduct(name: 'Jus Jeruk',      qty: 60,  revenue: 1680000),
    ];
  }
}

final reportProvider =
    StateNotifierProvider<ReportNotifier, ReportState>((ref) => ReportNotifier());
