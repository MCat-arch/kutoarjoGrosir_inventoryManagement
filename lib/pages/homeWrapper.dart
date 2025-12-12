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

  void _onNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: _pages[_selectedIndex],
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      backgroundColor: Colors.white,
      currentIndex: _selectedIndex,
      onTap: _onNavTap,
      selectedItemColor: const Color(0xFF27AE60),
      unselectedItemColor: Colors.grey[500],
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Home"),
        BottomNavigationBarItem(
          icon: Icon(Icons.inventory_2_rounded),
          label: "Inventory",
        ),
        BottomNavigationBarItem(icon: Icon(Icons.history), label: "Transaksi"),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_2_sharp),
          label: "Pihak",
        ),
      ],
    );
  }
}
