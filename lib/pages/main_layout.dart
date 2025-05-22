import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'home.dart';
import 'commerce_detail.dart';
import 'favorites_page.dart';

class MainLayout extends StatefulWidget {
  @override
  _MainLayoutState createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  final List<String> _routes = ['/home', '/explore', '/favorites'];

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
  }

  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });
      _navigatorKey.currentState?.pushReplacementNamed(_routes[index]);
    }
  }

  Route _onGenerateRoute(RouteSettings settings) {
    Widget page;
    switch (settings.name) {
      case '/home':
        page = HomePage();
        break;
      case '/explore':
        page = HomePage();
        break;
      case '/favorites':
        page = FavoritesPage();
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
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_navigatorKey.currentState != null &&
            _navigatorKey.currentState!.canPop()) {
          _navigatorKey.currentState!.pop();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            Column(
              children: [
                SizedBox(height: 90),
                Expanded(
                  child: Navigator(
                    key: _navigatorKey,
                    initialRoute: '/home',
                    onGenerateRoute: _onGenerateRoute,
                  ),
                ),
              ],
            ),

            // Barra de búsqueda con menú desplegable
            Positioned(
              top: 40,
              left: 16,
              right: 16,
              child: Material(
                elevation: 3,
                borderRadius: BorderRadius.circular(25),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Color.fromARGB(236, 255, 255, 255),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    children: [
                      SizedBox(width: 8),
                      // Menú desplegable con opción de cerrar sesión
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'logout') {
                            _signOut();
                          }
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        offset: Offset(0, 40),
                        itemBuilder: (context) => [
                          PopupMenuItem<String>(
                            value: 'logout',
                            child: Row(
                              children: [
                                Icon(Icons.logout,
                                    color:
                                        const Color.fromARGB(221, 201, 57, 57)),
                                SizedBox(width: 8),
                                Text('Cerrar sesión'),
                              ],
                            ),
                          ),
                        ],
                        icon: Icon(Icons.menu, color: Colors.grey),
                      ),
                      SizedBox(width: 4),
                      Expanded(
                        child: TextField(
                          enabled: false,
                          decoration: InputDecoration(
                            hintText: 'Buscar Productos...',
                            hintStyle: TextStyle(color: Colors.grey),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      Icon(Icons.search, color: Colors.grey),
                      SizedBox(width: 12),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: Container(
          margin: EdgeInsets.all(10),
          // padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          // decoration: BoxDecoration(
          //   color: Color(0xF6F2FA),
          //   borderRadius: BorderRadius.circular(40),
          //   boxShadow: [
          //     BoxShadow(
          //       color: Colors.black.withOpacity(0.1),
          //       // blurRadius: 2,
          //       offset: Offset(1, 4),
          //     ),
          //   ],
          // ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                index: 0,
                icon: Icons.explore_outlined,
                label: 'Inicio',
                selectedIcon: Icons.explore,
                highlight: true,
              ),
              _buildNavItem(
                index: 1,
                icon: Icons.place_outlined,
                label: 'Explorar',
                selectedIcon: Icons.place,
                highlight: true,
              ),
              _buildNavItem(
                index: 2,
                icon: Icons.favorite_border,
                label: 'Me gusta',
                selectedIcon: Icons.favorite,
                highlight: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    bool highlight = false,
  }) {
    bool isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => _onItemTapped(index),
      borderRadius: BorderRadius.circular(30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: isSelected && highlight
                ? BoxDecoration(
                    color: Color(0xFFFFD76F),
                    borderRadius: BorderRadius.circular(30),
                  )
                : null,
            child: Icon(
              isSelected ? selectedIcon : icon,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 12,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
