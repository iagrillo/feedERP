import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:erp_app/core/utils/user_role.dart';
import 'package:erp_app/features/auth/presentation/pages/login_page.dart';
import 'package:erp_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:erp_app/features/admin/presentation/pages/admin_shell.dart';
import 'package:erp_app/features/admin/presentation/pages/admin_dashboard_page.dart';
import 'package:erp_app/features/admin/presentation/pages/branch_management_page.dart';
import 'package:erp_app/features/admin/presentation/pages/user_management_page.dart';
import 'package:erp_app/features/admin/presentation/pages/global_inventory_page.dart';
import 'package:erp_app/features/branch/presentation/pages/branch_shell.dart';
import 'package:erp_app/features/branch/presentation/pages/branch_dashboard_page.dart';
import 'package:erp_app/features/inventory/presentation/pages/inventory_page.dart';
import 'package:erp_app/features/sales/presentation/pages/sales_list_page.dart';
import 'package:erp_app/features/sales/presentation/pages/create_sale_page.dart';
import 'package:erp_app/features/purchases/presentation/pages/purchases_list_page.dart';
import 'package:erp_app/features/purchases/presentation/pages/create_purchase_page.dart';
import 'package:erp_app/features/transfers/presentation/pages/transfers_page.dart';
import 'package:erp_app/features/accounting/presentation/pages/accounting_page.dart';
import 'package:erp_app/features/products/presentation/pages/products_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authAsync = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoading = authAsync.isLoading;
      if (isLoading) return null;

      final user   = authAsync.valueOrNull;
      final isAuth = user != null;
      final isLogin = state.matchedLocation == '/login';

      if (!isAuth && !isLogin) return '/login';
      if (isAuth && isLogin) {
        return user.isAdmin ? '/admin' : '/branch/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),

      //  Admin shell (NavigationRail) 
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(path: '/admin',                builder: (_, __) => const AdminDashboardPage()),
          GoRoute(path: '/admin/branches',       builder: (_, __) => const BranchManagementPage()),
          GoRoute(path: '/admin/users',          builder: (_, __) => const UserManagementPage()),
          GoRoute(path: '/admin/inventory',      builder: (_, __) => const GlobalInventoryPage()),
          GoRoute(path: '/admin/products',       builder: (_, __) => const ProductsPage()),
          GoRoute(path: '/admin/accounting',     builder: (_, __) => const AccountingPage()),
          GoRoute(path: '/admin/sales',          builder: (_, __) => const SalesListPage()),
          GoRoute(path: '/admin/purchases', builder: (_, __) => const PurchasesListPage()),
          GoRoute(path: '/admin/purchases/create', builder: (_, __) => const CreatePurchasePage()),
          GoRoute(path: '/admin/transfers',      builder: (_, __) => const TransfersPage()),
        ],
      ),

      //  Branch shell (NavigationRail) 
      ShellRoute(
        builder: (context, state, child) => BranchShell(child: child),
        routes: [
          GoRoute(path: '/branch/dashboard',    builder: (_, __) => const BranchDashboardPage()),
          GoRoute(path: '/branch/inventory',    builder: (_, __) => const InventoryPage()),
          GoRoute(path: '/branch/sales',        builder: (_, __) => const SalesListPage()),
          GoRoute(path: '/branch/sales/create', builder: (_, __) => const CreateSalePage()),
          GoRoute(path: '/branch/purchases',    builder: (_, __) => const PurchasesListPage()),
          GoRoute(path: '/branch/purchases/create', builder: (_, __) => const CreatePurchasePage()),
          GoRoute(path: '/branch/transfers',    builder: (_, __) => const TransfersPage()),
          GoRoute(path: '/branch/accounting',   builder: (_, __) => const AccountingPage()),
          GoRoute(path: '/branch/products',     builder: (_, __) => const ProductsPage()),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Route not found: ${state.error}')),
    ),
  );
});

