// widgets/search_results_page.dart

import 'package:flutter/material.dart';
import '../models/commerce.dart';
import '../services/commerce_service.dart';
import '../services/user_service.dart';
import '../ui/app_colors.dart';

class SearchResultsPage extends StatelessWidget {
  final String query;
  final ValueChanged<Commerce> onCommerceTap;

  const SearchResultsPage({
    Key? key,
    required this.query,
    required this.onCommerceTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Resultados de búsqueda',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
      ),
      body: SearchResultsContent(
        query: query,
        onCommerceTap: onCommerceTap,
      ),
    );
  }
}

class SearchResultsContent extends StatefulWidget {
  final String query;
  final ValueChanged<Commerce> onCommerceTap;

  const SearchResultsContent({
    Key? key,
    required this.query,
    required this.onCommerceTap,
  }) : super(key: key);

  @override
  _SearchResultsContentState createState() => _SearchResultsContentState();
}

class _SearchResultsContentState extends State<SearchResultsContent> {
  final CommerceService _commerceService = CommerceService();
  final UserService _userService = UserService();

  List<Commerce> _searchResults = [];
  List<Commerce> _recommended = [];
  List<String> _userFavorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Buscar comercios por query
      final results = await _commerceService.searchCommerces(widget.query);
      // Cargar primeros 3 comercios como recomendados
      final all = await _commerceService.fetchCommerces();
      final recommended = all.take(3).toList();
      // IDs favoritos del usuario
      final favIds = await _userService.fetchFavoriteIds();

      setState(() {
        _searchResults = results;
        _recommended = recommended;
        _userFavorites = favIds;
        _isLoading = false;
      });
    } catch (e) {
      print('Error al cargar datos de búsqueda: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleFavorite(String commerceId) async {
    try {
      final isFav = _userFavorites.contains(commerceId);
      if (isFav) {
        await _userService.removeFromFavorites(commerceId);
        _userFavorites.remove(commerceId);
      } else {
        await _userService.addToFavorites(commerceId);
        _userFavorites.add(commerceId);
      }
      setState(() {});
    } catch (e) {
      print('Error al actualizar favorito: $e');
    }
  }

  void _confirmToggleFavorite(BuildContext context, Commerce c) {
    final isFav = _userFavorites.contains(c.id);
    if (isFav) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('¿Eliminar de tus Me Gusta?'),
          content: Text('¿Deseas quitar "${c.name}" de tus favoritos?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _toggleFavorite(c.id);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Eliminar'),
            ),
          ],
        ),
      );
    } else {
      _toggleFavorite(c.id);
    }
  }

  Widget _buildCommerceCard(Commerce c) {
    final isFav = _userFavorites.contains(c.id);
    final imageUrl = c.images.isNotEmpty ? c.images.first : '';

    return GestureDetector(
      onTap: () => widget.onCommerceTap(c),
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 4 / 3,
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: imageUrl.startsWith('http')
                    ? Image.network(imageUrl, fit: BoxFit.cover)
                    : Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.store,
                            size: 50, color: Colors.grey)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          c.name,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _confirmToggleFavorite(context, c),
                        icon: Icon(
                            isFav ? Icons.favorite : Icons.favorite_border,
                            size: 16,
                            color: isFav ? Colors.red : Colors.grey),
                        label: Text(isFav ? 'Te Gusta' : 'Me Gusta'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.complement,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (c.city.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(c.city,
                            style: const TextStyle(
                                fontSize: 14, color: Colors.grey)),
                      ],
                    ),
                  const SizedBox(height: 12),
                  if (c.description.isNotEmpty)
                    Text(
                      c.description.length > 100
                          ? '${c.description.substring(0, 100)}...'
                          : c.description,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Resultados de búsqueda
        if (_searchResults.isEmpty) ...[
          const SizedBox(height: 40),
          const Icon(Icons.search_off, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('No se encontraron resultados',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          const Text('Intenta con otros términos de búsqueda',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey)),
        ] else ...[
          Text('Resultados (${_searchResults.length})',
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87)),
          const SizedBox(height: 16),
          ..._searchResults.map(_buildCommerceCard),
        ],

        // Recomendados
        if (_recommended.isNotEmpty) ...[
          const SizedBox(height: 24),
          Divider(thickness: 1, color: Colors.grey[300]),
          const SizedBox(height: 24),
          const Text('Recomendados para ti',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ..._recommended.map(_buildCommerceCard),
        ],

        const SizedBox(height: 16),
      ],
    );
  }
}
