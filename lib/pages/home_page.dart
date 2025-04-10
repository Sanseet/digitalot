import 'package:digitalot/pages/IndustryPage.dart';
import 'package:digitalot/pages/farmingPage.dart';
import 'package:digitalot/pages/homepage.dart';
import 'package:digitalot/pages/settingsPage.dart';
import 'package:flutter/material.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    HomePage(),
    IndustryPage(),
    FarmingPage(),
    SettingsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.transparent,
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.blueGrey,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.grey,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined, size: 30),
              activeIcon: Icon(Icons.home, size: 30),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.factory_outlined, size: 30),
              activeIcon: Icon(Icons.factory, size: 30),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.agriculture_outlined, size: 30),
              activeIcon: Icon(Icons.agriculture, size: 30),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined, size: 30),
              activeIcon: Icon(Icons.settings, size: 30),
              label: '',
            ),
          ],
        ),
      ),
    );
  }
}
