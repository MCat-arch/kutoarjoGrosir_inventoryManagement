import 'package:flutter/material.dart';
import 'package:kg/pages/home.dart';
import 'package:kg/pages/laporan_keuangan.dart';
import 'package:kg/pages/list_produk.dart';
import 'package:kg/pages/party_pages.dart';
import 'package:kg/utils/colors.dart';

class Homewrapper extends StatefulWidget {
  const Homewrapper({super.key});

  @override
  State<Homewrapper> createState() => _HomewrapperState();
}

class _HomewrapperState extends State<Homewrapper> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    HomeScreen(),
    InventoryScreen(),
    HistoryKeuangan(),
    PartyPages(),
  ];

  // Warna Tema Retro
  final Color _bgCream = const Color(0xFFFFFEF7);
  final Color _borderColor = Colors.black;

  // Data Menu Navigasi
  final List<Map<String, dynamic>> _navItems = [
    {
      'icon': Icons.storefront_outlined,
      'activeIcon': Icons.storefront,
      'label': 'Home',
    },
    {
      'icon': Icons.inventory_2_outlined,
      'activeIcon': Icons.inventory_2,
      'label': 'Stok',
    },
    {
      'icon': Icons.receipt_long_outlined,
      'activeIcon': Icons.receipt_long,
      'label': 'Transaksi',
    },
    {'icon': Icons.group_outlined, 'activeIcon': Icons.group, 'label': 'Pihak'},
  ];

  void _onNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgCream,
      body: _pages[_selectedIndex],
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _borderColor, width: 2)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_navItems.length, (index) {
              return _buildNavItem(index);
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index) {
    bool isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => _onNavTap(index),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOutQuad,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 20 : 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? _navItems[index]['activeIcon']
                  : _navItems[index]['icon'],
              color: isSelected ? Colors.white : Colors.grey[600],
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                _navItems[index]['label'],
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
