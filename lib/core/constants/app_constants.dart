// ignore_for_file: constant_identifier_names

class AppConstants {
  AppConstants._();

  static const String appName = 'FlutterPOS';
  static const String supabaseUrl = 'https://okeoke.supabase.co';
  static const String supabaseAnonKey =
      '289347283742342jsdbasjb56j7YGIhp7_R1_p_7eZJUIlfBs8fo0wihvWNgSiIeZ4';
  static const double taxRate = 0.11;
  static const int pinLength = 4;
  static const String currency = 'Rp';
  static const String defaultCashierPin = '1234';
  static const String invoicePrefix = 'INV';

  // Payment methods
  static const List<String> paymentMethods = ['CASH', 'CARD', 'QRIS'];

  // Routes
  static const String routeLogin = '/login';
  static const String routeRegister = '/register';
  static const String routeHome = '/home';
  static const String routeProducts = '/products';
  static const String routeAddProduct = '/add-product';
  static const String routeEditProduct = '/edit-product/:id';
  static const String routeCategories = '/categories';
  static const String routeAddCategory = '/add-category';
  static const String routeEditCategory = '/edit-category/:id';
  static const String routeTransactions = '/transactions';
  static const String routeReport = '/report';
  static const String routeSettings = '/settings';
  static const String routeCheckout = '/checkout';

  // Grid
  static const double productCardMaxExtentMobile = 180.0;
  static const double productCardMaxExtentTablet = 200.0;
  static const double productCardMaxExtentDesktop = 220.0;
  static const double breakpointTablet = 600.0;
  static const double breakpointDesktop = 900.0;

  // DB
  static const String dbName = 'pos_kasir.db';
  static const int dbVersion = 1;
}
