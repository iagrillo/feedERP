import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:erp_app/features/auth/presentation/providers/auth_provider.dart';

class _NavItem {
  final String label; final IconData icon; final String route;
  const _NavItem(this.label, this.icon, this.route);
}

const _branchNav = [
  _NavItem('Dashboard',  Icons.dashboard_outlined,       '/branch/dashboard'),
  _NavItem('Inventory',  Icons.inventory_2_outlined,     '/branch/inventory'),
  _NavItem('Sales',      Icons.receipt_long_outlined,    '/branch/sales'),
  _NavItem('Purchases',  Icons.shopping_cart_outlined,   '/branch/purchases'),
  _NavItem('Transfers',  Icons.swap_horiz_rounded,       '/branch/transfers'),
  _NavItem('Accounting', Icons.account_balance_outlined, '/branch/accounting'),
  _NavItem('Products',   Icons.category_outlined,        '/branch/products'),
];

class BranchShell extends ConsumerWidget {
  final Widget child;
  const BranchShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user      = ref.watch(authNotifierProvider).valueOrNull;
    final location  = GoRouterState.of(context).matchedLocation;
    final selIdx    = _branchNav.indexWhere((n) => location.startsWith(n.route));
    final isWide    = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: isWide,
            selectedIndex: selIdx < 0 ? 0 : selIdx,
            onDestinationSelected: (i) => context.go(_branchNav[i].route),
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(children: [
                Icon(Icons.store_outlined, color: Colors.white, size: 28),
                if (isWide && user?.branchId != null) ...[
                  const SizedBox(height: 4),
                  Text(user?.fullName ?? '', overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ]),
            ),
            trailing: Expanded(child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white70),
                  onPressed: () => ref.read(authNotifierProvider.notifier).signOut(),
                ),
              ),
            )),
            destinations: _branchNav.map((n) => NavigationRailDestination(
              icon: Icon(n.icon), label: Text(n.label),
            )).toList(),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}
