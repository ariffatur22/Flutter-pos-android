import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_pos_kasir/core/constants/app_constants.dart';
import 'package:flutter_pos_kasir/data/models/transaction_model.dart';
import 'package:flutter_pos_kasir/presentation/providers/auth_provider.dart';
import 'package:flutter_pos_kasir/presentation/screens/auth/login_screen.dart';
import 'package:flutter_pos_kasir/presentation/screens/auth/register_screen.dart';
import 'package:flutter_pos_kasir/presentation/screens/home/home_screen.dart';
import 'package:flutter_pos_kasir/presentation/screens/product/product_management_screen.dart';
import 'package:flutter_pos_kasir/presentation/screens/product/add_edit_product_screen.dart';
import 'package:flutter_pos_kasir/presentation/screens/product/category_management_screen.dart';
import 'package:flutter_pos_kasir/presentation/screens/product/add_edit_category_screen.dart';
import 'package:flutter_pos_kasir/presentation/screens/report/report_screen.dart';
import 'package:flutter_pos_kasir/presentation/screens/transaction/checkout_screen.dart';

class _RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  _RouterNotifier(this._ref) {
    _ref.listen<AuthState>(authProvider, (_, __) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);
  return GoRouter(
    initialLocation: AppConstants.routeLogin,
    refreshListenable: notifier,
    redirect: (BuildContext context, GoRouterState state) {
      final isLoggedIn = ref.read(authProvider).isLoggedIn;
      final isLogin = state.matchedLocation == AppConstants.routeLogin;
      final isRegister = state.matchedLocation == AppConstants.routeRegister;
      if (!isLoggedIn && !isLogin && !isRegister) {
        return AppConstants.routeLogin;
      }
      if (isLoggedIn && (isLogin || isRegister)) {
        return AppConstants.routeHome;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppConstants.routeLogin,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppConstants.routeRegister,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppConstants.routeHome,
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppConstants.routeProducts,
        name: 'products',
        builder: (context, state) => const ProductManagementScreen(),
      ),
      GoRoute(
        path: AppConstants.routeAddProduct,
        name: 'add-product',
        builder: (context, state) => const AddEditProductScreen(),
      ),
      GoRoute(
        path: '/edit-product/:id',
        name: 'edit-product',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return AddEditProductScreen(productId: id);
        },
      ),
      GoRoute(
        path: AppConstants.routeCategories,
        name: 'categories',
        builder: (context, state) => const CategoryManagementScreen(),
      ),
      GoRoute(
        path: AppConstants.routeAddCategory,
        name: 'add-category',
        builder: (context, state) => const AddEditCategoryScreen(),
      ),
      GoRoute(
        path: AppConstants.routeEditCategory,
        name: 'edit-category',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return AddEditCategoryScreen(categoryId: id);
        },
      ),
      GoRoute(
        path: AppConstants.routeReport,
        name: 'report',
        builder: (context, state) => const ReportScreen(),
      ),
      GoRoute(
        path: AppConstants.routeCheckout,
        name: 'checkout',
        builder: (context, state) {
          final transaction = state.extra as Transaction?;
          return CheckoutScreen(transaction: transaction);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Route tidak ditemukan: ${state.matchedLocation}'),
      ),
    ),
  );
});
