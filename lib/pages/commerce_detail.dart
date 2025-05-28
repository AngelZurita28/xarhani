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
import 'package:url_launcher/url_launcher.dart';

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

// LocationPreview Widget (Integrated)
class LocationPreview extends StatelessWidget {
  final String ubication;

  const LocationPreview({Key? key, required this.ubication}) : super(key: key);

  // Parses coordinates from the ubication string or URL
  LatLng? get _coords {
    try {
      // Case 1: Direct lat,lng format
      if (RegExp(r'^-?\d+\.\d+,-?\d+\.\d+$').hasMatch(ubication)) {
        final parts = ubication.trim().split(',');
        return LatLng(
          double.parse(parts[0].trim()),
          double.parse(parts[1].trim()),
        );
      }

      // Case 2: Google Maps URL
      if (ubication.contains('google.com/maps') ||
          ubication.contains('goo.gl')) {
        final match =
            RegExp(r'[@&]ll?=(-?\d+\.\d+),(-?\d+\.\d+)').firstMatch(ubication);
        if (match != null) {
          return LatLng(
            double.parse(match.group(1)!),
            double.parse(match.group(2)!),
          );
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error parsing coordinates: $e');
      return null;
    }
  }

  // Generates the static map URL using Google Static Maps API
  String get _staticMapUrl {
    final coords = _coords;
    if (coords == null) return '';

    const apiKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');
    if (apiKey.isEmpty) {
      debugPrint('Google Maps API key is missing');
      return '';
    }

    return 'https://maps.googleapis.com/maps/api/staticmap'
        '?center=${coords.latitude},${coords.longitude}'
        '&zoom=15'
        '&size=600x300'
        '&markers=color:0xFFFFB400|${coords.latitude},${coords.longitude}'
        '&key=$apiKey';
  }

  // Generates the URL to open in Google Maps
  String get _mapsUrl {
    final coords = _coords;
    if (coords != null) {
      return 'https://www.google.com/maps/dir/?api=1&destination=${coords.latitude},${coords.longitude}';
    } else if (ubication.contains('google.com/maps') ||
        ubication.contains('goo.gl')) {
      return ubication;
    } else {
      return 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(ubication)}';
    }
  }

  // Attempts to open Google Maps app or falls back to browser
  Future<void> _launchMaps() async {
    try {
      final mapsUrl = _mapsUrl;
      final uri = Uri.parse(mapsUrl);

      // Try Google Maps app first
      final googleMapsUri = Uri.parse(
        'comgooglemaps://?daddr=${_coords?.latitude ?? ''},${_coords?.longitude ?? ''}',
      );

      if (await canLaunchUrl(googleMapsUri) && _coords != null) {
        await launchUrl(googleMapsUri, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('Cannot launch Google Maps');
      }
    } catch (e) {
      debugPrint('Error launching Google Maps: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final mapUrl = _staticMapUrl;

    return GestureDetector(
      onTap: () async {
        final open = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: Colors.white,
            title: const Text('Abrir en Google Maps',
                style: TextStyle(fontWeight: FontWeight.bold)),
            content: const Text('¿Deseas abrir la ubicación en Google Maps?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Abrir'),
              ),
            ],
          ),
        );

        if (open == true) {
          await _launchMaps();
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: mapUrl.isNotEmpty
            ? Image.network(
                mapUrl,
                fit: BoxFit.cover,
                height: 200,
                width: double.infinity,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 200,
                    color: AppColors.bgSecondary,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) =>
                    _buildPlaceholder(),
              )
            : _buildPlaceholder(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      height: 200,
      color: AppColors.bgSecondary,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map_outlined,
              size: 48,
              color: AppColors.disabled,
            ),
            SizedBox(height: 8),
            Text(
              'Vista previa no disponible',
              style: TextStyle(
                color: AppColors.disabled,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LatLng {
  final double latitude;
  final double longitude;

  LatLng(this.latitude, this.longitude);
}
