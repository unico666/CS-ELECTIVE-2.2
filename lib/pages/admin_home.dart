import 'package:flutter/material.dart';

import '../widgets/logout_button.dart';
import 'admin_categories_page.dart';
import 'admin_orders_page.dart';
import 'product_form_page.dart';
import 'product_list_page.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _index = 0;

  static const _titles = ['Products', 'Categories', 'All orders'];

  Widget? _buildFab() {
    if (_index == 0) {
      return FloatingActionButton(
        tooltip: 'Add product',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ProductFormPage()),
        ),
        child: const Icon(Icons.add),
      );
    }
    if (_index == 1) {
      return FloatingActionButton(
        tooltip: 'Add category',
        onPressed: () => showCategoryDialog(context),
        child: const Icon(Icons.add),
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin · ${_titles[_index]}'),
        actions: const [LogoutButton()],
      ),
      body: IndexedStack(
        index: _index,
        children: const [
          ProductListPage(isAdmin: true),
          AdminCategoriesPage(),
          AdminOrdersPage(),
        ],
      ),
      floatingActionButton: _buildFab(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Products',
          ),
          NavigationDestination(
            icon: Icon(Icons.category_outlined),
            selectedIcon: Icon(Icons.category),
            label: 'Categories',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
        ],
      ),
    );
  }
}
