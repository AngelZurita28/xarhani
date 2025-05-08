import 'package:flutter/material.dart';
import 'home.dart';
import 'commerce_detail.dart';

class MainLayout extends StatefulWidget {
  @override
  _MainLayoutState createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  // Intercepta el botón de retroceso para manejar la navegación interna
  Future<bool> _onWillPop() async {
    if (_navigatorKey.currentState != null &&
        _navigatorKey.currentState!.canPop()) {
      _navigatorKey.currentState!.pop();
      return false;
    }
    return true;
  }

  // Al cambiar de pestaña, se actualiza el índice y se reinicia la pila interna
  void _onItemTapped(int index) {
    if (index != _selectedIndex) {
      setState(() {
        _selectedIndex = index;
      });
      _navigatorKey.currentState?.popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        // Navigator anidado que gestiona la navegación interna
        body: Navigator(
          key: _navigatorKey,
          initialRoute: '/',
          onGenerateRoute: (RouteSettings settings) {
            Widget page;
            switch (settings.name) {
              case '/':
                page = HomePage();
                break;
              case '/detail':
                final commerce = settings.arguments as Map<String, dynamic>;
                page = CommerceDetailContent(commerce: commerce);
                break;
              default:
                page = HomePage();
            }
            return MaterialPageRoute(
              builder: (_) => page,
              settings: settings,
            );
          },
        ),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: Color(0xffffffff),
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.black,
          items: [
            BottomNavigationBarItem(
              icon: Container(
                decoration: BoxDecoration(
                  color: _selectedIndex == 0
                      ? Color(0xFFFFC333)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: EdgeInsets.all(8),
                child: Icon(Icons.explore),
              ),
              label: 'Inicio',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search),
              label: 'Explorar',
            ),
          ],
        ),
      ),
    );
  }
}
