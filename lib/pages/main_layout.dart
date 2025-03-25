import 'package:flutter/material.dart';
import 'home.dart';

class MainLayout extends StatefulWidget {
  @override
  _MainLayoutState createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [HomePage()];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex], // Cambia solo la pantalla principal
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.black,
        unselectedIconTheme: IconThemeData(color: Colors.black),
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(
            icon: Container(
              decoration: BoxDecoration(
                color: _selectedIndex == 0
                    ? Color(0xFFFFC333)
                    : Colors.transparent, // Fondo amarillo si está seleccionado
                borderRadius: BorderRadius.circular(20),
              ),
              padding: EdgeInsets.all(8),
              child: Icon(Icons.explore),
            ),
            label: "Inicio",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Explorar"),
          BottomNavigationBarItem(
              icon: Icon(Icons.favorite), label: "Me gusta"),
        ],
      ),
    );
  }
}
