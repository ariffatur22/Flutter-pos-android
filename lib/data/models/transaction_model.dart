class TransactionItem {
  final String productId;
  final String productName;
  final String unit;
  final double price;
  final int quantity;
  final double subtotal;

  const TransactionItem({
    required this.productId,
    required this.productName,
    required this.unit,
    required this.price,
    required this.quantity,
    required this.subtotal,
  });

  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    return TransactionItem(
      productId: json['product_id'] as String,
      productName: json['product_name'] as String,
      unit: (json['unit'] as String?) ?? 'pcs',
      price: (json['price'] as num).toDouble(),
      quantity: json['quantity'] as int,
      subtotal: (json['subtotal'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'product_id': productId,
        'product_name': productName,
        'unit': unit,
        'price': price,
        'quantity': quantity,
        'subtotal': subtotal,
      };
}

class Transaction {
  final String id;
  final String invoiceNumber;
  final List<TransactionItem> items;
  final double subtotal;
  final double discount;
  final double tax;
  final double total;
  final double paid;
  final double change;
  final String paymentMethod;
  final DateTime createdAt;
  final String? cashierName;

  const Transaction({
    required this.id,
    required this.invoiceNumber,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.total,
    required this.paid,
    required this.change,
    required this.paymentMethod,
    required this.createdAt,
    this.cashierName,
  });

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      invoiceNumber: json['invoice_number'] as String,
      items: (json['items'] as List<dynamic>)
          .map((e) => TransactionItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      subtotal: (json['subtotal'] as num).toDouble(),
      discount: (json['discount'] as num).toDouble(),
      tax: (json['tax'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      paid: (json['paid'] as num).toDouble(),
      change: (json['change'] as num).toDouble(),
      paymentMethod: json['payment_method'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      cashierName: json['cashier_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'invoice_number': invoiceNumber,
        'items': items.map((e) => e.toJson()).toList(),
        'subtotal': subtotal,
        'discount': discount,
        'tax': tax,
        'total': total,
        'paid': paid,
        'change': change,
        'payment_method': paymentMethod,
        'created_at': createdAt.toIso8601String(),
        'cashier_name': cashierName,
      };
}
