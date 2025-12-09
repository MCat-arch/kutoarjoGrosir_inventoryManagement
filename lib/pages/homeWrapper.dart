import 'package:flutter/material.dart';
import 'package:kg/pages/home.dart';
import 'package:kg/pages/laporan_keuangan.dart';
import 'package:kg/pages/list_produk.dart';
import 'package:kg/pages/party/party_pages.dart';
import 'package:kg/utils/colors.dart';

class Homewrapper extends StatefulWidget {
  const Homewrapper({super.key});

  @override
  State<Homewrapper> createState() => _HomewrapperState();
}

class _HomewrapperState extends State<Homewrapper> {
  bool _initialized = false;
  int _selectedIndex = 0;

  final List<Widget> pages = [
    HomeScreen(),
    InventoryScreen(),
    HistoryKeuangan(),
    PartyPages(),
  ];

  void onNavTap(index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: pages[_selectedIndex],
      bottomNavigationBar: navbar(_selectedIndex, onNavTap),
    );
  }

  Widget navbar(int currentIndex, ValueChanged<int> onTap) {
    return BottomNavigationBar(
      backgroundColor: const Color.fromARGB(197, 2, 70, 255),
      currentIndex: currentIndex,
      onTap: onTap,
      items: [
        BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Home"),
        BottomNavigationBarItem(
          icon: Icon(Icons.inventory_2_rounded),
          label: "Inventory",
        ),
        BottomNavigationBarItem(icon: Icon(Icons.history), label: "History"),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_2_sharp),
          label: "Party",
        ),
      ],
    );
  }
}
