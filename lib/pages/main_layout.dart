import 'package:flutter/material.dart';
import 'home.dart';
import 'commerce_detail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class MainLayout extends StatefulWidget {
  @override
  _MainLayoutState createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  Future<bool> _onWillPop() async {
    if (_navigatorKey.currentState != null &&
        _navigatorKey.currentState!.canPop()) {
      _navigatorKey.currentState!.pop();
      return false;
    }
    return true;
  }

  void _onItemTapped(int index) {
    if (index != _selectedIndex) {
      setState(() {
        _selectedIndex = index;
      });
      _navigatorKey.currentState?.popUntil((route) => route.isFirst);
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: Stack(
          children: [
            Navigator(
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

            // Botón de cerrar sesión (esquina superior derecha)
            Positioned(
              top: 40,
              right: 20,
              child: FloatingActionButton(
                mini: true,
                onPressed: _signOut,
                backgroundColor: Colors.black,
                child: const Icon(Icons.logout, color: Colors.white),
                tooltip: 'Cerrar sesión',
              ),
            ),
          ],
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
