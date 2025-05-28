import 'package:flutter/material.dart';
import '../models/commerce.dart';
import '../models/product.dart';
import '../services/commerce_service.dart';
import '../services/user_service.dart';
import '../ui/app_colors.dart';
import '../widgets/image_carousel_with_favorite.dart';
import '../widgets/tab_selector.dart';
import '../widgets/info_tab.dart';
import '../widgets/products_tab.dart';
import '../widgets/full_screen_image_viewer.dart';
import '../widgets/location_preview.dart';

class CommerceDetailContent extends StatefulWidget {
  final Commerce commerce;
  const CommerceDetailContent({Key? key, required this.commerce})
      : super(key: key);

  @override
  _CommerceDetailContentState createState() => _CommerceDetailContentState();
}

class _CommerceDetailContentState extends State<CommerceDetailContent> {
  int _selectedTab = 0;
  late Future<List<Product>> _productsFuture;
  bool _isFavorite = false;
  bool _isLoadingFavorite = true;

  final CommerceService _commerceService = CommerceService();
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _productsFuture = _commerceService.fetchProducts(widget.commerce.id);
    _loadFavorite();
  }

  Future<void> _loadFavorite() async {
    setState(() => _isLoadingFavorite = true);
    final fav = await _userService.isCommerceFavorite(widget.commerce.id);
    if (!mounted) return;
    setState(() {
      _isFavorite = fav;
      _isLoadingFavorite = false;
    });
  }

  Future<void> _toggleFavorite() async {
    if (_userService.currentUser == null) {
      _showLoginDialog();
      return;
    }
    setState(() => _isLoadingFavorite = true);
    try {
      if (_isFavorite) {
        await _userService.removeFromFavorites(widget.commerce.id);
      } else {
        await _userService.addToFavorites(widget.commerce.id);
      }
      if (!mounted) return;
      setState(() {
        _isFavorite = !_isFavorite;
        _isLoadingFavorite = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingFavorite = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Error: No se pudo actualizar favoritos'),
          backgroundColor: Colors.red.shade600,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: const Text('Iniciar sesión requerido',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
            'Debes iniciar sesión para guardar comercios favoritos.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed('/login');
            },
            child: const Text('Iniciar sesión'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerScroll) => [
            SliverToBoxAdapter(
              child: ImageCarouselWithFavorite(
                images: widget.commerce.images,
                isFavorite: _isFavorite,
                isLoading: _isLoadingFavorite,
                onToggleFavorite: _toggleFavorite,
                onImageTap: (index) => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => FullScreenImageViewer(
                      images: widget.commerce.images,
                      initialIndex: index,
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(child: const SizedBox(height: 20)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: LocationPreview(
                  ubication: widget.commerce.ubication,
                ),
              ),
            ),
            SliverToBoxAdapter(child: const SizedBox(height: 20)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: TabSelector(
                  tabs: const ['Información', 'Productos'],
                  selected: _selectedTab,
                  onTap: (i) => setState(() => _selectedTab = i),
                ),
              ),
            ),
            SliverToBoxAdapter(child: const SizedBox(height: 12)),
          ],
          body: _selectedTab == 0
              ? InfoTab(
                  description: widget.commerce.description,
                  history: widget.commerce.history,
                )
              : ProductsTab(productsFuture: _productsFuture),
        ),
      ),
    );
  }
}
