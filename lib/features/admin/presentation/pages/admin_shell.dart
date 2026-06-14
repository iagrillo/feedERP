import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:erp_app/features/auth/presentation/providers/auth_provider.dart';

class _NavItem {
  final String   label;
  final IconData icon;
  final String   route;
  const _NavItem(this.label, this.icon, this.route);
}

const _adminNav = [
  _NavItem('Dashboard',   Icons.dashboard_outlined,        '/admin'),
  _NavItem('Branches',    Icons.store_outlined,            '/admin/branches'),
  _NavItem('Users',       Icons.people_outline,            '/admin/users'),
  _NavItem('Inventory',   Icons.inventory_2_outlined,      '/admin/inventory'),
  _NavItem('Products',    Icons.category_outlined,         '/admin/products'),
  _NavItem('Sales',       Icons.receipt_long_outlined,     '/admin/sales'),
  _NavItem('Purchases',   Icons.shopping_cart_outlined,    '/admin/purchases'),
  _NavItem('Transfers',   Icons.swap_horiz_rounded,        '/admin/transfers'),
  _NavItem('Accounting',  Icons.account_balance_outlined,  '/admin/accounting'),
];

class AdminShell extends ConsumerWidget {
  final Widget child;
  const AdminShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location  = GoRouterState.of(context).matchedLocation;
    final selectedIdx = _adminNav.indexWhere((n) => n.route == location)
        .clamp(0, _adminNav.length - 1);
    final isWide = MediaQuery.of(context).size.width > 700;

    final navRail = NavigationRail(
      extended: isWide,
      selectedIndex: selectedIdx < 0 ? 0 : selectedIdx,
      onDestinationSelected: (i) => context.go(_adminNav[i].route),
      leading: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(children: [
          Icon(Icons.agriculture_rounded, color: Colors.white, size: 32),
          if (isWide) const SizedBox(height: 4),
          if (isWide) const Text('FeedERP',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        ]),
      ),
      trailing: Expanded(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: IconButton(
              icon: const Icon(Icons.logout, color: Colors.white70),
              tooltip: 'Sign out',
              onPressed: () => ref.read(authNotifierProvider.notifier).signOut(),
            ),
          ),
        ),
      ),
      destinations: _adminNav.map((n) => NavigationRailDestination(
        icon:  Icon(n.icon),
        label: Text(n.label),
      )).toList(),
    );

    return Scaffold(
      body: Row(
        children: [
          navRail,
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}
