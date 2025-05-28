import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/commerce.dart';
import '../services/commerce_service.dart';
import '../services/user_service.dart';
import 'commerce_detail.dart';
import 'home.dart';
import 'favorites_page.dart';
import 'search_results_page.dart';
import 'map_page.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({Key? key}) : super(key: key);

  @override
  _MainLayoutState createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  final FocusNode _searchFocus = FocusNode();
  final TextEditingController _searchController = TextEditingController();
  bool _searching = false;
  List<String> _recentSearches = [];

  bool _showingSearchResults = false;
  String? _currentSearchQuery;

  final CommerceService _commerceService = CommerceService();
  final UserService _userService = UserService();

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
  }

  void _onItemTapped(int index) {
    if (_searching) {
      setState(() => _searching = false);
      _searchFocus.unfocus();
    }
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
        _showingSearchResults = false;
        _currentSearchQuery = null;
        _searchController.clear();
      });
      _navigatorKey.currentState?.pushReplacementNamed(_routes[index]);
    }
  }

  List<String> get _routes => ['/home', '/explore', '/favorites'];

  Route<dynamic> _onGenerateRoute(RouteSettings settings) {
    Widget page;
    switch (settings.name) {
      case '/home':
        page = HomePage(onCommerceTap: _openDetail);
        break;
      case '/explore':
        page = MapPage();
        break;
      case '/favorites':
        page = FavoritesPage(onCommerceTap: _openDetail);
        break;
      case '/detail':
        final commerce = settings.arguments as Commerce;
        page = CommerceDetailContent(commerce: commerce);
        break;
      case '/search':
        final query = settings.arguments as String;
        page = SearchResultsPage(
          query: query,
          onCommerceTap: _openDetail,
        );
        break;
      default:
        page = HomePage(onCommerceTap: _openDetail);
    }
    return MaterialPageRoute(builder: (_) => page, settings: settings);
  }

  void _openDetail(Commerce commerce) {
    _navigatorKey.currentState?.pushNamed('/detail', arguments: commerce);
  }

  void _triggerSearch() {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    setState(() {
      _searching = false;
      _showingSearchResults = true;
      _currentSearchQuery = query;
      if (!_recentSearches.contains(query)) {
        _recentSearches.insert(0, query);
        if (_recentSearches.length > 3) {
          _recentSearches = _recentSearches.sublist(0, 3);
        }
      }
    });
    _searchFocus.unfocus();
    _navigatorKey.currentState
        ?.pushReplacementNamed('/search', arguments: query);
  }

  void _selectRecentSearch(String query) {
    _searchController.text = query;
    _triggerSearch();
  }

  Widget _getCurrentPage() {
    if (_showingSearchResults && _currentSearchQuery != null) {
      return SearchResultsPage(
        query: _currentSearchQuery!,
        onCommerceTap: _openDetail,
      );
    }
    if (_selectedIndex == 2) {
      return FavoritesPage(onCommerceTap: _openDetail);
    }
    // Home and Explore share navigator
    return HomePage(onCommerceTap: _openDetail);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_showingSearchResults) {
          setState(() {
            _showingSearchResults = false;
            _currentSearchQuery = null;
            _searchController.clear();
          });
          _navigatorKey.currentState
              ?.pushReplacementNamed(_routes[_selectedIndex]);
          return false;
        }
        if (_navigatorKey.currentState?.canPop() ?? false) {
          _navigatorKey.currentState?.pop();
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
                const SizedBox(height: 90),
                Expanded(
                  child: Navigator(
                    key: _navigatorKey,
                    initialRoute: '/home',
                    onGenerateRoute: _onGenerateRoute,
                  ),
                ),
              ],
            ),
            // Search overlay
            if (_searching)
              GestureDetector(
                onTap: () {
                  setState(() => _searching = false);
                  _searchFocus.unfocus();
                },
                child: Container(color: Colors.black.withOpacity(0.3)),
              ),
            // Search bar
            Positioned(
              top: 40,
              left: 16,
              right: 16,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: _searching ? 60 : 50,
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(25),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25)),
                    child: Row(
                      children: [
                        PopupMenuButton<String>(
                          onSelected: (v) => v == 'logout' ? _signOut() : null,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          offset: const Offset(0, 40),
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: 'logout',
                              child: Row(
                                children: const [
                                  Icon(Icons.logout, color: Colors.redAccent),
                                  SizedBox(width: 8),
                                  Text('Cerrar sesión'),
                                ],
                              ),
                            ),
                          ],
                          icon: const Icon(Icons.menu, color: Colors.grey),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocus,
                            onTap: () => setState(() => _searching = true),
                            onSubmitted: (_) => _triggerSearch(),
                            textInputAction: TextInputAction.search,
                            decoration: InputDecoration(
                              hintText: _showingSearchResults
                                  ? 'Buscar de nuevo...'
                                  : 'Buscar Productos...',
                              hintStyle: const TextStyle(color: Colors.grey),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        if (_showingSearchResults)
                          IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              setState(() {
                                _showingSearchResults = false;
                                _currentSearchQuery = null;
                                _searchController.clear();
                              });
                              _navigatorKey.currentState?.pushReplacementNamed(
                                  _routes[_selectedIndex]);
                            },
                          ),
                        IconButton(
                          icon: const Icon(Icons.search, color: Colors.grey),
                          onPressed: _triggerSearch,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (_searching && _recentSearches.isNotEmpty)
              Positioned(
                top: 105,
                left: 16,
                right: 16,
                child: Material(
                  elevation: 2,
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: const [
                            Icon(Icons.history, size: 20, color: Colors.grey),
                            SizedBox(width: 8),
                            Text(
                              'Búsquedas recientes',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                      ..._recentSearches
                          .map((q) => ListTile(
                                title: Text(q),
                                leading: const Icon(Icons.history,
                                    color: Colors.grey),
                                onTap: () => _selectRecentSearch(q),
                              ))
                          .toList(),
                    ],
                  ),
                ),
              ),
          ],
        ),
        bottomNavigationBar: Container(
          margin: const EdgeInsets.all(10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                index: 0,
                icon: Icons.explore_outlined,
                selectedIcon: Icons.explore,
                label: 'Inicio',
              ),
              _buildNavItem(
                index: 1,
                icon: Icons.place_outlined,
                selectedIcon: Icons.place,
                label: 'Explorar',
              ),
              _buildNavItem(
                index: 2,
                icon: Icons.favorite_border,
                selectedIcon: Icons.favorite,
                label: 'Me gusta',
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
  }) {
    final isSelected = !_showingSearchResults && _selectedIndex == index;
    return InkWell(
      onTap: () => _onItemTapped(index),
      borderRadius: BorderRadius.circular(30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: isSelected
                ? BoxDecoration(
                    color: const Color(0xFFFFD76F),
                    borderRadius: BorderRadius.circular(30),
                  )
                : null,
            child: Icon(
              isSelected ? selectedIcon : icon,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
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
